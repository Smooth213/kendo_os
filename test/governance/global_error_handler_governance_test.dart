import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Governance] グローバル例外トラップおよび直前状態緊急退避保証規約', () {
    test('GlobalErrorHandlerがrunZonedGuardedを配備しZone内部で初期化を完結していること', () {
      final file = File('lib/shared/errors/global_error_handler.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('runZonedGuarded'), isTrue);
      expect(
        content.contains('WidgetsFlutterBinding.ensureInitialized()'),
        isTrue,
      );
    });

    test('同期および非同期ならびにプラットフォームエラーの全3系統で緊急退避メソッドが呼び出されていること', () {
      final file = File('lib/shared/errors/global_error_handler.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('FlutterError.onError'), isTrue);
      expect(content.contains('PlatformDispatcher.instance.onError'), isTrue);
      expect(
        'EmergencyCrashPreserver.preserveOnCrash'.allMatches(content).length,
        greaterThanOrEqualTo(3),
      );
    });
  });
}
