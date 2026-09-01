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
    double daihyoMatchTime,
    bool daihyoHasExtension,
    double daihyoEnchoTime,
    int daihyoEnchoCount,
    bool isDaihyoEnchoUnlimited,
    bool daihyoHasHantei,
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

    // 延長戦: isEnchoUnlimited または enchoCount > 0 または enchoCount == -2
    final bool hasExtension =
        targetRule.isEnchoUnlimited ||
        targetRule.enchoCount > 0 ||
        targetRule.enchoCount == -2;
    final bool isEnchoUnlimited =
        targetRule.isEnchoUnlimited || targetRule.enchoCount == -2;
    final double enchoTime = targetRule.enchoTimeMinutes > 0
        ? targetRule.enchoTimeMinutes
        : 2.0;
    final int enchoCount = targetRule.enchoCount > 0
        ? targetRule.enchoCount
        : 1;

    // 判定: targetRule.hasHantei をそのまま反映
    final bool hasHantei = targetRule.hasHantei;

    // 団体戦・代表戦: targetRule の設定を忠実に反映
    final bool hasRepresentativeMatch = isIndiv && !isTeam
        ? false
        : (targetRule.hasRepresentativeMatch || targetRule.hasLeagueDaihyo);
    final bool isDaihyoIpponShobu = targetRule.isDaihyoIpponShobu;
    final double daihyoMatchTime = targetRule.daihyoMatchTimeMinutes;
    final bool daihyoHasExtension = targetRule.daihyoHasExtension;
    final double daihyoEnchoTime = targetRule.daihyoEnchoTimeMinutes > 0
        ? targetRule.daihyoEnchoTimeMinutes
        : 3.0;
    final int daihyoEnchoCount = targetRule.daihyoEnchoCount > 0
        ? targetRule.daihyoEnchoCount
        : 1;
    final bool isDaihyoEnchoUnlimited =
        targetRule.daihyoEnchoCount == -2 || targetRule.isEnchoUnlimited;
    final bool daihyoHasHantei = targetRule.daihyoHasHantei;

    final isRenseikai = isRenseikaiOrMoushiawase || targetRule.isRenseikai;
    final renseikaiType = targetRule.renseikaiType.isNotEmpty
        ? targetRule.renseikaiType
        : (isRenseikaiOrMoushiawase ? '一試合制' : '一試合制');
    final overallTimeMinutes = targetRule.overallTimeMinutes > 0
        ? targetRule.overallTimeMinutes
        : 30;

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
      daihyoMatchTime: daihyoMatchTime,
      daihyoHasExtension: daihyoHasExtension,
      daihyoEnchoTime: daihyoEnchoTime,
      daihyoEnchoCount: daihyoEnchoCount,
      isDaihyoEnchoUnlimited: isDaihyoEnchoUnlimited,
      daihyoHasHantei: daihyoHasHantei,
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
