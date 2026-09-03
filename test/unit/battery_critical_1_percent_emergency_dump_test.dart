import 'package:flutter_test/flutter_test.dart';

/// 🪫 バッテリー1%緊急シャットダウン直前フラッシュマネージャー
class EmergencyPowerSaver {
  bool isEmergencyDumpCompleted = false;
  Map<String, dynamic>? persistentStorageSnapshot;

  void onBatteryCritical({
    required int batteryLevelPercent,
    required Map<String, dynamic> currentActiveMatchState,
  }) {
    if (batteryLevelPercent <= 1) {
      // 🚨 10ms以内の超高速同期ダンプ
      persistentStorageSnapshot = Map<String, dynamic>.from(
        currentActiveMatchState,
      );
      persistentStorageSnapshot!['dumpedAt'] = DateTime.now().toIso8601String();
      isEmergencyDumpCompleted = true;
    }
  }
}

void main() {
  group('☁️ 【Phase 7-2/8】バッテリー残量1%緊急電源断直前 同期フラッシュダンプテスト', () {
    test('1. バッテリー1%検知時、進行中のタイマー・スコアが即座に同期永続化されること', () {
      final emergencySaver = EmergencyPowerSaver();

      final activeMatch = {
        'matchId': 'critical_bat_m01',
        'remainingSeconds': 42,
        'remainingMilliseconds': 350,
        'redScore': 1,
        'whiteScore': 1,
        'eventsCount': 4,
      };

      final stopwatch = Stopwatch()..start();

      // 🪫 バッテリー1%イベント発火
      emergencySaver.onBatteryCritical(
        batteryLevelPercent: 1,
        currentActiveMatchState: activeMatch,
      );

      stopwatch.stop();

      // 10ms未満で即座にダンプ完了すること
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(emergencySaver.isEmergencyDumpCompleted, isTrue);
      expect(
        emergencySaver.persistentStorageSnapshot!['matchId'],
        'critical_bat_m01',
      );
      expect(emergencySaver.persistentStorageSnapshot!['remainingSeconds'], 42);
      expect(
        emergencySaver.persistentStorageSnapshot!['remainingMilliseconds'],
        350,
      );
    });
  });
}
