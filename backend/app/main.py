import asyncio
import hashlib
import logging
import re
import time
from collections import Counter, OrderedDict, deque
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool
from .auth import auth_request, require_uploader
from .config import settings
from .database import initialize, session, Asset, Snapshot, MarketCache
from .importer import parse_workbook, replace_snapshot, ImportErrorDetail
from .market import fetch_market
from .rules import VERSION, evaluate, present_assessment

logger=logging.getLogger('investir')


@asynccontextmanager
async def lifespan(app):
    await run_in_threadpool(initialize)
    yield


app=FastAPI(title='Investir — API',version='1.1.0',lifespan=lifespan)
origins=[x.strip() for x in settings().allowed_origins.split(',') if x.strip()]
app.add_middleware(CORSMiddleware,allow_origins=origins,allow_credentials=False,allow_methods=['GET','POST'],allow_headers=['Authorization','Content-Type'])


class BodyLimit:
    def __init__(self,app):self.app=app
    async def __call__(self,scope,receive,send):
        if scope['type']!='http':return await self.app(scope,receive,send)
        limit=settings().max_upload_bytes+1024*1024
        headers=dict(scope.get('headers',[]));length=headers.get(b'content-length',b'0')
        try:too_large=int(length)>limit
        except ValueError:too_large=True
        if too_large:return await JSONResponse({'detail':'Arquivo excede o limite de 12 MB.'},413)(scope,receive,send)
        total=0
        async def bounded():
            nonlocal total
            message=await receive();total+=len(message.get('body',b''))
            if total>limit:raise HTTPException(413,'Arquivo excede o limite de 12 MB.')
            return message
        return await self.app(scope,bounded,send)


app.add_middleware(BodyLimit)
rate_buckets=OrderedDict()


@app.middleware('http')
async def safety_headers(request,call_next):
    if request.url.path.startswith('/api/auth/') or (request.method=='POST' and request.url.path.startswith('/api/import')):
        # Não confiar em X-Forwarded-For enviado pelo cliente. Uvicorn decide proxies confiáveis.
        key=(request.client.host if request.client else 'unknown',request.url.path)
        now=time.monotonic();bucket=rate_buckets.setdefault(key,deque())
        while bucket and now-bucket[0]>60:bucket.popleft()
        if len(bucket)>=12:return JSONResponse({'detail':'Muitas tentativas. Aguarde um minuto.'},429,headers={'Retry-After':'60'})
        bucket.append(now);rate_buckets.move_to_end(key)
        while len(rate_buckets)>2000:rate_buckets.popitem(last=False)
    response=await call_next(request)
    response.headers['X-Content-Type-Options']='nosniff'
    response.headers['Referrer-Policy']='no-referrer'
    if request.url.path.startswith('/api/auth/') or request.method!='GET':response.headers['Cache-Control']='no-store'
    return response


def snapshot_json(s):
    month=datetime.now(ZoneInfo('America/Sao_Paulo')).strftime('%Y-%m')
    return dict(kind=s.kind,reference=s.reference,filename=s.filename,imported_at=s.imported_at.isoformat() if s.imported_at else None,count=s.count,revision=s.revision,older_than_current_month=bool(s.reference and s.reference<month))


@app.get('/health')
def health(db:Session=Depends(session)):
    db.execute(select(1))
    return {'status':'ok','rules_version':VERSION}


@app.get('/api/catalog')
def catalog(db:Session=Depends(session)):
    snapshots=[snapshot_json(s) for s in db.scalars(select(Snapshot).order_by(Snapshot.kind))]
    assets=[]
    for a in db.scalars(select(Asset).order_by(Asset.ticker)):
        x=a.assessment
        assets.append(dict(ticker=a.ticker,name=a.name,kind=a.kind,category=a.category,segment=a.segment,status=x['status'],acceptable_rules=x['acceptable_rules'],pending_rules=x['pending_rules']))
    return dict(snapshots=snapshots,assets=assets,rules_version=VERSION,demo=settings().demo_mode)


def lookup(ticker,db):
    if not re.fullmatch(r'[A-Z][A-Z0-9]{3}\d{1,2}',ticker):raise HTTPException(404,'Ativo não encontrado.')
    asset=db.get(Asset,ticker)
    if not asset:raise HTTPException(404,'Ativo não encontrado na base atual.')
    return asset


@app.get('/api/assets/{ticker}')
def detail(ticker:str,db:Session=Depends(session)):
    a=lookup(ticker,db)
    return dict(ticker=a.ticker,name=a.name,kind=a.kind,category=a.category,segment=a.segment,source_row=a.source_row,data=a.data,assessment=present_assessment(a.assessment),snapshot=snapshot_json(db.get(Snapshot,a.kind)))


market_locks=OrderedDict()


@app.get('/api/assets/{ticker}/market')
async def market(ticker:str,db:Session=Depends(session)):
    a=lookup(ticker,db);now=datetime.now(timezone.utc)
    cached=db.get(MarketCache,ticker)
    def age(c):return (now-c.fetched_at.replace(tzinfo=timezone.utc)).total_seconds()
    if cached and age(cached)<settings().market_cache_seconds:return dict(cached.payload,cached=True,stale=False)
    lock=market_locks.setdefault(ticker,asyncio.Lock())
    while len(market_locks)>1000:
        key=next(iter(market_locks))
        if market_locks[key].locked():break
        market_locks.pop(key)
    async with lock:
        # Outra sessão pode ter preenchido o cache durante a espera.
        db.expire_all();cached=db.get(MarketCache,ticker)
        if cached and age(cached)<settings().market_cache_seconds:return dict(cached.payload,cached=True,stale=False)
        result=await fetch_market(ticker,a.kind)
        if not result['quote'] and cached:
            return dict(cached.payload,cached=True,stale=True,warnings=cached.payload.get('warnings',[])+['Exibindo último cache: provedor indisponível. Confira a data da cotação.'])
        if cached:cached.payload=result;cached.fetched_at=now
        else:db.add(MarketCache(ticker=ticker,payload=result,fetched_at=now))
        db.commit()
        return dict(result,cached=False,stale=False)


class Login(BaseModel):
    email:str=Field(min_length=3,max_length=254)
    password:str=Field(min_length=1,max_length=256)


class Refresh(BaseModel):
    refresh_token:str=Field(min_length=1,max_length=4096)


@app.post('/api/auth/login')
async def login(body:Login):
    data=await auth_request('token?grant_type=password','POST',payload=body.model_dump())
    token=data.get('access_token')
    if not token:raise HTTPException(502,'Resposta inválida da autenticação.')
    try:user=await require_uploader('Bearer '+token)
    except HTTPException:
        try:await auth_request('logout','POST',token=token)
        except HTTPException:pass
        raise
    return dict(access_token=token,refresh_token=data['refresh_token'],expires_in=data.get('expires_in',3600),email=user['email'])


@app.post('/api/auth/refresh')
async def refresh(body:Refresh):
    data=await auth_request('token?grant_type=refresh_token','POST',payload=body.model_dump())
    user=await require_uploader('Bearer '+data['access_token'])
    return dict(access_token=data['access_token'],refresh_token=data['refresh_token'],expires_in=data.get('expires_in',3600),email=user['email'])


@app.post('/api/auth/logout')
async def logout(request:Request,user=Depends(require_uploader)):
    await auth_request('logout','POST',token=request.headers['authorization'][7:])
    return {'ok':True}


async def upload_records(file,kind,reference):
    data=await file.read(settings().max_upload_bytes+1)
    await file.close()
    if len(data)>settings().max_upload_bytes:raise HTTPException(413,'Arquivo excede 12 MB.')
    try:records=await run_in_threadpool(parse_workbook,data,kind,reference,file.filename or '')
    except ImportErrorDetail as e:raise HTTPException(422,str(e))
    return data,records


@app.post('/api/imports/preview')
async def preview(kind:str=Form(),reference:str=Form(),file:UploadFile=File(),user=Depends(require_uploader),db:Session=Depends(session)):
    content,records=await upload_records(file,kind,reference)
    snap=db.get(Snapshot,kind)
    if snap.reference and reference<snap.reference:raise HTTPException(409,'Competência anterior à base atual.')
    return dict(kind=kind,reference=reference,filename=file.filename,count=len(records),counts=dict(Counter(r['assessment']['status'] for r in records)),sha256=hashlib.sha256(content).hexdigest(),expected_revision=snap.revision,previous=snapshot_json(snap),message='A substituição só ocorre depois de confirmar. Apenas este tipo de planilha será trocado.')


@app.post('/api/imports')
async def import_file(kind:str=Form(),reference:str=Form(),expected_revision:int=Form(),sha256:str=Form(),file:UploadFile=File(),user=Depends(require_uploader),db:Session=Depends(session)):
    content,records=await upload_records(file,kind,reference)
    if hashlib.sha256(content).hexdigest()!=sha256:raise HTTPException(409,'O arquivo mudou depois da revisão. Revise novamente.')
    try:
        snap,changed=replace_snapshot(db,kind,reference,file.filename,content,records,user['id'],expected_revision)
        result=snapshot_json(snap);db.commit()
    except ImportErrorDetail as e:
        db.rollback();raise HTTPException(409,str(e))
    except Exception:
        db.rollback();logger.exception('Falha transacional na importação')
        raise HTTPException(500,'Não foi possível salvar. A base anterior foi preservada.')
    return dict(snapshot=result,changed=changed)


class EvidenceInput(BaseModel):
    key:str
    source_url:str=Field(min_length=10,max_length=1000)
    checked_date:str
    note:str=Field(min_length=8,max_length=1200)


@app.post('/api/assets/{ticker}/evidence')
def evidence(ticker:str,body:EvidenceInput,user=Depends(require_uploader),db:Session=Depends(session)):
    """Atestados específicos por base, descartados na próxima substituição mensal."""
    if not body.source_url.startswith('https://'):raise HTTPException(422,'Use uma fonte HTTPS.')
    try:checked=datetime.strptime(body.checked_date,'%Y-%m-%d').date()
    except ValueError:raise HTTPException(422,'Data inválida.')
    if checked>datetime.now(timezone.utc).date():raise HTTPException(422,'Data de conferência futura.')
    initial=lookup(ticker,db)
    db.execute(select(Snapshot).where(Snapshot.kind==initial.kind).with_for_update()).scalar_one()
    a=db.execute(select(Asset).where(Asset.ticker==ticker).with_for_update()).scalar_one()
    allowed={'profit_verified','no_performance','performance_history_verified','administrator_verified'}
    if body.key not in allowed:raise HTTPException(422,'Tipo de evidência inválido.')
    if body.key=='profit_verified' and a.kind!='stocks':raise HTTPException(422,'Evidência exclusiva de ações.')
    if body.key!='profit_verified' and a.kind!='fiis':raise HTTPException(422,'Evidência exclusiva de FIIs.')
    data=dict(a.data);ev=dict(data.get('_evidence',{}));ev[body.key]=dict(body.model_dump(),checked_by=user['id']);data['_evidence']=ev
    assessment=evaluate(a.kind,data)
    # Reaplicar atestados anteriores, todos pertencentes à mesma planilha.
    from .rules import finish
    if ev.get('no_performance'):
        for rule in assessment['rules']:
            if rule['key']=='Taxa de Performance' and str(data.get('Taxa de Performance','')).strip() in ('','-','—'):rule.update(status='pass',note='Ausência conferida em '+ev['no_performance']['source_url'])
    if ev.get('administrator_verified'):
        for rule in assessment['rules']:
            if rule['key']=='Administrador' and rule['status']=='pending':rule.update(status='pass',note='Identidade conferida em '+ev['administrator_verified']['source_url'])
    if ev.get('performance_history_verified'):
        for rule in assessment['rules']:
            if rule['key']=='Taxa de Performance' and rule['status']=='pending' and rule['note'].startswith('Percentual e IPCA identificados'):
                rule.update(status='pass',note='Fórmula completa e histórico conferidos em '+ev['performance_history_verified']['source_url'])
    assessment=finish(assessment['rules'],assessment['notes'])
    if ev.get('profit_verified'):assessment['notes'].append('Série de lucro conferida pelo responsável: '+ev['profit_verified']['source_url'])
    a.data=data;a.assessment=assessment;db.commit()
    return {'ok':True,'assessment':assessment}
