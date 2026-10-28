from datetime import date,datetime,timezone,timedelta
from app.market import parse_dividends,summarize_dividends
from app.database import SessionLocal,MarketCache
from conftest import send
import pytest


def test_payment_dates_not_ex_dates():
    rows=''.join(f'<tr><td>Rendimento</td><td>28/{m:02}/2025</td><td>15/{m+1:02}/2025</td><td>0,09000000</td></tr>' for m in range(1,8))
    text='<table><tr><th>Tipo</th><th>DATA COM</th><th>Pagamento</th><th>Valor</th></tr>'+rows+'</table>'
    e=parse_dividends(text);s=summarize_dividends(e,date(2025,9,1))
    assert s['last_payment_date']=='2025-08-15';assert s['last_amount_per_share']==.09
    assert s['frequency']=='Mensal (estimado)';assert s['typical_day']==15


def test_only_ex_date_is_insufficient():
    s=summarize_dividends([{'ex_date':'2026-10-01','payment_date':None,'amount':1}])
    assert s['last_payment_date'] is None;assert s['frequency']=='Dados insuficientes'


def test_same_day_jcp_and_dividend_are_summed_future_excluded():
    e=[{'payment_date':'2026-09-15','amount':.1},{'payment_date':'2026-09-15','amount':.2},{'payment_date':'2099-01-01','amount':9}]
    s=summarize_dividends(e,date(2026,10,1));assert abs(s['last_amount_per_share']-.3)<1e-10


def test_revoked_or_nonallowlisted_user_cannot_upload(monkeypatch,client,files):
    async def fake(*a,**kw):return {'id':'other','email':'someone@example.com','email_confirmed_at':'2026-01-01'}
    monkeypatch.setattr('app.auth.auth_request',fake)
    r=client.post('/api/imports/preview',headers={'Authorization':'Bearer token'},data={'kind':'stocks','reference':'2026-10'},files={'file':('stocks.xlsx',files['stocks'])})
    assert r.status_code==403


def test_market_failure_uses_dated_stale_cache(monkeypatch,authorized,files):
    send(authorized,files['stocks'])
    cached={'ticker':'B3SA3','quote':{'price':10,'as_of':'2026-01-01T00:00:00Z'},'warnings':[]}
    with SessionLocal.begin() as db:db.add(MarketCache(ticker='B3SA3',fetched_at=datetime.now(timezone.utc)-timedelta(hours=2),payload=cached))
    async def failure(*a,**kw):return {'quote':None,'warnings':['Falhou']}
    monkeypatch.setattr('app.main.fetch_market',failure)
    r=authorized.get('/api/assets/B3SA3/market');assert r.status_code==200
    assert r.json()['stale'] is True;assert r.json()['quote']['as_of']=='2026-01-01T00:00:00Z'


def test_login_has_no_demo_password(client):
    r=client.post('/api/auth/login',json={'email':'admin@example.com','password':'admin'})
    assert r.status_code in (401,503)
