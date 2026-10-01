import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';
import 'package:kendo_os/features/match/domain/services/match_domain_service.dart';

void main() {
  group('[Unit] 【Unit】勝ち抜き戦・5人抜きスイープ＆大将延長代表戦 境界値テスト', () {
    late MatchDomainService domainService;

    setUp(() {
      domainService = MatchDomainService();
    });

    test('先鋒1名による5人抜き（全勝優勝）の自動世代交代と完全終了判定こと', () {
      const rule = MatchRule(
        isKachinuki: true,
        matchTimeMinutes: 3.0,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        kachinukiUnlimitedType: '大将引き分け延長',
      );

      // 初期状態: 赤先鋒 vs 白先鋒
      final bout1 = MatchModel(
        id: 'bout_k1',
        tournamentId: 't_kachinuki_1',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redName: '赤先鋒',
        whiteName: '白先鋒',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        redRemaining: ['赤次鋒', '赤中堅', '赤副将', '赤大将'],
        whiteRemaining: ['白次鋒', '白中堅', '白副将', '白大将'],
        order: 1.0,
      );

      // 第1戦終了後の状態判定: まだ決着していない
      var status1 = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        bout1,
        rule,
        null,
      );
      expect(status1.isAllDone, isFalse);

      // 第2戦生成: 赤先鋒 vs 白次鋒
      final bout2 = domainService.generateNextKachinukiMatch(bout1, rule);
      expect(bout2, isNotNull);
      expect(bout2!.redName, '赤先鋒');
      expect(bout2.whiteName, '白次鋒');
      expect(bout2.whiteRemaining, ['白中堅', '白副将', '白大将']);
      expect(bout2.redRemaining.length, 4);

      // 第2戦: 赤先鋒 1 - 0 白次鋒 で赤勝利
      final bout2Finished = bout2.copyWith(
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
      );
      var status2 = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        bout2Finished,
        rule,
        null,
      );
      expect(status2.isAllDone, isFalse);

      // 第3戦生成: 赤先鋒 vs 白中堅
      final bout3 = domainService.generateNextKachinukiMatch(
        bout2Finished,
        rule,
      );
      expect(bout3, isNotNull);
      expect(bout3!.redName, '赤先鋒');
      expect(bout3.whiteName, '白中堅');
      expect(bout3.whiteRemaining, ['白副将', '白大将']);

      // 第3戦: 赤先鋒 2 - 0 白中堅 で赤勝利
      final bout3Finished = bout3.copyWith(
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      );
      var status3 = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        bout3Finished,
        rule,
        null,
      );
      expect(status3.isAllDone, isFalse);

      // 第4戦生成: 赤先鋒 vs 白副将
      final bout4 = domainService.generateNextKachinukiMatch(
        bout3Finished,
        rule,
      );
      expect(bout4, isNotNull);
      expect(bout4!.redName, '赤先鋒');
      expect(bout4.whiteName, '白副将');
      expect(bout4.whiteRemaining, ['白大将']);

      // 第4戦: 赤先鋒 1 - 0 白副将 で赤勝利
      final bout4Finished = bout4.copyWith(
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
      );
      var status4 = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        bout4Finished,
        rule,
        null,
      );
      expect(status4.isAllDone, isFalse);

      // 第5戦生成: 赤先鋒 vs 白大将（白チーム最後の1人）
      final bout5 = domainService.generateNextKachinukiMatch(
        bout4Finished,
        rule,
      );
      expect(bout5, isNotNull);
      expect(bout5!.redName, '赤先鋒');
      expect(bout5.whiteName, '白大将');
      expect(bout5.whiteRemaining, isEmpty); // 白は控えなし

      // 第5戦: 赤先鋒 2 - 1 白大将 で赤先鋒が白大将を破り5人抜き達成！
      final bout5Finished = bout5.copyWith(
        redScore: 2,
        whiteScore: 1,
        status: 'finished',
      );
      var status5 = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        bout5Finished,
        rule,
        null,
      );
      expect(status5.isAllDone, isTrue, reason: '白チーム全員敗退により勝ち抜き戦完了');
      expect(status5.isTie, isFalse);

      // 5人抜き完了のため、次試合は存在しない（null）
      final bout6 = domainService.generateNextKachinukiMatch(
        bout5Finished,
        rule,
      );
      expect(bout6, isNull, reason: '敗者側の控えが0名のため全試合終了');
    });

    test('先鋒〜副将相引き分け→大将戦時間切れ引き分け時の大将延長戦（一本勝負）自動生成と完全決着判定こと', () {
      const rule = MatchRule(
        isKachinuki: true,
        matchTimeMinutes: 3.0,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        kachinukiUnlimitedType: '大将引き分け延長',
      );

      // ── 第1戦: 赤先鋒 vs 白先鋒（0-0 引き分け、両者退場） ──
      final bout1 = MatchModel(
        id: 'bout_draw_1',
        tournamentId: 't_kachinuki_2',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redName: '赤先鋒',
        whiteName: '白先鋒',
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
        redRemaining: ['赤次鋒', '赤中堅', '赤副将', '赤大将'],
        whiteRemaining: ['白次鋒', '白中堅', '白副将', '白大将'],
        order: 1.0,
      );

      // ── 第2戦生成: 赤次鋒 vs 白次鋒 ──
      final bout2 = domainService.generateNextKachinukiMatch(bout1, rule);
      expect(bout2, isNotNull);
      expect(bout2!.redName, '赤次鋒');
      expect(bout2.whiteName, '白次鋒');

      // ── 第2戦: 赤次鋒 vs 白次鋒（0-0 引き分け、両者退場） ──
      final bout2Finished = bout2.copyWith(
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
      );

      // ── 第3戦生成: 赤中堅 vs 白中堅 ──
      final bout3 = domainService.generateNextKachinukiMatch(
        bout2Finished,
        rule,
      );
      expect(bout3, isNotNull);
      expect(bout3!.redName, '赤中堅');
      expect(bout3.whiteName, '白中堅');

      // ── 第3戦: 赤中堅 vs 白中堅（0-0 引き分け、両者退場） ──
      final bout3Finished = bout3.copyWith(
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
      );

      // ── 第4戦生成: 赤副将 vs 白副将 ──
      final bout4 = domainService.generateNextKachinukiMatch(
        bout3Finished,
        rule,
      );
      expect(bout4, isNotNull);
      expect(bout4!.redName, '赤副将');
      expect(bout4.whiteName, '白副将');

      // ── 第4戦: 赤副将 vs 白副将（0-0 引き分け、両者退場） ──
      final bout4Finished = bout4.copyWith(
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
      );

      // ── 第5戦生成: 赤大将 vs 白大将（双方最後の1人、控え0名） ──
      final bout5 = domainService.generateNextKachinukiMatch(
        bout4Finished,
        rule,
      );
      expect(bout5, isNotNull);
      expect(bout5!.redName, '赤大将');
      expect(bout5.whiteName, '白大将');
      expect(bout5.redRemaining, isEmpty);
      expect(bout5.whiteRemaining, isEmpty);

      // ── 第5戦（大将同士）: 0 - 0 で時間切れ引き分け ──
      final bout5Finished = bout5.copyWith(
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
      );

      // 大将同士が引き分けた場合、大将引き分け延長ルールにより次試合（大将延長戦）が生成される
      final boutEncho = domainService.generateNextKachinukiMatch(
        bout5Finished,
        rule,
      );
      expect(boutEncho, isNotNull);
      expect(boutEncho!.matchType, '大将延長戦');
      expect(boutEncho.redName, '赤大将');
      expect(boutEncho.whiteName, '白大将');
      expect(boutEncho.note, '延長戦（1本勝負）');

      // ── 第6戦（大将延長戦）: 赤大将が一本先取（1 - 0）で勝利 ──
      final boutEnchoFinished = boutEncho.copyWith(
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
      );

      // 大将延長戦で決着した後の状態判定
      final finalStatus = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        boutEnchoFinished,
        rule,
        null,
      );
      expect(finalStatus.isAllDone, isTrue);
      expect(finalStatus.isTie, isFalse);

      // さらに次試合生成を試みると null（完全決着・終了）となる
      final noMoreMatch = domainService.generateNextKachinukiMatch(
        boutEnchoFinished,
        rule,
      );
      expect(noMoreMatch, isNull);
    });
  });
}
