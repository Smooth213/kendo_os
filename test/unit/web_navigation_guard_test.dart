import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/services/web_navigation_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ WebNavigationGuard 単体テスト', () {
    test('1. 非Web / スタブ環境で例外なく安全に呼び出せること', () {
      expect(() => setWebBeforeUnloadActive(true), returnsNormally);
      expect(() => setWebBeforeUnloadActive(false), returnsNormally);
    });
  });
}
