import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';

/// 部門ルールセットの探索・照合（ルックアップ）を担当するヘルパークラス
class CategoryRuleLookupHelper {
  /// ルールキーから部門の基底名（「（個人戦）」などのサフィックスを除いた名称）を取得
  static String cleanCategoryBaseName(String ruleKey) {
    final base = ruleKey
        .trim()
        .replaceAll(
          RegExp(
            r'[\(（](個人戦|団体戦|勝ち抜き戦|勝抜|リーグ個人戦|リーグ団体戦|リーグ戦|剣道形|日本剣道形|錬成会|申合せ|\d+)[\)）]$',
          ),
          '',
        )
        .trim();
    return base.isEmpty ? ruleKey.trim() : base;
  }

  /// 試合形式文字列（またはカテゴリ名・メモ等）から正規化された種別（個人戦 / 団体戦 / リーグ個人戦 / リーグ団体戦 / 勝ち抜き戦 / 剣道形 / 錬成会）を判定
  static String normalizeMatchType(String type, {String text = ''}) {
    final combined = '$type $text';
    if (combined.contains('形') ||
        combined.contains('稽古法') ||
        combined.contains('木刀')) {
      return '剣道形';
    }
    if (combined.contains('勝ち抜き') || combined.contains('勝抜')) {
      return '勝ち抜き戦';
    }
    if (combined.contains('リーグ')) {
      if (combined.contains('個人') || type == '選手') {
        return 'リーグ個人戦';
      }
      return 'リーグ団体戦';
    }
    if (combined.contains('個人') || type == '選手') {
      return '個人戦';
    }
    if (combined.contains('錬成') || combined.contains('申合')) {
      return '錬成会';
    }
    return '団体戦';
  }

  /// ルールセットエントリから種別（個人戦 / 団体戦 / リーグ個人戦 / リーグ団体戦 / 勝ち抜き戦 / 剣道形 / 錬成会）を判定
  static String getRuleEntryMatchType(MapEntry<String, CategoryRuleSet> entry) {
    final set = entry.value;

    // 1. normalRuleのフラグによる優先判定
    if (set.normalRule.isKataMatch) return '剣道形';
    if (set.normalRule.isKachinuki) return '勝ち抜き戦';
    if (set.normalRule.isLeague) {
      if (set.matchType.contains('個人') || entry.key.contains('個人')) {
        return 'リーグ個人戦';
      }
      return 'リーグ団体戦';
    }
    if (set.normalRule.isRenseikai) return '錬成会';

    // 2. set.matchType（明示された試合形式設定）による判定
    if (set.matchType.isNotEmpty) {
      final mt = set.matchType;
      if (mt.contains('形') || mt.contains('稽古法') || mt.contains('木刀')) {
        return '剣道形';
      }
      if (mt.contains('勝ち抜き') || mt.contains('勝抜')) {
        return '勝ち抜き戦';
      }
      if (mt.contains('リーグ')) {
        if (mt.contains('個人')) return 'リーグ個人戦';
        return 'リーグ団体戦';
      }
      if (mt.contains('個人')) return '個人戦';
      if (mt.contains('錬成') || mt.contains('申合')) return '錬成会';
      if (mt.contains('団体')) return '団体戦';
    }

    // 3. キー名（部門名）に含まれる明示的キーワード判定（subtitleは参照しない）
    final key = entry.key;
    if (key.contains('形') || key.contains('稽古法') || key.contains('木刀')) {
      return '剣道形';
    }
    if (key.contains('勝ち抜き') || key.contains('勝抜')) {
      return '勝ち抜き戦';
    }
    if (key.contains('個人')) {
      return '個人戦';
    }
    if (key.contains('錬成') || key.contains('申合')) {
      return '錬成会';
    }

    return '団体戦';
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
    if (matchType != null && matchType.isNotEmpty) {
      final targetType = normalizeMatchType(matchType, text: cleanCat);
      final typeMatches = allMatches.where((entry) {
        final entryType = getRuleEntryMatchType(entry);
        return entryType == targetType;
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

    // 1. 試合形式（matchType）に基づく絞り込みを最優先プールとして作成
    final targetType = normalizeMatchType(
      matchType,
      text: '$category ${note.trim()}',
    );
    final typeMatchedCandidates = candidates.where((entry) {
      return getRuleEntryMatchType(entry) == targetType;
    }).toList();

    // 種別一致候補があればそれを優先探索プールとする（種別を跨いだ誤爆を防止）
    final searchPool = typeMatchedCandidates.isNotEmpty
        ? typeMatchedCandidates
        : candidates;

    // 2. note が指定されている場合、確定した探索プール内でのみ subtitle やキーワード照合を行う
    final cleanNote = note.trim();
    if (cleanNote.isNotEmpty) {
      for (final entry in searchPool) {
        final sub = entry.value.subtitle.trim();
        if (sub.isNotEmpty &&
            (cleanNote.contains(sub) || sub.contains(cleanNote))) {
          return entry;
        }
      }

      // 「予選」「決勝」「準決勝」「トーナメント」「リーグ」などのキーワード照合
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
          for (final entry in searchPool) {
            if (entry.value.subtitle.contains(kw) || entry.key.contains(kw)) {
              return entry;
            }
          }
        }
      }
    }

    // 3. キー完全一致があれば選択、なければ探索プールの先頭を採用
    return searchPool.firstWhere(
      (entry) => entry.key == category.trim(),
      orElse: () => searchPool.first,
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
