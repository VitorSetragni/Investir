import os
from pathlib import Path
import tempfile
import io
import pytest

os.environ['DATABASE_URL']=os.environ.get('TEST_DATABASE_URL','sqlite:///'+str(Path(tempfile.gettempdir())/'investir-tests.db'))
os.environ['APP_ENV']='test'
os.environ['UPLOADER_EMAILS']='admin@example.com'
from app.database import Base,engine,SessionLocal,initialize
from app.main import app,rate_buckets
from app.auth import require_uploader
from app.importer import parse_workbook
from fastapi.testclient import TestClient

EXAMPLES=Path(__file__).resolve().parents[2]/'examples'


@pytest.fixture(autouse=True)
def clean():
    Base.metadata.drop_all(engine);initialize();rate_buckets.clear();app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()


@pytest.fixture
def client():
    with TestClient(app) as c:yield c


@pytest.fixture
def authorized(client):
    async def user():return {'id':'test-uploader','email':'admin@example.com','email_confirmed_at':'2026-01-01'}
    app.dependency_overrides[require_uploader]=user
    return client


def synthetic_workbooks():
    """Dados fictícios para CI pública; os arquivos pessoais não vão ao GitHub."""
    from openpyxl import Workbook
    stock={'Ticker':'LREN3','Empresa':'Empresa de teste','Setor':'Comércio',
           'Tipo de ação':'ON','Tag Along':1,'Free Float':.9,
           'Segmento de listagem':'Novo Mercado','Governo como Majoritário?':'Não',
           'Patrim Liq':2_000_000_000,'Liquidez média diária':20_000_000,
           'Margem EBIT':.15,'Margem Líquida':.12,'ROIC':.18,'ROE':.2,
           'Anos desde o IPO':20,'Anos gerando lucro':12,'Dívida Líquida/EBITDA':1}
    fund={'Cód do fundo':'KNIP11','Tipo de fundo':'Papel','Segmento de Atuação':'TVM',
          'Liquidez diária':1_000_000,'Patrimônio Líquido':500_000_000,
          'Quantidade de Imóveis':0,'Multi-inquilino':'-','Vacância':0,
          '% em CRIs':.99,'Quantidade de CRIs':100,'Administrador':'Banco Genial S.A.',
          'Tempo de listagem':10,'Tipo de Gestão':'Ativa','Taxa de adm':.005,
          'Taxa de Performance':'-'}
    result={}
    for kind,base,tickers in (
        ('stocks',stock,['LREN3','B3SA3']+[f'S{i:03d}3' for i in range(372)]),
        ('fiis',fund,['KNIP11','RBRR11']+[f'F{i:03d}11' for i in range(353)])):
        book=Workbook();sheet=book.active;sheet.title='Método Davi'
        sheet.append(['Dados fictícios para testes']);sheet.append([]);sheet.append(list(base))
        for ticker in tickers:
            row=dict(base);row[next(iter(base))]=ticker
            if ticker=='RBRR11':row['Taxa de Performance']='20% do excedente do CDI'
            sheet.append(list(row.values()))
        content=io.BytesIO();book.save(content);book.close();result[kind]=content.getvalue()
    return result


@pytest.fixture(scope='session')
def files():
    paths={k:EXAMPLES/f'{k}_outubro_2026.xlsx' for k in ('stocks','fiis')}
    if os.environ.get('TEST_SYNTHETIC_WORKBOOKS')!='1' and all(p.exists() for p in paths.values()):
        return {k:p.read_bytes() for k,p in paths.items()}
    return synthetic_workbooks()


@pytest.fixture
def records(files):
    return {k:parse_workbook(v,k,'2026-10',f'{k}_outubro_2026.xlsx') for k,v in files.items()}


def send(client,content,kind='stocks',reference='2026-10',filename=None):
    fn=filename or f'{kind}_outubro_2026.xlsx'
    f={'file':(fn,content,'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')}
    p=client.post('/api/imports/preview',data={'kind':kind,'reference':reference},files=f)
    if p.status_code!=200:return p
    preview=p.json()
    return client.post('/api/imports',data={'kind':kind,'reference':reference,'expected_revision':preview['expected_revision'],'sha256':preview['sha256']},files=f)
