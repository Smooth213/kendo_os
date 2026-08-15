import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 運営画面トップの「進行中・次試合」コールバナー（純粋UIコンポーネント）
class HomeScreenCallBanner extends StatelessWidget {
  final List<MatchModel> uniqueInProgress;
  final List<MatchModel> uniqueWaiting;
  final AppThemeColors themeColors;
  final bool isDark;
  final bool enableLiquidGlass;

  const HomeScreenCallBanner({
    super.key,
    required this.uniqueInProgress,
    required this.uniqueWaiting,
    required this.themeColors,
    required this.isDark,
    required this.enableLiquidGlass,
  });

  String _getMatchTitle(MatchModel match) {
    final isGrouped = match.groupName != null && match.groupName!.isNotEmpty;
    final isIndividual =
        match.matchType == 'individual' ||
        match.matchType == '選手' ||
        match.matchType.contains('個人戦');
    if (isGrouped && !isIndividual) {
      return '${match.redName.contains(':') ? match.redName.split(':').first.trim() : match.redName} vs ${match.whiteName.contains(':') ? match.whiteName.split(':').first.trim() : match.whiteName}';
    }
    return '${match.redName} vs ${match.whiteName.contains(':') ? '${match.whiteName.split(':')[1].trim()} : ${match.whiteName.split(':')[0].trim()}' : match.whiteName}';
  }

  Widget _buildCallRow(
    BuildContext context,
    String label,
    MatchModel match,
    Color textColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (match.note.isNotEmpty)
          Text(
            match.note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.7),
              fontWeight: AppFontWeight.bold,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                _getMatchTitle(match),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontWeight: AppFontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uniqueInProgress.isEmpty && uniqueWaiting.isEmpty) {
      return const SizedBox.shrink();
    }

    final bannerColor = enableLiquidGlass
        ? themeColors.primaryAccent.withValues(alpha: isDark ? 0.35 : 0.65)
        : themeColors.primaryAccent;

    final bannerDecoration = BoxDecoration(
      color: bannerColor,
      borderRadius: AppRadius.large,
      border: enableLiquidGlass
          ? Border.all(
              color: isDark
                  ? context.appColors.textColor.withValues(alpha: 0.15)
                  : const Color(0xFF000000).withValues(alpha: 0.08),
              width: 0.5,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: themeColors.primaryAccent.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    final bannerContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (uniqueInProgress.isNotEmpty)
          _buildCallRow(
            context,
            '進行中',
            uniqueInProgress.first,
            AppKendoColors.orangeAccent,
          ),
        if (uniqueInProgress.isNotEmpty && uniqueWaiting.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(
              color: AppKendoColors.pureWhite.withValues(alpha: 0.24),
              height: 1,
            ),
          ),
        if (uniqueWaiting.isNotEmpty)
          _buildCallRow(
            context,
            '次試合',
            uniqueWaiting.first,
            AppKendoColors.pureWhite,
          ),
        if (uniqueWaiting.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '次々試合: ${uniqueWaiting[1].note.isNotEmpty ? "(${uniqueWaiting[1].note}) " : ""}${_getMatchTitle(uniqueWaiting[1])}',
              style: TextStyle(
                color: AppKendoColors.pureWhite.withValues(alpha: 0.7),
                fontSize: AppFontSize.small,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    if (enableLiquidGlass) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.large,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: bannerDecoration,
              child: bannerContent,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: bannerDecoration,
      child: bannerContent,
    );
  }
}
