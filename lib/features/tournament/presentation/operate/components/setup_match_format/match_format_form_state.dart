import 'package:flutter/material.dart';

import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

/// 対戦フォーマット設定画面のフォーム状態モデル
class MatchFormatFormState {
  String matchType;
  bool hasExtension;
  bool hasHantei;
  double matchTime;
  bool isRunningTime;
  bool isRenseikai;
  String? selectedTeamId;

  String kachinukiUnlimitedType;
  bool hasLeagueDaihyo;
  String renseikaiType;
  bool isDaihyoIpponShobu;

  double daihyoMatchTime;
  bool daihyoHasExtension;
  double daihyoEnchoTime;
  int daihyoEnchoCount;
  bool daihyoHasHantei;

  bool isIpponShobu;
  int ipponLimit;
  int hansokuLimit;

  int extCount;
  double extTime;

  String selectedMajorCategory;
  String selectedMinorCategory;
  String selectedRuleScene;
  String? manualRoundTypeOverride;

  MatchFormatFormState({
    this.matchType = '団体戦',
    this.hasExtension = false,
    this.hasHantei = true,
    this.matchTime = 3.0,
    this.isRunningTime = false,
    this.isRenseikai = false,
    this.selectedTeamId,
    this.kachinukiUnlimitedType = '3人勝ち抜き',
    this.hasLeagueDaihyo = false,
    this.renseikaiType = '時間制',
    this.isDaihyoIpponShobu = true,
    this.daihyoMatchTime = 3.0,
    this.daihyoHasExtension = false,
    this.daihyoEnchoTime = 2.0,
    this.daihyoEnchoCount = -2,
    this.daihyoHasHantei = true,
    this.isIpponShobu = false,
    this.ipponLimit = 2,
    this.hansokuLimit = 2,
    this.extCount = -2,
    this.extTime = -2.0,
    this.selectedMajorCategory = '一般・一般',
    this.selectedMinorCategory = '男子',
    this.selectedRuleScene = 'honsen',
    this.manualRoundTypeOverride,
  });

  String getCategory() {
    if (selectedMajorCategory == '初心者') return '初心者の部';
    if (selectedMajorCategory == '幼年') return '幼年の部';
    if (selectedMinorCategory == '全体') return '$selectedMajorCategoryの部';
    if (selectedMajorCategory == '大学・一般') return '$selectedMinorCategoryの部';
    return '$selectedMajorCategory$selectedMinorCategoryの部';
  }

  void applyMatchRule(
    MatchRule rule, {
    required TextEditingController overallTimeController,
    required TextEditingController winPointController,
    required TextEditingController lossPointController,
    required TextEditingController drawPointController,
  }) {
    matchTime = rule.matchTimeMinutes;
    isRunningTime = rule.isRunningTime;
    hasExtension = rule.enchoCount > 0 || rule.isEnchoUnlimited;
    extCount = rule.isEnchoUnlimited ? -2 : rule.enchoCount;
    extTime = rule.enchoTimeMinutes;
    hasHantei = rule.hasHantei;
    isRenseikai = rule.isRenseikai;
    renseikaiType = rule.renseikaiType;
    overallTimeController.text = rule.overallTimeMinutes.toString();
    winPointController.text = rule.winPoint.toString();
    lossPointController.text = rule.lossPoint.toString();
    drawPointController.text = rule.drawPoint.toString();
    kachinukiUnlimitedType = rule.kachinukiUnlimitedType;
    hasLeagueDaihyo = rule.hasLeagueDaihyo;
    isDaihyoIpponShobu = rule.isDaihyoIpponShobu;
    daihyoMatchTime = rule.daihyoMatchTimeMinutes;
    daihyoHasExtension = rule.daihyoHasExtension;
    daihyoEnchoTime = rule.daihyoEnchoTimeMinutes;
    daihyoEnchoCount = rule.daihyoEnchoCount;
    daihyoHasHantei = rule.daihyoHasHantei;
    isIpponShobu = rule.isIpponShobu;
    ipponLimit = rule.ipponLimit;
    hansokuLimit = rule.hansokuLimit;
  }
}
