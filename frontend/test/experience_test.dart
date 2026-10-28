import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:investir/api.dart';
import 'package:investir/app_theme.dart';
import 'package:investir/education.dart';
import 'package:investir/main.dart';

void main() {
  final catalog = File('test/fixtures/catalog.json').readAsStringSync();
  Api fakeApi() => Api(client: MockClient((request) async {
    return http.Response(catalog, 200,
      headers: {'content-type': 'application/json; charset=utf-8'});
  }))..base = 'https://example.test';

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('troca tema sem perder a busca e restaura a escolha ao reabrir', (tester) async {
    phone(tester);
    await tester.pumpWidget(InvestirApp(api: fakeApi()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'B3SA3');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Servidor'), findsNothing);
    expect(find.byTooltip('Ativar modo claro'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Home))).brightness, Brightness.light);
    expect(find.text('1 ativos nesta seleção'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool('dark_mode'), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(InvestirApp(api: fakeApi()));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Home))).brightness, Brightness.light);
    expect(find.byTooltip('Ativar modo escuro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards de regras abrem detalhes e o glossário permite buscar conceitos', (tester) async {
    phone(tester);
    await tester.pumpWidget(InvestirApp(api: fakeApi()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regras'));
    await tester.pumpAndSettle();
    expect(find.text('Sociedade'), findsOneWidget);
    expect(find.text('Informações incompletas'), findsNothing);
    expect(find.text('Preços e proventos'), findsNothing);
    expect(find.textContaining('Somente ON'), findsNothing);
    expect(find.textContaining(RegExp(r'[Aa]ulas?\s+[45]\.')), findsNothing);
    final society = tester.widget<ListTile>(find.ancestor(
      of: find.text('Sociedade'), matching: find.byType(ListTile)));
    expect(society.subtitle, isNull);
    await tester.tap(find.text('Sociedade'));
    await tester.pumpAndSettle();
    expect(find.byType(RuleSectionPage), findsOneWidget);
    expect(find.text('Tag along'), findsOneWidget);
    expect(find.textContaining('Preferido: 100%'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Aprenda um pouco mais'), 250);
    await tester.tap(find.text('Aprenda um pouco mais'));
    await tester.pumpAndSettle();
    expect(find.byType(LearnMorePage), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'ebitda');
    await tester.pumpAndSettle();
    expect(find.text('EBITDA'), findsOneWidget);
    expect(find.textContaining('não representa o dinheiro'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'final 11');
    await tester.pumpAndSettle();
    expect(find.text('Final 11 — units, FIIs e ETFs'), findsOneWidget);
    expect(find.textContaining('não identifica sozinho'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Status Invest usa o tipo do ativo e mantém o domínio fixo', () {
    final cases = {
      ('WEGE3', 'stocks'): 'https://statusinvest.com.br/acoes/wege3',
      ('CURY3', 'stocks'): 'https://statusinvest.com.br/acoes/cury3',
      ('BRCO11', 'fiis'): 'https://statusinvest.com.br/fundos-imobiliarios/brco11',
      ('GGRC11', 'fiis'): 'https://statusinvest.com.br/fundos-imobiliarios/ggrc11',
      ('KLBN11', 'stocks'): 'https://statusinvest.com.br/acoes/klbn11',
    };
    for (final entry in cases.entries) {
      expect(statusInvestUri(entry.key.$1, entry.key.$2).toString(), entry.value);
    }
    expect(() => statusInvestUri('../outro', 'stocks'), throwsArgumentError);
    expect(() => statusInvestUri('WEGE3', 'desconhecido'), throwsArgumentError);
  });

  testWidgets('botão abre o ativo e informa falha sem interromper a tela', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatusInvestButton(
      ticker: 'BRCO11', kind: 'fiis', launcher: (uri) async { opened = uri; return false; },
    ))));
    await tester.tap(find.text('Ver no Status Invest'));
    await tester.pumpAndSettle();
    expect(opened.toString(), 'https://statusinvest.com.br/fundos-imobiliarios/brco11');
    expect(find.textContaining('Não foi possível abrir o Status Invest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('atalho para Status Invest aparece no detalhe mesmo sem cotação', (tester) async {
    phone(tester);
    final api = Api(client: MockClient((request) async {
      final payload = request.url.path.endsWith('/market') ? {
        'quote': null, 'history': [], 'dividends': [], 'sources': {}, 'warnings': [],
        'dividend_summary': {'frequency': 'Dados insuficientes'},
      } : {
        'ticker': 'BRCO11', 'name': 'Bresco Logística', 'kind': 'fiis',
        'segment': 'Logística', 'source_row': 1,
        'snapshot': {'reference': '2026-10'},
        'assessment': {'status': 'review', 'version': 'test', 'rules': [], 'notes': []},
      };
      return http.Response(jsonEncode(payload), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
    }))..base = 'https://example.test';
    await tester.pumpWidget(MaterialApp(theme: investirTheme(Brightness.light),
      home: AssetDetail(api: api, ticker: 'BRCO11'))));
    await tester.pumpAndSettle();
    expect(find.text('Ver no Status Invest'), findsOneWidget);
    expect(find.text('Indisponível'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
