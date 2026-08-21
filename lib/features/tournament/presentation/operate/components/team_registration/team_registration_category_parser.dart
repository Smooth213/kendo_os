typedef CategoryStateResult = ({String majorCategory, String minorCategory});

/// チーム登録画面のカテゴリ文字列・状態相互変換パーサー
class TeamRegistrationCategoryParser {
  /// メジャー・マイナーカテゴリから表示用の完全なカテゴリ名を生成
  static String formatCategoryName({
    required String majorCategory,
    required String minorCategory,
  }) {
    if (majorCategory == '初心者') {
      return '初心者の部';
    }
    if (majorCategory == '幼年') {
      return '幼年の部';
    }
    if (minorCategory == '全体') {
      return '$majorCategoryの部';
    }
    if (majorCategory == '大学・一般') {
      return '$minorCategoryの部';
    }
    return '$majorCategory$minorCategoryの部';
  }

  /// 保存されたカテゴリ文字列からメジャー・マイナーカテゴリ状態を復元
  static CategoryStateResult parseCategoryToState(String categoryName) {
    if (categoryName == '初心者の部') {
      return (majorCategory: '初心者', minorCategory: '全体');
    }
    if (categoryName == '幼年の部') {
      return (majorCategory: '幼年', minorCategory: '全体');
    }
    final cleanCat = categoryName.replaceAll('の部', '');
    if (['大学生', '一般', 'シニア'].contains(cleanCat)) {
      return (majorCategory: '大学・一般', minorCategory: cleanCat);
    }
    for (var major in ['幼年', '小学生', '中学生', '高校生']) {
      if (cleanCat.startsWith(major)) {
        final minor = cleanCat.substring(major.length);
        return (
          majorCategory: major,
          minorCategory: minor.isEmpty ? '全体' : minor,
        );
      }
    }
    return (majorCategory: '小学生', minorCategory: '低学年');
  }
}
