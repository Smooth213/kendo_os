import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              match.note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.7),
                fontWeight: AppFontWeight.bold,
              ),
              maxLines: 1,
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _getMatchTitle(match),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: AppFontWeight.bold,
                  ),
                  maxLines: 1,
                ),
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

    return AppGlassContainer(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSemanticTokens.cardRadius,
      borderWidth: AppSemanticTokens.cardBorderWidth,
      enableLiquidGlass: enableLiquidGlass,
      customBackgroundColor: bannerColor,
      child: bannerContent,
    );
  }
}
