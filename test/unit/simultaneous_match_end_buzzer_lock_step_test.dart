import 'package:flutter_test/flutter_test.dart';

/// 🔊 複数コート同時ブザー鳴動スタガードマネージャー
class MultiCourtBuzzerScheduler {
  /// 複数コートの終了イベントを音割れ・位相打ち消し防止のため20ms間隔でスケジュール
  static List<({int court, int scheduledDelayMs})> scheduleBuzzers(
    List<int> courtNumbers,
  ) {
    final schedule = <({int court, int scheduledDelayMs})>[];
    for (int i = 0; i < courtNumbers.length; i++) {
      schedule.add((
        court: courtNumbers[i],
        scheduledDelayMs: i * 20, // 20ms スタガード
      ));
    }
    return schedule;
  }
}

void main() {
  group('☁️ 【Phase 7-7/8】全8コート一斉終了ブザー 音割れ・位相反転防止スタガード制御テスト', () {
    test('1. 8コート同時に試合終了時、0ms、20ms、40ms...と微小遅延配置され音割れが防止されること', () {
      final courts = [1, 2, 3, 4, 5, 6, 7, 8];
      final schedule = MultiCourtBuzzerScheduler.scheduleBuzzers(courts);

      expect(schedule.length, 8);
      for (int i = 0; i < 8; i++) {
        expect(schedule[i].court, i + 1);
        expect(schedule[i].scheduledDelayMs, i * 20);
      }

      // 最大遅延も 140ms（人間の耳にはほぼ同時だが、DSP波形としては位相重なり回避）
      expect(schedule.last.scheduledDelayMs, 140);
    });
  });
}
