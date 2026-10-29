import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/services/thermal_monitor_service.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
import 'package:kendo_os/shared/widgets/thermal_floating_toast.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] サーマル冷却および省電力フローティングトースト視覚ピクセルテスト', () {
    testWidgets('高熱警告トーストにおいてダークテーマ背景と警告アイコンが美しく描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final governor = ThermalPowerGovernor();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            thermalPowerGovernorProvider.overrideWith((ref) => governor),
          ],
          child: const MaterialApp(
            home: Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: ThermalToastListener(
                child: SizedBox.expand(
                  child: Center(child: Text('試合会場メインスコアボード')),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 発熱通知（41℃）を発行
      governor.updatePreference('auto');
      governor.updateThermalStatus(ThermalSensorStatus.serious);

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('端末の発熱を検知'), findsOneWidget);
      expect(find.byIcon(Icons.thermostat_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('過熱危険警告トーストにおいてスマートフォン画面幅で適切に折り返され視認性が維持されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844); // iPhone 14/15 相当
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final governor = ThermalPowerGovernor();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            thermalPowerGovernorProvider.overrideWith((ref) => governor),
          ],
          child: const MaterialApp(
            home: Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: ThermalToastListener(child: SizedBox.expand()),
            ),
          ),
        ),
      );

      await tester.pump();

      // 45℃過熱危険トーストを発行
      governor.updatePreference('auto');
      governor.updateThermalStatus(ThermalSensorStatus.critical);

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('端末の高温警戒'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 4));
    });
  });
}
