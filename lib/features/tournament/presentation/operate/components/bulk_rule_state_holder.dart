import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_apply_helper.dart';

/// ⚡ 一括ルール変更シート用の編集ステート管理クラス
class BulkRuleStateHolder {
  String selectedCategoryFilter = 'すべて';
  String selectedTypeFilter = 'すべて';
  List<String> selectedMatchIds = [];
  String? loadedMatchId;
  String? selectedCategoryRuleName;
  String selectedSceneType = 'normal';

  double matchTime = 3.0;
  bool isRunningTime = false;
  bool isIpponShobu = false;
  int ipponLimit = 2;
  int hansokuLimit = 2;
  bool hasExtension = false;
  double enchoTime = 3.0;
  int enchoCount = 1;
  bool isEnchoUnlimited = false;
  bool hasHantei = false;

  bool hasRepresentativeMatch = true;
  bool isDaihyoIpponShobu = true;
  double daihyoMatchTime = 0.0;
  bool daihyoHasExtension = true;
  double daihyoEnchoTime = 3.0;
  int daihyoEnchoCount = -2;
  bool isDaihyoEnchoUnlimited = true;
  bool daihyoHasHantei = false;

  bool isRenseikai = false;
  String renseikaiType = '一試合制';
  final overallTimeController = TextEditingController(text: '30');

  bool isKachinuki = false;
  String kachinukiUnlimitedType = '大将対大将';
  bool isLeague = false;
  double winPoint = 3.0;
  double lossPoint = 0.0;
  double drawPoint = 1.0;

  void dispose() {
    overallTimeController.dispose();
  }

  void applyCategoryRuleSet(
    MatchRule targetRule, {
    required bool isTeam,
    String? sceneKey,
  }) {
    final res = BulkRuleApplyHelper.computeRuleParams(
      targetRule: targetRule,
      isTeam: isTeam,
      isIndiv: !isTeam,
      sceneKey: sceneKey,
    );

    matchTime = res.matchTime;
    isRunningTime = targetRule.isRunningTime;
    isIpponShobu = res.isIpponShobu;
    ipponLimit = targetRule.ipponLimit;
    hansokuLimit = targetRule.hansokuLimit;
    hasExtension = res.hasExtension;
    enchoTime = res.enchoTime;
    enchoCount = res.enchoCount;
    isEnchoUnlimited = res.isEnchoUnlimited;
    hasHantei = res.hasHantei;
    hasRepresentativeMatch = res.hasRepresentativeMatch;
    isDaihyoIpponShobu = res.isDaihyoIpponShobu;
    daihyoMatchTime = res.daihyoMatchTime;
    daihyoHasExtension = res.daihyoHasExtension;
    daihyoEnchoTime = res.daihyoEnchoTime;
    daihyoEnchoCount = res.daihyoEnchoCount;
    isDaihyoEnchoUnlimited = res.isDaihyoEnchoUnlimited;
    daihyoHasHantei = res.daihyoHasHantei;
    isRenseikai = res.isRenseikai;
    renseikaiType = res.renseikaiType;
    overallTimeController.text = res.overallTimeMinutes.toString();
    isKachinuki = targetRule.isKachinuki;
    kachinukiUnlimitedType = targetRule.kachinukiUnlimitedType.isNotEmpty
        ? targetRule.kachinukiUnlimitedType
        : '大将対大将';
    isLeague = targetRule.isLeague;
    winPoint = targetRule.winPoint > 0 ? targetRule.winPoint : 3.0;
    lossPoint = targetRule.lossPoint;
    drawPoint = targetRule.drawPoint > 0 ? targetRule.drawPoint : 1.0;
  }

  void loadTemplateRules(MatchModel m) {
    loadedMatchId = m.id;
    final res = BulkRuleApplyHelper.loadTemplate(m);
    final r = m.rule ?? const MatchRule();
    matchTime = res.matchTime;
    isRunningTime = r.isRunningTime;
    isIpponShobu = res.isIpponShobu;
    ipponLimit = r.ipponLimit;
    hansokuLimit = r.hansokuLimit;
    hasExtension = res.hasExtension;
    enchoTime = res.enchoTime;
    enchoCount = res.enchoCount;
    isEnchoUnlimited = res.isEnchoUnlimited;
    hasHantei = res.hasHantei;
    hasRepresentativeMatch = res.hasRepresentativeMatch;
    isDaihyoIpponShobu = res.isDaihyoIpponShobu;
    daihyoMatchTime = r.daihyoMatchTimeMinutes;
    daihyoHasExtension = r.daihyoHasExtension;
    daihyoEnchoTime = r.daihyoEnchoTimeMinutes > 0
        ? r.daihyoEnchoTimeMinutes
        : 3.0;
    daihyoEnchoCount = r.daihyoEnchoCount;
    isDaihyoEnchoUnlimited = r.daihyoEnchoCount == -2;
    daihyoHasHantei = r.daihyoHasHantei;
    isRenseikai = res.isRenseikai;
    renseikaiType = res.renseikaiType;
    overallTimeController.text = res.overallTimeMinutes.toString();
    isKachinuki = r.isKachinuki;
    kachinukiUnlimitedType = r.kachinukiUnlimitedType.isNotEmpty
        ? r.kachinukiUnlimitedType
        : '大将対大将';
    isLeague = r.isLeague;
    winPoint = r.winPoint > 0 ? r.winPoint : 3.0;
    lossPoint = r.lossPoint;
    drawPoint = r.drawPoint > 0 ? r.drawPoint : 1.0;
  }

  MatchRule buildNewRule() {
    final sceneKey = selectedSceneType == 'renseikai'
        ? 'renseikai'
        : (selectedSceneType == 'moushiawase' ? 'moushiawase' : 'honsen');
    return MatchRule(
      matchScene: sceneKey,
      matchTimeMinutes: matchTime,
      isRunningTime: isRunningTime,
      isIpponShobu: isIpponShobu,
      ipponLimit: isIpponShobu ? 1 : ipponLimit,
      hansokuLimit: hansokuLimit,
      hasHantei: hasHantei,
      isEnchoUnlimited: hasExtension && isEnchoUnlimited,
      enchoTimeMinutes: hasExtension ? enchoTime : 0.0,
      enchoCount: hasExtension ? (isEnchoUnlimited ? -2 : enchoCount) : 0,
      hasRepresentativeMatch: hasRepresentativeMatch,
      isDaihyoIpponShobu: isDaihyoIpponShobu,
      daihyoMatchTimeMinutes: daihyoMatchTime,
      daihyoHasExtension: daihyoHasExtension,
      daihyoEnchoTimeMinutes: daihyoHasExtension ? daihyoEnchoTime : 0.0,
      daihyoEnchoCount: daihyoHasExtension
          ? (isDaihyoEnchoUnlimited ? -2 : daihyoEnchoCount)
          : 0,
      daihyoHasHantei: daihyoHasHantei,
      isRenseikai: isRenseikai,
      renseikaiType: renseikaiType,
      overallTimeMinutes: int.tryParse(overallTimeController.text) ?? 30,
      isKachinuki: isKachinuki,
      kachinukiUnlimitedType: kachinukiUnlimitedType,
      isLeague: isLeague,
      winPoint: winPoint,
      lossPoint: lossPoint,
      drawPoint: drawPoint,
    );
  }
}
