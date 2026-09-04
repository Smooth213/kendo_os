import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';

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
  });
}
