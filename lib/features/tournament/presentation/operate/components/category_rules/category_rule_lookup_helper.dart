import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';

/// 部門ルールセットの探索・照合（ルックアップ）を担当するヘルパークラス
class CategoryRuleLookupHelper {
  /// ルールキーから部門の基底名（「（個人戦）」などのサフィックスを除いた名称）を取得
  static String cleanCategoryBaseName(String ruleKey) {
    final base = ruleKey
        .trim()
        .replaceAll(RegExp(r'[\(（](個人戦|団体戦|錬成会|申合せ|申し合わせ|\d+)[\)）]$'), '')
        .trim();
    return base.isEmpty ? ruleKey.trim() : base;
  }

  /// 指定された部門名（および種別）に合致するすべてのルールセットエントリを取得
  static List<MapEntry<String, CategoryRuleSet>> findAllRuleSetsForCategory(
    Map<String, CategoryRuleSet> categoryRules,
    String category, {
    String? matchType,
  }) {
    if (categoryRules.isEmpty) return const [];
    final cleanCat = category.trim();
    final baseCat = cleanCategoryBaseName(cleanCat);
    final bool? isIndividual = matchType != null
        ? (matchType == '個人戦' ||
              matchType == '選手' ||
              matchType.contains('個人') ||
              cleanCat.contains('個人'))
        : null;

    final exactMatches = <MapEntry<String, CategoryRuleSet>>[];
    final baseMatches = <MapEntry<String, CategoryRuleSet>>[];
    final partialMatches = <MapEntry<String, CategoryRuleSet>>[];
    final seenKeys = <String>{};

    for (final entry in categoryRules.entries) {
      final key = entry.key.trim();
      final keyBase = cleanCategoryBaseName(key);
      if (key == cleanCat) {
        if (seenKeys.add(entry.key)) exactMatches.add(entry);
      } else if (keyBase == baseCat) {
        if (seenKeys.add(entry.key)) baseMatches.add(entry);
      } else if (key.contains(baseCat) || baseCat.contains(keyBase)) {
        if (seenKeys.add(entry.key)) partialMatches.add(entry);
      }
    }

    final allMatches = [...exactMatches, ...baseMatches, ...partialMatches];
    if (isIndividual != null) {
      final typeMatches = allMatches.where((entry) {
        final ruleIsIndiv =
            entry.value.matchType.contains('個人') || entry.key.contains('個人');
        return ruleIsIndiv == isIndividual;
      }).toList();
      if (typeMatches.isNotEmpty) return typeMatches;
    }
    return allMatches;
  }

  /// 試合（部門、種別、メモ）に最も合致するルールセットエントリをスマートに探索
  static MapEntry<String, CategoryRuleSet>? findRuleEntryForMatch(
    Map<String, CategoryRuleSet> categoryRules, {
    required String category,
    required String matchType,
    String note = '',
  }) {
    if (categoryRules.isEmpty) return null;
    final candidates = findAllRuleSetsForCategory(
      categoryRules,
      category,
      matchType: matchType,
    );

    if (candidates.isEmpty) {
      if (categoryRules.containsKey(category.trim())) {
        return MapEntry(category.trim(), categoryRules[category.trim()]!);
      }
      return null;
    }

    // note が指定されている場合、subtitle やキーワードと照合して優先選択
    final cleanNote = note.trim();
    if (cleanNote.isNotEmpty) {
      for (final entry in candidates) {
        final sub = entry.value.subtitle.trim();
        if (sub.isNotEmpty &&
            (cleanNote.contains(sub) || sub.contains(cleanNote))) {
          return entry;
        }
      }

      // 2. 「予選」「決勝」「準決勝」「トーナメント」「リーグ」などのキーワード照合
      final cleanNormalizedNote = cleanNote.replaceAll(RegExp(r'申し合わせ'), '申合せ');
      final keywords = const [
        '予選',
        '決勝',
        '準決勝',
        '準決',
        'リーグ',
        'トーナメント',
        '錬成',
        '申合せ',
        '3決',
        '三決',
      ];
      for (final kw in keywords) {
        if (cleanNormalizedNote.contains(kw)) {
          for (final entry in candidates) {
            if (entry.value.subtitle.contains(kw) || entry.key.contains(kw)) {
              return entry;
            }
          }
        }
      }
    }

    return candidates.firstWhere(
      (entry) => entry.key == category.trim(),
      orElse: () => candidates.first,
    );
  }

  /// 試合に最も合致するルールセットをスマートに探索（部門名 ＋ 団体/個人種別照合）
  static CategoryRuleSet? findRuleSetForMatch(
    Map<String, CategoryRuleSet> categoryRules, {
    required String category,
    required String matchType,
    String note = '',
  }) {
    return findRuleEntryForMatch(
      categoryRules,
      category: category,
      matchType: matchType,
      note: note,
    )?.value;
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
}
