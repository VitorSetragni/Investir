"""Atualização transacional das avaliações quando as regras de FIIs mudam."""
from sqlalchemy import select

from .database import Asset, SessionLocal, Snapshot
from .rules import VERSION, evaluate


def reassess_fiis(db):
    # A importação mensal usa o mesmo lock; nunca misturar duas competências.
    snapshot=db.execute(select(Snapshot).where(Snapshot.kind=='fiis').with_for_update()).scalar_one_or_none()
    if snapshot is None:
        return 0
    updated=0
    assets=db.scalars(select(Asset).where(Asset.kind=='fiis').order_by(Asset.ticker).with_for_update())
    for asset in assets:
        if asset.assessment.get('version')!=VERSION:
            asset.assessment=evaluate('fiis',asset.data)
            updated+=1
    # Dados originais, evidências e metadados da importação são preservados.
    return updated


def refresh_rule_assessments():
    with SessionLocal.begin() as db:
        return reassess_fiis(db)
