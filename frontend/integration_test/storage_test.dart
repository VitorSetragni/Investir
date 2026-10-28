import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:investir/api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Chaves local guarda, atualiza e remove a sessão sem provisionamento',
      (tester) async {
    await tester.runAsync(() async {
      final storage = Api().storage;
      final key = 'installation_check_${DateTime.now().microsecondsSinceEpoch}';
      try {
        await storage.write(key: key, value: 'first');
        expect(await storage.read(key: key), 'first');
        await storage.write(key: key, value: 'updated');
        expect(await storage.read(key: key), 'updated');
        await storage.delete(key: key);
        expect(await storage.read(key: key), isNull);
      } finally {
        await storage.delete(key: key);
      }
    });
  });
}
