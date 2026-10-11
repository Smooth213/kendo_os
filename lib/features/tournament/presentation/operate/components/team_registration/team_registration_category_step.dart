import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/category_cascade_selector_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_format_selector_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_quick_badges.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/category_format_history_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🏆 チーム登録: 出場カテゴリ・試合形式選択ステップ（PAGE 1）
class TeamRegistrationCategoryStep extends StatelessWidget {
  final String selectedMajorCategory;
  final String selectedMinorCategory;
  final String selectedCategory;
  final String matchType;
  final AppThemeColors themeColors;
  final ValueChanged<String> onMajorCategoryChanged;
  final ValueChanged<String> onMinorCategoryChanged;
  final ValueChanged<String> onMatchTypeChanged;
  final String customCategoryName;
  final ValueChanged<String>? onCustomCategoryChanged;
  final ValueChanged<CategoryFormatPresetItem>? onPresetSelected;

  // 後方互換性用（新UIではインライン展開のため不要だがインターフェース維持）
  final bool showExtraMajorCategories;
  final bool showExtraMatchTypes;
  final VoidCallback? onToggleExtraMajorCategories;
  final VoidCallback? onToggleExtraMatchTypes;

  static const List<String> mainMajorCategories = ['初心者', '幼年', '小学生', '中学生'];
  static const List<String> extraMajorCategories = ['高校生', '大学・一般', 'その他'];

  static const List<String> mainMatchTypes = [
    '団体戦（5人制）',
    '団体戦（3人制）',
    '勝ち抜き戦（5人制）',
    '勝ち抜き戦（3人制）',
    '個人戦',
  ];
  static const List<String> extraMatchTypes = [
    'リーグ団体戦',
    'リーグ個人戦',
    '団体戦（7人制）',
    '団体戦（それ以上）',
    '勝ち抜き戦（7人制）',
    '勝ち抜き戦（それ以上）',
  ];

  const TeamRegistrationCategoryStep({
    super.key,
    required this.selectedMajorCategory,
    required this.selectedMinorCategory,
    required this.selectedCategory,
    required this.matchType,
    required this.themeColors,
    required this.onMajorCategoryChanged,
    required this.onMinorCategoryChanged,
    required this.onMatchTypeChanged,
    this.customCategoryName = '',
    this.onCustomCategoryChanged,
    this.onPresetSelected,
    this.showExtraMajorCategories = false,
    this.showExtraMatchTypes = false,
    this.onToggleExtraMajorCategories,
    this.onToggleExtraMatchTypes,
  });

  /// 他画面からの参照互換性のための静的ヘルパー
  static List<String> getMinorCategories(String major) {
    return CategoryCascadeSelectorView.getMinorCategories(major);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppFontSize.subhead,
          fontWeight: AppFontWeight.bold,
          color: themeColors.primaryAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.appColors.textColor;
    final accentColor = themeColors.primaryAccent;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(
          '出場するカテゴリと\n試合形式を選んでください',
          style: TextStyle(
            fontSize: AppFontSize.titleLarge,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ⚡ クイックバッジ（よく使う組み合わせ）
        if (onPresetSelected != null) ...[
          TeamRegistrationQuickBadges(
            themeColors: themeColors,
            onPresetSelected: onPresetSelected!,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // 1. 出場カテゴリ（大分類 ＋ 連動サブコンテナ）
        _buildSectionTitle('1. 出場カテゴリ'),
        CategoryCascadeSelectorView(
          selectedMajorCategory: selectedMajorCategory,
          selectedMinorCategory: selectedMinorCategory,
          customCategoryName: customCategoryName,
          themeColors: themeColors,
          onCategoryChanged:
              ({
                required majorCategory,
                required minorCategory,
                customCategoryName,
              }) {
                if (majorCategory != selectedMajorCategory) {
                  onMajorCategoryChanged(majorCategory);
                }
                if (minorCategory != selectedMinorCategory) {
                  onMinorCategoryChanged(minorCategory);
                }
                if (customCategoryName != null &&
                    onCustomCategoryChanged != null) {
                  onCustomCategoryChanged!(customCategoryName);
                }
              },
        ),
        const SizedBox(height: AppSpacing.xl),

        // 2. 試合形式（5大分類 ＋ 詳細展開）
        _buildSectionTitle('2. 試合形式'),
        MatchFormatSelectorView(
          currentMatchType: matchType,
          themeColors: themeColors,
          onMatchTypeChanged: onMatchTypeChanged,
        ),
        const SizedBox(height: AppSpacing.xl),

        // 3. リアルタイムサマリーカード（カテゴリ ＋ 試合形式）
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: themeColors.softAccent,
            borderRadius: BorderRadius.circular(AppRadius.mediumValue),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: accentColor),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '選択中の設定内容',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '【部門】',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      selectedCategory,
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.subhead,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '【形式】',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      matchType,
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.subhead,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
