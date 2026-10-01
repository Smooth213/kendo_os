import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/services/thermal_monitor_service.dart';

void main() {
  group('[Unit] ThermalMonitorService 単体テスト', () {
    test('初期状態がnominalでありupdateStatusで通知されること', () {
      final service = ThermalMonitorService();
      expect(service.currentStatus, ThermalSensorStatus.nominal);

      int notifyCount = 0;
      service.addListener(() {
        notifyCount++;
      });

      service.updateStatus(ThermalSensorStatus.fair);
      expect(service.currentStatus, ThermalSensorStatus.fair);
      expect(notifyCount, 1);

      service.dispose();
    });

    test('setOverrideStatusによってステータスが上書きされ通知されること', () {
      final service = ThermalMonitorService();
      service.updateStatus(ThermalSensorStatus.nominal);

      int notifyCount = 0;
      service.addListener(() {
        notifyCount++;
      });

      service.setOverrideStatus(ThermalSensorStatus.critical);
      expect(service.currentStatus, ThermalSensorStatus.critical);
      expect(notifyCount, 1);

      // 上書き中は内部ステータス更新による通知が抑制されること
      service.updateStatus(ThermalSensorStatus.serious);
      expect(service.currentStatus, ThermalSensorStatus.critical);
      expect(notifyCount, 1);

      // 上書き解除で内部ステータスに戻ること
      service.setOverrideStatus(null);
      expect(service.currentStatus, ThermalSensorStatus.serious);
      expect(notifyCount, 2);

      service.dispose();
    });
  });
}
