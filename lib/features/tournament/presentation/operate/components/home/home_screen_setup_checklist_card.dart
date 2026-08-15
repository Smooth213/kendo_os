import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 運営画面トップの「大会準備ステップ」初期セットアップチェックリストカード（純粋UIコンポーネント）
class HomeScreenSetupChecklistCard extends StatelessWidget {
  final TournamentModel tournament;
  final List<dynamic> teams;
  final AppThemeColors themeColors;
  final bool isDark;
  final bool enableLiquidGlass;
  final String tournamentId;

  const HomeScreenSetupChecklistCard({
    super.key,
    required this.tournament,
    required this.teams,
    required this.themeColors,
    required this.isDark,
    required this.enableLiquidGlass,
    required this.tournamentId,
  });

  Widget _buildChecklistItem({
    required String title,
    required bool isCompleted,
    required AppThemeColors themeColors,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final activeTextColor = themeColors.textColor;
    final inactiveTextColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.54)
        : const Color(0xFF000000).withValues(alpha: 0.54);

    return Material(
      color: AppKendoColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.small,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted
                    ? AppKendoColors.successGreen
                    : AppKendoColors.grey,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: isCompleted
                        ? AppFontWeight.medium
                        : AppFontWeight.bold,
                    color: isCompleted ? inactiveTextColor : activeTextColor,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (!isCompleted && onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  color: themeColors.primaryAccent,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTeams = teams.isNotEmpty;
    final hasRules = tournament.categoryRules.isNotEmpty;

    int completedSteps = 1; // 大会作成は常に完了
    if (hasTeams) completedSteps++;
    if (hasRules) completedSteps++;

    final progress = completedSteps / 4.0;

    final cardBgColor = enableLiquidGlass
        ? themeColors.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.08)
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));

    final cardBorder = enableLiquidGlass
        ? Border.all(
            color: isDark
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                : const Color(0xFF000000).withValues(alpha: 0.05),
            width: 0.5,
          )
        : Border.all(
            color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.assignment_turned_in,
              color: themeColors.primaryAccent,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '大会準備ステップ',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.textColor,
                ),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}% 完了',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
                color: themeColors.primaryAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: context.appColors.separatorColor,
          valueColor: AlwaysStoppedAnimation<Color>(themeColors.primaryAccent),
          minHeight: 6,
          borderRadius: AppRadius.tiny,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildChecklistItem(
          title: '大会基本情報の登録',
          isCompleted: true,
          themeColors: themeColors,
          isDark: isDark,
        ),
        _buildChecklistItem(
          title: '出場チーム・選手の登録',
          isCompleted: hasTeams,
          themeColors: themeColors,
          isDark: isDark,
          onTap: () => context.push('/team-registration/$tournamentId'),
        ),
        _buildChecklistItem(
          title: '部門別ルールの設定',
          isCompleted: hasRules,
          themeColors: themeColors,
          isDark: isDark,
          onTap: () => context.push('/tournament/$tournamentId/category-rules'),
        ),
        _buildChecklistItem(
          title: '最初の試合枠の作成',
          isCompleted: false,
          themeColors: themeColors,
          isDark: isDark,
          onTap: () => context.push('/setup-match/$tournamentId'),
        ),
      ],
    );

    if (enableLiquidGlass) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.large,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: AppRadius.large,
                border: cardBorder,
              ),
              child: content,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: AppRadius.large,
        border: cardBorder,
        boxShadow: [
          BoxShadow(
            color: AppKendoColors.pureBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}
