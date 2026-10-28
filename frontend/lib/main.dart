import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

const bg = Color(0xFF0B111B),
    panel = Color(0xFF131D2B),
    line = Color(0xFF273449),
    mint = Color(0xFF74E5B2),
    muted = Color(0xFF9BAEC6),
    amber = Color(0xFFF5C47C);
final money = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);
final integer = NumberFormat.decimalPattern('pt_BR');
const names = {
  'preferred': 'Dentro dos filtros',
  'acceptable': 'Aceitáveis',
  'review': 'A confirmar',
  'excluded': 'Fora dos filtros',
  'pass': 'Atende',
  'fail': 'Não atende',
  'pending': 'A confirmar',
  'na': 'Não se aplica',
};
Color statusColor(String status) => switch (status) {
  'preferred' || 'pass' => mint,
  'acceptable' => amber,
  'excluded' || 'fail' => const Color(0xFFFF9B9B),
  _ => muted,
};
String monthLabel(String? s) {
  if (s == null) return 'Sem planilha';
  final p = s.split('-');
  const m = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return '${m[int.parse(p[1]) - 1]}/${p[0]}';
}

String shortDate(String? s) {
  if (s == null) return 'Não informado';
  try {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(s).toLocal());
  } catch (_) {
    return s;
  }
}

String shown(dynamic value, String key) {
  if (value == null) return 'Não informado';
  if (value is num) {
    if ([
      'Tag Along',
      'Free Float',
      'ROE',
      'ROIC',
      'Margem EBIT',
      'Margem Líquida',
      'Vacância',
      '% em CRIs',
      'Taxa de adm',
      'Div. Yield',
      'DY 12M Acumulado',
    ].contains(key))
      return '${NumberFormat('0.00', 'pt_BR').format(value * 100)}%';
    if ([
      'Patrim Liq',
      'Patrimônio Líquido',
      'Liquidez média diária',
      'Liquidez diária',
    ].contains(key))
      return money.format(value);
    if (key == 'Dívida Líquida/EBITDA')
      return '${NumberFormat('0.00', 'pt_BR').format(value)}x';
    return integer.format(value);
  }
  return value.toString();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = Api();
  await api.initialize();
  runApp(InvestirApp(api: api));
}

class InvestirApp extends StatelessWidget {
  final Api api;
  const InvestirApp({super.key, required this.api});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Investir',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mint,
        brightness: Brightness.dark,
        surface: panel,
        primary: mint,
      ),
      fontFamily: 'Roboto',
      dividerColor: line,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
      ),
    ),
    home: Home(api: api),
  );
}

class Home extends StatefulWidget {
  final Api api;
  const Home({super.key, required this.api});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int page = 0;
  String filter = 'selected', search = '';
  bool loading = true;
  String? error;
  Map<String, dynamic>? catalog;
  final searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (!widget.api.configured) {
      setState(() {
        loading = false;
        error = null;
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.api.get('/api/catalog');
      if (mounted)
        setState(() {
          catalog = Map<String, dynamic>.from(data);
          loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString();
          loading = false;
        });
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> configure() async {
    final ctrl = TextEditingController(text: widget.api.base);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conectar ao servidor'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informe o endereço HTTPS do seu backend. A consulta é pública; o login só é usado para atualizar a base.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Endereço da API',
                  hintText: 'https://seu-app.justrunmy.app',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        await widget.api.configure(result);
        catalog = null;
        await load();
      } catch (e) {
        message(e.toString());
      }
    }
  }

  Future<bool> login() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => LoginDialog(api: widget.api),
    );
    if (mounted) setState(() {});
    return result == true;
  }

  Future<void> importSheet() async {
    if (!widget.api.configured) {
      await configure();
      return;
    }
    if (!widget.api.signedIn && !await login()) return;
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ImportDialog(api: widget.api),
    );
    if (result == true) {
      await load();
      if (mounted)
        message('Planilha substituída. A nova triagem já está disponível.');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide) rail(),
            Expanded(
              child: Column(
                children: [
                  topbar(wide),
                  Expanded(child: page == 2 ? about() : body(wide)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: page,
              onDestinationSelected: (i) => setState(() {
                page = i;
                filter = 'selected';
              }),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.candlestick_chart_outlined),
                  label: 'Ações',
                ),
                NavigationDestination(
                  icon: Icon(Icons.apartment_outlined),
                  label: 'FIIs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.rule_outlined),
                  label: 'Regras',
                ),
              ],
            ),
    );
  }

  Widget rail() => Container(
    width: 210,
    decoration: const BoxDecoration(
      color: panel,
      border: Border(right: BorderSide(color: line)),
    ),
    padding: const EdgeInsets.fromLTRB(18, 30, 18, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.stacked_line_chart, color: mint, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'investir',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'FUNDAMENTOS EM FOCO',
          style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.6),
        ),
        const SizedBox(height: 46),
        for (final (i, icon, label) in [
          (0, Icons.candlestick_chart_outlined, 'Ações'),
          (1, Icons.apartment_outlined, 'Fundos imobiliários'),
          (2, Icons.rule_outlined, 'Regras da triagem'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: page == i
                  ? mint.withValues(alpha: .12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Icon(icon, color: page == i ? mint : muted),
                title: Text(
                  label,
                  style: TextStyle(
                    color: page == i ? mint : muted,
                    fontSize: 13,
                  ),
                ),
                onTap: () => setState(() {
                  page = i;
                  filter = 'selected';
                }),
              ),
            ),
          ),
        const Spacer(),
        const Divider(),
        const SizedBox(height: 12),
        Text(
          widget.api.signedIn ? 'Importação autorizada' : 'Consulta pública',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          widget.api.email ?? 'Sem cadastro para consultar',
          style: const TextStyle(fontSize: 11),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: configure,
          icon: const Icon(Icons.settings_outlined, size: 16),
          label: const Text('Servidor'),
        ),
      ],
    ),
  );
  Widget topbar(bool wide) => Padding(
    padding: EdgeInsets.fromLTRB(wide ? 32 : 18, 18, wide ? 32 : 14, 12),
    child: Row(
      children: [
        Expanded(
          child: wide
              ? const Text(
                  'Carteira de pesquisa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 13),
                )
              : const Row(
                  children: [
                    Icon(Icons.stacked_line_chart, color: mint),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'investir',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
        ),
        IconButton(
          tooltip: 'Atualizar base',
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh, size: 21),
        ),
        if (!wide)
          IconButton(
            tooltip: 'Servidor',
            onPressed: configure,
            icon: const Icon(Icons.settings_outlined, size: 21),
          ),
        if (widget.api.signedIn)
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: () async {
              await widget.api.logout();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.logout, size: 20),
          ),
        FilledButton.icon(
          onPressed: importSheet,
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(wide ? 'Importar planilha' : 'Importar'),
        ),
      ],
    ),
  );
  Widget body(bool wide) {
    if (!widget.api.configured)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hub_outlined, size: 64, color: mint),
              const SizedBox(height: 24),
              const Text(
                'Conecte sua base de investimentos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                'Ações e FIIs organizados pelas suas regras, com a competência de cada planilha sempre visível.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: configure,
                child: const Text('Configurar servidor'),
              ),
            ],
          ),
        ),
      );
    if (loading && catalog == null)
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Conectando ao servidor…'),
              SizedBox(height: 8),
              Text(
                'O primeiro acesso pode levar até 2 minutos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ],
          ),
        ),
      );
    if (error != null)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44, color: amber),
              const SizedBox(height: 16),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: load,
                child: const Text('Tentar novamente'),
              ),
              TextButton(
                onPressed: configure,
                child: const Text('Alterar servidor'),
              ),
            ],
          ),
        ),
      );
    final kind = page == 0 ? 'stocks' : 'fiis';
    final all = (catalog?['assets'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where((a) => a['kind'] == kind)
        .toList();
    final snapshots = (catalog?['snapshots'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final snapshot = snapshots.where((s) => s['kind'] == kind).firstOrNull;
    final filtered = all.where((a) {
      final st = a['status'];
      return (filter == 'all' ||
              filter == 'selected' &&
                  (st == 'preferred' || st == 'acceptable') ||
              st == filter) &&
          ('${a['ticker']} ${a['name']} ${a['segment']}'.toLowerCase().contains(
            search.toLowerCase(),
          ));
    }).toList();
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final a in filtered) {
      final cat = switch (a['category']) {
        'brick' => 'Tijolo',
        'paper' => 'Papel',
        'hybrid' => 'Híbridos',
        _ => 'Outros',
      };
      final key = page == 0
          ? a['segment'].toString()
          : '$cat · ${a['segment']}';
      groups.putIfAbsent(key, () => []).add(a);
    }
    final keys = groups.keys.toList()..sort();
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(wide ? 32 : 18, 16, wide ? 32 : 18, 30),
        children: [
          Text(
            page == 0 ? 'Ações' : 'Fundos imobiliários',
            style: TextStyle(
              fontSize: wide ? 32 : 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page == 0
                ? 'Compare os fundamentos por setor.'
                : 'Explore tijolo e papel por segmento de atuação.',
            style: const TextStyle(color: muted, fontSize: 14),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              tag(
                Icons.calendar_month_outlined,
                'Base: ${monthLabel(snapshot?['reference'])}',
              ),
              tag(Icons.dataset_outlined, '${all.length} ativos analisados'),
              if (catalog?['demo'] == true)
                tag(
                  Icons.science_outlined,
                  'Ambiente local de demonstração',
                  color: amber,
                ),
            ],
          ),
          if (snapshot?['older_than_current_month'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: notice(
                'A última planilha disponível é de ${monthLabel(snapshot?['reference'])}. A seleção será mantida até uma nova importação.',
                Icons.history,
              ),
            ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (ctx, c) {
              final cols = c.maxWidth > 680 ? 4 : 2;
              final width = (c.maxWidth - (cols - 1) * 10) / cols;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final s in [
                    'preferred',
                    'acceptable',
                    'review',
                    'excluded',
                  ])
                    SizedBox(
                      width: width,
                      child: InkWell(
                        onTap: () => setState(() => filter = s),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panel,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: filter == s ? statusColor(s) : line,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${all.where((a) => a['status'] == s).length}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor(s),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                names[s]!,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: searchController,
            onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(
              hintText: 'Buscar código, empresa ou segmento',
              prefixIcon: Icon(Icons.search, size: 22),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in [
                  ('selected', 'Selecionados'),
                  ('preferred', 'Dentro dos filtros'),
                  ('acceptable', 'Aceitáveis'),
                  ('review', 'A confirmar'),
                  ('excluded', 'Fora dos filtros'),
                  ('all', 'Todos'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: filter == value,
                      onSelected: (_) => setState(() => filter = value),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${filtered.length} ativos nesta seleção',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  const Icon(
                    Icons.filter_alt_off_outlined,
                    color: muted,
                    size: 38,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    all.isEmpty
                        ? 'Importe a primeira planilha para gerar a triagem.'
                        : 'Nenhum ativo nesta seleção. Consulte “A confirmar” para dados que exigem conferência.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
          for (final key in keys) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 12),
              child: Row(
                children: [
                  Container(width: 3, height: 18, color: mint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${groups[key]!.length}',
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (ctx, c) {
                final cols = c.maxWidth >= 1080
                    ? 3
                    : c.maxWidth >= 570
                    ? 2
                    : 1;
                final w = (c.maxWidth - 12 * (cols - 1)) / cols;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final a in groups[key]!)
                      SizedBox(width: w, child: assetCard(a)),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'A triagem usa os dados da planilha. Não avalia preço justo nem garante continuidade de lucros ou rendimentos.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget assetCard(Map<String, dynamic> a) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetail(api: widget.api, ticker: a['ticker']),
          ),
        );
        await load();
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    a['ticker'].toString().substring(0, 2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: mint,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['ticker'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        a['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: muted),
              ],
            ),
            const SizedBox(height: 18),
            statusBadge(a['status']),
            const SizedBox(height: 12),
            Text(
              (a['acceptable_rules'] as List).isNotEmpty
                  ? 'Faixa tolerada: ${(a['acceptable_rules'] as List).join(', ')}'
                  : (a['pending_rules'] as List).isNotEmpty
                  ? 'Conferir: ${(a['pending_rules'] as List).join(', ')}'
                  : 'Veja os critérios e seus valores',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: muted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
  Widget about() => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      const Text(
        'Regras da triagem',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 14),
      const Text(
        'Baseadas nas aulas 4.2 a 4.4 e 5.2 a 5.4 do material fornecido. Cada ativo mostra o valor, a referência, a fonte da regra e as pendências.',
        style: TextStyle(color: muted, height: 1.6),
      ),
      const SizedBox(height: 22),
      for (final (title, body) in [
        (
          'Sociedade',
          'Somente ON. Tag along de 100% preferido e ≥80% tolerado. Free float >35% preferido e 15–35% tolerado. Preferência por Novo Mercado. Sem controle estatal direto ou indireto.',
        ),
        (
          'Lucro e negócio',
          'Lucro consistente ≥11 anos preferido; 6–10 anos tolerado. Mínimo de 5 anos de listagem. Dívida líquida/EBITDA <3x preferida, 3–4x intermediária, >4x excluída. Filtros: ROE/ROIC ≥10%, PL ≥R\$ 1 bi, liquidez ≥R\$ 10 mi/dia, margens EBIT e líquida ≥4%.',
        ),
        (
          'FIIs de tijolo',
          'Preferência por 10 imóveis ou mais; seu mínimo é 8. Vacância <25% preferida e 25–30% tolerada. Multi-inquilino e listagem >4 anos. Preferência por lajes, logística e shopping. Residencial e outros intermediários; hospital/hotel excluídos.',
        ),
        (
          'FIIs de papel',
          'Não se aplicam vacância, imóveis e inquilinos. CRIs: alocação >75% e ≥50 títulos preferidos; ≥50% e ≥30 títulos no mínimo.',
        ),
        (
          'Gestão e taxas',
          'Ranking de administradores fornecido. Papel: referência 1% a.a., sem performance. Tijolo passivo: referência 0,2% a.a., sem performance. Tijolo ativo: referência 2% a.a.; performance até 20% do excedente de IPCA+X, com ótimos resultados. Acima da referência fica a confirmar, pois o curso não define “muito superior” numericamente.',
        ),
        (
          'Informações incompletas',
          'Traço em performance e taxa de administração zero exigem conferência. Número de negociações não é volume em reais. A planilha não prova sozinha lucro anual consecutivo. “Dentro dos filtros” significa conformidade com os dados disponíveis.',
        ),
        (
          'Preços e proventos',
          'Cotações de provedor público, sujeitas a atraso, com cache de 15 minutos. Gráfico de preços não representa retorno total. Periodicidade e dia de pagamento são estimativas históricas. Não há preço justo automático.',
        ),
      ])
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 10),
                Text(body, style: const TextStyle(color: muted, height: 1.6)),
              ],
            ),
          ),
        ),
    ],
  );
}

Widget tag(IconData icon, String label, {Color color = muted}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
  decoration: BoxDecoration(
    border: Border.all(color: line),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Flexible(child: Text(label, style: TextStyle(color: color, fontSize: 12))),
    ],
  ),
);
Widget statusBadge(String status) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: statusColor(status).withValues(alpha: .10),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    names[status] ?? status,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: statusColor(status),
    ),
  ),
);
Widget notice(String text, IconData icon) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: amber.withValues(alpha: .07),
    border: Border.all(color: amber.withValues(alpha: .22)),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: amber, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: amber, height: 1.5),
        ),
      ),
    ],
  ),
);

class LoginDialog extends StatefulWidget {
  final Api api;
  const LoginDialog({super.key, required this.api});
  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false, obscure = true;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.api.login(email.text, password.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() {
          busy = false;
          error = e.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Entrar para importar'),
    content: SizedBox(
      width: 400,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A consulta é livre. Use a conta autorizada pelo responsável para substituir as planilhas.',
              style: TextStyle(color: muted, height: 1.5),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: email,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: password,
              enabled: !busy,
              obscureText: obscure,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) {
                if (!busy) submit();
              },
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(error!, style: const TextStyle(color: amber)),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: busy ? null : submit,
        child: Text(busy ? 'Entrando…' : 'Entrar'),
      ),
    ],
  );
}

class ImportDialog extends StatefulWidget {
  final Api api;
  const ImportDialog({super.key, required this.api});
  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  String kind = 'stocks';
  late int year, month;
  Uint8List? bytes;
  String? filename, error;
  bool busy = false;
  Map<String, dynamic>? preview;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    year = now.year;
    month = now.month;
  }

  String get reference => '$year-${month.toString().padLeft(2, '0')}';
  Future<void> pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null) return;
      final f = result.files.single;
      if (f.size > 12 * 1024 * 1024) throw ApiError('O arquivo excede 12 MB.');
      if (f.bytes == null) throw ApiError('Não foi possível ler o arquivo.');
      if (mounted)
        setState(() {
          bytes = f.bytes;
          filename = f.name;
          preview = null;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final fields = {'kind': kind, 'reference': reference};
      if (preview == null) {
        final p = await widget.api.upload(
          '/api/imports/preview',
          bytes!,
          filename!,
          fields,
        );
        if (mounted) setState(() => preview = Map<String, dynamic>.from(p));
      } else {
        fields['expected_revision'] = preview!['expected_revision'].toString();
        fields['sha256'] = preview!['sha256'];
        await widget.api.upload('/api/imports', bytes!, filename!, fields);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString();
          if (e is ApiError && e.status == 409) preview = null;
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(
        preview == null ? 'Importar planilha mensal' : 'Confirmar substituição',
      ),
      content: SizedBox(
        width: 490,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (preview == null) ...[
                const Text(
                  'Escolha o tipo e a competência. A outra planilha será mantida.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  decoration: const InputDecoration(
                    labelText: 'Tipo da planilha',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'stocks', child: Text('Ações')),
                    DropdownMenuItem(value: 'fiis', child: Text('FIIs')),
                  ],
                  onChanged: busy ? null : (v) => setState(() => kind = v!),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: month,
                        decoration: const InputDecoration(labelText: 'Mês'),
                        items: [
                          for (var i = 1; i <= 12; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text(
                                monthLabel(
                                  '2026-${i.toString().padLeft(2, '0')}',
                                ).split('/')[0],
                              ),
                            ),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() => month = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: year,
                        decoration: const InputDecoration(labelText: 'Ano'),
                        items: [
                          for (
                            var i = DateTime.now().year - 5;
                            i <= DateTime.now().year;
                            i++
                          )
                            DropdownMenuItem(value: i, child: Text('$i')),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() => year = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: busy ? null : pick,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Escolher arquivo XLSX'),
                ),
                if (filename != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(filename!, style: const TextStyle(color: mint)),
                  ),
              ] else ...[
                Text(
                  '${preview!['count']} ativos · ${monthLabel(preview!['reference'])}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                for (final s in [
                  'preferred',
                  'acceptable',
                  'review',
                  'excluded',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(names[s]!)),
                        Text(
                          '${preview!['counts'][s] ?? 0}',
                          style: TextStyle(
                            color: statusColor(s),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                notice(
                  'A base anterior de ${kind == 'stocks' ? 'ações' : 'FIIs'} (${monthLabel(preview!['previous']['reference'])}) será substituída por ${monthLabel(reference)}. O arquivo antigo e seus registros não serão mantidos.',
                  Icons.swap_horiz,
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(error!, style: const TextStyle(color: amber)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (preview != null)
          TextButton(
            onPressed: busy ? null : () => setState(() => preview = null),
            child: const Text('Voltar'),
          ),
        FilledButton(
          onPressed: busy || bytes == null ? null : submit,
          child: Text(
            busy
                ? 'Processando…'
                : preview == null
                ? 'Validar e revisar'
                : 'Substituir base',
          ),
        ),
      ],
    ),
  );
}

class AssetDetail extends StatefulWidget {
  final Api api;
  final String ticker;
  const AssetDetail({super.key, required this.api, required this.ticker});
  @override
  State<AssetDetail> createState() => _AssetDetailState();
}

class _AssetDetailState extends State<AssetDetail> {
  late Future<dynamic> detailFuture, marketFuture;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    detailFuture = widget.api.get('/api/assets/${widget.ticker}');
    marketFuture = widget.api.get('/api/assets/${widget.ticker}/market');
  }

  Future<void> attest(bool stock) async {
    final source = TextEditingController(), note = TextEditingController();
    String key = stock ? 'profit_verified' : 'no_performance';
    bool saving = false;
    String? error;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Registrar conferência'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Registre somente o que você conferiu em documento oficial. Esta evidência vale apenas para a planilha atual.',
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: key,
                    items: stock
                        ? const [
                            DropdownMenuItem(
                              value: 'profit_verified',
                              child: Text('Série anual de lucros conferida'),
                            ),
                          ]
                        : const [
                            DropdownMenuItem(
                              value: 'no_performance',
                              child: Text(
                                'Regulamento confirma ausência de performance',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'administrator_verified',
                              child: Text(
                                'Administrador corresponde ao ranking',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'performance_history_verified',
                              child: Text(
                                'Performance e ótimo histórico conferidos',
                              ),
                            ),
                          ],
                    onChanged: saving ? null : (v) => set(() => key = v!),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: source,
                    decoration: const InputDecoration(
                      labelText: 'Link HTTPS do documento',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: note,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'O que foi conferido',
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!, style: const TextStyle(color: amber)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      set(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await widget.api.attest(widget.ticker, {
                          'key': key,
                          'source_url': source.text.trim(),
                          'note': note.text.trim(),
                          'checked_date': DateFormat(
                            'yyyy-MM-dd',
                          ).format(DateTime.now()),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        set(() {
                          saving = false;
                          error = e.toString();
                        });
                      }
                    },
              child: Text(saving ? 'Salvando…' : 'Registrar'),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.ticker),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => setState(reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder(
      future: detailFuture,
      builder: (ctx, s) {
        if (s.hasError)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(s.error.toString()),
            ),
          );
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final d = s.data as Map;
        final a = d['assessment'] as Map;
        final rules = (a['rules'] as List).cast<Map>();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
              children: [
                Text(
                  d['name'],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    statusBadge(a['status']),
                    tag(
                      Icons.calendar_month_outlined,
                      'Planilha: ${monthLabel(d['snapshot']['reference'])}',
                    ),
                    tag(Icons.layers_outlined, d['segment']),
                  ],
                ),
                const SizedBox(height: 24),
                FutureBuilder(
                  future: marketFuture,
                  builder: (ctx, m) {
                    if (m.hasError)
                      return notice(
                        'Não foi possível consultar o mercado. Os fundamentos continuam disponíveis.',
                        Icons.cloud_off_outlined,
                      );
                    if (!m.hasData)
                      return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    return MarketPanel(data: Map<String, dynamic>.from(m.data));
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'Regra por regra',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dados da planilha, linha ${d['source_row']}. Regras ${a['version']}.',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                for (final r in rules)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Icon(switch (r['status']) {
                        'pass' => Icons.check_circle_outline,
                        'fail' => Icons.cancel_outlined,
                        'acceptable' => Icons.tune,
                        'pending' => Icons.help_outline,
                        _ => Icons.remove_circle_outline,
                      }, color: statusColor(r['status'])),
                      title: Text(
                        r['label'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          shown(r['value'], r['key']),
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                      trailing: statusBadge(r['status']),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['expected'],
                                style: const TextStyle(height: 1.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                r['source'],
                                style: const TextStyle(
                                  color: mint,
                                  fontSize: 12,
                                ),
                              ),
                              if ((r['note'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  r['note'],
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                for (final note in a['notes'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                if (widget.api.signedIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => attest(d['kind'] == 'stocks'),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Registrar conferência documental'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class MarketPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  const MarketPanel({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final q = data['quote'] as Map?;
    final div = data['dividend_summary'] as Map;
    final timestamp = q?['as_of'];
    String timing = 'Horário não informado';
    try {
      if (timestamp != null)
        timing = DateFormat(
          'dd/MM/yyyy HH:mm',
        ).format(DateTime.parse(timestamp).toLocal());
    } catch (_) {}
    final day = div['typical_day'];
    final range = div['typical_day_range'] as List?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ÚLTIMA COTAÇÃO',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q?['price'] != null
                        ? money.format(q!['price'])
                        : 'Indisponível',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timing,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (data['cached'] == true)
              tag(
                Icons.schedule,
                data['stale'] == true ? 'Cache antigo' : 'Cache de até 15 min',
                color: data['stale'] == true ? amber : muted,
              ),
          ],
        ),
        const SizedBox(height: 20),
        PriceChart(
          history: (data['history'] as List)
              .cast<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (ctx, c) {
            final w = c.maxWidth > 620 ? (c.maxWidth - 24) / 3 : c.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metric(
                  'Último pagamento por cota',
                  div['last_amount_per_share'] != null
                      ? money.format(div['last_amount_per_share'])
                      : 'Não informado',
                  shortDate(div['last_payment_date']),
                  w,
                ),
                metric(
                  'Periodicidade',
                  div['frequency'] ?? 'Não informada',
                  'Estimativa por datas de pagamento',
                  w,
                ),
                metric(
                  'Dia habitual',
                  day == null
                      ? 'Variável / sem dados'
                      : 'Por volta do dia $day',
                  range == null
                      ? 'Sem data fixa comprovada'
                      : 'Faixa histórica: dias ${range[0]}–${range[1]}',
                  w,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          div['note'] ?? '',
          style: const TextStyle(color: muted, fontSize: 11, height: 1.5),
        ),
        for (final warning in data['warnings'] ?? [])
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: notice(warning, Icons.info_outline),
          ),
        if ((data['dividends'] as List).isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Histórico de pagamentos',
              style: TextStyle(fontSize: 14),
            ),
            children: [
              for (final e in (data['dividends'] as List).take(12))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${shortDate(e['payment_date'])} · ${e['type']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        money.format(e['amount']),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        Wrap(
          spacing: 10,
          children: [
            for (final entry in (data['sources'] as Map).entries)
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(entry.value.toString());
                  if (uri != null && uri.scheme == 'https')
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new, size: 14),
                label: Text(
                  entry.key == 'prices'
                      ? 'Fonte das cotações'
                      : 'Fonte dos proventos',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget metric(String title, String value, String note, double width) =>
      SizedBox(
        width: width,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: muted, fontSize: 11)),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(note, style: const TextStyle(color: muted, fontSize: 10)),
              ],
            ),
          ),
        ),
      );
}

class PriceChart extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  const PriceChart({super.key, required this.history});
  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  int days = 183;
  int? selected;
  @override
  Widget build(BuildContext context) {
    final last = widget.history.isEmpty
        ? DateTime.now()
        : DateTime.parse(widget.history.last['date']);
    final data = widget.history
        .where((p) => last.difference(DateTime.parse(p['date'])).inDays <= days)
        .toList();
    final values = data.map((p) => (p['close'] as num).toDouble()).toList();
    final min = values.isEmpty ? 0.0 : values.reduce(math.min),
        max = values.isEmpty ? 0.0 : values.reduce(math.max);
    final i = selected != null && selected! < data.length ? selected : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Preço em bolsa',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              for (final (n, label) in [
                (31, '1M'),
                (183, '6M'),
                (366, '1A'),
                (732, '2A'),
              ])
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => setState(() {
                      days = n;
                      selected = null;
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: days == n
                            ? mint.withValues(alpha: .13)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: days == n ? mint : muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (values.length < 2)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Sem histórico disponível',
                  style: TextStyle(color: muted),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 28,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  i == null
                      ? 'Mín. ${money.format(min)}     Máx. ${money.format(max)}'
                      : '${shortDate(data[i]['date'])}   ${money.format(data[i]['close'])}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
            ),
            SizedBox(
              height: 185,
              child: LayoutBuilder(
                builder: (ctx, c) => MouseRegion(
                  onExit: (_) => setState(() => selected = null),
                  onHover: (e) => setState(
                    () => selected =
                        ((e.localPosition.dx / c.maxWidth) * (data.length - 1))
                            .round()
                            .clamp(0, data.length - 1),
                  ),
                  child: GestureDetector(
                    onPanDown: (d) => setState(
                      () => selected =
                          ((d.localPosition.dx / c.maxWidth) *
                                  (data.length - 1))
                              .round()
                              .clamp(0, data.length - 1),
                    ),
                    onPanUpdate: (d) => setState(
                      () => selected =
                          ((d.localPosition.dx / c.maxWidth) *
                                  (data.length - 1))
                              .round()
                              .clamp(0, data.length - 1),
                    ),
                    child: CustomPaint(
                      size: Size(c.maxWidth, 185),
                      painter: SparkPainter(values, i),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shortDate(data.first['date']),
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
                Text(
                  shortDate(data.last['date']),
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Preços da fonte, sem somar dividendos. Toque ou passe o cursor para explorar.',
              style: TextStyle(color: muted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class SparkPainter extends CustomPainter {
  final List<double> values;
  final int? selected;
  SparkPainter(this.values, this.selected);
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min), hi = values.reduce(math.max);
    final span = hi == lo ? 1.0 : hi - lo;
    Offset point(int i) => Offset(
      i / (values.length - 1) * size.width,
      12 + (1 - (values[i] - lo) / span) * (size.height - 24),
    );
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = i / 3 * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mint.withValues(alpha: .20), mint.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = mint
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    if (selected != null) {
      final p = point(selected!);
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, size.height),
        Paint()
          ..color = muted
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 5, Paint()..color = mint);
    }
  }

  @override
  bool shouldRepaint(SparkPainter old) =>
      old.values != values || old.selected != selected;
}
