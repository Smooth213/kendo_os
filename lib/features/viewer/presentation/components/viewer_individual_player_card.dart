import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
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

    final Color pCardBg = pAllFinished
        ? (isDark ? const Color(0xFF161618) : context.appColors.inputBackground)
        : (context.appColors.cardBackground);

    final Color pTitleColor = pAllFinished
        ? context.appColors.subTextColor
        : (context.appColors.textColor);

    final Color pSubTitleColor = context.appColors.subTextColor;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark
              ? const Color(0xFF38383A)
              : context.appColors.separatorColor,
          width: 1,
        ),
        boxShadow: pInProgress
            ? [
                BoxShadow(
                  color: AppKendoColors.blue.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.smooth,
        child: ExpansionTile(
          collapsedBackgroundColor: pCardBg,
          backgroundColor: pCardBg,
          leading: CircleAvatar(
            backgroundColor: pAllFinished
                ? (isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0))
                : const Color(0xFFFFE0B2),
            child: Text(
              playerName.isNotEmpty ? playerName[0] : '?',
              style: TextStyle(
                color: pAllFinished
                    ? (isDark
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF757575))
                    : const Color(0xFFE65100),
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          title: Text(
            playerName,
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodyMedium,
              color: pTitleColor,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                '$matchLabel • ${playerMatches.length}試合',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: pSubTitleColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.subValue,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: pInProgress
                      ? const Color(0xFF546E7A)
                      : (pAllFinished
                            ? context.appColors.separatorColor
                            : (isDark
                                  ? const Color(0xFF2C2C2E)
                                  : context.appColors.separatorColor)),
                  borderRadius: AppRadius.tiny,
                ),
                child: Text(
                  pInProgress ? '進行中' : (pAllFinished ? '終了' : '待機中'),
                  style: TextStyle(
                    fontSize: AppFontSize.badge,
                    fontWeight: AppFontWeight.bold,
                    color: pInProgress
                        ? AppKendoColors.pureWhite
                        : context.appColors.subTextColor,
                  ),
                ),
              ),
            ],
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
    );
  }
}
