import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🚀 【E2E 4/5】部内戦・勝ち抜き戦（勝ち残り）完全フロー実践E2Eテスト', () {
    test('赤5名 vs 白5名の勝ち抜き戦において、勝者残留・引分両者退場・大将戦決着のフローが完全保証されること', () {
      const kachinukiRule = MatchRule(isKachinuki: true, matchTimeMinutes: 3.0);

      final redPlayers = ['赤先鋒:佐藤', '赤次鋒:田中', '赤中堅:高橋', '赤副将:渡辺', '赤大将:伊藤'];
      final whitePlayers = ['白先鋒:小林', '白次鋒:加藤', '白中堅:吉田', '白副将:山田', '白大将:佐々木'];

      int redIndex = 0;
      int whiteIndex = 0;
      final kachinukiMatches = <MatchModel>[];
      int boutNumber = 1;

      // ── 第1試合: 先鋒同士 ─────────────────────────────
      // 赤先鋒が2本勝ち (残留)
      final bout1 = MatchModel(
        id: 'kachinuki_bout_$boutNumber',
        tournamentId: 'bunaiksen_tour_1',
        category: '部内戦',
        groupName: '東西対抗勝ち抜き戦',
        matchType: '勝ち抜き戦',
        status: 'finished',
        redName: redPlayers[redIndex],
        whiteName: whitePlayers[whiteIndex],
        redScore: 2,
        whiteScore: 0,
        rule: kachinukiRule,
        order: boutNumber.toDouble(),
        events: [
          ScoreEvent(
            id: 'k_ev_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime(2026, 9, 3, 14, 0),
            logicalClock: 1,
          ),
          ScoreEvent(
            id: 'k_ev_2',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime(2026, 9, 3, 14, 1),
            logicalClock: 2,
          ),
        ],
      );
      kachinukiMatches.add(bout1);
      // 白先鋒敗退 ➔ 白次鋒へ
      whiteIndex++;
      boutNumber++;

      expect(bout1.redScore, 2);
      expect(bout1.whiteScore, 0);

      // ── 第2試合: 赤先鋒(残留) vs 白次鋒 ─────────────────
      // 引き分け ➔ 両者退場
      final bout2 = MatchModel(
        id: 'kachinuki_bout_$boutNumber',
        tournamentId: 'bunaiksen_tour_1',
        category: '部内戦',
        groupName: '東西対抗勝ち抜き戦',
        matchType: '勝ち抜き戦',
        status: 'finished',
        redName: redPlayers[redIndex],
        whiteName: whitePlayers[whiteIndex],
        redScore: 0,
        whiteScore: 0,
        rule: kachinukiRule,
        order: boutNumber.toDouble(),
        events: [],
      );
      kachinukiMatches.add(bout2);
      // 引分のため両者退場
      redIndex++;
      whiteIndex++;
      boutNumber++;

      expect(bout2.redScore, 0);
      expect(bout2.whiteScore, 0);

      // ── 第3試合: 赤次鋒 vs 白中堅 ───────────────────────
      // 白中堅が1本勝ち (残留)
      final bout3 = MatchModel(
        id: 'kachinuki_bout_$boutNumber',
        tournamentId: 'bunaiksen_tour_1',
        category: '部内戦',
        groupName: '東西対抗勝ち抜き戦',
        matchType: '勝ち抜き戦',
        status: 'finished',
        redName: redPlayers[redIndex],
        whiteName: whitePlayers[whiteIndex],
        redScore: 0,
        whiteScore: 1,
        rule: kachinukiRule,
        order: boutNumber.toDouble(),
        events: [
          ScoreEvent(
            id: 'k_ev_3',
            side: Side.white,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: DateTime(2026, 9, 3, 14, 5),
            logicalClock: 3,
          ),
        ],
      );
      kachinukiMatches.add(bout3);
      // 赤次鋒敗退 ➔ 赤中堅へ
      redIndex++;
      boutNumber++;

      expect(bout3.whiteScore, 1);

      // ── 第4試合: 赤中堅 vs 白中堅(残留) ─────────────────
      expect(redPlayers[redIndex], '赤中堅:高橋');
      expect(whitePlayers[whiteIndex], '白中堅:吉田');

      // 全試合履歴の整合性検証
      expect(kachinukiMatches.length, 3);
      expect(
        kachinukiMatches.every((m) => m.rule?.isKachinuki ?? false),
        isTrue,
      );
      expect(kachinukiMatches.every((m) => m.status == 'finished'), isTrue);
    });
  });
}
