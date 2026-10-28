from fastapi import HTTPException, Request, Header
import httpx
from .config import settings


def configured():
    s=settings()
    if not s.supabase_url or not s.supabase_anon_key:raise HTTPException(503,'Login ainda não configurado no servidor.')
    return s


async def auth_request(path,method='GET',token=None,payload=None):
    s=configured();headers={'apikey':s.supabase_anon_key}
    if token:headers['Authorization']='Bearer '+token
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            res=await client.request(method,s.supabase_url.rstrip('/')+'/auth/v1/'+path,headers=headers,json=payload)
        if res.status_code==429:raise HTTPException(429,'Muitas tentativas no serviço de login. Aguarde antes de tentar novamente.')
        if res.status_code>=500:raise HTTPException(503,'Serviço de autenticação indisponível. Tente novamente.')
        if res.status_code>=400:raise HTTPException(401,'Credenciais inválidas ou sessão expirada.')
        try:return res.json()
        except ValueError:raise HTTPException(502,'O serviço de autenticação retornou uma resposta inválida.')
    except httpx.HTTPError:raise HTTPException(503,'Serviço de autenticação indisponível. Tente novamente.')


async def require_uploader(authorization: str | None=Header(default=None)):
    if not authorization or not authorization.startswith('Bearer '):raise HTTPException(401,'Entre para importar planilhas.')
    token=authorization[7:]
    user=await auth_request('user',token=token)
    if not user.get('id') or not user.get('email_confirmed_at'):raise HTTPException(403,'Confirme o e-mail para importar.')
    if user.get('email','').lower() not in settings().uploaders:raise HTTPException(403,'Este usuário não tem permissão para substituir a base pública.')
    return user
