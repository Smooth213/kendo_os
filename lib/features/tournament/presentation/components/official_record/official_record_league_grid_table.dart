import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/league_grid_card.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

/// 🏆 公式記録画面: リーグ星取表カード＆対戦モーダルコンポーネント
class OfficialRecordLeagueGridTable extends ConsumerWidget {
  final String groupName;
  final List<MatchModel> matches;
  final Color? cardColor;
  final bool isDark;
  final Widget Function(String matchupName, List<MatchModel> bouts)
  scoreTableBuilder;
  final Widget Function(String matchupName, List<MatchModel> bouts)
  individualListBuilder;

  const OfficialRecordLeagueGridTable({
    super.key,
    required this.groupName,
    required this.matches,
    this.cardColor,
    required this.isDark,
    required this.scoreTableBuilder,
    required this.individualListBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalMatches = matches
        .where((m) => !m.note.contains('[順位決定戦]'))
        .toList();
    if (normalMatches.isEmpty) return const SizedBox();

    final rule = normalMatches.first.rule ?? ref.read(matchRuleProvider);
    final nonNullRule = rule!;
    final stats = KendoRuleEngine.calculateLeagueStandings(
      normalMatches,
      nonNullRule,
    );
    final isIndiv = normalMatches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );
    final allFinished = matches.every(
      (m) => m.status == 'approved' || m.status == 'finished',
    );
    final hasMatchPoints = nonNullRule.isLeague;

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

    final teams = <String>{};
    for (var m in normalMatches) {
      teams.add(getEntityName(m.redName));
      teams.add(getEntityName(m.whiteName));
    }
    final teamList = teams.toList()..sort();

    final leagueTeams = teamList.map((rowTeam) {
      final stat = stats.firstWhere(
        (s) => s.name == rowTeam,
        orElse: () => stats.first,
      );
      final rankStr = allFinished
          ? '${stats.indexWhere((s) => s.name == rowTeam) + 1}'
          : '-';
      return LeagueGridTeamInfo(
        teamName: rowTeam,
        matchWins: '${stat.matchWins}',
        individualWinners: '${stat.individualWinners}',
        totalPoints: '${stat.totalPointsScored}',
        customPoints: stat.customPoints.toStringAsFixed(
          stat.customPoints.truncateToDouble() == stat.customPoints ? 0 : 1,
        ),
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
          final rs = (m.redScore as num).toInt();
          final ws = (m.whiteScore as num).toInt();
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
            final extractedMap = MatchCalculatorHelper.extractPointsFromModel(
              m,
            );
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
                        color: isDark
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFFFFFFFF),
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
                                ? individualListBuilder(
                                    '$rowTeam vs $colTeam',
                                    bouts,
                                  )
                                : scoreTableBuilder(
                                    '$rowTeam vs $colTeam',
                                    bouts,
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
              transitionBuilder: (ctx, anim1, anim2, child) {
                return FadeTransition(
                  opacity: anim1,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: anim1,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
            );
          },
        );
      }
    }

    return LeagueGridCard(
      teams: leagueTeams,
      matrix: matrix,
      hasMatchPoints: hasMatchPoints,
      cardColor: cardColor,
      isDark: isDark,
    );
  }
}
