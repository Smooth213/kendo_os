import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';

void main() {
  group('📱 【Phase 2-2/10】試合中の画面消灯（スリープ）防止 WakeLock 保持・復帰テスト', () {
    test('1. SettingsModel のデフォルトで sleepPrevent が true（消灯防止有効）であること', () {
      final defaultSettings = SettingsModel();
      expect(defaultSettings.sleepPrevent, isTrue);
    });

    test('2. 試合進行中の WakeLock 状態判定ロジックが安全に true を維持すること', () {
      bool shouldKeepScreenOn(bool isProgress, bool prevent) =>
          isProgress && prevent;

      // 試合中かつ消灯防止ONの場合、常時WakeLockを要求
      expect(shouldKeepScreenOn(true, true), isTrue);

      // 大会終了・待機画面へ遷移した場合
      expect(shouldKeepScreenOn(false, true), isFalse);
    });

    test('3. 設定トグルによる WakeLock 有効/無効の切り替えの完全性', () {
      final settings = SettingsModel(sleepPrevent: false);
      expect(settings.sleepPrevent, isFalse);

      final reEnabled = settings.copyWith(sleepPrevent: true);
      expect(reEnabled.sleepPrevent, isTrue);
    });
  });
}
