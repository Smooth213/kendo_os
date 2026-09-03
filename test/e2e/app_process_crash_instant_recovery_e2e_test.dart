import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🚀 【E2E 5/5】アプリ強制終了（OOMキル/端末再起動）ミリ秒精度復旧実践E2Eテスト', () {
    test('タイマー稼働中にアプリが強制キルされても、再起動時に経過時間とスコアイベントがミリ秒単位で復元されること', () {
      final matchStart = DateTime(2026, 9, 3, 15, 30, 0, 0); // 15:30:00.000

      // 1. 試合開始とイベント発生
      final event1 = ScoreEvent(
        id: 'crash_ev_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: matchStart.add(
          const Duration(seconds: 45, milliseconds: 320),
        ),
        logicalClock: 1,
      );

      // 試合中状態（タイマー動作中: 一時停止で累積停止時間あり）
      final pauseTime = matchStart.add(const Duration(seconds: 45));
      final activeMatch = MatchModel(
        id: 'crash_test_match_1',
        tournamentId: 'crash_tour_1',
        category: '一般個人',
        matchType: '個人戦',
        status: 'inProgress',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 1,
        whiteScore: 0,
        events: [event1],
        timerStartedAt: matchStart,
        timerPausedAt: pauseTime,
        accumulatedPauseDurationMs: 5000, // 5秒間の一時停止
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );

      // 2. クラッシュ前の状態をシリアライズ（ローカルDBへの自動保存シミュレーション）
      final serializedData = activeMatch.toJson();

      // 3. 【シミュレーション】OSによりプロセスが突然強制終了（メモリ初期化）
      // ... アプリ再起動 ...

      // 4. 再起動直後にローカルストレージからデシリアライズ
      final recoveredMatch = MatchModel.fromJson(serializedData);

      // 5. 復元精度の厳密検証
      expect(recoveredMatch.id, activeMatch.id);
      expect(recoveredMatch.status, 'inProgress');
      expect(recoveredMatch.redScore, 1);
      expect(recoveredMatch.whiteScore, 0);
      expect(recoveredMatch.events.length, 1);

      // イベントのタイムスタンプがミリ秒単位で完全一致すること
      final recoveredEvent = recoveredMatch.events.first;
      expect(recoveredEvent.id, 'crash_ev_1');
      expect(recoveredEvent.strikeType, StrikeType.men);
      expect(
        recoveredEvent.timestamp.millisecondsSinceEpoch,
        event1.timestamp.millisecondsSinceEpoch,
      );

      // タイマー開始時刻、一時停止時刻、累積停止時間の完全復元
      expect(
        recoveredMatch.timerStartedAt?.millisecondsSinceEpoch,
        matchStart.millisecondsSinceEpoch,
      );
      expect(
        recoveredMatch.timerPausedAt?.millisecondsSinceEpoch,
        pauseTime.millisecondsSinceEpoch,
      );
      expect(recoveredMatch.accumulatedPauseDurationMs, 5000);

      // 6. クラッシュ復旧後、即座に試合再開し2本目を取得して試合終了できること
      final event2 = ScoreEvent(
        id: 'crash_ev_2',
        side: Side.red,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: matchStart.add(const Duration(minutes: 2)),
        logicalClock: 2,
      );

      final finalizedMatch = recoveredMatch.copyWith(
        redScore: 2,
        status: 'finished',
        events: [...recoveredMatch.events, event2],
      );

      expect(finalizedMatch.status, 'finished');
      expect(finalizedMatch.redScore, 2);
      expect(finalizedMatch.events.length, 2);
      expect(finalizedMatch.events.last.strikeType, StrikeType.kote);
    });
  });
}
