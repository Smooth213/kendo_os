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

  /// ルールキーから部門の基底名（「（個人戦）」などのサフィックスを除いた名称）を取得
  static String cleanCategoryBaseName(String ruleKey) {
    var base = ruleKey.trim();
    // （個人戦）、（団体戦）、(個人戦)、(団体戦)、(2) などのサフィックスを除去
    base = base
        .replaceAll(RegExp(r'[\(（](個人戦|団体戦|錬成会|申合せ|申し合わせ|\d+)[\)）]$'), '')
        .trim();
    return base.isEmpty ? ruleKey.trim() : base;
  }

  /// 一意なルールキーを生成
  static String generateUniqueRuleKey(
    Map<String, CategoryRuleSet> existingRules,
    String baseName, {
    String? matchType,
  }) {
    final cleanBase = baseName.trim();
    if (!existingRules.containsKey(cleanBase)) {
      return cleanBase;
    }

    // 種別サフィックス付きキーの検証
    if (matchType != null && matchType.isNotEmpty) {
      final typeKey = '$cleanBase（$matchType）';
      if (!existingRules.containsKey(typeKey)) {
        return typeKey;
      }
    }

    // 番号サフィックスによる一意キー生成
    int count = 2;
    while (existingRules.containsKey('$cleanBase ($count)')) {
      count++;
    }
    return '$cleanBase ($count)';
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

  /// 部門追加ヘルパー（同一カテゴリ名でも重複せず新規ルールとして追加可能）
  static (TournamentModel, String, CategoryRuleSet) addCategoryToTournament(
    TournamentModel tournament,
    String name, {
    String? matchType,
  }) {
    final cleanName = name.trim();
    final ruleKey = generateUniqueRuleKey(
      tournament.categoryRules,
      cleanName,
      matchType: matchType,
    );

    final newRuleSet = CategoryRuleSet(
      normalRule: const MatchRule(matchTimeMinutes: 3.0),
      advancedRule: const MatchRule(matchTimeMinutes: 3.0),
      useAdvancedRule: false,
      matchType: matchType ?? '団体戦',
    );

    final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
      tournament.categoryRules,
    )..[ruleKey] = newRuleSet;

    final updatedCategories = List<String>.from(tournament.categories);
    if (!updatedCategories.contains(ruleKey)) {
      updatedCategories.add(ruleKey);
    }

    final updatedTournament = tournament.copyWith(
      categories: updatedCategories,
      categoryRules: updatedCategoryRules,
    );

    return (updatedTournament, ruleKey, newRuleSet);
  }

  /// 試合に最も合致するルールセットをスマートに探索（部門名 ＋ 団体/個人種別照合）
  static CategoryRuleSet? findRuleSetForMatch(
    Map<String, CategoryRuleSet> categoryRules, {
    required String category,
    required String matchType,
    String note = '',
  }) {
    if (categoryRules.isEmpty) return null;

    final isIndividual =
        matchType == '個人戦' ||
        matchType == '選手' ||
        matchType.contains('個人') ||
        category.contains('個人');

    final cleanCat = category.trim();

    // 1. 完全一致するキーが存在する場合
    if (categoryRules.containsKey(cleanCat)) {
      final directRule = categoryRules[cleanCat]!;
      final bool ruleIsIndiv = directRule.matchType.contains('個人');
      if (isIndividual == ruleIsIndiv) {
        return directRule;
      }
    }

    // 2. 基底部門名が一致し、かつ種別（団体戦/個人戦）が一致するルールを優先検索
    final baseCat = cleanCategoryBaseName(cleanCat);
    CategoryRuleSet? matchedTypeRule;
    CategoryRuleSet? fallbackRule;

    for (final entry in categoryRules.entries) {
      final keyBase = cleanCategoryBaseName(entry.key);
      if (keyBase == baseCat ||
          entry.key.contains(baseCat) ||
          baseCat.contains(keyBase)) {
        fallbackRule ??= entry.value;
        final bool ruleIsIndiv =
            entry.value.matchType.contains('個人') || entry.key.contains('個人');
        if (isIndividual == ruleIsIndiv) {
          matchedTypeRule = entry.value;
          break;
        }
      }
    }

    return matchedTypeRule ?? fallbackRule ?? categoryRules[cleanCat];
  }

  /// カテゴリ名と種別からルールセットを検索
  static CategoryRuleSet? findRuleSetForCategoryAndType(
    Map<String, CategoryRuleSet> categoryRules,
    String category, {
    String? matchType,
  }) {
    if (categoryRules.isEmpty) return null;
    return findRuleSetForMatch(
      categoryRules,
      category: category,
      matchType: matchType ?? '団体戦',
    );
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
