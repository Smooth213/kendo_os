import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/match_strategy.dart';

/// 延長戦・代表戦・勝ち抜き戦の突入判定・グループ状況解析 ユーティリティ
///
/// [KendoRuleEngine] から分離されたグループ試合状況解析ロジック。
/// 延長判定・勝ち抜き戦の進行管理を一元化する。
class KendoOvertimeEvaluator {
  const KendoOvertimeEvaluator._();

  /// 延長戦突入判定
  ///
  /// [ctx] 現在のMatchContext、[allowsEncho] 延長許可フラグ、
  /// [rule] 試合ルール、[events] イベント一覧を受け取り、
  /// 延長戦に入るべきかどうかを返す。
  static bool shouldEnterEncho({
    required MatchContext ctx,
    required bool allowsEncho,
    required bool Function(MatchContext, MatchRule?, List<ScoreEvent>)
    decideResultIsDraw,
    MatchRule? rule,
    List<ScoreEvent> events = const [],
  }) {
    // 明示的な決着イベント(判定)がある場合、延長戦には絶対に入らない
    for (final e in events) {
      if (e.isCanceled) continue;
      if (e.isHantei || e.type == PointType.hantei) {
        return false;
      }
    }

    return ctx.isTimeUp &&
        ctx.redIppon == ctx.whiteIppon &&
        allowsEncho &&
        decideResultIsDraw(ctx, rule, events);
  }

  /// 代表戦・延長戦の targetIppon を補正する
  ///
  /// 延長戦・代表戦ではサドンデス（先取1本）が原則。
  /// 現在のスコアに応じて targetIppon を動的に 1 加算する。
  static MatchContext applyOvertimeCorrectionIfNeeded(
    MatchContext ctx,
    String matchType,
  ) {
    if (matchType != '延長戦' && matchType != '代表戦') return ctx;

    final minScore = ctx.redIppon < ctx.whiteIppon
        ? ctx.redIppon
        : ctx.whiteIppon;

    return MatchContext(
      redIppon: ctx.redIppon,
      whiteIppon: ctx.whiteIppon,
      redHansoku: ctx.redHansoku,
      whiteHansoku: ctx.whiteHansoku,
      isTimeUp: ctx.isTimeUp,
      targetIppon: minScore + 1,
      hasHantei: ctx.hasHantei,
    );
  }

  /// 団体戦のグループ全体の状況を解析する
  static GroupMatchStatus analyzeTeamMatchStatus(List<MatchModel> matches) {
    final isAllDone = matches.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );
    final hasDaihyo = matches.any((m) => m.matchType == '代表戦');

    if (isAllDone && !hasDaihyo) {
      int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
      for (final m in matches) {
        rPts += m.redScore;
        wPts += m.whiteScore;
        if (m.redScore > m.whiteScore) {
          rWins++;
        } else if (m.whiteScore > m.redScore) {
          wWins++;
        }
      }
      if (rWins == wWins && rPts == wPts) {
        return GroupMatchStatus(isAllDone: true, isTie: true);
      }
    }
    return GroupMatchStatus(isAllDone: isAllDone, isTie: false);
  }

  /// 勝ち抜き戦（かちぬき）のグループ状況を解析する
  static GroupMatchStatus analyzeKachinukiStatus(
    MatchModel currentMatch,
    MatchRule? rule,
    Map<String, dynamic>? lastSettings,
  ) {
    if (currentMatch.status != 'finished' &&
        currentMatch.status != 'approved') {
      return GroupMatchStatus(isAllDone: false, isTie: false);
    }

    bool isTie = false;
    bool isAllDone = false;

    if (currentMatch.redScore == currentMatch.whiteScore) {
      final isTaishoVsTaisho =
          currentMatch.redRemaining.isEmpty &&
          currentMatch.whiteRemaining.isEmpty;
      if (isTaishoVsTaisho) {
        final kType = rule?.kachinukiUnlimitedType ?? '';
        final maxExt = lastSettings?['extensionCount'] ?? -2;
        final currentExt = '延長'.allMatches(currentMatch.note).length;

        final canExtend =
            kType == '大将引き分け延長' &&
            (maxExt == -2 || maxExt == -1 || currentExt < maxExt);
        if (canExtend &&
            currentMatch.matchType != '大将延長戦' &&
            currentMatch.status != 'finished') {
          isAllDone = false;
        } else {
          isAllDone = true;
          isTie = true;
        }
      } else {
        isAllDone =
            (currentMatch.redRemaining.isEmpty ||
            currentMatch.whiteRemaining.isEmpty);
      }
    } else {
      isAllDone = (currentMatch.redScore > currentMatch.whiteScore)
          ? currentMatch.whiteRemaining.isEmpty
          : currentMatch.redRemaining.isEmpty;
    }

    return GroupMatchStatus(isAllDone: isAllDone, isTie: isTie);
  }
}
