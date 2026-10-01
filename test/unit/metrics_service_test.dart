import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/providers/metrics_provider.dart';

class MockAlertService extends AlertService {
  final List<String> triggeredAlerts = [];

  @override
  void triggerAlert(String name, String reason, num value, {String? traceId}) {
    triggeredAlerts.add(name);
  }
}

void main() {
  late ProviderContainer container;
  late MockAlertService mockAlert;
  late MetricsService metricsService;

  setUp(() {
    mockAlert = MockAlertService();
    container = ProviderContainer(
      overrides: [alertProvider.overrideWithValue(mockAlert)],
    );
    metricsService = container.read(metricsProvider);
  });

  tearDown(() {
    container.dispose();
  });

  group('[Unit] MetricsService および AlertService 単体テスト', () {
    test(
      'recordProjectionLagにおいて2000ms以下ではアラートが出ず2000ms超過時にHighProjectionLagが発火すること',
      () {
        metricsService.recordProjectionLag(1500);
        expect(mockAlert.triggeredAlerts, isEmpty);
        expect(container.read(dashboardMetricsProvider)['lastLagMs'], 1500);

        metricsService.recordProjectionLag(2500);
        expect(mockAlert.triggeredAlerts, contains('HighProjectionLag'));
        expect(container.read(dashboardMetricsProvider)['lastLagMs'], 2500);
      },
    );

    test('十分なサンプル数蓄積後にエラー率1パーセント超過でHighErrorRateが発火すること', () async {
      // 9件の成功を記録
      for (int i = 0; i < 9; i++) {
        metricsService.recordLatency('event_append', 20);
      }
      // 1件のエラーを記録（計10件中1件 = 10% > 1%）
      metricsService.recordError();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(mockAlert.triggeredAlerts, contains('HighErrorRate'));
      final state = container.read(dashboardMetricsProvider);
      expect(state['totalEvents'], 10);
      expect(state['errorRate'], 0.1);
    });

    test('十分なサンプル数蓄積後に競合率5パーセント超過でHighConflictRateが発火すること', () async {
      // 9件の成功を記録
      for (int i = 0; i < 9; i++) {
        metricsService.recordLatency('event_append', 20);
      }
      // 1件の競合を記録（計10件中1件 = 10% > 5%）
      metricsService.recordConcurrencyConflict();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(mockAlert.triggeredAlerts, contains('HighConflictRate'));
      final state = container.read(dashboardMetricsProvider);
      expect(state['conflictRate'], 0.1);
    });
  });
}
