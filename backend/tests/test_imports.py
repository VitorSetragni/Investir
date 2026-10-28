import hashlib
from sqlalchemy import select
from app.database import SessionLocal,Asset,Snapshot
from app.importer import parse_workbook,ImportErrorDetail
from conftest import send
import pytest


def test_workbook_counts(records):
    assert len(records['stocks'])==374
    assert len(records['fiis'])==355
    assert len({r['ticker'] for r in records['stocks']})==374


def test_read_public_write_requires_login(client,files):
    assert client.get('/api/catalog').status_code==200
    r=send(client,files['stocks']);assert r.status_code==401
    assert client.get('/api/catalog').json()['assets']==[]


def test_independent_replacement_and_idempotency(authorized,files):
    assert send(authorized,files['stocks']).status_code==200
    assert send(authorized,files['fiis'],'fiis').status_code==200
    before=authorized.get('/api/catalog').json()
    r=send(authorized,files['stocks']);assert r.status_code==200;assert r.json()['changed'] is False
    after=authorized.get('/api/catalog').json()
    assert len(after['assets'])==729
    assert before['snapshots']==after['snapshots']


def test_broken_upload_preserves_old(authorized,files):
    send(authorized,files['stocks']);before=authorized.get('/api/catalog').json()
    assert send(authorized,b'not-a-workbook').status_code==422
    assert authorized.get('/api/catalog').json()==before


def test_old_and_future_months_rejected(authorized,files):
    send(authorized,files['stocks'])
    assert send(authorized,files['stocks'],reference='2026-09',filename='stocks.xlsx').status_code==409
    assert send(authorized,files['stocks'],reference='2099-01',filename='stocks.xlsx').status_code==422
    assert send(authorized,files['stocks'],reference='2026-09').status_code==422


def test_revision_conflict_cannot_overwrite(authorized,files):
    p=authorized.post('/api/imports/preview',data={'kind':'stocks','reference':'2026-10'},files={'file':('stocks.xlsx',files['stocks'])}).json()
    assert send(authorized,files['stocks']).status_code==200
    r=authorized.post('/api/imports',data={'kind':'stocks','reference':'2026-10','expected_revision':p['expected_revision'],'sha256':p['sha256']},files={'file':('stocks.xlsx',files['stocks'])})
    assert r.status_code==409
    assert len(authorized.get('/api/catalog').json()['assets'])==374


def test_different_file_after_preview_rejected(authorized,files):
    r=authorized.post('/api/imports',data={'kind':'stocks','reference':'2026-10','expected_revision':0,'sha256':'0'*64},files={'file':('stocks.xlsx',files['stocks'])})
    assert r.status_code==409;assert authorized.get('/api/catalog').json()['assets']==[]


def test_preview_does_not_change_database(authorized,files):
    assert authorized.post('/api/imports/preview',data={'kind':'fiis','reference':'2026-10'},files={'file':('fiis.xlsx',files['fiis'])}).status_code==200
    assert authorized.get('/api/catalog').json()['assets']==[]


def test_actual_replacement_removes_old_rows_and_preserves_other_kind(records,files):
    from app.importer import replace_snapshot
    with SessionLocal.begin() as db:
        replace_snapshot(db,'stocks','2026-10','old.xlsx',files['stocks'],records['stocks'],'user',0)
        replace_snapshot(db,'fiis','2026-10','fiis.xlsx',files['fiis'],records['fiis'],'user',0)
    subset=records['stocks'][:3]
    with SessionLocal.begin() as db:
        replace_snapshot(db,'stocks','2026-10','new.xlsx',b'changed-file-content',subset,'user',1)
    with SessionLocal() as db:
        assert len(list(db.scalars(select(Asset).where(Asset.kind=='stocks'))))==3
        assert len(list(db.scalars(select(Asset).where(Asset.kind=='fiis'))))==355
        assert db.get(Snapshot,'stocks').filename=='new.xlsx'


def test_unknown_ticker_no_arbitrary_market_request(client):
    assert client.get('/api/assets/ABCD99/market').status_code==404


def test_documentary_evidence_is_tied_to_current_snapshot(authorized,files):
    send(authorized,files['fiis'],'fiis')
    body={'key':'no_performance','source_url':'https://www.kinea.com.br/fundos/','checked_date':'2026-10-01','note':'Regulamento consultado confirma ausência de taxa de performance.'}
    r=authorized.post('/api/assets/KNIP11/evidence',json=body);assert r.status_code==200
    first=authorized.get('/api/assets/KNIP11').json()
    assert first['data']['_evidence']['no_performance']['source_url']==body['source_url']
    assert next(r for r in first['assessment']['rules'] if r['key']=='Taxa de Performance')['status']=='pass'
    # XLSX permite bytes finais fora do ZIP; muda o hash sem alterar as células.
    assert send(authorized,files['fiis']+b'\x00','fiis').status_code==200
    after=authorized.get('/api/assets/KNIP11').json()
    assert '_evidence' not in after['data']
    assert next(r for r in after['assessment']['rules'] if r['key']=='Taxa de Performance')['status']=='pending'


def test_explicitly_prohibited_performance_cannot_be_overridden(authorized,files):
    send(authorized,files['fiis'],'fiis')
    body={'key':'no_performance','source_url':'https://example.com/regulamento','checked_date':'2026-10-01','note':'Conferência registrada pelo responsável pelo catálogo.'}
    r=authorized.post('/api/assets/RBRR11/evidence',json=body);assert r.status_code==200
    after=authorized.get('/api/assets/RBRR11').json()
    assert next(r for r in after['assessment']['rules'] if r['key']=='Taxa de Performance')['status']=='fail'
