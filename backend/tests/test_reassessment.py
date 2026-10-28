from copy import deepcopy
from sqlalchemy import select

from app.database import Asset, SessionLocal, Snapshot
from app.importer import replace_snapshot
from app.reassessment import reassess_fiis
from app.rules import VERSION, evaluate, finish


def test_rule_refresh_preserves_sources_evidence_stocks_and_snapshot(records,files):
    funds=deepcopy(records['fiis'][:2])
    first=funds[0]
    first['data']['Taxa de Performance']='-'
    first['data']['Administrador']='Administrador documentado fora da lista'
    first['data']['_evidence']={'administrator_verified':{'source_url':'https://example.com/registro'}}
    first['assessment']=evaluate('fiis',first['data'])
    for record in funds:
        record['assessment']['version']='legacy'
    fee=next(r for r in first['assessment']['rules'] if r['key']=='Taxa de Performance')
    fee.update(status='pending',value='-')
    old=finish(first['assessment']['rules'],first['assessment']['notes'])
    old['version']='legacy';first['assessment']=old
    with SessionLocal.begin() as db:
        replace_snapshot(db,'fiis','2026-10','fiis.xlsx',files['fiis'],funds,'user',0)
        replace_snapshot(db,'stocks','2026-10','stocks.xlsx',files['stocks'],records['stocks'][:1],'user',0)
    with SessionLocal() as db:
        snap=db.get(Snapshot,'fiis')
        before_snapshot=(snap.reference,snap.filename,snap.sha256,snap.revision,snap.count,snap.imported_at,snap.imported_by)
        stock=deepcopy(db.scalar(select(Asset).where(Asset.kind=='stocks')).assessment)
        raw={a.ticker:deepcopy(a.data) for a in db.scalars(select(Asset).where(Asset.kind=='fiis'))}
    with SessionLocal.begin() as db:
        assert reassess_fiis(db)==2
    with SessionLocal.begin() as db:
        assert reassess_fiis(db)==0
        snap=db.get(Snapshot,'fiis')
        assert (snap.reference,snap.filename,snap.sha256,snap.revision,snap.count,snap.imported_at,snap.imported_by)==before_snapshot
        assert db.scalar(select(Asset).where(Asset.kind=='stocks')).assessment==stock
        for asset in db.scalars(select(Asset).where(Asset.kind=='fiis')):
            assert asset.data==raw[asset.ticker]
            assert asset.assessment['version']==VERSION
        assessment=db.get(Asset,first['ticker']).assessment
        assert next(r for r in assessment['rules'] if r['key']=='Administrador')['status']=='pass'
        assert next(r for r in assessment['rules'] if r['key']=='Taxa de Performance')['benchmark']==0
