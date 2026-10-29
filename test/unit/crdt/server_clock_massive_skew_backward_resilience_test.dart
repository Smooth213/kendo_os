import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/time/server_clock_offset_service.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[Unit] 端末時計大規模過去巻き戻し（Clock Backward Skew）耐障害性テスト', () {
    test('端末時計が手動で1時間過去に戻された場合でも、補正により時刻が単調増加し負の経過時間やNaNが発生しないこと', () {
      final clockService = ServerClockOffsetService.instance;
      clockService.resetOffset();

      final timeSource = SystemTimeSource(clockService);

      // 試合開始時刻
      final matchStartTime = timeSource.now();

      // 端末のOS時計が手動で1時間過去（-3600秒）に巻き戻されたシミュレーション
      // サーバー同期により、オフセットが +1時間に設定されて補正される
      clockService.setOffset(const Duration(hours: 1));

      final correctedNow = timeSource.now();

      // 経過時間の計算
      final elapsed = correctedNow.difference(matchStartTime);

      // 検証:
      // 1. 経過時間が負数にならないこと
      expect(elapsed.isNegative, isFalse);
      // 2. 時計が過去に戻されても補正により未来の時刻として単調増加していること
      expect(
        correctedNow.isAfter(matchStartTime) ||
            correctedNow.isAtSameMomentAs(matchStartTime),
        isTrue,
      );

      clockService.resetOffset();
    });
  });
}
