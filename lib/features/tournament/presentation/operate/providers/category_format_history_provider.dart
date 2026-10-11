import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

/// 🏆 カテゴリと試合形式のプリセット項目
class CategoryFormatPresetItem {
  final String majorCategory;
  final String minorCategory;
  final String category;
  final String matchType;
  final int count;
  final int lastUsedAt;

  const CategoryFormatPresetItem({
    required this.majorCategory,
    required this.minorCategory,
    required this.category,
    required this.matchType,
    this.count = 1,
    this.lastUsedAt = 0,
  });

  /// チップやバッジ表示用のコンパクトなラベル
  String get displayLabel {
    final catLabel = category.replaceAll('の部', '').trim();
    // 試合形式の表記を少し簡潔に整形（例: 団体戦（5人制） -> 団体 5人制）
    final cleanFormat = matchType
        .replaceAll('（', ' ')
        .replaceAll('）', '')
        .replaceAll('戦', '');
    return '$catLabel / $cleanFormat';
  }

  Map<String, dynamic> toJson() => {
    'majorCategory': majorCategory,
    'minorCategory': minorCategory,
    'category': category,
    'matchType': matchType,
    'count': count,
    'lastUsedAt': lastUsedAt,
  };

  factory CategoryFormatPresetItem.fromJson(Map<String, dynamic> json) {
    return CategoryFormatPresetItem(
      majorCategory: json['majorCategory'] as String? ?? '小学生',
      minorCategory: json['minorCategory'] as String? ?? '全体',
      category: json['category'] as String? ?? '小学生の部',
      matchType: json['matchType'] as String? ?? '団体戦（5人制）',
      count: (json['count'] as num?)?.toInt() ?? 1,
      lastUsedAt: (json['lastUsedAt'] as num?)?.toInt() ?? 0,
    );
  }

  CategoryFormatPresetItem copyWith({
    String? majorCategory,
    String? minorCategory,
    String? category,
    String? matchType,
    int? count,
    int? lastUsedAt,
  }) {
    return CategoryFormatPresetItem(
      majorCategory: majorCategory ?? this.majorCategory,
      minorCategory: minorCategory ?? this.minorCategory,
      category: category ?? this.category,
      matchType: matchType ?? this.matchType,
      count: count ?? this.count,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

/// 🏆 カテゴリ・試合形式の使用履歴・頻度集計 Notifier
class CategoryFormatHistoryNotifier
    extends Notifier<List<CategoryFormatPresetItem>> {
  static const _key = 'kendo_category_format_history_v1';
  static const _maxHistoryItems = 20;

  /// 初期デフォルトプリセット（剣道大会で高頻度の定番）
  static const List<CategoryFormatPresetItem> defaultPresets = [
    CategoryFormatPresetItem(
      majorCategory: '小学生',
      minorCategory: '高学年',
      category: '小学生高学年の部',
      matchType: '団体戦（5人制）',
      count: 0,
    ),
    CategoryFormatPresetItem(
      majorCategory: '小学生',
      minorCategory: '低学年',
      category: '小学生低学年の部',
      matchType: '団体戦（5人制）',
      count: 0,
    ),
    CategoryFormatPresetItem(
      majorCategory: '中学生',
      minorCategory: '男子',
      category: '中学生男子の部',
      matchType: '団体戦（5人制）',
      count: 0,
    ),
    CategoryFormatPresetItem(
      majorCategory: '中学生',
      minorCategory: '女子',
      category: '中学生女子の部',
      matchType: '団体戦（5人制）',
      count: 0,
    ),
    CategoryFormatPresetItem(
      majorCategory: '中学生',
      minorCategory: '全体',
      category: '中学生の部',
      matchType: '個人戦',
      count: 0,
    ),
  ];

  @override
  List<CategoryFormatPresetItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonString = prefs.getString(_key);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map(
              (item) => CategoryFormatPresetItem.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  /// チーム登録時などに使用実績を記録
  Future<void> recordUsage({
    required String majorCategory,
    required String minorCategory,
    required String category,
    required String matchType,
  }) async {
    final currentList = List<CategoryFormatPresetItem>.from(state);
    final now = DateTime.now().millisecondsSinceEpoch;

    final existingIndex = currentList.indexWhere(
      (item) => item.category == category && item.matchType == matchType,
    );

    if (existingIndex >= 0) {
      final existing = currentList[existingIndex];
      currentList[existingIndex] = existing.copyWith(
        majorCategory: majorCategory,
        minorCategory: minorCategory,
        count: existing.count + 1,
        lastUsedAt: now,
      );
    } else {
      currentList.insert(
        0,
        CategoryFormatPresetItem(
          majorCategory: majorCategory,
          minorCategory: minorCategory,
          category: category,
          matchType: matchType,
          count: 1,
          lastUsedAt: now,
        ),
      );
    }

    // 上限件数に制限
    if (currentList.length > _maxHistoryItems) {
      currentList.sort((a, b) {
        final countCompare = b.count.compareTo(a.count);
        if (countCompare != 0) return countCompare;
        return b.lastUsedAt.compareTo(a.lastUsedAt);
      });
      currentList.removeRange(_maxHistoryItems, currentList.length);
    }

    state = currentList;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _key,
      jsonEncode(currentList.map((e) => e.toJson()).toList()),
    );
  }

  /// 使用頻度上位（＋初期プリセット補完）の上位N件を取得
  List<CategoryFormatPresetItem> getTopPresets({int limit = 4}) {
    final sorted = List<CategoryFormatPresetItem>.from(state)
      ..sort((a, b) {
        final countCompare = b.count.compareTo(a.count);
        if (countCompare != 0) return countCompare;
        return b.lastUsedAt.compareTo(a.lastUsedAt);
      });

    final result = <CategoryFormatPresetItem>[];
    for (final item in sorted) {
      if (result.length >= limit) break;
      result.add(item);
    }

    // 足りない分はデフォルトプリセットから重複なしで補充
    if (result.length < limit) {
      for (final def in defaultPresets) {
        if (result.length >= limit) break;
        final alreadyExists = result.any(
          (r) => r.category == def.category && r.matchType == def.matchType,
        );
        if (!alreadyExists) {
          result.add(def);
        }
      }
    }

    return result;
  }
}

final categoryFormatHistoryProvider =
    NotifierProvider<
      CategoryFormatHistoryNotifier,
      List<CategoryFormatPresetItem>
    >(() {
      return CategoryFormatHistoryNotifier();
    });
