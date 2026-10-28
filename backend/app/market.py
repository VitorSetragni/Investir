"""Preços públicos e proventos, com cache, origem e sem inventar data de pagamento."""
import asyncio
from datetime import datetime, timezone, date
from statistics import median
from collections import Counter
from zoneinfo import ZoneInfo
import re
import httpx
from lxml import html
from .rules import norm

HEADERS={'User-Agent':'Mozilla/5.0 (compatible; InvestirApp/1.0)'}
SEMAPHORE=asyncio.Semaphore(4)


def iso_timestamp(v):
    try:return datetime.fromtimestamp(float(v),timezone.utc).isoformat()
    except (TypeError,ValueError,OverflowError,OSError):return None


def parse_date(s):
    try:return datetime.strptime(s.strip(),'%d/%m/%Y').date().isoformat()
    except (ValueError,AttributeError):return None


def parse_dividends(text):
    tree=html.fromstring(text);events=[]
    for table in tree.xpath('//table'):
        rows=table.xpath('.//tr')
        headers=[];column_map=None
        for row in rows:
            cells=[' '.join(c.text_content().split()) for c in row.xpath('./td|./th')]
            labels=[norm(c) for c in cells]
            if 'pagamento' in labels and 'valor' in labels:
                column_map={k:labels.index(k) for k in ('pagamento','valor')}
                for k in ('tipo','data com'):
                    if k in labels:column_map[k]=labels.index(k)
                continue
            if not column_map or len(cells)<=max(column_map.values()):continue
            payment=parse_date(cells[column_map['pagamento']]);amount=cells[column_map['valor']].replace('R$','').replace('.','').replace(',','.').strip()
            if not payment:continue
            try:value=float(amount)
            except ValueError:continue
            typ=cells[column_map['tipo']] if 'tipo' in column_map else 'Provento'
            if 'amortiza' in norm(typ) or value<=0:continue
            events.append(dict(payment_date=payment,amount=value,type=typ,record_date=parse_date(cells[column_map['data com']]) if 'data com' in column_map else None,ex_date=None))
    unique={(e['payment_date'],e['amount'],e['type']):e for e in events}
    return sorted(unique.values(),key=lambda x:x['payment_date'],reverse=True)


def summarize_dividends(events,today=None):
    today=today or datetime.now(ZoneInfo('America/Sao_Paulo')).date();paid=[e for e in events if e.get('payment_date') and e['payment_date']<=today.isoformat()]
    groups={}
    for e in paid:groups[e['payment_date']]=groups.get(e['payment_date'],0)+e['amount']
    dates=sorted(date.fromisoformat(d) for d in groups)
    latest=dates[-1].isoformat() if dates else None
    frequency='Dados insuficientes';typical_day=None;day_range=None
    if len(dates)>=4:
        dates=dates[-16:];gaps=[(b-a).days for a,b in zip(dates,dates[1:])]
        bands=[('Mensal',20,45),('Trimestral',65,115),('Semestral',140,230),('Anual',300,430)]
        frequency='Irregular'
        for label,lo,hi in bands:
            if sum(lo<=g<=hi for g in gaps)/len(gaps)>=.7:frequency=label+' (estimado)';break
        days=[d.day for d in dates]
        if frequency!='Irregular':
            center=int(median(days))
            if sum(abs(d-center)<=4 for d in days)/len(days)>=.7:
                typical_day=center;day_range=[max(1,center-4),min(31,center+4)]
    return dict(last_payment_date=latest,last_amount_per_share=groups.get(latest),frequency=frequency,typical_day=typical_day,typical_day_range=day_range,observations=len(dates),note='Periodicidade e dia são estimados pelo histórico de pagamentos, não uma agenda garantida. Valores brutos, inclusive JCP quando informado.')


async def fetch_market(ticker,kind):
    errors=[];payload=dict(ticker=ticker,currency='BRL',quote=None,history=[],dividends=[],dividend_summary=summarize_dividends([]),sources={},warnings=errors)
    async with SEMAPHORE:
        async with httpx.AsyncClient(timeout=18,headers=HEADERS,follow_redirects=True) as client:
            async def prices():
                url=f'https://query1.finance.yahoo.com/v8/finance/chart/{ticker}.SA'
                try:
                    response=await client.get(url,params={'range':'2y','interval':'1d','events':'div,splits'})
                    response.raise_for_status();data=response.json()['chart']['result'][0];meta=data['meta']
                    values=data['indicators']['quote'][0];ts=data.get('timestamp',[])
                    payload['quote']=dict(price=meta.get('regularMarketPrice'),previous_close=meta.get('previousClose'),as_of=iso_timestamp(meta.get('regularMarketTime')),market_state='Consulte o horário da cotação; dados podem ter atraso.',name=meta.get('longName') or meta.get('shortName') or ticker)
                    payload['history']=[dict(date=datetime.fromtimestamp(t,timezone.utc).date().isoformat(),close=values['close'][i]) for i,t in enumerate(ts) if values['close'][i] is not None and (values.get('volume',[0]*len(ts))[i] or 0)>0]
                    payload['sources']['prices']=url
                    payload['ex_date_events']=[dict(ex_date=iso_timestamp(e.get('date')),amount=e.get('amount'),payment_date=None) for e in data.get('events',{}).get('dividends',{}).values()]
                except (httpx.HTTPError,ValueError,KeyError,TypeError,IndexError):errors.append('Cotação e gráfico indisponíveis no provedor público. Nenhum preço foi estimado.')
            async def dividends():
                path='acoes' if kind=='stocks' else 'fundos-imobiliarios';url=f'https://statusinvest.com.br/{path}/{ticker.lower()}'
                try:
                    response=await client.get(url);response.raise_for_status();events=parse_dividends(response.text)
                    payload['dividends']=events[:60];payload['dividend_summary']=summarize_dividends(events)
                    payload['sources']['dividends']=url
                    if not events:errors.append('Datas de pagamento não disponíveis. Data ex-dividendo não foi usada como data de pagamento.')
                except (httpx.HTTPError,ValueError,TypeError):errors.append('Histórico de pagamentos indisponível; consulte o RI do ativo.')
            await asyncio.gather(prices(),dividends())
    payload['fetched_at']=datetime.now(timezone.utc).isoformat()
    return payload
