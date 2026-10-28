"""Critérios de triagem adotados para ações e fundos imobiliários.

O resultado classifica os dados da planilha. Pendências documentais continuam
visíveis e jamais são convertidas em evidência favorável.
"""
import html
import re
import unicodedata

VERSION = '2026.10.27.1'

SOURCE_GROUPS = {
    '4.2': 'Sociedade', '4.3': 'Lucro', '4.4': 'Negócio',
    '5.2': 'Tipo e escala do fundo', '5.3': 'Carteira e imóveis', '5.4': 'Gestão e taxas',
    'Pedido do usuário': 'Critérios adotados',
}

PUBLIC_TEXT = {
    'A planilha não identifica vacância física/financeira; o curso prioriza a financeira quando disponível.':
        'A planilha não identifica vacância física ou financeira. Confira a metodologia e a vacância financeira quando disponível.',
    'Usuário: mínimo 8; curso: preferido ≥10': 'Mínimo 8; preferido ≥10',
    'Usuário: >4 anos; curso: preferido ≥5': 'Mais de 4 anos; preferido ≥5',
    'O curso exige ausência de performance para papel/passivo.':
        'O critério exige ausência de taxa de performance para papel e gestão passiva.',
    'Zero exige confirmação. Acima da referência exige julgamento: o PDF diz “muito superior”, sem um corte exato. Não é reprovação automática.':
        'Zero exige confirmação. Acima da referência exige análise, pois não foi adotado um limite numérico adicional. Não é reprovação automática.',
    'Não atinge a referência de filtragem adotada. O PDF apresenta estes parâmetros como ideais, não como prova de negócio ruim.':
        'Não atinge a referência de filtragem adotada. Esse resultado isolado não determina a qualidade do negócio.',
}


def public_text(value):
    return PUBLIC_TEXT.get(value, value)


def present_assessment(assessment):
    """Atualiza a apresentação de bases antigas sem reclassificar os ativos."""
    result = dict(assessment)
    result['rules'] = []
    for original in assessment['rules']:
        rule = dict(original)
        source = rule.get('source', '')
        rule['source'] = SOURCE_GROUPS.get(source.removeprefix('Aula '), source)
        for key in ('expected', 'note'):
            if key in rule:
                rule[key] = public_text(rule[key])
        result['rules'].append(rule)
    result['notes'] = [public_text(note) for note in assessment.get('notes', [])]
    return result


def norm(value):
    return ''.join(c for c in unicodedata.normalize('NFKD', str(value or '')) if not unicodedata.combining(c)).lower().strip()


def criterion(key, label, value, status, expected, source, note=''):
    return dict(key=key, label=label, value=value, status=status, expected=expected, source=source, note=note)


def finish(rules, notes):
    states = [r['status'] for r in rules]
    status = 'excluded' if 'fail' in states else 'review' if 'pending' in states else 'acceptable' if 'acceptable' in states else 'preferred'
    return dict(status=status, rules=rules, notes=notes, version=VERSION,
                acceptable_rules=[r['label'] for r in rules if r['status']=='acceptable'],
                pending_rules=[r['label'] for r in rules if r['status']=='pending'])


def stock_rules(d):
    r=[]
    def add(key,label,status,expected,chapter,note=''):
        r.append(criterion(key,label,d.get(key),status,public_text(expected),SOURCE_GROUPS[chapter],public_text(note)))
    add('Tipo de ação','Ação ordinária','pass' if norm(d['Tipo de ação'])=='on' else 'fail','Somente ON','4.2')
    x=d['Tag Along'];add('Tag Along','Tag along','pass' if x>=1 else 'acceptable' if x>=.8 else 'fail','Preferido 100%; tolerado 80% ou mais','4.2')
    x=d['Free Float'];add('Free Float','Free float','pass' if x>.35 else 'acceptable' if x>=.15 else 'fail','Preferido >35%; tolerado 15% a 35%','4.2')
    add('Segmento de listagem','Governança','pending' if norm(d['Segmento de listagem']) in ('','-') else 'pass' if norm(d['Segmento de listagem'])=='novo mercado' else 'acceptable','Novo Mercado; demais segmentos tolerados','4.2')
    government=norm(d['Governo como Majoritário?'])
    # O controle indireto da CPFL é conhecido; a coluna da planilha não o captura.
    government='sim' if d['Ticker']=='CPFE3' else government
    add('Governo como Majoritário?','Controle não estatal','pass' if government=='nao' else 'fail' if government=='sim' else 'pending','Sem controle estatal direto ou indireto','4.2', 'CPFL: State Grid é controladora estatal indireta.' if d['Ticker']=='CPFE3' else '')
    years=d['Anos gerando lucro']
    # Casos identificados na conferência anual anterior: a contagem da base não basta.
    correction={'CEAB3':5,'MILS3':5,'VULC3':10,'JHSF3':8}
    corrected=d.get('_reference')=='2026-10' and d['Ticker'] in correction
    years=correction[d['Ticker']] if corrected else years
    state='pass' if years>=11 else 'acceptable' if years>=6 else 'fail'
    add('Anos gerando lucro','Histórico de lucro',state,'Preferido ≥11 anos consistentes e tendência crescente; tolerado 6–10','4.3',f'{years:g} anos usados na triagem de outubro/2026. A planilha não contém a série anual para comprovar continuidade e crescimento; conferir demonstrações. Correções históricas: CEAB3/MILS3 têm prejuízo em 2020; VULC3 em 2015; JHSF3 em 2017.' if corrected else 'Contagem informada pela planilha. Não comprova sozinha sequência anual e crescimento.')
    add('Anos desde o IPO','Tempo de bolsa','pass' if d['Anos desde o IPO']>=10 else 'acceptable' if d['Anos desde o IPO']>=5 else 'fail','Mínimo 5 anos; preferido histórico de 10 anos ou mais','4.3')
    debt=d['Dívida Líquida/EBITDA']
    banking=norm(d['Setor'])=='financeiro' and d['ROIC']==0 and d['Margem EBIT']==0
    add('Dívida Líquida/EBITDA','Endividamento','pending' if banking and debt==0 else 'pass' if debt<3 else 'acceptable' if debt<=4 else 'fail','Preferido <3x; 3–4x intermediário; >4x eliminado','4.4','Bancos exigem métricas próprias de capital e risco; zero não comprova ausência de endividamento.' if banking else 'Valor negativo geralmente indica caixa líquido. Conferir a definição contábil.')
    for key,label,limit in [('ROE','ROE',.10),('ROIC','ROIC',.10),('Patrim Liq','Patrimônio líquido',1e9),('Liquidez média diária','Liquidez diária em reais',1e7),('Margem EBIT','Margem EBIT',.04),('Margem Líquida','Margem líquida',.04)]:
        x=d[key]
        if x==0 and norm(d['Setor'])=='financeiro' and key in ('ROIC','Margem EBIT'):state='pending'
        else:state='pass' if x>=limit else 'fail'
        target={'ROE':'Referência cerca de 10% (triagem usa ≥10%)','ROIC':'Referência cerca de 10% (triagem usa ≥10%)','Patrim Liq':'Ideal ≥R$ 1 bilhão','Liquidez média diária':'Ideal ≥R$ 10 milhões/dia','Margem EBIT':'Ideal ≥4%','Margem Líquida':'Ideal ≥4%'}[key]
        add(key,label,state,target,'4.4','Não atinge a referência de filtragem adotada. Esse resultado isolado não determina a qualidade do negócio.' if state=='fail' else 'Indicador não adequado ou não informado para este negócio; analisar por setor.' if state=='pending' else '')
    sector=norm(d['Setor'])
    add('Setor','Exposição a commodities','pending' if sector in ('','-','outros','materiais basicos','petroleo gas e biocombustiveis') else 'pass','Evitar commodities; setor amplo não comprova o subsetor','4.4')
    notes=['Resultado pelos números da planilha, sem análise do preço ou indicação de compra.', 'Continuidade dos lucros e qualidade do negócio exigem confirmação documental.']
    if years>=11 and d.get('CAGR do lucro em 5 anos',0)<=0:
        notes.append('CAGR do lucro não positivo: revisar a tendência de crescimento exigida para a faixa preferida.')
    return finish(r,notes)


def administrator(name):
    n=norm(name)
    aliases=[(('banco genial',),'Banco Genial — 1º grupo'),(('intrag',),'Intrag — 1º grupo'),(('banco fator',),'Banco Fator — 2º grupo'),(('brl trust investimentos','brl trust inv.'),'BRL Trust Inv. — 2º grupo'),(('xp investimentos',),'XP — 3º grupo'),(('coinvalores','rio bravo','btg pactual','votorantim asset','cm capital','safra'),'Outros viáveis do ranking')]
    for names,label in aliases:
        if any(x in n for x in names):return 'pass',label
    return 'pending','Identidade não confirmada no ranking. Não equiparar Apex/BRL Trust DTVM a BRL Trust Inv., nem BR-Capital a BRL Trust.'


def fii_rules(d):
    r=[]
    def add(key,label,status,expected,chapter,note=''):
        r.append(criterion(key,label,d.get(key),status,public_text(expected),SOURCE_GROUPS[chapter],public_text(note)))
    typ=norm(d['Tipo de fundo']);paper=typ=='papel';hybrid=typ=='hibrido'
    add('Tipo de fundo','Tipo de FII','pass' if typ in ('tijolo','papel') else 'acceptable' if hybrid else 'fail','Tijolo/papel preferidos; híbrido intermediário; FOF/desenvolvimento excluídos','5.2')
    seg=norm(d['Segmento de Atuação'])
    state='fail' if any(x in seg for x in ('hospital','hotel','hoteis')) else 'pass' if any(x in seg for x in ('lajes','logistic','shopping','titulos','tvm','papeis')) else 'acceptable'
    add('Segmento de Atuação','Segmento',state,'Preferidos: lajes, logística, shopping e TVM; demais tolerados; hospital/hotel excluídos','5.2')
    if paper:
        x=d['% em CRIs'];add('% em CRIs','Alocação em CRIs','pass' if x>.75 else 'acceptable' if x>=.5 else 'fail','Preferido >75%; mínimo 50%','5.3')
        x=d['Quantidade de CRIs'];add('Quantidade de CRIs','Diversificação de CRIs','pass' if x>=50 else 'acceptable' if x>=30 else 'fail','Preferido ≥50; mínimo 30 CRIs','5.3')
        for k,l in [('Vacância','Vacância'),('Quantidade de Imóveis','Quantidade de imóveis'),('Multi-inquilino','Multi-inquilino')]:add(k,l,'na','Não se aplica ao FII de papel','5.3')
    else:
        x=d['Vacância'];add('Vacância','Vacância','pass' if x<.25 else 'acceptable' if x<=.30 else 'fail','Preferido <25%; tolerado até 30%','5.3','A planilha não identifica vacância física ou financeira. Confira a metodologia e a vacância financeira quando disponível.')
        x=d['Quantidade de Imóveis'];add('Quantidade de Imóveis','Quantidade de imóveis','pass' if x>=10 else 'acceptable' if x>=8 else 'fail','Mínimo 8; preferido ≥10','Pedido do usuário')
        val=norm(d['Multi-inquilino']);add('Multi-inquilino','Multi-inquilino','pass' if val=='sim' else 'fail' if val=='nao' else 'pending','Não pode ser mono-inquilino','Pedido do usuário')
    x=d['Tempo de listagem'];add('Tempo de listagem','Tempo de bolsa','pass' if x>=5 else 'acceptable' if x>4 else 'fail','Mais de 4 anos; preferido ≥5','Pedido do usuário')
    st,ex=administrator(d['Administrador']);add('Administrador','Administrador no ranking',st,'Conforme ranking fornecido','5.4',ex)
    add('Patrimônio Líquido','Escala patrimonial','pass' if d['Patrimônio Líquido']>=3e8 else 'acceptable','Preferido ≥R$ 300 milhões; não eliminatório','5.2')
    # Volume financeiro não substitui número de negócios.
    r.append(criterion('trade_count','Liquidez em número de negociações',None,'na','Referência de 7 mil negociações/dia',SOURCE_GROUPS['5.2'],'Não verificável: a coluna disponível é volume em reais, não número de negócios.'))
    management=norm(d['Tipo de Gestão'])
    ref=.01 if paper else .002 if management=='passiva' else .02
    if not paper and management not in ('ativa','passiva'):
        add('Tipo de Gestão','Tipo de gestão','pending','Ativa ou passiva; gestão definida exige consultar regulamento','5.4')
    fee=d['Taxa de adm']
    add('Taxa de adm','Taxa de administração','pending' if fee==0 or fee>ref else 'pass',f'Referência {ref*100:g}% a.a. (papel 1%; tijolo passivo 0,2%; ativo 2%)','5.4','Zero exige confirmação. Acima da referência exige análise, pois não foi adotado um limite numérico adicional. Não é reprovação automática.' if fee==0 or fee>ref else 'Dentro da referência. Conferir se inclui gestão, consultoria e demais custos.')
    perf=html.unescape(str(d.get('Taxa de Performance',''))).strip();np=norm(perf)
    if np in ('nao ha','nao possui','inexistente','sem taxa','0','0%','nao'):
        state='pass';note='Ausência expressamente informada na base; conferir regulamento vigente.'
    elif np in ('','-','—'):
        state='pending';note='Traço ou vazio na planilha não comprova inexistência da taxa.'
    elif paper or management=='passiva':
        state='fail';note='O critério exige ausência de taxa de performance para papel e gestão passiva.'
    else:
        m=re.search(r'(\d+(?:[.,]\d+)?)\s*%',np)
        rate=float(m.group(1).replace(',','.')) if m else None
        if rate is not None and rate>20:state='fail';note='Performance acima de 20%.'
        elif 'ipca' not in np:state='pending';note='Benchmark IPCA+X não comprovado; fórmula pode estar truncada.'
        elif rate is None:state='pending';note='Percentual não identificado com segurança.'
        else:state='pending';note='Percentual e IPCA identificados; ótimos resultados e fórmula completa exigem conferência do regulamento.'
    add('Taxa de Performance','Taxa de performance',state,'Papel/passivo: ausente; ativo: até 20% do excedente de IPCA+X, com ótimos resultados','5.4',note)
    return finish(r,['Triagem quantitativa, sem avaliação do preço da cota.', 'Taxas, ranking e dados ausentes podem deixar o fundo em “A confirmar”.', 'Número de negociações não foi substituído pelo volume em reais.'])


def evaluate(kind,data):
    missing={k for k,v in data.items() if v is None}
    prepared={k:(0 if v is None else v) for k,v in data.items()}
    result=stock_rules(prepared) if kind=='stocks' else fii_rules(prepared)
    for rule in result['rules']:
        if rule['key'] in missing:
            rule['value']=None
            if rule['status']!='na':
                rule['status']='pending'
                rule['note']='Valor ausente na planilha. Não foi tratado como zero nem como atendimento da regra.'
    return finish(result['rules'],result['notes'])
