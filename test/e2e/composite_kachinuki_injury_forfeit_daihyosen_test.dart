import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('[E2E] 勝ち抜き戦 途中選手負傷不戦勝 ＆ 大将戦もつれこみ代表戦複合耐性テスト', () {
    test('勝ち抜き戦途中の負傷棄権・不戦勝処理から大将引き分け代表戦決着まで全ライフサイクルが破綻なく完結すること', () async {
      final engine = KendoRuleEngine();
      final baseTime = DateTime(2026, 10, 15, 10, 0, 0);

      const kachinukiRule = MatchRule(
        isKachinuki: true,
        matchTimeMinutes: 3,
        ipponLimit: 2,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        kachinukiUnlimitedType: '大将引き分け延長',
      );

      final redRoster = ['赤井(先鋒)', '赤木(次鋒)', '赤松(中堅)', '赤星(副将)', '赤羽(大将)'];
      final whiteRoster = ['白石(先鋒)', '白川(次鋒)', '白鳥(中堅)', '白木(副将)', '白峰(大将)'];

      // ── 第1戦: 赤先鋒 vs 白先鋒 ──
      // 赤先鋒が面・小手で白先鋒に二本勝ち
      final match1 = MatchModel(
        id: 'bout_kachi_injury_1',
        tournamentId: 't_kachinuki_chaos',
        groupName: '男子団体勝ち抜き戦',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redName: '道上剣友会: ${redRoster[0]}',
        whiteName: '修道館: ${whiteRoster[0]}',
        redRemaining: redRoster.sublist(1).map((n) => '道上剣友会: $n').toList(),
        whiteRemaining: whiteRoster.sublist(1).map((n) => '修道館: $n').toList(),
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
        rule: kachinukiRule,
        events: [
          ScoreEvent(
            id: 'ev_k1_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: baseTime.add(const Duration(seconds: 30)),
            sequence: 1,
            logicalClock: 1,
          ),
          ScoreEvent(
            id: 'ev_k1_2',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: baseTime.add(const Duration(seconds: 90)),
            sequence: 2,
            logicalClock: 2,
          ),
        ],
      );

      final analysis1 = engine.analyzeHistory(
        match1.events,
        match1,
        kachinukiRule,
      );
      expect(analysis1.context.redIppon, equals(2));

      // ── 第2戦: 赤先鋒（勝ち残り） vs 白次鋒 ──
      // ここで赤先鋒がアキレス腱負傷により急遽棄権（Retirement）➔ 白次鋒の不戦勝（Fusen）
      final match2 = MatchModel(
        id: 'bout_kachi_injury_2',
        tournamentId: 't_kachinuki_chaos',
        groupName: '男子団体勝ち抜き戦',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redName: '道上剣友会: ${redRoster[0]}',
        whiteName: '修道館: ${whiteRoster[1]}',
        redRemaining: redRoster.sublist(1).map((n) => '道上剣友会: $n').toList(),
        whiteRemaining: whiteRoster.sublist(2).map((n) => '修道館: $n').toList(),
        status: 'finished',
        redScore: 0,
        whiteScore: 2,
        note: '赤先鋒負傷棄権による白次鋒不戦勝',
        rule: kachinukiRule,
        events: [
          ScoreEvent(
            id: 'ev_k2_retire',
            side: Side.red,
            isRetirement: true,
            timestamp: baseTime.add(const Duration(minutes: 5)),
            sequence: 1,
            logicalClock: 1,
          ),
          ScoreEvent(
            id: 'ev_k2_fusen',
            side: Side.white,
            isFusen: true,
            isIppon: true,
            timestamp: baseTime.add(const Duration(minutes: 5)),
            sequence: 2,
            logicalClock: 2,
          ),
        ],
      );

      final analysis2 = engine.analyzeHistory(
        match2.events,
        match2,
        kachinukiRule,
      );
      expect(analysis2.displays[Side.white]?.any((d) => d.mark == '◯'), isTrue);

      // ── 中間戦を経て大将戦へもつれこみ ──
      // 赤大将 vs 白大将 の対戦。本戦3分間でスコア 0-0 引き分け
      final matchDaisho = MatchModel(
        id: 'bout_kachi_injury_daisho',
        tournamentId: 't_kachinuki_chaos',
        groupName: '男子団体勝ち抜き戦',
        matchType: '大将戦',
        isKachinuki: true,
        redName: '道上剣友会: ${redRoster[4]}',
        whiteName: '修道館: ${whiteRoster[4]}',
        redRemaining: const [],
        whiteRemaining: const [],
        status: 'finished',
        redScore: 0,
        whiteScore: 0,
        rule: kachinukiRule,
        events: const [],
      );

      final daishoAnalysis = engine.analyzeHistory(
        matchDaisho.events,
        matchDaisho,
        kachinukiRule,
      );
      expect(daishoAnalysis.context.redIppon, equals(0));
      expect(daishoAnalysis.context.whiteIppon, equals(0));

      // ── 代表決定戦（時間無制限1本勝負） ──
      // 大将引き分けにより代表戦を発動
      const daihyoRule = MatchRule(
        isIpponShobu: true,
        ipponLimit: 1,
        matchTimeMinutes: 0,
      );

      final matchDaihyo = MatchModel(
        id: 'bout_kachi_injury_daihyo_final',
        tournamentId: 't_kachinuki_chaos',
        groupName: '男子団体勝ち抜き戦',
        matchType: '代表戦',
        redName: '道上剣友会: ${redRoster[4]}(代表)',
        whiteName: '修道館: ${whiteRoster[4]}(代表)',
        status: 'finished',
        redScore: 1,
        whiteScore: 0,
        rule: daihyoRule,
        events: [
          ScoreEvent(
            id: 'ev_daihyo_decisive_men',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: baseTime.add(const Duration(minutes: 25)),
            sequence: 1,
            logicalClock: 1,
          ),
        ],
      );

      final daihyoAnalysis = engine.analyzeHistory(
        matchDaihyo.events,
        matchDaihyo,
        daihyoRule,
      );

      // 代表戦で赤が面を取得し、完全決着していること
      expect(daihyoAnalysis.context.redIppon, equals(1));
      expect(daihyoAnalysis.context.whiteIppon, equals(0));
      expect(daihyoAnalysis.displays[Side.red]?.first.mark, equals('メ'));
    });
  });
}
