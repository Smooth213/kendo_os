import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_header.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_list_tile_card.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 観客席画面用 個人戦 選手単位カード（ExpansionTile）
class ViewerIndividualPlayerCard extends StatelessWidget {
  final String playerName;
  final List<MatchModel> playerMatches;
  final String matchLabel;

  const ViewerIndividualPlayerCard({
    super.key,
    required this.playerName,
    required this.playerMatches,
    required this.matchLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool pInProgress = playerMatches.any(
      (m) => m.status == 'in_progress',
    );
    final bool pAllFinished = playerMatches.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );

    final Color pTitleColor = pAllFinished
        ? context.appColors.subTextColor
        : (context.appColors.textColor);

    final Color cardBg = pAllFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? context.appColors.cardBackground : const Color(0xFFFFFFFF));
    final Color collapsedCardBg = pAllFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? context.appColors.cardBackground : const Color(0xFFFAFAFC));

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: pInProgress
              ? AppKendoColors.hansokuRed.withValues(alpha: 0.6)
              : (isDark
                    ? const Color(0xFF2C2C2E)
                    : context.appColors.separatorColor),
          width: pInProgress ? 1.5 : 1.0,
        ),
        boxShadow: pInProgress
            ? [
                BoxShadow(
                  color: AppKendoColors.hansokuRed.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.smooth,
        child: ExpansionTileTheme(
          data: ExpansionTileThemeData(
            backgroundColor: cardBg,
            collapsedBackgroundColor: collapsedCardBg,
            iconColor: context.appColors.primaryAccent,
            collapsedIconColor: context.appColors.subTextColor,
            textColor: context.appColors.textColor,
            collapsedTextColor: isDark
                ? AppKendoColors.pureWhite.withValues(alpha: 0.7)
                : AppKendoColors.pureBlack.withValues(alpha: 0.54),
          ),
          child: ExpansionTile(
            collapsedBackgroundColor: collapsedCardBg,
            backgroundColor: cardBg,
            shape: const Border(),
            collapsedShape: const Border(),
            childrenPadding: EdgeInsets.zero,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            title: TimelineIndividualPlayerHeader(
              playerName: playerName,
              playerMatches: playerMatches,
              isDark: isDark,
              isReadOnlyUI: true,
              titleColor: pTitleColor,
            ),
            children: playerMatches
                .map(
                  (match) => ViewerMatchListTileCard(
                    key: Key('viewer_match_card_${match.id}'),
                    initialMatch: match,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
