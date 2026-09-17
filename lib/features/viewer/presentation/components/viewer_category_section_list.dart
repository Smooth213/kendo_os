import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_team_card.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 観客席画面用 部門別・チーム別リストセクション
class ViewerCategorySectionList extends StatelessWidget {
  final List<MapEntry<String, List<MatchModel>>> entries;
  final List<String> ownTeams;
  final String sanitizedQuery;
  final Set<String> matchedMatchIds;
  final Set<String> matchedGroupNames;
  final bool isDark;

  const ViewerCategorySectionList({
    super.key,
    required this.entries,
    required this.ownTeams,
    required this.sanitizedQuery,
    required this.matchedMatchIds,
    required this.matchedGroupNames,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      children: entries.map<Widget>((catEntry) {
        return ViewerCategorySection(
          key: ValueKey('category_section_${catEntry.key}'),
          categoryName: catEntry.key,
          matches: catEntry.value,
          ownTeams: ownTeams,
          sanitizedQuery: sanitizedQuery,
          matchedMatchIds: matchedMatchIds,
          matchedGroupNames: matchedGroupNames,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

/// 🛡️ 部門セクション描画ウィジェット（RepaintBoundaryによりGPU再描画を局所隔離）
class ViewerCategorySection extends StatelessWidget {
  final String categoryName;
  final List<MatchModel> matches;
  final List<String> ownTeams;
  final String sanitizedQuery;
  final Set<String> matchedMatchIds;
  final Set<String> matchedGroupNames;
  final bool isDark;

  const ViewerCategorySection({
    super.key,
    required this.categoryName,
    required this.matches,
    required this.ownTeams,
    required this.sanitizedQuery,
    required this.matchedMatchIds,
    required this.matchedGroupNames,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final sortedTeams = ViewerTeamGroupingHelper.groupAndSortTeams(
        matches: matches,
        ownTeams: ownTeams,
      );

      return RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: Color(0xFF607D8B),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...sortedTeams.map((teamEntry) {
              return ViewerTeamCard(
                teamName: teamEntry.key,
                teamMatchesList: teamEntry.value,
                ownTeams: ownTeams,
                sanitizedQuery: sanitizedQuery,
                matchedMatchIds: matchedMatchIds,
                matchedGroupNames: matchedGroupNames,
              );
            }),
          ],
        ),
      );
    } catch (e, stack) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'レンダリングエラー発生: $e\n$stack',
          style: const TextStyle(color: AppKendoColors.red),
        ),
      );
    }
  }
}

/// 🛡️ チーム集計・ソートの純粋関数ヘルパー（CPU計算負荷を分離）
class ViewerTeamGroupingHelper {
  static List<MapEntry<String, List<MatchModel>>> groupAndSortTeams({
    required List<MatchModel> matches,
    required List<String> ownTeams,
  }) {
    final matchesByTeam = <String, List<MatchModel>>{};
    final groupToOwnTeams = <String, Set<String>>{};
    final groupToRepresentativeTeam = <String, String>{};

    for (final m in matches) {
      if (m.groupName != null && m.groupName!.isNotEmpty) {
        final String rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : m.redName;
        final String wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : m.whiteName;
        final isRedOwnForM =
            ownTeams.contains(rTeam) ||
            (m.rule?.teamName.isNotEmpty == true && rTeam == m.rule!.teamName);
        final isWhiteOwnForM =
            ownTeams.contains(wTeam) ||
            (m.rule?.teamName.isNotEmpty == true && wTeam == m.rule!.teamName);
        if (isRedOwnForM) {
          groupToOwnTeams.putIfAbsent(m.groupName!, () => {}).add(rTeam);
        }
        if (isWhiteOwnForM) {
          groupToOwnTeams.putIfAbsent(m.groupName!, () => {}).add(wTeam);
        }

        if (!groupToRepresentativeTeam.containsKey(m.groupName!)) {
          groupToRepresentativeTeam[m.groupName!] =
              rTeam.isNotEmpty && !rTeam.contains('代表')
              ? rTeam
              : (wTeam.isNotEmpty && !wTeam.contains('代表') ? wTeam : '設定なし');
        }
      }
    }

    for (final m in matches) {
      final String rTeam = m.redName.contains(':')
          ? m.redName.split(':').first.trim()
          : m.redName;
      final String wTeam = m.whiteName.contains(':')
          ? m.whiteName.split(':').first.trim()
          : m.whiteName;

      final bool isRedOwn =
          ownTeams.contains(rTeam) ||
          (m.rule?.teamName.isNotEmpty == true && rTeam == m.rule!.teamName);
      final bool isWhiteOwn =
          ownTeams.contains(wTeam) ||
          (m.rule?.teamName.isNotEmpty == true && wTeam == m.rule!.teamName);

      if (m.groupName != null && m.groupName!.isNotEmpty) {
        if (groupToOwnTeams.containsKey(m.groupName!)) {
          for (final String team in groupToOwnTeams[m.groupName!]!) {
            matchesByTeam.putIfAbsent(team, () => []).add(m);
          }
        } else {
          final repTeam = groupToRepresentativeTeam[m.groupName!] ?? '設定なし';
          matchesByTeam.putIfAbsent(repTeam, () => []).add(m);
        }
      } else {
        if (isRedOwn) {
          matchesByTeam.putIfAbsent(rTeam, () => []).add(m);
        }
        if (isWhiteOwn && wTeam != rTeam) {
          matchesByTeam.putIfAbsent(wTeam, () => []).add(m);
        }
        if (!isRedOwn && !isWhiteOwn) {
          final keyTeam = rTeam.isNotEmpty && !rTeam.contains('代表')
              ? rTeam
              : (wTeam.isNotEmpty && !wTeam.contains('代表') ? wTeam : '設定なし');
          matchesByTeam.putIfAbsent(keyTeam, () => []).add(m);
        }
      }
    }

    final sortedTeams = matchesByTeam.entries.toList();
    sortedTeams.sort((a, b) => a.key.compareTo(b.key));
    return sortedTeams;
  }
}
