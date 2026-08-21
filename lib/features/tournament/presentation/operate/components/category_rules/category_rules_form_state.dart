import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';

/// 大会カテゴリ詳細ルール設定用フォーム状態ホルダークラス
class CategoryRulesFormState {
  String? editingCategory;

  // 編集中のルールセット状態
  bool useAdvancedRule = false;
  List<String> editingAdvancedKeywords = [
    '準決勝',
    '準決',
    '決勝',
    'final',
    '3位決定',
    '3決',
    'ベスト4',
  ];
  String editingMatchType = '個人戦';
  bool editingIsRenseikai = false;

  // 道場遠征用マルチシーン設定
  bool isMultiScene = false;
  bool useHonsenRule = true;
  bool useRenseikaiRule = true;
  bool useMoushiawaseRule = true;
  double renseikaiTime = 2.0;
  bool renseikaiIsRunningTime = true;
  bool renseikaiHasHantei = true;
  String renseikaiType = '一試合制';
  int renseikaiOverallTime = 30;

  double moushiawaseTime = 2.0;
  bool moushiawaseIsRunningTime = true;
  bool moushiawaseHasHantei = true;
  String moushiawaseType = '一試合制';
  int moushiawaseOverallTime = 30;

  // 通常戦の設定
  double normalTime = 3.0;
  bool normalIsRunningTime = false;
  bool normalIsIpponShobu = false;
  int normalIpponLimit = 2;
  int normalHansokuLimit = 2;
  bool normalHasHantei = false;
  bool normalHasExtension = false;
  bool normalIsEnchoUnlimited = false;
  double normalEnchoTime = 2.0;
  int normalEnchoCount = 1;
  String normalKachinukiUnlimitedType = '大将対大将';
  bool normalHasLeagueDaihyo = false;
  bool normalIsDaihyoIpponShobu = true;
  double normalWinPoint = 0.0;
  double normalLossPoint = 0.0;
  double normalDrawPoint = 0.0;
  String normalRenseikaiType = '一試合制';
  int normalOverallTime = 30;

  // 上位戦の設定
  double advancedTime = 3.0;
  bool advancedIsRunningTime = false;
  bool advancedIsIpponShobu = false;
  int advancedIpponLimit = 2;
  int advancedHansokuLimit = 2;
  bool advancedHasHantei = false;
  bool advancedHasExtension = true;
  bool advancedIsEnchoUnlimited = true;
  double advancedEnchoTime = 3.0;
  int advancedEnchoCount = 0;
  String advancedKachinukiUnlimitedType = '大将対大将';
  bool advancedHasLeagueDaihyo = false;
  bool advancedIsDaihyoIpponShobu = true;
  double advancedWinPoint = 0.0;
  double advancedLossPoint = 0.0;
  double advancedDrawPoint = 0.0;
  String advancedRenseikaiType = '一試合制';
  int advancedOverallTime = 30;

  // 代表戦の詳細設定 (通常戦用)
  double normalDaihyoMatchTime = 0.0;
  bool normalDaihyoHasExtension = true;
  double normalDaihyoEnchoTime = 3.0;
  int normalDaihyoEnchoCount = -2;
  bool normalDaihyoHasHantei = false;

  // 代表戦の詳細設定 (上位戦用)
  double advancedDaihyoMatchTime = 0.0;
  bool advancedDaihyoHasExtension = true;
  double advancedDaihyoEnchoTime = 3.0;
  int advancedDaihyoEnchoCount = -2;
  bool advancedDaihyoHasHantei = false;

  /// ルールセットから状態を展開
  void populateFromRuleSet(String category, CategoryRuleSet rules) {
    editingCategory = category;
    useAdvancedRule = rules.useAdvancedRule;

    isMultiScene = rules.isMultiScene;
    useHonsenRule = rules.useHonsenRule;
    useRenseikaiRule = rules.useRenseikaiRule;
    useMoushiawaseRule = rules.useMoushiawaseRule;
    renseikaiTime = rules.renseikaiRule.matchTimeMinutes;
    renseikaiIsRunningTime = rules.renseikaiRule.isRunningTime;
    renseikaiHasHantei = rules.renseikaiRule.hasHantei;
    renseikaiType = rules.renseikaiRule.renseikaiType;
    renseikaiOverallTime = rules.renseikaiRule.overallTimeMinutes;

    moushiawaseTime = rules.moushiawaseRule.matchTimeMinutes;
    moushiawaseIsRunningTime = rules.moushiawaseRule.isRunningTime;
    moushiawaseHasHantei = rules.moushiawaseRule.hasHantei;
    moushiawaseType = rules.moushiawaseRule.renseikaiType;
    moushiawaseOverallTime = rules.moushiawaseRule.overallTimeMinutes;

    // 通常戦設定
    normalTime = rules.normalRule.matchTimeMinutes;
    normalIsRunningTime = rules.normalRule.isRunningTime;
    normalIsIpponShobu = rules.normalRule.isIpponShobu;
    normalIpponLimit = rules.normalRule.ipponLimit;
    normalHansokuLimit = rules.normalRule.hansokuLimit;
    normalHasHantei = rules.normalRule.hasHantei;
    normalHasExtension =
        rules.normalRule.enchoCount > 0 || rules.normalRule.isEnchoUnlimited;
    normalIsEnchoUnlimited = rules.normalRule.isEnchoUnlimited;
    normalEnchoTime = rules.normalRule.enchoTimeMinutes;
    normalEnchoCount = rules.normalRule.enchoCount;
    normalKachinukiUnlimitedType = rules.normalRule.kachinukiUnlimitedType;
    normalHasLeagueDaihyo = rules.normalRule.hasLeagueDaihyo;
    normalIsDaihyoIpponShobu = rules.normalRule.isDaihyoIpponShobu;
    normalWinPoint = rules.normalRule.winPoint;
    normalLossPoint = rules.normalRule.lossPoint;
    normalDrawPoint = rules.normalRule.drawPoint;
    normalRenseikaiType = rules.normalRule.renseikaiType;
    normalOverallTime = rules.normalRule.overallTimeMinutes;

    // 上位戦設定
    advancedTime = rules.advancedRule.matchTimeMinutes;
    advancedIsRunningTime = rules.advancedRule.isRunningTime;
    advancedIsIpponShobu = rules.advancedRule.isIpponShobu;
    advancedIpponLimit = rules.advancedRule.ipponLimit;
    advancedHansokuLimit = rules.advancedRule.hansokuLimit;
    advancedHasHantei = rules.advancedRule.hasHantei;
    advancedHasExtension =
        rules.advancedRule.enchoCount > 0 ||
        rules.advancedRule.isEnchoUnlimited;
    advancedIsEnchoUnlimited = rules.advancedRule.isEnchoUnlimited;
    advancedEnchoTime = rules.advancedRule.enchoTimeMinutes;
    advancedEnchoCount = rules.advancedRule.enchoCount;
    advancedKachinukiUnlimitedType = rules.advancedRule.kachinukiUnlimitedType;
    advancedHasLeagueDaihyo = rules.advancedRule.hasLeagueDaihyo;
    advancedIsDaihyoIpponShobu = rules.advancedRule.isDaihyoIpponShobu;
    advancedWinPoint = rules.advancedRule.winPoint;
    advancedLossPoint = rules.advancedRule.lossPoint;
    advancedDrawPoint = rules.advancedRule.drawPoint;
    advancedRenseikaiType = rules.advancedRule.renseikaiType;
    advancedOverallTime = rules.advancedRule.overallTimeMinutes;
    editingAdvancedKeywords = List.from(rules.advancedKeywords);

    normalDaihyoMatchTime = rules.normalRule.daihyoMatchTimeMinutes;
    normalDaihyoHasExtension = rules.normalRule.daihyoHasExtension;
    normalDaihyoEnchoTime = rules.normalRule.daihyoEnchoTimeMinutes;
    normalDaihyoEnchoCount = rules.normalRule.daihyoEnchoCount;
    normalDaihyoHasHantei = rules.normalRule.daihyoHasHantei;

    advancedDaihyoMatchTime = rules.advancedRule.daihyoMatchTimeMinutes;
    advancedDaihyoHasExtension = rules.advancedRule.daihyoHasExtension;
    advancedDaihyoEnchoTime = rules.advancedRule.daihyoEnchoTimeMinutes;
    advancedDaihyoEnchoCount = rules.advancedRule.daihyoEnchoCount;
    advancedDaihyoHasHantei = rules.advancedRule.daihyoHasHantei;

    editingIsRenseikai = rules.normalRule.isRenseikai;
    if (rules.normalRule.isRenseikai) {
      editingMatchType = '錬成会';
    } else if (rules.normalRule.isKachinuki) {
      editingMatchType = '勝ち抜き戦';
    } else if (rules.normalRule.isLeague) {
      editingMatchType = rules.normalRule.hasLeagueDaihyo ? 'リーグ団体戦' : 'リーグ個人戦';
    } else if (rules.normalRule.hasLeagueDaihyo) {
      editingMatchType = '団体戦';
    } else if (rules.matchType.isNotEmpty) {
      editingMatchType = rules.matchType;
    } else {
      editingMatchType = category.contains('団体') ? '団体戦' : '個人戦';
    }
  }

  /// 現在の状態から MatchRule を構築
  MatchRule buildRuleForCategory(String category, {required bool isNormal}) {
    return CategoryRuleMatchHelper.buildMatchRule(
      category: category,
      matchType: editingMatchType,
      matchTime: isNormal ? normalTime : advancedTime,
      isRunningTime: isNormal ? normalIsRunningTime : advancedIsRunningTime,
      isIpponShobu: isNormal ? normalIsIpponShobu : advancedIsIpponShobu,
      ipponLimit: isNormal ? normalIpponLimit : advancedIpponLimit,
      hansokuLimit: isNormal ? normalHansokuLimit : advancedHansokuLimit,
      hasHantei: isNormal ? normalHasHantei : advancedHasHantei,
      hasExtension: isNormal ? normalHasExtension : advancedHasExtension,
      isEnchoUnlimited: isNormal
          ? normalIsEnchoUnlimited
          : advancedIsEnchoUnlimited,
      enchoTime: isNormal ? normalEnchoTime : advancedEnchoTime,
      enchoCount: isNormal ? normalEnchoCount : advancedEnchoCount,
      kachinukiUnlimitedType: isNormal
          ? normalKachinukiUnlimitedType
          : advancedKachinukiUnlimitedType,
      isDaihyoIpponShobu: isNormal
          ? normalIsDaihyoIpponShobu
          : advancedIsDaihyoIpponShobu,
      winPoint: isNormal ? normalWinPoint : advancedWinPoint,
      lossPoint: isNormal ? normalLossPoint : advancedLossPoint,
      drawPoint: isNormal ? normalDrawPoint : advancedDrawPoint,
      isRenseikai: editingIsRenseikai,
      renseikaiType: isNormal ? normalRenseikaiType : advancedRenseikaiType,
      overallTime: isNormal ? normalOverallTime : advancedOverallTime,
      daihyoMatchTime: isNormal
          ? normalDaihyoMatchTime
          : advancedDaihyoMatchTime,
      daihyoHasExtension: isNormal
          ? normalDaihyoHasExtension
          : advancedDaihyoHasExtension,
      daihyoEnchoTime: isNormal
          ? normalDaihyoEnchoTime
          : advancedDaihyoEnchoTime,
      daihyoEnchoCount: isNormal
          ? normalDaihyoEnchoCount
          : advancedDaihyoEnchoCount,
      daihyoHasHantei: isNormal
          ? normalDaihyoHasHantei
          : advancedDaihyoHasHantei,
    );
  }

  /// 現在の状態から完全な CategoryRuleSet を生成
  CategoryRuleSet buildCategoryRuleSet(String category) {
    final normalRule = buildRuleForCategory(category, isNormal: true);
    final advancedRule = buildRuleForCategory(category, isNormal: false);

    return CategoryRuleMatchHelper.createCategoryRuleSet(
      normalRule: normalRule,
      advancedRule: advancedRule,
      useAdvancedRule: useAdvancedRule,
      advancedKeywords: editingAdvancedKeywords,
      matchType: editingMatchType,
      isRenseikai: editingIsRenseikai,
      isMultiScene: isMultiScene,
      useHonsenRule: useHonsenRule,
      useRenseikaiRule: useRenseikaiRule,
      useMoushiawaseRule: useMoushiawaseRule,
      renseikaiTime: renseikaiTime,
      renseikaiIsRunningTime: renseikaiIsRunningTime,
      renseikaiHasHantei: renseikaiHasHantei,
      renseikaiType: renseikaiType,
      renseikaiOverallTime: renseikaiOverallTime,
      moushiawaseTime: moushiawaseTime,
      moushiawaseIsRunningTime: moushiawaseIsRunningTime,
      moushiawaseHasHantei: moushiawaseHasHantei,
      moushiawaseType: moushiawaseType,
      moushiawaseOverallTime: moushiawaseOverallTime,
    );
  }
}
