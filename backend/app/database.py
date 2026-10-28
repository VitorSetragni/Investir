from datetime import datetime, timezone
from sqlalchemy import create_engine, String, DateTime, Integer, JSON, Text, ForeignKey, text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker
from .config import settings


class Base(DeclarativeBase):
    pass


class Snapshot(Base):
    __tablename__ = 'snapshots'
    # Uma linha estável por tipo permite lock transacional em importações concorrentes.
    kind: Mapped[str] = mapped_column(String(12), primary_key=True)
    reference: Mapped[str | None] = mapped_column(String(7), nullable=True)
    filename: Mapped[str | None] = mapped_column(Text, nullable=True)
    sha256: Mapped[str | None] = mapped_column(String(64), nullable=True)
    imported_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    imported_by: Mapped[str | None] = mapped_column(String(128), nullable=True)
    revision: Mapped[int] = mapped_column(Integer, default=0)
    count: Mapped[int] = mapped_column(Integer, default=0)


class Asset(Base):
    __tablename__ = 'assets'
    ticker: Mapped[str] = mapped_column(String(12), primary_key=True)
    kind: Mapped[str] = mapped_column(ForeignKey('snapshots.kind'), index=True)
    name: Mapped[str] = mapped_column(Text)
    category: Mapped[str] = mapped_column(String(30), index=True)
    segment: Mapped[str] = mapped_column(Text)
    source_row: Mapped[int] = mapped_column(Integer)
    data: Mapped[dict] = mapped_column(JSON)
    assessment: Mapped[dict] = mapped_column(JSON)


class MarketCache(Base):
    __tablename__ = 'market_cache'
    ticker: Mapped[str] = mapped_column(String(12), primary_key=True)
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    payload: Mapped[dict] = mapped_column(JSON)


url = settings().database_url
if url.startswith('postgres://'):
    url = url.replace('postgres://', 'postgresql+psycopg://', 1)
elif url.startswith('postgresql://'):
    url = url.replace('postgresql://', 'postgresql+psycopg://', 1)
engine = create_engine(url, pool_pre_ping=True, **({'connect_args': {'check_same_thread': False}} if url.startswith('sqlite') else {'pool_size': 3, 'max_overflow': 2}))
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)


def initialize():
    if settings().app_env=='production' and engine.dialect.name!='postgresql':
        raise RuntimeError('Produção exige DATABASE_URL do PostgreSQL; SQLite é apenas para desenvolvimento local.')
    production=settings().app_env=='production'
    if production:
        # A aplicação não deve executar DDL nem precisar ser dona das tabelas.
        with engine.connect() as conn:
            rows=conn.execute(text("SELECT c.relname,c.relrowsecurity FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname IN ('snapshots','assets','market_cache') AND c.relkind='r'")).all()
        if {r[0] for r in rows}!={'snapshots','assets','market_cache'}:
            raise RuntimeError('Schema incompleto. Aplique database/schema.sql antes de iniciar a API.')
        if not all(r[1] for r in rows):
            raise RuntimeError('RLS não está ativo em todas as tabelas. Corrija o schema antes de iniciar a API.')
    else:
        Base.metadata.create_all(engine)
    if engine.dialect.name=='postgresql' and not production:
        with engine.begin() as conn:
            for table in ('snapshots','assets','market_cache'):
                conn.execute(text(f'ALTER TABLE public.{table} ENABLE ROW LEVEL SECURITY'))
            # Roles existem no Supabase; Postgres puro da CI não possui anon/authenticated.
            for role in ('anon','authenticated'):
                exists=conn.execute(text('SELECT 1 FROM pg_roles WHERE rolname=:name'),{'name':role}).scalar()
                if exists:conn.execute(text(f'REVOKE ALL ON public.snapshots, public.assets, public.market_cache FROM {role}'))
    with SessionLocal.begin() as db:
        for kind in ('stocks', 'fiis'):
            if not db.get(Snapshot, kind):
                if production:raise RuntimeError('Competências iniciais ausentes. Aplique database/schema.sql.')
                db.add(Snapshot(kind=kind, count=0, revision=0))


def session():
    with SessionLocal() as db:
        yield db
