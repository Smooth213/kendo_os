import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';

/// 判定イベントのファクトリ
ScoreEvent _hanteiEvent(Side side, {bool isCanceled = false}) =>
    ScoreEventLegacyAdapter.fromLegacy(
      side: side,
      type: PointType.hantei,
      sequence: 0,
      userId: 'test_user',
    ).copyWith(isCanceled: isCanceled);

void main() {
  // 共通テスト用 MatchContext
  final drawTimeUpCtx = MatchContext(
    redIppon: 1,
    whiteIppon: 1,
    redHansoku: 0,
    whiteHansoku: 0,
    isTimeUp: true,
    targetIppon: 2,
    hasHantei: false,
  );

  // ──────────────────────────────────────────────
  // 延長突入判定テスト
  // ──────────────────────────────────────────────
  group('KendoOvertimeEvaluator.shouldEnterEncho', () {
    test('時間切れ・同点・延長許可あり → 延長に入る', () {
      final result = KendoOvertimeEvaluator.shouldEnterEncho(
        ctx: drawTimeUpCtx,
        allowsEncho: true,
        decideResultIsDraw: (c, r, e) => true,
      );
      expect(result, isTrue);
    });

    test('延長許可なし → 延長に入らない', () {
      final result = KendoOvertimeEvaluator.shouldEnterEncho(
        ctx: drawTimeUpCtx,
        allowsEncho: false,
        decideResultIsDraw: (c, r, e) => true,
      );
      expect(result, isFalse);
    });

    test('時間切れでない → 延長に入らない', () {
      final notTimeUpCtx = MatchContext(
        redIppon: 1,
        whiteIppon: 1,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: false,
        targetIppon: 2,
        hasHantei: false,
      );
      final result = KendoOvertimeEvaluator.shouldEnterEncho(
        ctx: notTimeUpCtx,
        allowsEncho: true,
        decideResultIsDraw: (c, r, e) => false,
      );
      expect(result, isFalse);
    });

    test('勝敗がついている場合 → 延長に入らない', () {
      final redWinCtx = MatchContext(
        redIppon: 2,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: false,
        targetIppon: 2,
        hasHantei: false,
      );
      final result = KendoOvertimeEvaluator.shouldEnterEncho(
        ctx: redWinCtx,
        allowsEncho: true,
        decideResultIsDraw: (c, r, e) => false,
      );
      expect(result, isFalse);
    });

    test('判定イベントがある場合 → 延長に入らない（判定で決着済み）', () {
      final events = [_hanteiEvent(Side.red)];
      final result = KendoOvertimeEvaluator.shouldEnterEncho(
        ctx: drawTimeUpCtx,
        allowsEncho: true,
        events: events,
        decideResultIsDraw: (c, r, e) => true,
      );
      expect(result, isFalse);
    });

    test('キャンセル済みの判定イベントは無視される → 延長に入れる', () {
      final events = [_hanteiEvent(Side.red, isCanceled: true)];
      final result = KendoOvertimeEvaluator.shouldEnterEncho(
        ctx: drawTimeUpCtx,
        allowsEncho: true,
        events: events,
        decideResultIsDraw: (c, r, e) => true,
      );
      expect(result, isTrue);
    });
  });

  // ──────────────────────────────────────────────
  // 延長戦・代表戦 targetIppon 補正テスト
  // ──────────────────────────────────────────────
  group('KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded', () {
    test('代表戦: スコア0-0 → targetIpponが1になること', () {
      final ctx = MatchContext(
        redIppon: 0,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: false,
        targetIppon: 2,
        hasHantei: false,
      );
      final result = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        ctx,
        '代表戦',
      );
      expect(result.targetIppon, 1);
    });

    test('延長戦: スコア1-1 → targetIpponが2になること', () {
      final ctx = MatchContext(
        redIppon: 1,
        whiteIppon: 1,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: true,
        targetIppon: 2,
        hasHantei: false,
      );
      final result = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        ctx,
        '延長戦',
      );
      expect(result.targetIppon, 2); // min(1,1)+1 = 2
    });

    test('個人戦: targetIpponは変化しないこと', () {
      final ctx = MatchContext(
        redIppon: 1,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: false,
        targetIppon: 2,
        hasHantei: false,
      );
      final result = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        ctx,
        '個人戦',
      );
      expect(result.targetIppon, 2); // 変化なし
    });

    test('補正後も元のイプポン数は保持される', () {
      final ctx = MatchContext(
        redIppon: 1,
        whiteIppon: 1,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: true,
        targetIppon: 2,
        hasHantei: false,
      );
      final result = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        ctx,
        '代表戦',
      );
      expect(result.redIppon, 1);
      expect(result.whiteIppon, 1);
    });
  });

  // ──────────────────────────────────────────────
  // 団体戦グループ状況解析テスト
  // ──────────────────────────────────────────────
  group('KendoOvertimeEvaluator.analyzeTeamMatchStatus', () {
    MatchModel makeMatch({
      required String id,
      required String status,
      required int red,
      required int white,
    }) {
      return MatchModel(
        id: id,
        tournamentId: 't1',
        matchOrder: 1,
        redName: 'Red',
        whiteName: 'White',
        status: status,
        matchType: '団体戦',
        redScore: red,
        whiteScore: white,
      );
    }

    test('全試合終了・赤が多数勝利 → isAllDone=true, isTie=false', () {
      final matches = [
        makeMatch(id: 'm1', status: 'finished', red: 2, white: 0),
        makeMatch(id: 'm2', status: 'approved', red: 1, white: 1),
      ];
      final status = KendoOvertimeEvaluator.analyzeTeamMatchStatus(matches);
      expect(status.isAllDone, isTrue);
      expect(status.isTie, isFalse);
    });

    test('全試合引き分け（勝数・本数とも同数） → isTie=true', () {
      final matches = [
        makeMatch(id: 'm1', status: 'finished', red: 1, white: 1),
        makeMatch(id: 'm2', status: 'finished', red: 0, white: 0),
      ];
      final status = KendoOvertimeEvaluator.analyzeTeamMatchStatus(matches);
      expect(status.isAllDone, isTrue);
      expect(status.isTie, isTrue);
    });

    test('勝数も本数も引き分け → isTie=true（代表戦ルールへ進む）', () {
      final matches = [
        makeMatch(id: 'm1', status: 'finished', red: 1, white: 0),
        makeMatch(id: 'm2', status: 'finished', red: 0, white: 1),
      ];
      final status = KendoOvertimeEvaluator.analyzeTeamMatchStatus(matches);
      expect(status.isAllDone, isTrue);
      expect(status.isTie, isTrue); // 勝数1-1・本数1-1 → 完全引き分け
    });

    test('試合が進行中 → isAllDone=false', () {
      final matches = [
        makeMatch(id: 'm1', status: 'in_progress', red: 0, white: 0),
      ];
      final status = KendoOvertimeEvaluator.analyzeTeamMatchStatus(matches);
      expect(status.isAllDone, isFalse);
    });
  });

  // ──────────────────────────────────────────────
  // 勝ち抜き戦状況解析テスト
  // ──────────────────────────────────────────────
  group('KendoOvertimeEvaluator.analyzeKachinukiStatus', () {
    MatchModel makeKachinukiMatch({
      required String status,
      required int red,
      required int white,
      List<String> redRemaining = const [],
      List<String> whiteRemaining = const [],
    }) {
      return MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchOrder: 1,
        redName: 'Red',
        whiteName: 'White',
        status: status,
        matchType: '個人戦',
        isKachinuki: true,
        redScore: red,
        whiteScore: white,
        redRemaining: redRemaining,
        whiteRemaining: whiteRemaining,
      );
    }

    test('試合が進行中 → isAllDone=false', () {
      final match = makeKachinukiMatch(
        status: 'in_progress',
        red: 0,
        white: 0,
        redRemaining: ['A', 'B'],
        whiteRemaining: ['C', 'D'],
      );
      final status = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        match,
        null,
        null,
      );
      expect(status.isAllDone, isFalse);
    });

    test('赤が勝利し白の選手が全員消化 → isAllDone=true', () {
      final match = makeKachinukiMatch(
        status: 'finished',
        red: 3,
        white: 1,
        redRemaining: ['A'],
        whiteRemaining: [], // 白選手が全員消化
      );
      final status = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        match,
        null,
        null,
      );
      expect(status.isAllDone, isTrue);
    });

    test('白が勝利し赤の選手が全員消化 → isAllDone=true', () {
      final match = makeKachinukiMatch(
        status: 'finished',
        red: 1,
        white: 4,
        redRemaining: [], // 赤選手が全員消化
        whiteRemaining: ['C'],
      );
      final status = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        match,
        null,
        null,
      );
      expect(status.isAllDone, isTrue);
    });

    test('大将戦まで進んで引き分け → isAllDone=true, isTie=true', () {
      final match = makeKachinukiMatch(
        status: 'finished',
        red: 2,
        white: 2,
        redRemaining: [], // 大将同士の対戦
        whiteRemaining: [],
      );
      final status = KendoOvertimeEvaluator.analyzeKachinukiStatus(
        match,
        null,
        null,
      );
      expect(status.isAllDone, isTrue);
      expect(status.isTie, isTrue);
    });
  });
}
