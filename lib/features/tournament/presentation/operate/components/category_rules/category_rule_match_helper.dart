import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_lookup_helper.dart';
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
    if (mins == 0) return '$secs秒';
    if (secs == 0) return '$mins分';
    return '$mins分$secs秒';
  }

  /// 上位戦（準決勝・決勝等）判定
  static bool isAdvancedMatchName(String note, {List<String>? customKeywords}) {
    final cleanNote = note.toLowerCase().trim();
    final List<String> keywords =
        (customKeywords != null && customKeywords.isNotEmpty)
        ? customKeywords.map((kw) => kw.toLowerCase().trim()).toList()
        : const [
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

    final hasSemis = keywords.any(
      (kw) =>
          kw.contains('準決') ||
          kw.contains('準決勝') ||
          kw.contains('ベスト4') ||
          kw.contains('sf'),
    );
    final testNote = hasSemis
        ? cleanNote
        : cleanNote.replaceAll(
            RegExp(r'準決勝|準決|准決|順決|じゅんけつ|semifinal|sf|3位決定|3決|三決'),
            '',
          );
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
    bool hasRepresentativeMatch = true,
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
    final isIndiv =
        matchType == '個人戦' || matchType == 'リーグ個人戦' || matchType.contains('個人');
    final isLeague = matchType == 'リーグ団体戦' || matchType == 'リーグ個人戦';
    final isKachinuki = matchType == '勝ち抜き戦';
    final effectiveHasExt = (isIndiv || isKachinuki) ? hasExtension : false;

    return MatchRule(
      category: category,
      matchTimeMinutes: matchTime,
      isRunningTime: isRunningTime,
      isIpponShobu: isIpponShobu,
      ipponLimit: isIpponShobu ? 1 : ipponLimit,
      hansokuLimit: hansokuLimit,
      hasHantei: hasHantei,
      isEnchoUnlimited: effectiveHasExt && isEnchoUnlimited,
      enchoTimeMinutes: enchoTime,
      enchoCount: effectiveHasExt ? (isEnchoUnlimited ? 0 : enchoCount) : 0,
      isKachinuki: isKachinuki,
      kachinukiUnlimitedType: kachinukiUnlimitedType,
      hasRepresentativeMatch: hasRepresentativeMatch,
      hasLeagueDaihyo: hasRepresentativeMatch,
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

  /// 部門名とサブタイトルを整形（例:「小学生の部 決勝トーナメント」）
  static String formatRuleTitle(String category, String subtitle) {
    final cleanSub = subtitle.trim();
    return cleanSub.isEmpty ? category : '$category $cleanSub';
  }

  /// 部門名から番号サフィックス（例: " (2)", " (3)", "（2）" など）を除去
  static String stripNumberSuffix(String category) {
    return category.replaceAll(RegExp(r'[\s\u3000]*[\(（]\d+[\)）]$'), '').trim();
  }

  /// 連番サフィックス（(2)等）を持つ部門名について、
  /// サブタイトルによって他のルールと区別できる場合は連番を除去した表示用部門名を返す。
  static String resolveDisplayCategory({
    required String category,
    required String subtitle,
    required Map<String, CategoryRuleSet> allCategoryRules,
  }) {
    final cleanSub = subtitle.trim();
    if (cleanSub.isEmpty) return category;

    final baseCategory = stripNumberSuffix(category);
    if (baseCategory == category.trim()) return category;

    final isDuplicate = allCategoryRules.entries.any((entry) {
      if (entry.key == category) return false;
      return stripNumberSuffix(entry.key) == baseCategory &&
          entry.value.subtitle.trim() == cleanSub;
    });

    return isDuplicate ? category : baseCategory;
  }

  /// ルールセット情報と既存ルールマップを元に、最適なタイトル表示を生成
  static String formatDisplayTitle({
    required String category,
    required String subtitle,
    Map<String, CategoryRuleSet>? allCategoryRules,
  }) {
    final effectiveCategory = allCategoryRules != null
        ? resolveDisplayCategory(
            category: category,
            subtitle: subtitle,
            allCategoryRules: allCategoryRules,
          )
        : category;
    return formatRuleTitle(effectiveCategory, subtitle);
  }

  /// CategoryRuleSet インスタンスの組み立てヘルパー
  static CategoryRuleSet createCategoryRuleSet({
    String subtitle = '',
    String comment = '',
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
    return CategoryRuleSet(
      subtitle: subtitle,
      comment: comment,
      normalRule: normalRule,
      advancedRule: advancedRule,
      useAdvancedRule: useAdvancedRule,
      advancedKeywords: advancedKeywords,
      matchType: isRenseikai ? '錬成会' : matchType,
      isMultiScene: isMultiScene,
      useHonsenRule: useHonsenRule,
      useRenseikaiRule: useRenseikaiRule,
      useMoushiawaseRule: useMoushiawaseRule,
      renseikaiRule: MatchRule(
        matchTimeMinutes: renseikaiTime,
        isRunningTime: renseikaiIsRunningTime,
        hasHantei: renseikaiHasHantei,
        enchoCount: 0,
        isEnchoUnlimited: false,
        isRenseikai: true,
        renseikaiType: renseikaiType,
        overallTimeMinutes: renseikaiOverallTime,
      ),
      moushiawaseRule: MatchRule(
        matchTimeMinutes: moushiawaseTime,
        isRunningTime: moushiawaseIsRunningTime,
        hasHantei: moushiawaseHasHantei,
        enchoCount: 0,
        isEnchoUnlimited: false,
        isRenseikai: true,
        renseikaiType: moushiawaseType,
        overallTimeMinutes: moushiawaseOverallTime,
      ),
    );
  }

  /// ルールキーから部門の基底名（「（個人戦）」などのサフィックスを除いた名称）を取得
  static String cleanCategoryBaseName(String ruleKey) =>
      CategoryRuleLookupHelper.cleanCategoryBaseName(ruleKey);

  /// 一意なルールキーを生成
  static String generateUniqueRuleKey(
    Map<String, CategoryRuleSet> existingRules,
    String baseName, {
    String? matchType,
  }) {
    final cleanBase = baseName.trim();
    if (!existingRules.containsKey(cleanBase)) return cleanBase;

    if (matchType != null && matchType.isNotEmpty) {
      final typeKey = '$cleanBase（$matchType）';
      if (!existingRules.containsKey(typeKey)) return typeKey;
    }

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
    return tournament.copyWith(
      categories: List<String>.from(tournament.categories)..remove(category),
      categoryRules: Map<String, CategoryRuleSet>.from(tournament.categoryRules)
        ..remove(category),
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
    final effectiveMatchType = matchType ?? '団体戦';
    final isIndiv = effectiveMatchType.contains('個人');
    final newRuleSet = CategoryRuleSet(
      normalRule: MatchRule(
        matchTimeMinutes: 3.0,
        enchoCount: isIndiv ? 1 : 0,
        isEnchoUnlimited: false,
      ),
      advancedRule: MatchRule(
        matchTimeMinutes: 3.0,
        enchoCount: isIndiv ? 1 : 0,
        isEnchoUnlimited: false,
      ),
      useAdvancedRule: false,
      matchType: effectiveMatchType,
    );

    final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
      tournament.categoryRules,
    )..[ruleKey] = newRuleSet;
    final updatedCategories = List<String>.from(tournament.categories);
    if (!updatedCategories.contains(ruleKey)) updatedCategories.add(ruleKey);

    return (
      tournament.copyWith(
        categories: updatedCategories,
        categoryRules: updatedCategoryRules,
      ),
      ruleKey,
      newRuleSet,
    );
  }

  /// 指定された部門名（および種別）に合致するすべてのルールセットエントリを取得
  static List<MapEntry<String, CategoryRuleSet>> findAllRuleSetsForCategory(
    Map<String, CategoryRuleSet> categoryRules,
    String category, {
    String? matchType,
  }) => CategoryRuleLookupHelper.findAllRuleSetsForCategory(
    categoryRules,
    category,
    matchType: matchType,
  );

  /// 試合（部門、種別、メモ）に最も合致するルールセットエントリをスマートに探索
  static MapEntry<String, CategoryRuleSet>? findRuleEntryForMatch(
    Map<String, CategoryRuleSet> categoryRules, {
    required String category,
    required String matchType,
    String note = '',
  }) => CategoryRuleLookupHelper.findRuleEntryForMatch(
    categoryRules,
    category: category,
    matchType: matchType,
    note: note,
  );

  /// 試合に最も合致するルールセットをスマートに探索（部門名 ＋ 団体/個人種別照合）
  static CategoryRuleSet? findRuleSetForMatch(
    Map<String, CategoryRuleSet> categoryRules, {
    required String category,
    required String matchType,
    String note = '',
  }) => CategoryRuleLookupHelper.findRuleSetForMatch(
    categoryRules,
    category: category,
    matchType: matchType,
    note: note,
  );

  /// カテゴリ名と種別からルールセットを検索
  static CategoryRuleSet? findRuleSetForCategoryAndType(
    Map<String, CategoryRuleSet> categoryRules,
    String category, {
    String? matchType,
  }) => CategoryRuleLookupHelper.findRuleSetForCategoryAndType(
    categoryRules,
    category,
    matchType: matchType,
  );

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
    if (!updatedCategories.contains(category)) updatedCategories.add(category);
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
    return targetMatches.map((match) {
      final isAdvanced =
          useAdvancedRule &&
          isAdvancedMatchName(match.note, customKeywords: advancedKeywords);
      final activeRule = isAdvanced ? ruleSet.advancedRule : ruleSet.normalRule;
      return match.copyWith(
        matchTimeMinutes: activeRule.matchTimeMinutes,
        isRunningTime: activeRule.isRunningTime,
        hasExtension: activeRule.enchoCount > 0 || activeRule.isEnchoUnlimited,
        extensionTimeMinutes: activeRule.enchoTimeMinutes,
        extensionCount: activeRule.enchoCount,
        hasHantei: activeRule.hasHantei,
        isKachinuki: activeRule.isKachinuki,
        rule: activeRule,
      );
    }).toList();
  }
}
