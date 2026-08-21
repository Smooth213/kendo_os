import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

class CategoryRuleMatchHelper {
  /// プリセット部門一覧
  static const List<String> presetCategories = [
    '小学生の部',
    '小学生低学年の部',
    '小学生高学年の部',
    '中学生の部',
    '中学生男子の部',
    '中学生女子の部',
    '高校生男子の部',
    '高校生女子の部',
    '一般男子の部',
    '一般女子の部',
  ];

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

  /// CategoryRuleSet インスタンスの組み立てヘルパー
  static CategoryRuleSet createCategoryRuleSet({
    required MatchRule normalRule,
    required MatchRule advancedRule,
    required bool useAdvancedRule,
    required List<String> advancedKeywords,
    required String matchType,
    required bool isRenseikai,
    required bool isMultiScene,
    required bool useHonsenRule,
    required bool useRenseikaiRule,
    required bool useMoushiawaseRule,
    required double renseikaiTime,
    required bool renseikaiIsRunningTime,
    required bool renseikaiHasHantei,
    required String renseikaiType,
    required int renseikaiOverallTime,
    required double moushiawaseTime,
    required bool moushiawaseIsRunningTime,
    required bool moushiawaseHasHantei,
    required String moushiawaseType,
    required int moushiawaseOverallTime,
  }) {
    final renseikaiRule = MatchRule(
      matchTimeMinutes: renseikaiTime,
      isRunningTime: renseikaiIsRunningTime,
      hasHantei: renseikaiHasHantei,
      enchoCount: 0,
      isEnchoUnlimited: false,
      isRenseikai: true,
      renseikaiType: renseikaiType,
      overallTimeMinutes: renseikaiOverallTime,
    );

    final moushiawaseRule = MatchRule(
      matchTimeMinutes: moushiawaseTime,
      isRunningTime: moushiawaseIsRunningTime,
      hasHantei: moushiawaseHasHantei,
      enchoCount: 0,
      isEnchoUnlimited: false,
      isRenseikai: true,
      renseikaiType: moushiawaseType,
      overallTimeMinutes: moushiawaseOverallTime,
    );

    return CategoryRuleSet(
      normalRule: normalRule,
      advancedRule: advancedRule,
      useAdvancedRule: useAdvancedRule,
      advancedKeywords: advancedKeywords,
      matchType: isRenseikai ? '錬成会' : matchType,
      isMultiScene: isMultiScene,
      useHonsenRule: useHonsenRule,
      useRenseikaiRule: useRenseikaiRule,
      useMoushiawaseRule: useMoushiawaseRule,
      renseikaiRule: renseikaiRule,
      moushiawaseRule: moushiawaseRule,
    );
  }

  /// 部門削除ヘルパー
  static TournamentModel deleteCategoryFromTournament(
    TournamentModel tournament,
    String category,
  ) {
    final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
      tournament.categoryRules,
    )..remove(category);

    final updatedCategories = List<String>.from(tournament.categories)
      ..remove(category);

    return tournament.copyWith(
      categories: updatedCategories,
      categoryRules: updatedCategoryRules,
    );
  }

  /// 部門追加ヘルパー
  static (TournamentModel, CategoryRuleSet) addCategoryToTournament(
    TournamentModel tournament,
    String name,
  ) {
    final cleanName = name.trim();
    if (tournament.categoryRules.containsKey(cleanName)) {
      return (tournament, tournament.categoryRules[cleanName]!);
    }

    final newRuleSet = CategoryRuleSet(
      normalRule: const MatchRule(matchTimeMinutes: 3.0),
      advancedRule: const MatchRule(matchTimeMinutes: 3.0),
      useAdvancedRule: false,
    );

    final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
      tournament.categoryRules,
    )..[cleanName] = newRuleSet;

    final updatedCategories = List<String>.from(tournament.categories);
    if (!updatedCategories.contains(cleanName)) {
      updatedCategories.add(cleanName);
    }

    final updatedTournament = tournament.copyWith(
      categories: updatedCategories,
      categoryRules: updatedCategoryRules,
    );

    return (updatedTournament, newRuleSet);
  }

  /// 大会モデルのルールセット更新ヘルパー
  static TournamentModel updateTournamentWithRuleSet({
    required TournamentModel tournament,
    required String category,
    required CategoryRuleSet ruleSet,
  }) {
    final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
      tournament.categoryRules,
    )..[category] = ruleSet;

    final updatedCategories = List<String>.from(tournament.categories);
    if (!updatedCategories.contains(category)) {
      updatedCategories.add(category);
    }

    return tournament.copyWith(
      categories: updatedCategories,
      categoryRules: updatedCategoryRules,
    );
  }

  /// 既存試合へのルール一括適用ヘルパー
  static List<MatchModel> applyRulesToMatches({
    required List<MatchModel> targetMatches,
    required CategoryRuleSet ruleSet,
    required bool useAdvancedRule,
    required List<String> advancedKeywords,
  }) {
    List<MatchModel> matchesToSave = [];
    for (var match in targetMatches) {
      final isAdvanced =
          useAdvancedRule &&
          isAdvancedMatchName(match.note, customKeywords: advancedKeywords);
      final activeRule = isAdvanced ? ruleSet.advancedRule : ruleSet.normalRule;

      final updatedMatch = match.copyWith(
        matchTimeMinutes: activeRule.matchTimeMinutes,
        isRunningTime: activeRule.isRunningTime,
        hasExtension: activeRule.enchoCount > 0 || activeRule.isEnchoUnlimited,
        extensionTimeMinutes: activeRule.enchoTimeMinutes,
        extensionCount: activeRule.enchoCount,
        hasHantei: activeRule.hasHantei,
        isKachinuki: activeRule.isKachinuki,
        rule: activeRule,
      );
      matchesToSave.add(updatedMatch);
    }
    return matchesToSave;
  }
}
