import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_selection_card.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 選手選択シート上部のアクション群（助っ人登録カード、未定・欠員ボタン、既存手入力選手）
class TeamRegistrationSelectHeaderActions extends StatelessWidget {
  final String query;
  final int currentIndex;
  final List<String> posNames;
  final List<MapEntry<int, String>> helperEntries;
  final AppThemeColors themeColors;
  final bool isDark;
  final Color textColor;
  final ValueChanged<String> onSelected;

  const TeamRegistrationSelectHeaderActions({
    super.key,
    required this.query,
    required this.currentIndex,
    required this.posNames,
    required this.helperEntries,
    required this.themeColors,
    required this.isDark,
    required this.textColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 助っ人即時登録カード（テキスト入力時に最上部に表示）
        if (query.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InkWell(
              onTap: () => onSelected(query),
              borderRadius: AppRadius.medium,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: themeColors.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: themeColors.primaryAccent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: themeColors.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: AppKendoColors.pureWhite,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '助っ人として「$query」を登録',
                            style: TextStyle(
                              fontSize: AppFontSize.body,
                              fontWeight: AppFontWeight.bold,
                              color: themeColors.primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'タップしてこの名前で登録します',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              color: themeColors.subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: themeColors.primaryAccent,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // 未定・欠員ボタン
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onSelected('CLEAR_FLAG'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF545458)
                        : context.appColors.separatorColor,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.smallValue),
                  ),
                ),
                child: const Text(
                  '未定',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onSelected('欠員'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppKendoColors.redAccent,
                  side: BorderSide(
                    color: AppKendoColors.redAccent.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.smallValue),
                  ),
                ),
                child: const Text(
                  '欠員',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 現在チームにいる手入力選手
        if (helperEntries.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              '現在チームにいる手入力選手',
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
          ),
          ...helperEntries.map((entry) {
            if (entry.key == currentIndex) {
              return const SizedBox.shrink();
            }
            return TeamRegistrationSelectionCard(
              name: entry.value,
              subtitle: '手入力選手',
              isUsed: true,
              usedPos: entry.key < posNames.length ? posNames[entry.key] : '補欠',
              isDark: isDark,
              isHelper: true,
              onTap: () => onSelected(entry.value),
            );
          }),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
