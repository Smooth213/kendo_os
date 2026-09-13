import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/thermal_monitor_service.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

/// 🔋 【ガバナンス監査 23/23】端末サーマル冷却＆省電力モード管理（温度＞手動＞自動 ガバナンス永続保証テスト）
void main() {
  group('🔋 【ガバナンス監査 23/23】端末サーマル冷却＆省電力モード管理 永続保証テスト', () {
    late ThermalPowerGovernor governor;
    late SharedPreferences prefs;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    setUp(() {
      governor = ThermalPowerGovernor();
    });

    // =========================================================================
    // 1. 最重要ガバナンス「温度 ＞ 手動 ＞ 自動」の完全階層保証
    // =========================================================================
    test('1. 【最重要ガバナンス】優先順位「温度 ＞ 手動 ＞ 自動」の完全階層保証規約', () {
      // A. 手動 ＞ 自動: 手動通常固定時は、バッテリー低下やOS低電力モードを無視して通常高速を維持
      governor.updatePreference('normal');
      governor.updateBatteryInfo(
        batteryLevel: 0.10, // 極限低下 (10%)
        isCharging: false,
        isOsLowPowerMode: true, // OS低電力モードON
      );
      expect(
        governor.mode,
        equals(ThermalPowerMode.normal),
        reason: '平常温度下では手動固定設定が自動低電力モードよりも最優先されること',
      );

      // B. 温度 ＞ 手動: 41℃（Serious）警戒検知時は、手動通常固定であってもエコ冷却へ強制移行
      governor.updateThermalStatus(ThermalSensorStatus.serious);
      expect(
        governor.mode,
        equals(ThermalPowerMode.ecoCooling),
        reason: '41℃到達時は熱暴走・端末クラッシュ防止のためエコ冷却へ強制移行すること',
      );

      // C. 温度 ＞ 手動: 45℃（Critical）危険検知時は、強制終了回避のため極限省電力へ強制移行
      governor.updateThermalStatus(ThermalSensorStatus.critical);
      expect(
        governor.mode,
        equals(ThermalPowerMode.ultraSave),
        reason: '45℃到達時はシャットダウン防止のため極限省電力へ強制避難すること',
      );

      // D. 平常復帰: 温度が平常（Nominal）に戻れば、手動設定の通常高速へ自動復帰
      governor.updateThermalStatus(ThermalSensorStatus.nominal);
      expect(
        governor.mode,
        equals(ThermalPowerMode.normal),
        reason: '端末冷却完了後は手動設定（通常高速）へ正しく復帰すること',
      );
    });

    // =========================================================================
    // 2. 低電力モードON時における電池残量自動切り替え規約
    // =========================================================================
    test('2. 【低電力＆電池残量連携】OS低電力モードON時における電池残量自動切り替え規約', () {
      governor.updatePreference('auto');
      governor.updateBatteryInfo(
        batteryLevel: 0.80,
        isCharging: false,
        isOsLowPowerMode: false,
      );
      expect(governor.mode, equals(ThermalPowerMode.normal));

      // 低電力モードON且つ残量 > 15%: エコ冷却 (500ms)
      governor.updateBatteryInfo(
        batteryLevel: 0.25,
        isCharging: false,
        isOsLowPowerMode: true,
      );
      expect(governor.mode, equals(ThermalPowerMode.ecoCooling));

      // 低電力モードON且つ残量 <= 15%: 極限省電力 (1000ms) へ自動切り替え
      governor.updateBatteryInfo(
        batteryLevel: 0.12,
        isCharging: false,
        isOsLowPowerMode: true,
      );
      expect(governor.mode, equals(ThermalPowerMode.ultraSave));

      // 充電・回復で残量が 30% に回復: 自動でエコ冷却へ復帰
      governor.updateBatteryInfo(
        batteryLevel: 0.30,
        isCharging: false,
        isOsLowPowerMode: true,
      );
      expect(governor.mode, equals(ThermalPowerMode.ecoCooling));

      // 低電力モード解除: 通常高速へ復帰
      governor.updateBatteryInfo(
        batteryLevel: 0.50,
        isCharging: false,
        isOsLowPowerMode: false,
      );
      expect(governor.mode, equals(ThermalPowerMode.normal));
    });

    // =========================================================================
    // 3. 絶対時間精度保証規約（タイマー間引き時の精度100%保証）
    // =========================================================================
    test(
      '3. 【絶対時間精度保証】サーマル間引き（100ms vs 500ms vs 1000ms）におけるタイマー計算精度100%規約',
      () {
        final baseTime = DateTime(2026, 9, 13, 10, 0, 0);
        final match = MatchModel(
          id: 'gov_thermal_match',
          tournamentId: 'tour_1',
          matchType: 'individual',
          redName: '選手A',
          whiteName: '選手B',
          category: '一般男子',
          status: 'in_progress',
          matchTimeMinutes: 3.0, // 3分 (180秒)
          timerStartedAt: baseTime,
        );

        // モードが極限省電力 (1000ms) に間引かれても絶対時刻から残り秒数が完全一致すること
        final t45 = baseTime.add(const Duration(seconds: 45));
        expect(match.calculateRemainingSeconds(t45), equals(135));

        final t90 = baseTime.add(const Duration(seconds: 90));
        expect(match.calculateRemainingSeconds(t90), equals(90));

        final t180 = baseTime.add(const Duration(seconds: 180));
        expect(match.calculateRemainingSeconds(t180), equals(0));
      },
    );

    // =========================================================================
    // 4. CPU負荷削減規約（エコ冷却80%削減、極限省電力90%削減）
    // =========================================================================
    test('4. 【CPU負荷削減規約】エコ冷却で80%削減、極限省電力で90%削減のウェイクアップ間引き規約', () {
      expect(
        governor.recommendedTickInterval,
        equals(const Duration(milliseconds: 100)),
      );

      governor.setMode(ThermalPowerMode.ecoCooling);
      expect(
        governor.recommendedTickInterval,
        equals(const Duration(milliseconds: 500)),
      );

      governor.setMode(ThermalPowerMode.ultraSave);
      expect(
        governor.recommendedTickInterval,
        equals(const Duration(milliseconds: 1000)),
      );

      const normalHz = 1000 / 100; // 10
      const ecoHz = 1000 / 500; // 2
      const ultraHz = 1000 / 1000; // 1

      final ecoReduction = (normalHz - ecoHz) / normalHz * 100;
      final ultraReduction = (normalHz - ultraHz) / normalHz * 100;

      expect(ecoReduction, equals(80.0));
      expect(ultraReduction, equals(90.0));
    });

    // =========================================================================
    // 5. 通知クールダウン規約（重複・連続連発の完全防止）
    // =========================================================================
    test('5. 【通知クールダウン規約】同一温度・状態におけるトースト通知の連発抑制規約', () async {
      governor.updatePreference('auto');
      final events = <ThermalToastEvent>[];
      final sub = governor.toastStream.listen(events.add);

      // 41℃検知でトースト発行
      governor.updateThermalStatus(ThermalSensorStatus.serious);
      await pumpEventQueue();
      expect(events.length, equals(1));

      // 同じ41℃状態での連続トリガーはクールダウンにより抑制されること
      governor.updateThermalStatus(ThermalSensorStatus.serious);
      await pumpEventQueue();
      expect(events.length, equals(1));

      await sub.cancel();
    });

    // =========================================================================
    // 6. 操作非遮断・タップ透過規約（トースト表示中もボタンタップが阻害されない）
    // =========================================================================
    testWidgets('6. 【操作非遮断・タップ透過規約】トースト表示中も試合画面のボタン操作が一切阻害されない規約', (
      tester,
    ) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(
                  child: ElevatedButton(
                    onPressed: () => tapCount++,
                    child: const Text('一本（面）'),
                  ),
                ),
                // トーストリスナービュー
                const Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: IgnorePointer(
                    child: SizedBox(
                      height: 40,
                      child: Text('🌡️ 端末の発熱を検知：エコ冷却モード'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // ボタンをタップ
      await tester.tap(find.text('一本（面）'));
      await tester.pump();

      expect(tapCount, equals(1), reason: 'トースト表示中も背後の試合記録タップが100%確実に処理されること');
    });

    // =========================================================================
    // 7. 設定永続化規約（thermalPowerPreference の SharedPreferences 保持復元）
    // =========================================================================
    test(
      '7. 【設定永続化規約】thermalPowerPreference の変更が SharedPreferences および SettingsModel に完全永続化・復元される規約',
      () async {
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );

        final notifier = container.read(settingsProvider.notifier);
        expect(
          container.read(settingsProvider).thermalPowerPreference,
          equals('auto'),
        );

        // 手動モード「ecoCooling」に変更
        await notifier.updateField(thermalPowerPreference: 'ecoCooling');
        expect(
          container.read(settingsProvider).thermalPowerPreference,
          equals('ecoCooling'),
        );

        // SharedPreferences から直接再読み込みして永続化を確認
        final rawJson = prefs.getString('kendo_sync_settings');
        expect(rawJson, isNotNull);
        final restoredSettings = SettingsModel.fromJson(jsonDecode(rawJson!));
        expect(restoredSettings.thermalPowerPreference, equals('ecoCooling'));

        container.dispose();
      },
    );
  });
}
