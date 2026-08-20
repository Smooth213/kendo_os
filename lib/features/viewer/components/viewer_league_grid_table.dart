import 'package:flutter/material.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_table_sections.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/league_grid_card.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

/// 🥋 観客席 公式記録画面の 星取り表（リーググリッド）コンポーネント
class ViewerLeagueGridTable extends StatelessWidget {
  final String groupName;
  final List<MatchListProjection> matches;
  final Color? cardColor;
  final bool isDark;
  final List<dynamic> stats;
  final bool isLeagueRule;

  const ViewerLeagueGridTable({
    super.key,
    required this.groupName,
    required this.matches,
    this.cardColor,
    required this.isDark,
    required this.stats,
    required this.isLeagueRule,
  });

  @override
  Widget build(BuildContext context) {
    final normalMatches = matches
        .where((m) => !m.note.contains('[順位決定戦]'))
        .toList();
    if (normalMatches.isEmpty) return const SizedBox();

    final isIndiv = normalMatches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );
    final allFinished = matches.every(
      (m) => m.status == 'approved' || m.status == 'finished',
    );
    final hasMatchPoints = isLeagueRule;

    String getEntityName(String fullName) {
      if (isIndiv) {
        return fullName.contains(':')
            ? fullName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
            : fullName.trim();
      }
      return fullName.contains(':')
          ? fullName.split(':').first.trim()
          : fullName.trim();
    }

    final teamSet = <String>{};
    for (var m in normalMatches) {
      teamSet.add(getEntityName(m.redName));
      teamSet.add(getEntityName(m.whiteName));
    }
    final teamList = teamSet.toList()..sort();

    String getStatName(dynamic s) => s is Map ? s['name'] : (s?.name ?? '');
    int getStatMatchWins(dynamic s) =>
        s is Map ? (s['matchWins'] ?? 0) : (s?.matchWins ?? 0);
    int getStatIndivWinners(dynamic s) =>
        s is Map ? (s['individualWinners'] ?? 0) : (s?.individualWinners ?? 0);
    int getStatTotalPts(dynamic s) =>
        s is Map ? (s['totalPointsScored'] ?? 0) : (s?.totalPointsScored ?? 0);
    double getStatCustomPts(dynamic s) => s == null
        ? 0.0
        : (s is Map
              ? ((s['customPoints'] ?? 0.0) as num).toDouble()
              : (s.customPoints as num).toDouble());

    final leagueTeams = teamList.map((rowTeam) {
      final stat = stats.where((s) => getStatName(s) == rowTeam).firstOrNull;
      final rankStr = allFinished
          ? '${stats.indexWhere((s) => getStatName(s) == rowTeam) + 1}'
          : '-';
      final customPts = getStatCustomPts(stat);
      return LeagueGridTeamInfo(
        teamName: rowTeam,
        matchWins: '${getStatMatchWins(stat)}',
        individualWinners: '${getStatIndivWinners(stat)}',
        totalPoints: '${getStatTotalPts(stat)}',
        customPoints: stat != null
            ? customPts.toStringAsFixed(
                customPts.truncateToDouble() == customPts ? 0 : 1,
              )
            : '0',
        rank: rankStr,
      );
    }).toList();

    final matrix = <String, Map<String, LeagueGridCellData>>{};
    for (var rowTeam in teamList) {
      matrix[rowTeam] = {};
      for (var colTeam in teamList) {
        if (rowTeam == colTeam) continue;

        final bouts = normalMatches.where((m) {
          final r = getEntityName(m.redName);
          final w = getEntityName(m.whiteName);
          return (r == rowTeam && w == colTeam) ||
              (r == colTeam && w == rowTeam);
        }).toList();

        if (bouts.isEmpty) continue;

        int rWins = 0,
            cWins = 0,
            rPoints = 0,
            cPoints = 0,
            rWinners = 0,
            cWinners = 0;
        List<PointMark> techs = [];
        for (var m in bouts) {
          final isRowRed = getEntityName(m.redName) == rowTeam;
          final rs = m.redScore;
          final ws = m.whiteScore;
          if (rs > ws) {
            isRowRed ? rWins++ : cWins++;
            isRowRed ? rWinners++ : cWinners++;
          } else if (ws > rs) {
            isRowRed ? cWins++ : rWins++;
            isRowRed ? cWinners++ : rWinners++;
          }
          isRowRed ? rPoints += rs : cPoints += rs;
          isRowRed ? cPoints += ws : rPoints += ws;
          if (isIndiv) {
            final extractedMap =
                MatchCalculatorHelper.extractPointsFromProjection(m);
            final extracted = List<PointMark>.from(
              isRowRed ? extractedMap['red']! : extractedMap['white']!,
            );

            final bool isSummary = m.note.contains('[SUMMARY]');
            if (isSummary || extracted.isEmpty) {
              extracted.clear();
              for (int k = 0; k < (isRowRed ? rs : ws); k++) {
                extracted.add(const PointMark(mark: '◯', isFirst: false));
              }
            }
            techs.addAll(extracted);
          }
        }

        String result = 'draw';
        if (rWins > cWins) {
          result = 'win';
        } else if (cWins > rWins) {
          result = 'loss';
        }

        if (!bouts.every(
          (m) => m.status == 'approved' || m.status == 'finished',
        )) {
          continue;
        }

        matrix[rowTeam]![colTeam] = LeagueGridCellData(
          result: result,
          isIndiv: isIndiv,
          techMarks: techs,
          rPoints: rPoints,
          rWinners: rWinners,
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: '閉じる',
              barrierColor: AppKendoColors.pureBlack.withValues(alpha: 0.7),
              transitionDuration: const Duration(milliseconds: 350),
              pageBuilder: (ctx, anim1, anim2) {
                return Center(
                  child: Dialog(
                    backgroundColor: AppKendoColors.transparent,
                    elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.roundValue,
                      vertical: AppSpacing.giant,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 550),
                      decoration: BoxDecoration(
                        color: context.appColors.cardBackground,
                        borderRadius: AppRadius.round,
                        boxShadow: [
                          BoxShadow(
                            color: AppKendoColors.pureBlack.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.roundValue),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: isIndiv
                                ? ViewerOfficialIndividualListCard(
                                    groupName: '$rowTeam vs $colTeam',
                                    matches: bouts,
                                    cardColor: AppKendoColors.transparent,
                                    isDark: isDark,
                                    applySort: false,
                                  )
                                : ViewerOfficialScoreTableCard(
                                    groupName: '$rowTeam vs $colTeam',
                                    matches: bouts,
                                    cardColor: AppKendoColors.transparent,
                                    isDark: isDark,
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appColors.separatorColor,
                              foregroundColor: context.appColors.textColor,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: AppSpacing.md,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '閉じる',
                              style: TextStyle(fontWeight: AppFontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    }

    return InkWell(
      key: Key('viewer_match_card_$groupName'),
      onTap: () {},
      child: LeagueGridCard(
        teams: leagueTeams,
        matrix: matrix,
        hasMatchPoints: hasMatchPoints,
        cardColor: cardColor,
        isDark: isDark,
      ),
    );
  }
}
