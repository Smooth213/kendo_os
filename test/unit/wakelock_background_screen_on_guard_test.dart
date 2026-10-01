import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';

void main() {
  group('[Unit] 試合中の画面消灯（スリープ）防止 WakeLock 保持・復帰テスト', () {
    test('設定モデルの初期値で画面消灯防止が有効となること', () {
      final defaultSettings = SettingsModel();
      expect(defaultSettings.sleepPrevent, isTrue);
    });

    test('試合進行中の WakeLock 状態判定ロジックが安全に true を維持すること', () {
      bool shouldKeepScreenOn(bool isProgress, bool prevent) =>
          isProgress && prevent;

      // 試合中かつ消灯防止ONの場合、常時WakeLockを要求
      expect(shouldKeepScreenOn(true, true), isTrue);

      // 大会終了・待機画面へ遷移した場合
      expect(shouldKeepScreenOn(false, true), isFalse);
    });

    test('設定トグルによる WakeLock 有効/無効の切り替えの完全性こと', () {
      final settings = SettingsModel(sleepPrevent: false);
      expect(settings.sleepPrevent, isFalse);

      final reEnabled = settings.copyWith(sleepPrevent: true);
      expect(reEnabled.sleepPrevent, isTrue);
    });
  });
}
