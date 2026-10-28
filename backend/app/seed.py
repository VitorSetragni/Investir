"""Carrega os dois arquivos fornecidos para demonstração local, sem criar login falso."""
import argparse
from pathlib import Path
from .database import initialize, SessionLocal, Snapshot
from .importer import parse_workbook, replace_snapshot


def main():
    p=argparse.ArgumentParser();p.add_argument('--stocks',required=True);p.add_argument('--fiis',required=True);p.add_argument('--reference',required=True);a=p.parse_args()
    initialize()
    for kind,path in [('stocks',Path(a.stocks)),('fiis',Path(a.fiis))]:
        data=path.read_bytes();rows=parse_workbook(data,kind,a.reference,path.name)
        with SessionLocal.begin() as db:
            revision=db.get(Snapshot,kind).revision
            snap,changed=replace_snapshot(db,kind,a.reference,path.name,data,rows,'seed-local',revision)
            print(kind,snap.count,snap.reference,'atualizado' if changed else 'sem alterações')


if __name__=='__main__':main()
