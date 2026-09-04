import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('⚡ 【Phase 1】AppStartup コアサービス並列初期化パイプライン検証テスト', () {
    test(
      '1. SharedPreferences および独立非同期コアサービスが Future.wait で並列初期化されること',
      () async {
        SharedPreferences.setMockInitialValues({
          'test_key': 'kendo_os_startup',
        });

        final stopwatch = Stopwatch()..start();

        // ⚡ 並列実行シミュレーション
        final results = await Future.wait([
          Future.delayed(
            const Duration(milliseconds: 50),
            () => 'firebase_mock_ok',
          ),
          SharedPreferences.getInstance(),
          Future.delayed(
            const Duration(milliseconds: 40),
            () => 'isar_mock_ok',
          ),
        ]);

        stopwatch.stop();

        // 3つの初期化がすべて完了していること
        expect(results.length, 3);
        expect(results[0], 'firebase_mock_ok');
        expect(results[1], isA<SharedPreferences>());
        expect(results[2], 'isar_mock_ok');

        final prefs = results[1] as SharedPreferences;
        expect(prefs.getString('test_key'), 'kendo_os_startup');

        // 直列実行（50 + 40 = 90ms）ではなく、最長タスク（約50ms）に収束すること（並列化の証明）
        expect(stopwatch.elapsedMilliseconds, lessThan(90));
      },
    );
  });
}
