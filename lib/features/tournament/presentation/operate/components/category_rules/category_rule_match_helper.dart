import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

class CategoryRuleMatchHelper {
  /// 分秒フォーマットヘルパー
  static String formatMinutes(double minutes) {
    if (minutes <= 0) return '0分';
    final mins = minutes.floor();
    final secs = ((minutes - mins) * 60).round();
    if (mins == 0) {
      return '$secs秒';
    }
    if (secs == 0) {
      return '$mins分';
    }
    return '$mins分$secs秒';
  }

  /// 上位戦（準決勝・決勝等）判定
  static bool isAdvancedMatchName(String note, {List<String>? customKeywords}) {
    final cleanNote = note.toLowerCase().trim();
    final List<String> keywords;
    if (customKeywords != null && customKeywords.isNotEmpty) {
      keywords = customKeywords.map((kw) => kw.toLowerCase().trim()).toList();
    } else {
      keywords = [
        '準決勝',
        '準決',
        'じゅんけつ',
        'ベスト4',
        'b4',
        'sf',
        'semifinal',
        '准決',
        '順決',
        '決勝',
        'けっしょう',
        'ファイナル',
        'final',
        '結勝',
        '決勝戦',
        '3位決定',
        '3決',
        '三決',
      ];
    }

    String testNote = cleanNote;
    final hasSemisKeyword = keywords.any(
      (kw) =>
          kw.contains('準決') ||
          kw.contains('準決勝') ||
          kw.contains('ベスト4') ||
          kw.contains('sf'),
    );
    if (!hasSemisKeyword) {
      testNote = testNote
          .replaceAll('準決勝', '')
          .replaceAll('準決', '')
          .replaceAll('准決', '')
          .replaceAll('順決', '')
          .replaceAll('じゅんけつ', '')
          .replaceAll('semifinal', '')
          .replaceAll('sf', '')
          .replaceAll('3位決定', '')
          .replaceAll('3決', '')
          .replaceAll('三決', '');
    }

    return keywords.any((kw) => kw.isNotEmpty && testNote.contains(kw));
  }

  /// MatchRule インスタンスの組み立てヘルパー
  static MatchRule buildMatchRule({
    required String category,
    required String matchType,
    required double matchTime,
    required bool isRunningTime,
    required bool isIpponShobu,
    required int ipponLimit,
    required int hansokuLimit,
    required bool hasHantei,
    required bool hasExtension,
    required bool isEnchoUnlimited,
    required double enchoTime,
    required int enchoCount,
    required String kachinukiUnlimitedType,
    required bool isDaihyoIpponShobu,
    required double winPoint,
    required double lossPoint,
    required double drawPoint,
    required bool isRenseikai,
    required String renseikaiType,
    required int overallTime,
    required double daihyoMatchTime,
    required bool daihyoHasExtension,
    required double daihyoEnchoTime,
    required int daihyoEnchoCount,
    required bool daihyoHasHantei,
  }) {
    final isLeague = matchType == 'リーグ団体戦' || matchType == 'リーグ個人戦';
    final isKachinuki = matchType == '勝ち抜き戦';
    final hasLeagueDaihyo = matchType == '団体戦' || matchType == 'リーグ団体戦';

    return MatchRule(
      category: category,
      matchTimeMinutes: matchTime,
      isRunningTime: isRunningTime,
      isIpponShobu: isIpponShobu,
      ipponLimit: isIpponShobu ? 1 : ipponLimit,
      hansokuLimit: hansokuLimit,
      hasHantei: hasHantei,
      isEnchoUnlimited: hasExtension && isEnchoUnlimited,
      enchoTimeMinutes: enchoTime,
      enchoCount: hasExtension ? (isEnchoUnlimited ? 0 : enchoCount) : 0,
      isKachinuki: isKachinuki,
      kachinukiUnlimitedType: kachinukiUnlimitedType,
      hasLeagueDaihyo: hasLeagueDaihyo,
      isDaihyoIpponShobu: isDaihyoIpponShobu,
      winPoint: winPoint,
      lossPoint: lossPoint,
      drawPoint: drawPoint,
      isRenseikai: isRenseikai,
      renseikaiType: renseikaiType,
      overallTimeMinutes: overallTime,
      isLeague: isLeague,
      daihyoMatchTimeMinutes: daihyoMatchTime,
      daihyoHasExtension: daihyoHasExtension,
      daihyoEnchoTimeMinutes: daihyoEnchoTime,
      daihyoEnchoCount: daihyoEnchoCount,
      daihyoHasHantei: daihyoHasHantei,
    );
  }
}
