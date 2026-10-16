import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_team_match_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_summary_input_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_ui_state_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムライン内の団体リーグ戦・対戦カード（チーム対抗戦）ごとのアコーディオンWidget
class TimelineLeagueMatchupTile extends ConsumerWidget {
  final String matchupName;
  final List<MatchModel> bouts;
  final List<String> ownTeams;
  final bool isReadOnlyUI;
  final bool isDark;
  final PermissionState permissions;

  const TimelineLeagueMatchupTile({
    super.key,
    required this.matchupName,
    required this.bouts,
    required this.ownTeams,
    required this.isReadOnlyUI,
    required this.isDark,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expansionVersion = ref.watch(timelineExpansionVersionProvider);
    final isAllExpanded = ref.watch(timelineAllExpandedProvider);

    final bool boutsInProgress = bouts.any((m) => m.status == 'in_progress');
    final bool boutsAllFinished = bouts.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );

    final parts = matchupName.split(' vs ');
    final t1 = parts.isNotEmpty ? parts[0] : '';
    final t2 = parts.length > 1 ? parts[1] : '';

    final Color mTitleColor = boutsAllFinished
        ? (context.appColors.subTextColor)
        : (context.appColors.textColor);

    final Color cardBg = boutsAllFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? context.appColors.cardBackground : const Color(0xFFFFFFFF));
    final Color collapsedCardBg = boutsAllFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? context.appColors.cardBackground : const Color(0xFFFAFAFC));

    return Container(
      key: ValueKey('league_team_$matchupName'),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: boutsInProgress
              ? AppKendoColors.hansokuRed.withValues(alpha: 0.6)
              : (isDark
                    ? const Color(0xFF38383A)
                    : context.appColors.separatorColor),
          width: boutsInProgress ? 1.5 : 1.0,
        ),
        boxShadow: boutsInProgress
            ? [
                BoxShadow(
                  color: AppKendoColors.hansokuRed.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                ? context.appColors.textColor.withValues(alpha: 0.7)
                : context.appColors.cardBackground.withValues(alpha: 0.54),
          ),
          child: ExpansionTile(
            key: expansionVersion == 0
                ? ValueKey('tile_league_team_$matchupName')
                : ValueKey('tile_league_team_${matchupName}_$expansionVersion'),
            initiallyExpanded: isAllExpanded || boutsInProgress,
            shape: const Border(),
            collapsedShape: const Border(),
            childrenPadding: EdgeInsets.zero,
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            title: TimelineLeagueTeamMatchHeader(
              bouts: bouts,
              isReadOnlyUI: isReadOnlyUI,
              boutsAllFinished: boutsAllFinished,
              boutsInProgress: boutsInProgress,
              t1: t1,
              t2: t2,
              ownTeams: ownTeams,
              mTitleColor: mTitleColor,
              isDark: isDark,
              onShowSummaryInputDialog: (ctx, r, list) =>
                  TimelineSummaryInputDialog.show(ctx, r, list),
            ),
            children: bouts
                .map(
                  (m) =>
                      MatchListTileCard(key: ValueKey(m.id), initialMatch: m),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
