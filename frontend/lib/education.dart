import 'package:flutter/material.dart';
import 'app_theme.dart';

class RuleEntry {
  final String title, text;
  const RuleEntry(this.title, this.text);
}

class RuleSection {
  final String title;
  final IconData icon;
  final List<RuleEntry> entries;
  const RuleSection(this.title, this.icon, this.entries);
}

const ruleSections = [
  RuleSection('Sociedade', Icons.groups_outlined, [
    RuleEntry('Tipo de ação', 'A seleção considera apenas ações ordinárias (ON). Ações preferenciais (PN) e units ficam fora deste filtro.'),
    RuleEntry('Tag along', 'Preferido: 100%. Aceitável: de 80% até menos de 100%. Abaixo de 80% fica fora dos filtros.'),
    RuleEntry('Free float', 'Preferido: mais de 35%. Aceitável: de 15% a 35%, incluindo os limites. Menos de 15% fica fora dos filtros.'),
    RuleEntry('Governança', 'Novo Mercado é o segmento preferido. Outros segmentos são tolerados; ausência da informação exige conferência.'),
    RuleEntry('Controle estatal', 'A seleção exige ausência de controle estatal direto ou indireto. Quando a informação não permite identificar o controlador, o critério fica a confirmar.'),
  ]),
  RuleSection('Lucro e negócio', Icons.insights_outlined, [
    RuleEntry('Histórico de lucro', 'Preferido: pelo menos 11 anos de lucros consistentes e tendência de crescimento. Aceitável: de 6 a 10 anos. Menos de 6 anos fica fora. A contagem da planilha, sozinha, não comprova a sequência anual.'),
    RuleEntry('Tempo de bolsa', 'Mínimo: 5 anos desde o IPO. De 5 a 9 anos é aceitável; 10 anos ou mais é a faixa preferida.'),
    RuleEntry('Dívida líquida / EBITDA', 'Preferido: abaixo de 3 vezes. De 3 a 4 vezes, inclusive, é aceitável. Acima de 4 vezes fica fora. Valor negativo costuma indicar caixa líquido; bancos exigem uma análise própria.'),
    RuleEntry('ROE e ROIC', 'Referência de filtragem: pelo menos 10% em cada indicador. Indicadores que não se aplicam ao setor precisam de uma avaliação específica.'),
    RuleEntry('Patrimônio e liquidez', 'Os filtros adotados são patrimônio líquido de pelo menos R\$ 1 bilhão e volume financeiro médio de pelo menos R\$ 10 milhões por dia.'),
    RuleEntry('Margens', 'Margem EBIT e margem líquida de pelo menos 4%. Esses limites servem para esta seleção quantitativa.'),
    RuleEntry('Commodities', 'A seleção evita exposição identificada a commodities. Um setor amplo ou ambíguo exige conferir o subsetor e a atividade da empresa.'),
  ]),
  RuleSection('FIIs de tijolo', Icons.apartment_outlined, [
    RuleEntry('Tipos e segmentos', 'Tijolo e papel são os tipos preferidos; híbridos são intermediários. FOFs e fundos de desenvolvimento ficam fora. Entre os segmentos, lajes, logística e shopping são preferidos; residencial e outros são tolerados. Hospital e hotel ficam fora.'),
    RuleEntry('Quantidade de imóveis', 'Preferido: 10 imóveis ou mais. De 8 a 9 imóveis é aceitável. Menos de 8 fica fora dos filtros.'),
    RuleEntry('Vacância', 'Preferido: abaixo de 25%. De 25% a 30%, inclusive, é aceitável. Acima de 30% fica fora. A planilha não identifica se a vacância é física ou financeira; essa distinção deve ser conferida.'),
    RuleEntry('Inquilinos', 'O fundo precisa ter mais de um inquilino. Mono-inquilino fica fora; informação ausente fica a confirmar.'),
    RuleEntry('Tempo de bolsa', 'Exige mais de 4 anos de listagem. Acima de 4 e abaixo de 5 anos é aceitável; 5 anos ou mais é a faixa preferida.'),
    RuleEntry('Patrimônio líquido', 'Referência preferida: pelo menos R\$ 300 milhões. Um patrimônio menor é intermediário, sem exclusão automática por esse critério.'),
  ]),
  RuleSection('FIIs de papel', Icons.description_outlined, [
    RuleEntry('Alocação em CRIs', 'Preferido: mais de 75% do patrimônio alocado em CRIs. De 50% a 75%, inclusive, é aceitável. Abaixo de 50% fica fora.'),
    RuleEntry('Quantidade de CRIs', 'Preferido: pelo menos 50 CRIs. De 30 a 49 é aceitável. Menos de 30 fica fora. A quantidade, sozinha, não comprova diversificação de devedores ou garantias.'),
    RuleEntry('Critérios imobiliários', 'Vacância, quantidade de imóveis e número de inquilinos não se aplicam ao fundo de papel.'),
    RuleEntry('Tempo de bolsa e patrimônio', 'A listagem deve superar 4 anos; 5 anos ou mais é preferido. O patrimônio de referência é R\$ 300 milhões, sem exclusão automática abaixo desse valor.'),
  ]),
  RuleSection('Gestão e taxas', Icons.manage_accounts_outlined, [
    RuleEntry('Administrador', 'A comparação usa o ranking de administradores adotado na triagem. Banco Genial e Intrag estão no primeiro grupo; Banco Fator e BRL Trust Inv. no segundo; XP no terceiro. Outras entidades viáveis do ranking são Coinvalores, Rio Bravo, BTG Pactual, Votorantim Asset, CM Capital e Safra. Nomes parecidos não comprovam que se trata da mesma entidade.'),
    RuleEntry('Gestão ativa ou passiva', 'É necessário identificar o mandato do fundo. O rótulo “gestão definida” não significa automaticamente gestão passiva e exige conferir o regulamento.'),
    RuleEntry('Taxa de administração', 'Referências anuais: papel, 1%; tijolo passivo, 0,2%; tijolo ativo, 2%. Acima da referência fica a confirmar, pois não foi adotado um limite numérico adicional. Valor zero também exige conferência.'),
    RuleEntry('Taxa de performance', 'Papel e tijolo passivo: ausência de taxa. Tijolo ativo: até 20% do excedente de IPCA+X, com fórmula completa e ótimos resultados conferidos. Sem indicação explícita de ausência de taxa, ou com informação ambígua, o critério fica a confirmar.'),
    RuleEntry('Número de negociações', 'A referência é de 7 mil negócios por dia. A planilha informa volume em reais, que não substitui a quantidade de negócios; por isso esse critério não é considerado comprovado por essa coluna.'),
  ]),
];

class RulesOverviewPage extends StatelessWidget {
  const RulesOverviewPage({super.key});

  Widget tile(BuildContext context, String title, IconData icon, VoidCallback onTap) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      minVerticalPadding: 20,
      leading: Icon(icon, color: context.palette.mint),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
      trailing: Icon(Icons.chevron_right, color: context.palette.muted),
      onTap: onTap,
    ),
  );

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
    children: [
      const Text('Regras da triagem', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      for (final section in ruleSections)
        tile(context, section.title, section.icon, () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => RuleSectionPage(section: section)),
        )),
      const SizedBox(height: 12),
      tile(context, 'Aprenda um pouco mais', Icons.menu_book_outlined, () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LearnMorePage()),
      )),
      Text('As explicações dos termos usados nas regras estão em Aprenda um pouco mais.',
        style: TextStyle(color: context.palette.muted, fontSize: 13, height: 1.5)),
    ],
  );
}

class RuleSectionPage extends StatelessWidget {
  final RuleSection section;
  const RuleSectionPage({super.key, required this.section});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(section.title)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            for (final entry in section.entries)
              Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Text(entry.text, style: TextStyle(color: context.palette.muted, height: 1.6)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LearnMorePage())),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Aprenda um pouco mais'),
            ),
          ],
        ),
      ),
    ),
  );
}

class GlossaryTerm {
  final String group, name, definition;
  const GlossaryTerm(this.group, this.name, this.definition);
}

const glossary = [
  GlossaryTerm('Códigos da bolsa', 'Final 3 — ação ordinária (ON)', 'Em códigos de ações, o final 3 identifica ações ordinárias, que dão direito a voto nas assembleias. Exemplo: WEGE3. Isso não garante rentabilidade nem aprovação nos filtros.'),
  GlossaryTerm('Códigos da bolsa', 'Final 4 — ação preferencial (PN)', 'O final 4 normalmente identifica ações preferenciais. Elas têm preferências previstas no estatuto, como prioridade em dividendos ou no reembolso de capital, e podem ter voto limitado. Exemplo: PETR4. A preferência não garante pagamento de dividendos.'),
  GlossaryTerm('Códigos da bolsa', 'Final 11 — units, FIIs e ETFs', 'O número 11 não identifica sozinho o tipo de investimento. Em ações, pode indicar uma unit: um conjunto de valores mobiliários negociado junto, como KLBN11. FIIs, como BRCO11, e ETFs, como BOVA11, também usam esse final. Confira sempre o tipo de ativo.'),
  GlossaryTerm('Códigos da bolsa', 'Ticker e IPO', 'Ticker é o código de negociação do ativo, como WEGE3. IPO é a oferta pública inicial de ações de uma empresa; a triagem usa os anos desde o IPO para medir seu histórico em bolsa.'),
  GlossaryTerm('Sociedade', 'Tag along', 'Proteção em uma venda do controle da empresa: permite ao acionista protegido vender suas ações nas condições previstas. Um tag along de 100% usa o mesmo preço por ação pago ao controlador; 80% corresponde a 80% desse preço, conforme as regras aplicáveis.'),
  GlossaryTerm('Sociedade', 'Free float', 'Percentual de ações em circulação no mercado, fora das participações consideradas de controle e de outras exclusões da definição usada. Um percentual maior pode favorecer a negociação, mas não garante liquidez.'),
  GlossaryTerm('Sociedade', 'Novo Mercado e governança', 'Governança reúne práticas de transparência, administração e proteção dos acionistas. Novo Mercado é um segmento de listagem da B3 com exigências adicionais, inclusive a emissão apenas de ações ordinárias.'),
  GlossaryTerm('Sociedade', 'Controlador e controle estatal', 'Controlador é quem exerce o poder de dirigir as decisões da companhia. O controle estatal pode ser direto, por um ente público, ou indireto, por outra empresa controlada pelo governo.'),
  GlossaryTerm('Lucro e negócio', 'Lucro e anos gerando lucro', 'Lucro é o resultado positivo após receitas, custos e despesas do período. A quantidade de anos positivos não mostra, sozinha, se eles foram consecutivos nem se o lucro está crescendo.'),
  GlossaryTerm('Lucro e negócio', 'CAGR', 'Taxa média composta de crescimento entre o começo e o fim de um período. Um CAGR de 10% ao ano equivale ao ritmo constante que ligaria os dois valores; não significa crescimento de 10% em cada ano.'),
  GlossaryTerm('Lucro e negócio', 'EBITDA', 'Resultado antes de juros, impostos sobre o lucro, depreciação e amortização. Ajuda a comparar o desempenho operacional, mas não representa o dinheiro efetivamente disponível em caixa.'),
  GlossaryTerm('Lucro e negócio', 'EBIT', 'Resultado antes de juros e impostos sobre o lucro. Diferentemente do EBITDA, considera as despesas de depreciação e amortização.'),
  GlossaryTerm('Lucro e negócio', 'Dívida líquida', 'Dívida financeira menos caixa e aplicações considerados na metodologia. Se for negativa, o caixa supera a dívida incluída no cálculo.'),
  GlossaryTerm('Lucro e negócio', 'Dívida líquida / EBITDA', 'Compara a dívida líquida com o resultado operacional EBITDA. Um valor de 3x significa dívida líquida de três vezes o EBITDA do período de referência; não é uma promessa de quitação em três anos.'),
  GlossaryTerm('Lucro e negócio', 'ROE', 'Retorno sobre o patrimônio líquido: relaciona o lucro ao capital contábil dos acionistas. Um ROE alto pode refletir eficiência, mas também pode ser influenciado pelo endividamento e por eventos pontuais.'),
  GlossaryTerm('Lucro e negócio', 'ROIC', 'Retorno sobre o capital investido na operação, considerando capital próprio e de terceiros conforme a metodologia. Ajuda a avaliar a eficiência do negócio; suas fórmulas podem variar entre fontes.'),
  GlossaryTerm('Lucro e negócio', 'Patrimônio líquido (PL)', 'Diferença contábil entre os ativos e as obrigações da empresa ou do fundo. É diferente do valor que o mercado atribui às ações ou cotas.'),
  GlossaryTerm('Lucro e negócio', 'Liquidez diária e volume financeiro', 'Volume financeiro é o valor em reais negociado em um período. Liquidez descreve a facilidade de comprar ou vender; volume alto ajuda, mas não elimina variações de preço ou a diferença entre compra e venda.'),
  GlossaryTerm('Lucro e negócio', 'Número de negociações', 'Quantidade de negócios realizados. Não é o mesmo que volume em reais: poucos negócios grandes podem movimentar muito dinheiro.'),
  GlossaryTerm('Lucro e negócio', 'Margem EBIT e margem líquida', 'Margem EBIT é o EBIT dividido pela receita líquida. Margem líquida é o lucro líquido dividido pela receita líquida. Elas mostram quanto da receita corresponde a cada resultado.'),
  GlossaryTerm('Lucro e negócio', 'Commodities', 'Produtos com características padronizadas, como petróleo, minério e grãos. Empresas expostas a eles podem depender bastante dos preços internacionais e dos ciclos de oferta e demanda.'),
  GlossaryTerm('Fundos imobiliários', 'FII de tijolo, papel e híbrido', 'Tijolo investe principalmente em imóveis. Papel investe principalmente em títulos e direitos ligados ao setor imobiliário, como CRIs. Híbridos combinam estratégias; o mandato e a carteira ajudam a identificar a exposição real.'),
  GlossaryTerm('Fundos imobiliários', 'FOF e desenvolvimento', 'FOF é um fundo que investe principalmente em cotas de outros fundos. Um fundo de desenvolvimento participa de projetos de construção ou incorporação, assumindo riscos diferentes dos de imóveis já alugados.'),
  GlossaryTerm('Fundos imobiliários', 'Vacância física e financeira', 'Vacância física mede a parcela da área disponível sem ocupação. Vacância financeira mede a parcela da receita potencial perdida por desocupação, conforme a metodologia do fundo. Os percentuais podem ser diferentes.'),
  GlossaryTerm('Fundos imobiliários', 'Multi-inquilino e mono-inquilino', 'Multi-inquilino significa mais de um locatário. Mono-inquilino indica concentração em apenas um. Muitos imóveis alugados ao mesmo grupo econômico ainda podem representar concentração relevante.'),
  GlossaryTerm('Fundos imobiliários', 'CRI e alocação em CRIs', 'CRI é um Certificado de Recebíveis Imobiliários, ligado a créditos do setor imobiliário. A alocação informa quanto da carteira está aplicado nesses títulos. Quantidade de CRIs não equivale automaticamente a quantidade de devedores independentes.'),
  GlossaryTerm('Fundos imobiliários', 'Administrador e gestor', 'O administrador cuida da administração e das obrigações do fundo. O gestor toma decisões de investimento dentro do mandato. As funções e remunerações devem ser conferidas no regulamento.'),
  GlossaryTerm('Fundos imobiliários', 'Gestão ativa e passiva', 'Na gestão ativa, o gestor decide como alocar e movimentar a carteira dentro do mandato. Na passiva, a estratégia é mais restrita ou segue uma referência. “Gestão definida” não é sinônimo automático de passiva.'),
  GlossaryTerm('Fundos imobiliários', 'Taxa de administração', 'Remuneração recorrente pelos serviços do fundo, calculada sobre a base e na frequência previstas no regulamento. Confira quais custos estão incluídos e se a referência apresentada é anual.'),
  GlossaryTerm('Fundos imobiliários', 'Taxa de performance', 'Remuneração variável vinculada ao desempenho acima de uma referência. O percentual isolado não basta: confira benchmark, fórmula, período de apuração e condições de cobrança.'),
  GlossaryTerm('Fundos imobiliários', 'Benchmark, IPCA+X e CDI', 'Benchmark é a referência de comparação. IPCA é um índice de inflação; IPCA+X combina inflação e uma parcela adicional definida na fórmula. CDI é uma referência ligada às operações entre bancos. Essas referências não são equivalentes.'),
  GlossaryTerm('Preço e rendimentos', 'Cotação e valor de mercado', 'Cotação é o preço de negociação de uma ação ou cota. O valor de mercado de uma empresa relaciona o preço de suas ações à quantidade de ações; ele é diferente do patrimônio líquido.'),
  GlossaryTerm('Preço e rendimentos', 'Dividend yield (DY)', 'Relação entre os proventos considerados em um período e o preço usado no cálculo. O DY passado não garante o rendimento futuro. Ele não deve ser somado ao CAGR da planilha como uma estimativa automática de retorno.'),
  GlossaryTerm('Preço e rendimentos', 'P/L, LPA, P/VP e VPA', 'LPA é o lucro por ação; P/L compara preço e lucro por ação. VPA é o patrimônio líquido por ação ou cota; P/VP compara o preço com esse valor patrimonial. Valores baixos, isoladamente, não comprovam que um ativo esteja barato.'),
  GlossaryTerm('Preço e rendimentos', 'Dividendos, JCP e rendimentos', 'São formas de pagamento aos investidores. JCP significa juros sobre capital próprio e pode ter retenção tributária. Nos FIIs, os pagamentos de renda costumam ser chamados de rendimentos. Amortização devolve capital e não deve ser confundida com renda recorrente.'),
  GlossaryTerm('Preço e rendimentos', 'Data com, data ex e pagamento', 'Data com é a data-limite de posição para ter direito ao evento anunciado. A partir da data ex, a negociação já ocorre sem esse direito. A data de pagamento é quando o valor é creditado; pode ser bem depois.'),
  GlossaryTerm('Preço e rendimentos', 'Periodicidade e dia habitual', 'São estimativas construídas com as datas de pagamentos anteriores. O padrão histórico pode mudar; ele não representa uma agenda garantida para os próximos pagamentos.'),
];

String searchKey(String text) => text.toLowerCase()
    .replaceAll(RegExp('[áàâãä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[íìîï]'), 'i')
    .replaceAll(RegExp('[óòôõö]'), 'o')
    .replaceAll(RegExp('[úùûü]'), 'u')
    .replaceAll('ç', 'c');

class LearnMorePage extends StatefulWidget {
  const LearnMorePage({super.key});
  @override
  State<LearnMorePage> createState() => _LearnMorePageState();
}

class _LearnMorePageState extends State<LearnMorePage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final key = searchKey(query.trim());
    final terms = glossary.where((term) => searchKey('${term.name} ${term.definition} ${term.group}').contains(key)).toList();
    String? lastGroup;
    return Scaffold(
      appBar: AppBar(title: const Text('Aprenda um pouco mais')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    labelText: 'Buscar um termo',
                    hintText: 'Tag along, EBITDA, final 11…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    if (terms.isEmpty)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text('Nenhum termo encontrado. Tente outra palavra.', style: TextStyle(color: context.palette.muted))),
                    for (final term in terms) ...[
                      if (lastGroup != term.group)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
                          child: Text(lastGroup = term.group, style: TextStyle(color: context.palette.mint, fontWeight: FontWeight.w600)),
                        ),
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          key: ValueKey('${term.name}:$key'),
                          initiallyExpanded: key.isNotEmpty || term.group == 'Códigos da bolsa',
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: Text(term.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text(term.definition, style: TextStyle(color: context.palette.muted, height: 1.6))],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
