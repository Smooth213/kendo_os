import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_battle_card_helper.dart';

void main() {
  group('[E2E] 勝ち抜き戦 5人抜き全勝スイープ ＆ 大将引き分け代表戦 フルライフサイクル検証', () {
    late MatchDomainService domainService;
    late KendoRuleEngine ruleEngine;
    final now = DateTime(2026, 9, 27, 10, 0, 0);

    setUp(() {
      domainService = MatchDomainService();
      ruleEngine = KendoRuleEngine();
    });

    test('全勝スイープE2Eに関して、先鋒1名による5人抜き達成・連勝バッジ・公式記録投影ライフサイクルこと', () {
      const rule = MatchRule(
        isKachinuki: true,
        matchTimeMinutes: 3.0,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        kachinukiUnlimitedType: '大将引き分け延長',
      );

      final redTeam = '誠道館A';
      final whiteTeam = '修道館B';

      final redRoster = ['先鋒:赤井', '次鋒:赤木', '中堅:赤松', '副将:赤星', '大将:赤羽'];
      final whiteRoster = ['先鋒:白石', '次鋒:白川', '中堅:白鳥', '副将:白木', '大将:白峰'];

      final matches = <MatchModel>[];

      // ── 第1戦: 赤先鋒 vs 白先鋒 ──
      var currentMatch = MatchModel(
        id: 'bout_sweep_1',
        tournamentId: 't_sweep_e2e',
        groupName: '高校男子勝ち抜き戦',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redName: '$redTeam : ${redRoster[0]}',
        whiteName: '$whiteTeam : ${whiteRoster[0]}',
        redRemaining: redRoster.sublist(1).map((n) => '$redTeam : $n').toList(),
        whiteRemaining: whiteRoster
            .sublist(1)
            .map((n) => '$whiteTeam : $n')
            .toList(),
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
        order: 1.0,
        events: [
          ScoreEvent(
            id: 'ev_s1_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'ev_s1_2',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 40)),
          ),
        ],
      );
      matches.add(currentMatch);

      // 2戦目〜5戦目をループで進行（赤先鋒が全勝）
      for (int i = 1; i < 5; i++) {
        final next = domainService.generateNextKachinukiMatch(
          currentMatch,
          rule,
        );
        expect(next, isNotNull);
        expect(next!.redName, '$redTeam : ${redRoster[0]}', reason: '勝者先鋒が残留');
        expect(
          next.whiteName,
          '$whiteTeam : ${whiteRoster[i]}',
          reason: '白の次の選手が出場',
        );

        final finishedBout = next.copyWith(
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev_s${i + 1}_1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: now.add(Duration(minutes: i * 5)),
            ),
            ScoreEvent(
              id: 'ev_s${i + 1}_2',
              side: Side.red,
              strikeType: StrikeType.dou,
              isIppon: true,
              timestamp: now.add(Duration(minutes: i * 5, seconds: 30)),
            ),
          ],
        );
        matches.add(finishedBout);
        currentMatch = finishedBout;

        // 連勝人数の検証
        final currentStreak = i + 1;
        // 連勝バッジウィジェットの生成検証
        final badge = KachinukiBattleCardHelper.buildStreakBadge(
          isWin: true,
          isStreaking: false,
          streak: currentStreak,
          isDark: false,
        );
        expect(badge, isNotNull, reason: '2人抜き以上で連勝バッジが正常生成されること');
      }

      // 第5戦（白大将戦）終了時点のグループ状況判定
      expect(matches.length, equals(5));
      final groupStatus = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        currentMatch,
        rule,
        null,
      );
      expect(groupStatus.isAllDone, isTrue, reason: '白チーム5名全員敗退で完全決着');
      expect(groupStatus.isTie, isFalse);

      // さらに次試合生成は null
      final nextMatch = domainService.generateNextKachinukiMatch(
        currentMatch,
        rule,
      );
      expect(nextMatch, isNull);

      // 公式記録投影の検証: 全5試合の赤合計取得本数は 10本、失点 0本
      final totalRedPts = matches.fold<int>(0, (sum, m) => sum + m.redScore);
      final totalWhitePts = matches.fold<int>(
        0,
        (sum, m) => sum + m.whiteScore,
      );
      expect(totalRedPts, equals(10));
      expect(totalWhitePts, equals(0));
    });

    test('大将延長代表戦E2Eに関して、先鋒〜副将相引き分け→大将戦相引き分け→大将延長戦完全決着ライフサイクルこと', () {
      const rule = MatchRule(
        isKachinuki: true,
        matchTimeMinutes: 3.0,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        kachinukiUnlimitedType: '大将引き分け延長',
      );

      final redTeam = '玄武館';
      final whiteTeam = '白虎会';

      final redRoster = ['先鋒:赤井', '次鋒:赤木', '中堅:赤松', '副将:赤星', '大将:赤羽'];
      final whiteRoster = ['先鋒:白石', '次鋒:白川', '中堅:白鳥', '副将:白木', '大将:白峰'];

      final matches = <MatchModel>[];

      // ── 第1戦: 先鋒同士（0-0 引き分け） ──
      var currentMatch = MatchModel(
        id: 'bout_draw_e2e_1',
        tournamentId: 't_draw_e2e',
        groupName: '全日本東西対抗',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redName: '$redTeam : ${redRoster[0]}',
        whiteName: '$whiteTeam : ${whiteRoster[0]}',
        redRemaining: redRoster.sublist(1).map((n) => '$redTeam : $n').toList(),
        whiteRemaining: whiteRoster
            .sublist(1)
            .map((n) => '$whiteTeam : $n')
            .toList(),
        status: 'finished',
        redScore: 0,
        whiteScore: 0,
        order: 1.0,
      );
      matches.add(currentMatch);

      // ── 第2戦〜第4戦（次鋒、中堅、副将）もすべて 0-0 相引き分けで両者退場 ──
      for (int i = 1; i <= 3; i++) {
        final next = domainService.generateNextKachinukiMatch(
          currentMatch,
          rule,
        );
        expect(next, isNotNull);
        expect(next!.redName, '$redTeam : ${redRoster[i]}');
        expect(next.whiteName, '$whiteTeam : ${whiteRoster[i]}');

        final finishedBout = next.copyWith(
          redScore: 0,
          whiteScore: 0,
          status: 'finished',
        );
        matches.add(finishedBout);
        currentMatch = finishedBout;
      }

      // ── 第5戦（大将同士）の生成 ──
      final taishoBout = domainService.generateNextKachinukiMatch(
        currentMatch,
        rule,
      );
      expect(taishoBout, isNotNull);
      expect(taishoBout!.redName, '$redTeam : ${redRoster[4]}');
      expect(taishoBout.whiteName, '$whiteTeam : ${whiteRoster[4]}');
      expect(taishoBout.redRemaining, isEmpty);
      expect(taishoBout.whiteRemaining, isEmpty);

      // 大将戦も本戦 0-0 で時間切れ引き分け
      final finishedTaishoBout = taishoBout.copyWith(
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
      );
      matches.add(finishedTaishoBout);

      // ── 第6戦（大将延長戦・代表戦一本勝負）の自動生成 ──
      final enchoBout = domainService.generateNextKachinukiMatch(
        finishedTaishoBout,
        rule,
      );
      expect(enchoBout, isNotNull);
      expect(enchoBout!.matchType, '大将延長戦');
      expect(enchoBout.note, '延長戦（1本勝負）');
      expect(enchoBout.redName, '$redTeam : ${redRoster[4]}');
      expect(enchoBout.whiteName, '$whiteTeam : ${whiteRoster[4]}');

      // 大将延長戦で赤大将が面を決めて 1 - 0 で完全決着！
      final finishedEnchoBout = enchoBout.copyWith(
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'ev_encho_men',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now.add(const Duration(minutes: 30)),
          ),
        ],
      );
      matches.add(finishedEnchoBout);

      // ルールエンジンでの判定結果アサーション
      final analysis = ruleEngine.analyzeHistory(
        finishedEnchoBout.events,
        finishedEnchoBout,
        rule,
      );
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 0);

      // 最終ステータス判定: 延長戦で一本決着したため完全完了
      final finalGroupStatus = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        finishedEnchoBout,
        rule,
        null,
      );
      expect(finalGroupStatus.isAllDone, isTrue);
      expect(finalGroupStatus.isTie, isFalse);

      // 次試合生成は null（全戦完了）
      final nextNull = domainService.generateNextKachinukiMatch(
        finishedEnchoBout,
        rule,
      );
      expect(nextNull, isNull);

      // 全6試合が記録され、第6戦で玄武館の勝利が確定したことの検証
      expect(matches.length, equals(6));
      expect(matches.last.matchType, equals('大将延長戦'));
      expect(matches.last.redScore, equals(1));
    });
  });
}
