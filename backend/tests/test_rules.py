from copy import deepcopy
import pytest
from app.rules import evaluate,administrator


def stock(records):return deepcopy(next(r['data'] for r in records['stocks'] if r['ticker']=='LREN3'))
def fund(records):return deepcopy(next(r['data'] for r in records['fiis'] if r['ticker']=='KNIP11'))
def state(a,key):return next(r['status'] for r in a['rules'] if r['key']==key)


@pytest.mark.parametrize('v,expected',[(.1499,'fail'),(.15,'acceptable'),(.35,'acceptable'),(.3501,'pass')])
def test_float_boundaries(records,v,expected):
    d=stock(records);d['Free Float']=v;assert state(evaluate('stocks',d),'Free Float')==expected


@pytest.mark.parametrize('v,expected',[(2.99,'pass'),(3,'acceptable'),(4,'acceptable'),(4.01,'fail')])
def test_debt_boundaries(records,v,expected):
    d=stock(records);d['Dívida Líquida/EBITDA']=v;assert state(evaluate('stocks',d),'Dívida Líquida/EBITDA')==expected


@pytest.mark.parametrize('ticker,years',[('CEAB3',5),('MILS3',5),('VULC3',10),('JHSF3',8)])
def test_profit_corrections(records,ticker,years):
    d=stock(records);d['Ticker']=ticker;d['Anos gerando lucro']=20
    a=evaluate('stocks',d);assert state(a,'Anos gerando lucro')==('fail' if years<6 else 'acceptable')


def test_paper_does_not_require_properties(records):
    d=fund(records);d['Quantidade de Imóveis']=0;d['Vacância']=0;d['Multi-inquilino']='-';d['Taxa de Performance']='Não há'
    a=evaluate('fiis',d);assert state(a,'Quantidade de Imóveis')=='na';assert a['status']!='excluded'


@pytest.mark.parametrize('fee,expected',[(0,'pending'),(.01,'pass'),(.0101,'pending')])
def test_paper_fee_reference_not_strict_cap(records,fee,expected):
    d=fund(records);d['Taxa de adm']=fee;assert state(evaluate('fiis',d),'Taxa de adm')==expected


@pytest.mark.parametrize('value',['-', '–', '—', 0, 0.0, '0', '0,00%', '0.0%', '0% do excedente do CDI', 'Não há'])
@pytest.mark.parametrize('kind,management',[('Papel','Ativa'),('Tijolo','Ativa'),('Tijolo','Passiva')])
def test_zero_performance_requires_no_benchmark(records,value,kind,management):
    d=fund(records);d.update({'Tipo de fundo':kind,'Tipo de Gestão':management,'Taxa de Performance':value})
    before=deepcopy(d)
    rule=next(r for r in evaluate('fiis',d)['rules'] if r['key']=='Taxa de Performance')
    assert rule['status']=='pass'
    assert rule['value']=='0%' and rule['benchmark']==0
    assert rule['source_value']==value
    assert d==before


@pytest.mark.parametrize('value',[None,'','  '])
def test_blank_performance_remains_unknown(records,value):
    d=fund(records);d['Taxa de Performance']=value
    rule=next(r for r in evaluate('fiis',d)['rules'] if r['key']=='Taxa de Performance')
    assert rule['status']=='pending'
    assert 'benchmark' not in rule


@pytest.mark.parametrize('value',['0,5% do CDI','20% do excedente do CDI'])
def test_nonzero_performance_remains_prohibited_for_paper(records,value):
    d=fund(records);d['Taxa de Performance']=value
    assert state(evaluate('fiis',d),'Taxa de Performance')=='fail'


def test_charged_performance_still_requires_benchmark(records):
    d=fund(records);d.update({'Tipo de fundo':'Tijolo','Tipo de Gestão':'Ativa','Taxa de Performance':'20% do excedente do CDI'})
    rule=next(r for r in evaluate('fiis',d)['rules'] if r['key']=='Taxa de Performance')
    assert rule['status']=='pending'
    assert 'Benchmark IPCA+X' in rule['note']
    assert 'benchmark' not in rule


@pytest.mark.parametrize('v,expected',[(.2499,'pass'),(.25,'acceptable'),(.30,'acceptable'),(.3001,'fail')])
def test_brick_vacancy(records,v,expected):
    d=fund(records);d.update({'Tipo de fundo':'Tijolo','Vacância':v,'Quantidade de Imóveis':10,'Multi-inquilino':'Sim','Tipo de Gestão':'Ativa','Taxa de Performance':'Não há'})
    assert state(evaluate('fiis',d),'Vacância')==expected


def test_eight_properties_user_minimum(records):
    d=fund(records);d.update({'Tipo de fundo':'Tijolo','Quantidade de Imóveis':8})
    assert state(evaluate('fiis',d),'Quantidade de Imóveis')=='acceptable'
    d['Quantidade de Imóveis']=7;assert state(evaluate('fiis',d),'Quantidade de Imóveis')=='fail'


def test_different_admin_entities_are_not_equated():
    assert administrator('BR-Capital Dist. de Títulos')[0]=='pending'
    assert administrator('Apex Group DTVM')[0]=='pending'
    assert administrator('Banco Genial S.A.')[0]=='pass'


def test_all_eleven_administrators_from_supplied_ranking_are_present():
    names=['Banco Genial','Intrag DTVM','Banco Fator','BRL Trust Inv.',
           'XP Investimentos','Coinvalores','Rio Bravo','BTG Pactual',
           'Votorantim Asset','CM Capital Markets','Safra Asset Management']
    assert len(names)==11
    assert all(administrator(name)[0]=='pass' for name in names)
