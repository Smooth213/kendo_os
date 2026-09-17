import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🔋 【第13条 ガバナンス監査】端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約', () {
    test('Rule 1: [タイマーTick適正化＆天井逆算排除] 通常1000ms間引きTick＆停止時生ミリ秒加算規約', () {
      final governor = ThermalPowerGovernor();

      expect(
        governor.getTickIntervalForMatch(isHighPrecision: false),
        equals(const Duration(milliseconds: 1000)),
      );
      expect(
        governor.getTickIntervalForMatch(isHighPrecision: true),
        equals(const Duration(milliseconds: 100)),
      );

      governor.setMode(ThermalPowerMode.ecoCooling);
      expect(
        governor.getTickIntervalForMatch(isHighPrecision: false),
        equals(const Duration(milliseconds: 500)),
      );

      final timerFile = File(
        'lib/features/tournament/presentation/operate/providers/match_timer_provider.dart',
      );
      expect(timerFile.existsSync(), isTrue);
      final timerContent = timerFile.readAsStringSync();

      expect(
        timerContent.contains(
          'now.difference(match.timerStartedAt!).inMilliseconds',
        ),
        isTrue,
        reason: 'タイマー停止時は生ミリ秒の差分を加算しなければなりません。',
      );

      final togglePos = timerContent.indexOf('Future<void> toggleTimer(');
      expect(togglePos, isNonNegative);
      final nextMethodPos = timerContent.indexOf(
        'Future<void> updateRemainingSeconds',
        togglePos,
      );
      expect(nextMethodPos, isNonNegative);
      final toggleTimerBody = timerContent.substring(togglePos, nextMethodPos);
      expect(
        toggleTimerBody.contains('.updateRemainingSeconds('),
        isFalse,
        reason: 'toggleTimer 停止処理内で updateRemainingSeconds による逆算再設定は禁止されています。',
      );
    });

    test(
      'Rule 2: [待機時タイマー沈黙] タイマーループ内ディスクI/O禁止 ＆ AppLifecycleListener によるタイマー沈黙規約',
      () {
        final timerFile = File(
          'lib/features/tournament/presentation/operate/providers/match_timer_provider.dart',
        );
        final masterTimerFile = File(
          'lib/features/tournament/presentation/operate/providers/renseikai_master_timer_provider.dart',
        );
        final dockTimerFile = File(
          'lib/features/tournament/presentation/providers/dock_timer_provider.dart',
        );
        final settingsFile = File(
          'lib/shared/presentation/providers/settings_provider.dart',
        );

        expect(timerFile.existsSync(), isTrue);
        expect(masterTimerFile.existsSync(), isTrue);
        expect(dockTimerFile.existsSync(), isTrue);
        expect(settingsFile.existsSync(), isTrue);

        final renseikaiContent = masterTimerFile.readAsStringSync();
        final dockContent = dockTimerFile.readAsStringSync();
        final settingsContent = settingsFile.readAsStringSync();

        expect(
          renseikaiContent.contains('AppLifecycleListener('),
          isTrue,
          reason:
              'RenseikaiMasterTimerNotifier に AppLifecycleListener が配備されていること',
        );
        expect(
          dockContent.contains('AppLifecycleListener('),
          isTrue,
          reason: 'DockTimerNotifier に AppLifecycleListener が配備されていること',
        );
        expect(
          settingsContent.contains('AppLifecycleListener('),
          isTrue,
          reason: 'BatteryNotifier に AppLifecycleListener が配備されていること',
        );

        final ifStatePos = renseikaiContent.indexOf('if (state > 0) {');
        expect(ifStatePos, isNonNegative);
        final elsePos = renseikaiContent.indexOf('} else {', ifStatePos);
        expect(elsePos, isNonNegative);
        final stateDecrementBlock = renseikaiContent.substring(
          ifStatePos,
          elsePos,
        );
        expect(stateDecrementBlock.contains('state--;'), isTrue);
        expect(stateDecrementBlock.contains('_saveState();'), isFalse);
      },
    );

    test(
      'Rule 3: [VRR適応制御] ThermalPowerGovernor の targetFps / isVrrThrottled 規約',
      () {
        final governor = ThermalPowerGovernor();
        expect(governor.targetFps, equals(60));
        expect(governor.isVrrThrottled, isFalse);

        governor.setMode(ThermalPowerMode.ecoCooling);
        expect(governor.targetFps, equals(30));
        expect(governor.isVrrThrottled, isTrue);

        governor.setMode(ThermalPowerMode.ultraSave);
        expect(governor.targetFps, equals(15));
        expect(governor.isVrrThrottled, isTrue);
      },
    );

    test(
      'Rule 4: [タイマーコールドスリープ] match_timer_provider.dart の enterColdSleep / resumeFromColdSleep 規約',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/providers/match_timer_provider.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('void enterColdSleep()'), isTrue);
        expect(content.contains('void resumeFromColdSleep()'), isTrue);
        expect(content.contains('AppLifecycleListener'), isTrue);
      },
    );

    test(
      'Rule 5: [画像ダウンサンプリング＆StackTrace走査排除] cacheWidth / cacheHeight ＆ StackTrace走査排除規約',
      () {
        final viewsFile = File(
          'lib/features/tournament/presentation/components/program_management/program_management_content_views.dart',
        );
        expect(viewsFile.existsSync(), isTrue);
        final viewsContent = viewsFile.readAsStringSync();
        expect(viewsContent.contains('cacheWidth: 400'), isTrue);
        expect(viewsContent.contains('cacheWidth: 150'), isTrue);

        final bodyFile = File(
          'lib/features/tournament/presentation/components/program_viewer/program_viewer_image_body.dart',
        );
        expect(bodyFile.existsSync(), isTrue);
        final bodyContent = bodyFile.readAsStringSync();
        expect(
          bodyContent.contains('cacheWidth: displaySize.width.toInt()'),
          isTrue,
        );

        final bgFile = File('lib/shared/widgets/liquid_background.dart');
        expect(bgFile.existsSync(), isTrue);
        final bgContent = bgFile.readAsStringSync();
        expect(bgContent.contains('StackTrace.current.toString()'), isFalse);
        expect(bgContent.contains('RadialGradient'), isTrue);
      },
    );

    test(
      'Rule 6: [バッテリーポーリング緩和] settings_provider.dart のバッテリーポーリングが60秒に緩和されていること',
      () {
        final file = File(
          'lib/shared/presentation/providers/settings_provider.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        expect(content.contains('Duration(seconds: 60)'), isTrue);
      },
    );
  });
}
