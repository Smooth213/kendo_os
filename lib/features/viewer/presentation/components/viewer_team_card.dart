import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_individual_player_card.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 観客席画面用 チーム単位カード（外枠カード）
class ViewerTeamCard extends StatelessWidget {
  final String teamName;
  final List<MatchModel> teamMatchesList;
  final List<String> ownTeams;
  final String sanitizedQuery;
  final Set<String> matchedMatchIds;
  final Set<String> matchedGroupNames;

  const ViewerTeamCard({
    super.key,
    required this.teamName,
    required this.teamMatchesList,
    required this.ownTeams,
    required this.sanitizedQuery,
    required this.matchedMatchIds,
    required this.matchedGroupNames,
  });

  String _getMatchLabel(MatchModel m) {
    final bool isLeague = m.note.contains('[リーグ戦]');
    final bool isKachinuki = m.isKachinuki;
    final bool isIndividual =
        !isKachinuki && (m.matchType == 'individual' || m.matchType == '選手');

    if (isLeague) {
      return isIndividual ? '個人戦/リーグ戦' : '団体戦/リーグ戦';
    }
    if (isKachinuki) return '団体戦/勝ち抜き戦';
    return isIndividual ? '個人戦' : '団体戦';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final catGroupedMatches = <String, List<MatchModel>>{};
    final catIndividualMatches = <MatchModel>[];

    for (var m in teamMatchesList) {
      final bool forceIndividual =
          sanitizedQuery.isNotEmpty &&
          matchedMatchIds.contains(m.id) &&
          (m.groupName == null || !matchedGroupNames.contains(m.groupName!));

      if (!forceIndividual && m.groupName != null && m.groupName!.isNotEmpty) {
        catGroupedMatches.putIfAbsent(m.groupName!, () => []).add(m);
      } else {
        catIndividualMatches.add(m);
      }
    }

    final actualGroupedMatches = <String, List<MatchModel>>{};
    for (var entry in catGroupedMatches.entries) {
      final firstMatch = entry.value.first;
      final bool isLeagueMatch = firstMatch.note.contains('[リーグ戦]');
      final bool isPureIndividual =
          !firstMatch.isKachinuki &&
          (firstMatch.matchType == 'individual' ||
              firstMatch.matchType == '選手' ||
              firstMatch.matchType.contains('個人戦'));

      if (!isPureIndividual &&
          (entry.value.length > 1 || firstMatch.isKachinuki)) {
        actualGroupedMatches[entry.key] = entry.value;
      } else if (isLeagueMatch) {
        actualGroupedMatches[entry.key] = entry.value;
      } else {
        catIndividualMatches.addAll(entry.value);
      }
    }

    final matchesByPlayer = <String, List<MatchModel>>{};
    for (var m in catIndividualMatches) {
      String playerName = '選手名不明';

      final bool forceIndividual =
          sanitizedQuery.isNotEmpty &&
          matchedMatchIds.contains(m.id) &&
          (m.groupName == null || !matchedGroupNames.contains(m.groupName!));
      if (forceIndividual) {
        final String rPlayer = m.redName.contains(':')
            ? m.redName.split(':').last.trim()
            : m.redName;
        final String wPlayer = m.whiteName.contains(':')
            ? m.whiteName.split(':').last.trim()
            : m.whiteName;
        final bool rHit = rPlayer
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase()
            .contains(sanitizedQuery);
        final bool wHit = wPlayer
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase()
            .contains(sanitizedQuery);
        if (rHit) {
          playerName = rPlayer;
        } else if (wHit) {
          playerName = wPlayer;
        } else {
          final rTeam = m.redName.contains(':')
              ? m.redName.split(':').first.trim()
              : m.redName;
          final wTeam = m.whiteName.contains(':')
              ? m.whiteName.split(':').first.trim()
              : m.whiteName;
          final isRedOwn =
              ownTeams.contains(rTeam) ||
              (m.rule?.teamName.isNotEmpty == true &&
                  rTeam == m.rule!.teamName);
          final isWhiteOwn =
              ownTeams.contains(wTeam) ||
              (m.rule?.teamName.isNotEmpty == true &&
                  wTeam == m.rule!.teamName);
          if (isWhiteOwn && !isRedOwn) {
            playerName = wPlayer;
          } else if (isRedOwn && !isWhiteOwn) {
            playerName = rPlayer;
          } else {
            playerName = m.redName.contains(teamName) ? rPlayer : wPlayer;
          }
        }
      } else {
        final rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : m.redName;
        final wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : m.whiteName;
        final isRedOwn =
            ownTeams.contains(rTeam) ||
            (m.rule?.teamName.isNotEmpty == true && rTeam == m.rule!.teamName);
        final isWhiteOwn =
            ownTeams.contains(wTeam) ||
            (m.rule?.teamName.isNotEmpty == true && wTeam == m.rule!.teamName);

        if (isWhiteOwn && !isRedOwn) {
          playerName = m.whiteName.contains(':')
              ? m.whiteName.split(':').last.trim()
              : m.whiteName;
        } else if (isRedOwn && !isWhiteOwn) {
          playerName = m.redName.contains(':')
              ? m.redName.split(':').last.trim()
              : m.redName;
        } else {
          if (m.redName.contains(teamName)) {
            playerName = m.redName.contains(':')
                ? m.redName.split(':').last.trim()
                : m.redName;
          } else if (m.whiteName.contains(teamName)) {
            playerName = m.whiteName.contains(':')
                ? m.whiteName.split(':').last.trim()
                : m.whiteName;
          } else {
            playerName = m.redName.contains(teamName)
                ? (m.redName.contains(':')
                      ? m.redName.split(':').last.trim()
                      : m.redName)
                : (m.whiteName.contains(':')
                      ? m.whiteName.split(':').last.trim()
                      : m.whiteName);
          }
        }
      }
      matchesByPlayer.putIfAbsent(playerName, () => []).add(m);
    }

    final sortedGroups = actualGroupedMatches.entries.toList()
      ..sort((a, b) => a.value.first.order.compareTo(b.value.first.order));
    final sortedPlayers = matchesByPlayer.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
          width: 2,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : context.appColors.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.modernValue),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : context.appColors.separatorColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: context.appColors.primaryAccent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    teamName,
                    style: TextStyle(
                      fontSize: AppFontSize.headline,
                      fontWeight: AppFontWeight.bold,
                      color: isDark
                          ? AppKendoColors.pureWhite
                          : context.appColors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...(() {
            String lastGroupLabel = '';

            return sortedGroups.map((entry) {
              final groupList = entry.value;
              final firstMatch = groupList.first;
              final label = _getMatchLabel(firstMatch);

              Widget? headerWidget;
              if (label != lastGroupLabel) {
                headerWidget = Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    top: AppSpacing.md,
                    bottom: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups,
                        color: context.appColors.subTextColor,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: AppFontSize.bodySmall,
                          fontWeight: AppFontWeight.bold,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                );
                lastGroupLabel = label;
              }

              return ViewerGroupMatchCard(
                groupKey: entry.key,
                groupList: groupList,
                matchLabel: label,
                headerWidget: headerWidget,
                ownTeams: ownTeams,
              );
            });
          })(),
          if (sortedPlayers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                top: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    sanitizedQuery.isNotEmpty
                        ? Icons.manage_search
                        : Icons.person,
                    color: AppKendoColors.orangeAccent,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    sanitizedQuery.isNotEmpty ? '抽出された個別試合' : '個人戦',
                    style: const TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),
            ...sortedPlayers.map((playerEntry) {
              final playerName = playerEntry.key;
              final playerMatches = playerEntry.value;
              final firstMatch = playerMatches.first;
              final label = _getMatchLabel(firstMatch);

              return ViewerIndividualPlayerCard(
                playerName: playerName,
                playerMatches: playerMatches,
                matchLabel: label,
              );
            }),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
