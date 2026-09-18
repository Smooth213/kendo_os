import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 登録済みチーム一覧カードウィジェット
class RegisteredTeamCard extends StatelessWidget {
  final TeamModel team;
  final AppThemeColors themeColors;
  final void Function(TeamModel team) onEditTeam;
  final void Function(String teamId) onDeleteTeam;
  final void Function(TeamModel team) onChangeCategory;

  const RegisteredTeamCard({
    super.key,
    required this.team,
    required this.themeColors,
    required this.onEditTeam,
    required this.onDeleteTeam,
    required this.onChangeCategory,
  });

  List<String> _getPosNames(String matchType, int count) {
    List<String> base;
    if (matchType.contains('3人制')) {
      base = ['先鋒', '中堅', '大将'];
    } else if (matchType.contains('個人戦')) {
      base = ['選手'];
    } else if (matchType.contains('7人制')) {
      base = ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
    } else {
      base = ['先鋒', '次鋒', '中堅', '副将', '大将'];
    }
    while (base.length < count) {
      base.add('補欠');
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final inputBgColor = themeColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;
    final accentColor = themeColors.primaryAccent;
    final posNames = _getPosNames(team.matchType, team.playerNames.length);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      color: inputBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.mediumValue),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.mediumValue),
        onTap: () => onEditTeam(team),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1段目: カテゴリバッジ（タップで変更） & 編集/削除アクション
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => onChangeCategory(team),
                    borderRadius: BorderRadius.circular(AppRadius.smallValue),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppRadius.smallValue,
                        ),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            team.category,
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 編集ボタン
                      InkWell(
                        onTap: () => onEditTeam(team),
                        borderRadius: BorderRadius.circular(
                          AppRadius.smallValue,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppRadius.smallValue,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 13, color: accentColor),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '編集',
                                style: TextStyle(
                                  fontSize: AppFontSize.caption,
                                  fontWeight: AppFontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppKendoColors.red,
                          size: 20,
                        ),
                        tooltip: 'チームを削除',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        onPressed: () => onDeleteTeam(team.id),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // 2段目: チーム名
              Text(
                team.teamName,
                style: TextStyle(
                  fontSize: AppFontSize.headline,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                team.matchType,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  color: subTextColor,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // 3段目: ポジション付き選手一覧チップ
              Wrap(
                spacing: AppSpacing.subValue,
                runSpacing: AppSpacing.subValue,
                children: List.generate(team.playerNames.length, (i) {
                  final name = team.playerNames[i];
                  if (name.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final pos = i < posNames.length ? posNames[i] : '選手';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C35)
                          : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pos,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.medium,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
