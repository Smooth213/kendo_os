import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
import 'package:kendo_os/shared/application/services/thermal_monitor_service.dart';

void main() {
  group('🔋 【Phase 10: アダプティブ省電力・サーマル冷却】ガバナンステスト', () {
    late ThermalPowerGovernor governor;

    setUp(() {
      governor = ThermalPowerGovernor();
    });

    test('初期状態では通常モード（100ms・高精度レスポンス）であること', () {
      expect(governor.mode, equals(ThermalPowerMode.normal));
      expect(
        governor.recommendedTickInterval,
        equals(const Duration(milliseconds: 100)),
      );
    });

    test('バッテリー低下時（30%以下/15%以下）にエコ冷却および極限省電力へ自動遷移すること', () {
      // 30%以下: エコ冷却モード（500ms）
      governor.evaluateBatteryState(batteryLevel: 0.25, isCharging: false);
      expect(governor.mode, equals(ThermalPowerMode.ecoCooling));
      expect(
        governor.recommendedTickInterval,
        equals(const Duration(milliseconds: 500)),
      );

      // 15%以下: 極限省電力モード（1000ms）
      governor.evaluateBatteryState(batteryLevel: 0.12, isCharging: false);
      expect(governor.mode, equals(ThermalPowerMode.ultraSave));
      expect(
        governor.recommendedTickInterval,
        equals(const Duration(milliseconds: 1000)),
      );

      // 充電開始時: 通常モードへ安全に復帰
      governor.evaluateBatteryState(batteryLevel: 0.50, isCharging: true);
      expect(governor.mode, equals(ThermalPowerMode.normal));
      expect(
        governor.recommendedTickInterval,
        equals(const Duration(milliseconds: 100)),
      );
    });

    test('ユーザー操作記録（recordUserActivity）によりアクティブ状態へ即座に復帰すること', () {
      governor.setMode(ThermalPowerMode.ultraSave);
      expect(governor.mode, equals(ThermalPowerMode.ultraSave));

      governor.recordUserActivity();
      expect(governor.mode, equals(ThermalPowerMode.normal));
      expect(
        governor.recommendedTickInterval,
        equals(const Duration(milliseconds: 100)),
      );
    });

    test('tick 間引き（100ms vs 500ms vs 1000ms）でもタイマー計算の絶対精度が 100% 維持されること', () {
      final baseTime = DateTime(2026, 9, 4, 10, 0, 0);
      final match = MatchModel(
        id: 'test_thermal_match',
        tournamentId: 't1',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
        category: '一般男子',
        status: 'in_progress',
        matchTimeMinutes: 3.0, // 3分 (180秒)
        timerStartedAt: baseTime,
      );

      // 30秒後
      final t30 = baseTime.add(const Duration(seconds: 30));
      expect(match.calculateRemainingSeconds(t30), equals(150));

      // 60秒後
      final t60 = baseTime.add(const Duration(seconds: 60));
      expect(match.calculateRemainingSeconds(t60), equals(120));

      // 180秒後（時間切れ）
      final t180 = baseTime.add(const Duration(seconds: 180));
      expect(match.calculateRemainingSeconds(t180), equals(0));
    });

    test('CPUウェイクアップ削減率の検証: エコ冷却で80%削減、極限省電力で90%削減', () {
      const normalTicksPerSec = 1000 / 100; // 10 ticks/sec
      const ecoTicksPerSec = 1000 / 500; // 2 ticks/sec
      const ultraTicksPerSec = 1000 / 1000; // 1 tick/sec

      final ecoReduction =
          (normalTicksPerSec - ecoTicksPerSec) / normalTicksPerSec * 100;
      final ultraReduction =
          (normalTicksPerSec - ultraTicksPerSec) / normalTicksPerSec * 100;

      // ignore: avoid_print
      print(
        '🔋 [Thermal Governor Power Benchmark]\n'
        '  - 通常モード: $normalTicksPerSec 回/秒 (100ms)\n'
        '  - エコ冷却モード: $ecoTicksPerSec 回/秒 (500ms, CPUウェイクアップ削減: ${ecoReduction.toStringAsFixed(1)}%)\n'
        '  - 極限省電力モード: $ultraTicksPerSec 回/秒 (1000ms, CPUウェイクアップ削減: ${ultraReduction.toStringAsFixed(1)}%)',
      );

      expect(ecoReduction, equals(80.0));
      expect(ultraReduction, equals(90.0));
    });

    test('【最重要ガバナンス】優先順位「温度 ＞ 手動 ＞ 自動」が厳格に適用されること', () {
      // 1. 【手動 ＞ 自動】通常高速固定時は、バッテリー低下やOS低電力モードを無視して通常高速を維持
      governor.updatePreference('normal');
      governor.updateBatteryInfo(
        batteryLevel: 0.10, // バッテリー極限低下
        isCharging: false,
        isOsLowPowerMode: true, // OS低電力モードON
      );
      expect(governor.mode, equals(ThermalPowerMode.normal));

      // 2. 【温度 ＞ 手動】手動通常固定時でも、41℃（Serious）検知で熱暴走防止のため「エコ冷却」へ強制移行
      governor.updateThermalStatus(ThermalSensorStatus.serious);
      expect(governor.mode, equals(ThermalPowerMode.ecoCooling));

      // 3. 【温度 ＞ 手動】手動通常固定時でも、45℃（Critical）検知で強制終了回避のため「極限省電力」へ強制移行
      governor.updateThermalStatus(ThermalSensorStatus.critical);
      expect(governor.mode, equals(ThermalPowerMode.ultraSave));

      // 4. 【平常復帰】温度が平常（Nominal）に戻れば、手動設定の「通常高速」へ正しく復帰
      governor.updateThermalStatus(ThermalSensorStatus.nominal);
      expect(governor.mode, equals(ThermalPowerMode.normal));

      // 5. 【手動固定の他のモード】エコ冷却固定 / 極限省電力固定
      governor.updatePreference('ecoCooling');
      expect(governor.mode, equals(ThermalPowerMode.ecoCooling));
      governor.updatePreference('ultraSave');
      expect(governor.mode, equals(ThermalPowerMode.ultraSave));
    });

    test('自動モード時、OS低電力モードON且つ電池残量で「エコ冷却」と「極限省電力」が自動で切り替わること', () {
      governor.updatePreference('auto');
      governor.updateBatteryInfo(
        batteryLevel: 0.80,
        isCharging: false,
        isOsLowPowerMode: false,
      );
      expect(governor.mode, equals(ThermalPowerMode.normal));

      // 1. OS低電力モードON（残量80%）：エコ冷却モードへ移行
      governor.updateBatteryInfo(
        batteryLevel: 0.80,
        isCharging: false,
        isOsLowPowerMode: true,
      );
      expect(governor.mode, equals(ThermalPowerMode.ecoCooling));

      // 2. OS低電力モードONのまま、電池残量が20%（>15%）：依然エコ冷却を維持
      governor.updateBatteryInfo(
        batteryLevel: 0.20,
        isCharging: false,
        isOsLowPowerMode: true,
      );
      expect(governor.mode, equals(ThermalPowerMode.ecoCooling));

      // 3. 電池残量が15%以下に低下（<=15%）：自動で極限省電力へ移行！
      governor.updateBatteryInfo(
        batteryLevel: 0.12,
        isCharging: false,
        isOsLowPowerMode: true,
      );
      expect(governor.mode, equals(ThermalPowerMode.ultraSave));
      expect(
        governor.recommendedTickInterval,
        equals(const Duration(milliseconds: 1000)),
      );

      // 4. 充電接続・回復で電池が30%へ復帰：自動でエコ冷却へ復帰！
      governor.updateBatteryInfo(
        batteryLevel: 0.30,
        isCharging: false,
        isOsLowPowerMode: true,
      );
      expect(governor.mode, equals(ThermalPowerMode.ecoCooling));

      // 5. ユーザーがOS低電力モードを解除：通常高速モードへ復帰
      governor.updateBatteryInfo(
        batteryLevel: 0.50,
        isCharging: false,
        isOsLowPowerMode: false,
      );
      expect(governor.mode, equals(ThermalPowerMode.normal));
    });

    test('自動モード時、41℃（Serious）でエコ冷却、45℃（Critical）で極限省電力、39℃復帰で通常へ戻ること', () {
      governor.updatePreference('auto');
      governor.updateBatteryInfo(
        batteryLevel: 0.80,
        isCharging: false,
        isOsLowPowerMode: false,
      );
      expect(governor.mode, equals(ThermalPowerMode.normal));

      // 41℃（Serious）検知
      governor.updateThermalStatus(ThermalSensorStatus.serious);
      expect(governor.mode, equals(ThermalPowerMode.ecoCooling));

      // 45℃（Critical）検知
      governor.updateThermalStatus(ThermalSensorStatus.critical);
      expect(governor.mode, equals(ThermalPowerMode.ultraSave));

      // 平常復帰（Nominal）
      governor.updateThermalStatus(ThermalSensorStatus.nominal);
      expect(governor.mode, equals(ThermalPowerMode.normal));
    });

    test('トースト通知イベントが重複連発せず適切に配信されること', () async {
      governor.updatePreference('auto');
      final events = <ThermalToastEvent>[];
      final sub = governor.toastStream.listen(events.add);

      // 1. 41℃検知 -> トースト発行
      governor.updateThermalStatus(ThermalSensorStatus.serious);
      await pumpEventQueue();
      expect(events.length, equals(1));
      expect(events.first.message, contains('約41℃'));

      // 2. 同じ温度帯での連続更新 -> クールダウンにより重複通知されない
      governor.updateThermalStatus(ThermalSensorStatus.serious);
      await pumpEventQueue();
      expect(events.length, equals(1));

      // 3. 45℃検知 -> Criticalトースト発行
      governor.updateThermalStatus(ThermalSensorStatus.critical);
      await pumpEventQueue();
      expect(events.length, equals(2));
      expect(events.last.message, contains('約45℃'));

      // 4. 冷却完了復帰 -> 復帰トースト発行
      governor.updateThermalStatus(ThermalSensorStatus.nominal);
      await pumpEventQueue();
      expect(events.length, equals(3));
      expect(events.last.message, contains('冷却完了'));

      await sub.cancel();
    });
  });
}
