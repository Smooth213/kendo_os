import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

/// 一括ルール設定のパラメータ計算ヘルパー
class BulkRuleApplyHelper {
  static ({
    double matchTime,
    bool isIpponShobu,
    bool hasExtension,
    double enchoTime,
    int enchoCount,
    bool isEnchoUnlimited,
    bool hasHantei,
    bool hasRepresentativeMatch,
    bool isDaihyoIpponShobu,
    bool isRenseikai,
    String renseikaiType,
    int overallTimeMinutes,
  })
  computeRuleParams({
    required MatchRule targetRule,
    required bool isTeam,
    required bool isIndiv,
    String? sceneKey,
  }) {
    final effectiveScene = sceneKey ?? targetRule.matchScene;
    final isRenseikaiOrMoushiawase =
        effectiveScene == 'renseikai' ||
        effectiveScene == 'moushiawase' ||
        targetRule.isRenseikai ||
        targetRule.matchScene == 'renseikai' ||
        targetRule.matchScene == 'moushiawase';

    final matchTime = targetRule.matchTimeMinutes;
    final isIpponShobu = targetRule.isIpponShobu;

    bool hasExtension;
    bool isEnchoUnlimited;
    double enchoTime;
    int enchoCount;
    bool hasHantei;
    bool hasRepresentativeMatch;
    bool isDaihyoIpponShobu;

    if (isRenseikaiOrMoushiawase) {
      hasExtension = false;
      isEnchoUnlimited = false;
      enchoTime = 0.0;
      enchoCount = 0;
      hasHantei = false;
      hasRepresentativeMatch = false;
      isDaihyoIpponShobu = false;
    } else {
      final bool extensionEnabled =
          (targetRule.enchoTimeMinutes > 0) || targetRule.isEnchoUnlimited;
      hasExtension = extensionEnabled;
      isEnchoUnlimited = extensionEnabled ? targetRule.isEnchoUnlimited : false;
      enchoTime = targetRule.enchoTimeMinutes > 0
          ? targetRule.enchoTimeMinutes
          : 3.0;
      enchoCount = targetRule.enchoCount > 0 ? targetRule.enchoCount : 1;

      if (isTeam && !isIndiv) {
        hasHantei = false;
        hasRepresentativeMatch = targetRule.hasRepresentativeMatch;
        isDaihyoIpponShobu = targetRule.hasRepresentativeMatch
            ? targetRule.isDaihyoIpponShobu
            : false;
      } else if (isIndiv && !isTeam) {
        hasRepresentativeMatch = false;
        isDaihyoIpponShobu = false;
        hasHantei = targetRule.hasHantei;
      } else {
        hasHantei = targetRule.hasHantei;
        hasRepresentativeMatch = targetRule.hasRepresentativeMatch;
        isDaihyoIpponShobu = targetRule.hasRepresentativeMatch
            ? targetRule.isDaihyoIpponShobu
            : false;
      }
    }

    final isRenseikai = isRenseikaiOrMoushiawase || targetRule.isRenseikai;
    final renseikaiType = targetRule.renseikaiType;
    final overallTimeMinutes = targetRule.overallTimeMinutes;

    return (
      matchTime: matchTime,
      isIpponShobu: isIpponShobu,
      hasExtension: hasExtension,
      enchoTime: enchoTime,
      enchoCount: enchoCount,
      isEnchoUnlimited: isEnchoUnlimited,
      hasHantei: hasHantei,
      hasRepresentativeMatch: hasRepresentativeMatch,
      isDaihyoIpponShobu: isDaihyoIpponShobu,
      isRenseikai: isRenseikai,
      renseikaiType: renseikaiType,
      overallTimeMinutes: overallTimeMinutes,
    );
  }

  static ({
    double matchTime,
    bool isIpponShobu,
    bool hasExtension,
    double enchoTime,
    int enchoCount,
    bool isEnchoUnlimited,
    bool hasHantei,
    bool hasRepresentativeMatch,
    bool isDaihyoIpponShobu,
    bool isRenseikai,
    String renseikaiType,
    int overallTimeMinutes,
  })
  loadTemplate(dynamic match) {
    final r = match.rule ?? const MatchRule();
    return (
      matchTime: match.matchTimeMinutes as double,
      isIpponShobu: r.isIpponShobu as bool,
      hasExtension: match.hasExtension as bool,
      enchoTime: (match.extensionTimeMinutes ?? 3.0) as double,
      enchoCount: (match.extensionCount ?? 1) as int,
      isEnchoUnlimited: r.isEnchoUnlimited as bool,
      hasHantei: match.hasHantei as bool,
      hasRepresentativeMatch: r.hasRepresentativeMatch as bool,
      isDaihyoIpponShobu: r.isDaihyoIpponShobu as bool,
      isRenseikai: r.isRenseikai as bool,
      renseikaiType: r.renseikaiType as String,
      overallTimeMinutes: r.overallTimeMinutes as int,
    );
  }
}
