import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import '../helpers/test_match_factory.dart';

void main() {
  group('🌪️ Phase 7: シミュレーションテスト (同時操作・競合の検証)', () {
    
    test('【Phase 7-2: 衝突解消検証】オフライン中の異なる入力が、同期後に正しくマージされ結果整合性が保たれること', () async {
      // 1. 準備
      final rule = const MatchRule(ipponLimit: 2, matchTimeMinutes: 3.0);
      final initialMatch = TestMatchFactory.createIndividualMatch(id: 'sim-match-1');
      
      // ★ 修正: organizationId の必須エラーを解消
      final userA = const User(id: 'user_A', role: Role.scorer, organizationId: 'org1');
      final userB = const User(id: 'user_B', role: Role.scorer, organizationId: 'org1');

      // 2. AさんとBさんが同時に（オフラインで）異なる技を入力
      // A: 赤メン (時刻T1, 論理時計1)
      final eventA = ScoreEventLegacyAdapter.fromLegacy(
        side: Side.red, type: PointType.men, userId: userA.id, sequence: 1,
      ).copyWith(timestamp: DateTime(2026, 5, 1, 10, 0, 0), logicalClock: 1);

      // B: 白コテ (時刻T2, 論理時計1) ※Bの方がわずかに遅い
      final eventB = ScoreEventLegacyAdapter.fromLegacy(
        side: Side.white, type: PointType.kote, userId: userB.id, sequence: 1,
      ).copyWith(timestamp: DateTime(2026, 5, 1, 10, 0, 1), logicalClock: 1);

      // 3. サーバー側（Firestore）の歴史をエミュレート
      // サーバーには A さんの「赤メン」が先に届いたとする
      final serverState = initialMatch.copyWith(
        events: [eventA],
        redScore: 1,
        version: 1,
      );

      // 4. B さんがオンラインになり、自分の「白コテ」を同期しようとする
      // SyncEngine の CRDT ロジックを模倣: 歴史を統合してソート
      final Map<String, ScoreEvent> mergedEventsMap = {};
      for (var e in serverState.events) { mergedEventsMap[e.id] = e; }
      mergedEventsMap[eventB.id] = eventB; // Bさんの未送信イベントを追記

      final mergedEvents = mergedEventsMap.values.toList()
        ..sort((a, b) {
          if (a.logicalClock != b.logicalClock) return a.logicalClock.compareTo(b.logicalClock);
          return a.timestamp.compareTo(b.timestamp);
        });

      // 5. ルールエンジンで再構築
      // ★ 修正: isMatchFinished プロパティの代わりに、規定本数(ipponLimit)との比較で終了判定を行う
      final analysis = KendoRuleEngine().analyzeHistory(mergedEvents, initialMatch, rule);
      final isFinished = analysis.context.redIppon >= rule.ipponLimit || analysis.context.whiteIppon >= rule.ipponLimit;
      
      final rebuiltMatch = initialMatch.copyWith(
        events: mergedEvents,
        redScore: analysis.context.redIppon,
        whiteScore: analysis.context.whiteIppon,
        status: isFinished ? 'finished' : 'in_progress',
      );

      // 6. 検証: 二人の入力が「赤メン -> 白コテ」の順で並び、スコアが 1-1 になっていること
      expect(rebuiltMatch.events.length, 2);
      expect(rebuiltMatch.events[0].side, Side.red, reason: '時刻が早いAさんのメンが先');
      expect(rebuiltMatch.events[1].side, Side.white, reason: '時刻が遅いBさんのコテが次');
      expect(rebuiltMatch.redScore, 1);
      expect(rebuiltMatch.whiteScore, 1);
      expect(rebuiltMatch.status, 'in_progress', reason: '1-1なので試合は続行');
    });
  });
}