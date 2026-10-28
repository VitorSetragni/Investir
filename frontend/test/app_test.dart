import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investir/api.dart';
import 'package:investir/main.dart';

void main() {
  final catalog = File('test/fixtures/catalog.json').readAsStringSync();
  Api fakeApi() => Api(
    client: MockClient((request) async {
      if (request.url.path == '/api/catalog') {
        return http.Response(
          catalog,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{"detail":"Ativo não encontrado"}', 404);
    }),
  )..base = 'https://example.test';

  testWidgets('consulta pública mostra ações sem login e respeita busca', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(InvestirApp(api: fakeApi()));
    await tester.pumpAndSettle();
    expect(find.text('Base: out/2026'), findsOneWidget);
    expect(find.text('Entrar para importar'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'B3SA3');
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((widget) => widget is Text && widget.data == 'B3SA3'),
      findsOneWidget,
    );
    expect(find.text('1 ativos nesta seleção'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout de telefone não apresenta overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(InvestirApp(api: fakeApi()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('importação exige login, consulta não', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(InvestirApp(api: fakeApi()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importar planilha'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar para importar'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
  });

  testWidgets('gráfico com histórico vazio mostra indisponibilidade', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PriceChart(history: const [])),
      ),
    );
    expect(find.text('Sem histórico disponível'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gráfico constante não divide por zero', (tester) async {
    final history = List.generate(
      8,
      (i) => {
        'date': '2026-10-${(i + 10).toString().padLeft(2, '0')}',
        'close': 10.0,
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PriceChart(history: history)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('API apresenta mensagem do servidor sem mascarar erro', () async {
    final api = Api(
      client: MockClient(
        (r) async =>
            http.Response(jsonEncode({'detail': 'Sessão expirada'}), 401),
      ),
    )..base = 'https://example.test';
    expect(
      () => api.get('/api/catalog'),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', 401)),
    );
  });
}
