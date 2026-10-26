import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';

/// PDFヘッダー表示用の試合ルール要約生成ヘルパー
class PdfRuleFormatter {
  const PdfRuleFormatter._();

  /// groupDataList から代表的なルールを抽出し、要約テキストを生成
  static String formatFromGroupDataList(
    List<Map<String, dynamic>> groupDataList,
  ) {
    if (groupDataList.isEmpty) return '';

    for (final group in groupDataList) {
      final matches = group['matches'] as List<dynamic>?;
      if (matches == null || matches.isEmpty) continue;

      final first = matches.first;
      if (first is MatchModel) {
        final isIndividual = matches.every(
          (m) => m is MatchModel && TeamProgressHelper.isIndividualMatch(m),
        );
        return formatMatchRule(
          rule: first.rule,
          fallbackMatch: first,
          isIndividual: isIndividual,
        );
      } else {
        try {
          final isIndividual = matches.every(
            (m) =>
                m.matchType == '個人戦' ||
                m.matchType == 'リーグ個人戦' ||
                m.matchType == '選手' ||
                m.matchType.isEmpty,
          );
          return formatMatchRule(
            rule: first.rule as MatchRule?,
            fallbackTimeMinutes: (first.matchTimeMinutes as num?)?.toDouble(),
            fallbackIsRunningTime: first.isRunningTime as bool?,
            fallbackHasExtension: first.hasExtension as bool?,
            fallbackHasHantei: first.hasHantei as bool?,
            isIndividual: isIndividual,
          );
        } catch (_) {
          // ignore
        }
      }
    }
    return '';
  }

  /// MatchRule または MatchModel から要約文字列を生成
  static String formatMatchRule({
    MatchRule? rule,
    MatchModel? fallbackMatch,
    double? fallbackTimeMinutes,
    bool? fallbackIsRunningTime,
    bool? fallbackHasExtension,
    bool? fallbackHasHantei,
    bool isIndividual = true,
  }) {
    // 試合時間
    final timeMinutes =
        rule?.matchTimeMinutes ??
        fallbackMatch?.matchTimeMinutes ??
        fallbackTimeMinutes ??
        3.0;
    final isRunning =
        rule?.isRunningTime ??
        fallbackMatch?.isRunningTime ??
        fallbackIsRunningTime ??
        false;

    final timeStr = _formatTime(timeMinutes, isRunning);

    // 形試合
    if (rule?.isKataMatch ?? false) {
      return '$timeStr / 形・旗判定';
    }

    // 勝負方式
    final isIppon = rule?.isIpponShobu ?? false;
    final shobuStr = isIppon ? '1本勝負' : '3本勝負';

    final parts = <String>[timeStr, shobuStr];

    if (isIndividual) {
      // 個人戦の延長・判定
      final isUnlimited = rule?.isEnchoUnlimited ?? false;
      final enchoMinutes =
          rule?.enchoTimeMinutes ?? fallbackMatch?.extensionTimeMinutes ?? 0.0;
      final hasExtension =
          isUnlimited ||
          (rule != null
              ? rule.enchoCount > 0
              : (fallbackMatch?.hasExtension ?? fallbackHasExtension ?? false));

      final String enchoStr;
      if (isUnlimited) {
        enchoStr = '延長無制限';
      } else if (hasExtension && enchoMinutes > 0) {
        enchoStr = '延長あり(${_fmtNum(enchoMinutes)}分)';
      } else if (hasExtension) {
        enchoStr = '延長あり';
      } else {
        enchoStr = '延長なし';
      }
      parts.add(enchoStr);

      final hasHantei =
          rule?.hasHantei ??
          fallbackMatch?.hasHantei ??
          fallbackHasHantei ??
          false;
      parts.add(hasHantei ? '判定あり' : '判定なし');
    } else {
      // 団体戦
      final hasRep = rule?.hasRepresentativeMatch ?? true;
      if (hasRep) {
        final repIppon = rule?.isDaihyoIpponShobu ?? true;
        final repShobu = repIppon ? '1本勝負' : '3本勝負';
        final repEncho = (rule?.daihyoHasExtension ?? true)
            ? ((rule?.daihyoEnchoCount ?? -2) <= 0 ? '延長無制限' : '延長あり')
            : '延長なし';
        parts.add('代表戦あり($repShobu・$repEncho)');
      } else {
        parts.add('代表戦なし');
      }
    }

    return parts.join(' / ');
  }

  static String _formatTime(double minutes, bool isRunning) {
    final base = '${_fmtNum(minutes)}分';
    return isRunning ? '$base(ランニング)' : base;
  }

  static String _fmtNum(double v) {
    return v == v.toInt() ? v.toInt().toString() : v.toString();
  }
}
