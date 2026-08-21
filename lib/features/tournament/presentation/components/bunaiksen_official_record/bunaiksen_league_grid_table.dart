import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_individual_matches_list.dart';
import 'package:kendo_os/features/viewer/components/viewer_point_box_cell.dart';
import 'package:kendo_os/features/viewer/components/viewer_vertical_player_name_cell.dart';
import 'package:kendo_os/features/viewer/painters/league_table_painters.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🏆 部内戦公式記録: リーグ戦グリッド星取り表＆対戦詳細ダイアログ
class BunaiksenLeagueGridTable extends ConsumerWidget {
  final String groupName;
  final List<MatchModel> matches;
  final Color? cardColor;
  final bool isDark;
  final Widget Function(String matchupName, List<MatchModel> bouts)?
  buildScoreTableCallback;

  const BunaiksenLeagueGridTable({
    super.key,
    required this.groupName,
    required this.matches,
    this.cardColor,
    required this.isDark,
    this.buildScoreTableCallback,
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
          m.matchType.contains('個人戦') ||
          (!m.redName.contains(':') && !m.whiteName.contains(':')),
    );
    final allFinished = matches.every(
      (m) => m.status == 'approved' || m.status == 'finished',
    );
    final hasMatchPoints = nonNullRule.isLeague;

    final teams = <String>{};
    for (var m in normalMatches) {
      teams.add(m.redName.split(':').first.trim());
      teams.add(m.whiteName.split(':').first.trim());
    }
    final teamList = teams.toList()..sort();

    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0x8A000000);
    final headerColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFF3F51B5);
    final blankColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0x33000000);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.small,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Table(
          border: TableBorder.all(color: borderColor, width: 1),
          columnWidths: {
            0: const FixedColumnWidth(100),
            for (int i = 1; i <= teamList.length; i++)
              i: const FixedColumnWidth(65),
            teamList.length + 1: const FixedColumnWidth(45),
            teamList.length + 2: const FixedColumnWidth(45),
            teamList.length + 3: const FixedColumnWidth(45),
            if (hasMatchPoints) teamList.length + 4: const FixedColumnWidth(45),
            teamList.length + (hasMatchPoints ? 5 : 4): const FixedColumnWidth(
              45,
            ),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerColor),
              children: [
                const SizedBox(height: 50),
                ...teamList.map(
                  (t) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: ViewerVerticalPlayerNameCell(
                        text: t,
                        initial: '',
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
                _buildHeaderCell('勝数', isDark),
                _buildHeaderCell('勝者', isDark),
                _buildHeaderCell('本数', isDark),
                if (hasMatchPoints) _buildHeaderCell('勝点', isDark),
                _buildHeaderCell('順位', isDark),
              ],
            ),
            ...teamList.map((rowTeam) {
              final stat = stats.firstWhere(
                (s) => s.name == rowTeam,
                orElse: () => stats.first,
              );
              final rankStr = allFinished
                  ? '${stats.indexWhere((s) => s.name == rowTeam) + 1}'
                  : '-';

              int customTeamPoints =
                  BunaiksenHelper.calculateCustomLeaguePoints(
                    rowTeam,
                    teamList,
                    normalMatches,
                  );

              return TableRow(
                children: [
                  Container(
                    height: 65,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: headerColor),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Text(
                        rowTeam,
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.caption,
                          color: isDark
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF000000),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  ...teamList.map((colTeam) {
                    if (rowTeam == colTeam) {
                      return Container(
                        height: 65,
                        color: blankColor,
                        child: CustomPaint(
                          painter: DiagonalLinePainter(color: borderColor),
                        ),
                      );
                    }
                    final bouts = normalMatches.where((m) {
                      final r = m.redName.split(':').first.trim();
                      final w = m.whiteName.split(':').first.trim();
                      return (r == rowTeam && w == colTeam) ||
                          (r == colTeam && w == rowTeam);
                    }).toList();

                    if (bouts.isEmpty) {
                      return const SizedBox(height: 65);
                    }

                    int rWins = 0,
                        cWins = 0,
                        rPoints = 0,
                        cPoints = 0,
                        rWinners = 0,
                        cWinners = 0;
                    List<OfficialPointDisplay> techs = [];
                    for (var m in bouts) {
                      final isRowRed =
                          m.redName.split(':').first.trim() == rowTeam;
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
                        final engine = KendoRuleEngine();
                        final analysis = engine.analyzeHistory(
                          m.events,
                          m,
                          m.rule,
                        );
                        final proj = MatchProjectionMapper.toProjection(
                          m,
                          analysis,
                        );
                        final bool isRowFirst =
                            (isRowRed && proj.firstPointSide == 'red') ||
                            (!isRowRed && proj.firstPointSide == 'white');
                        final displays = isRowRed
                            ? analysis.displays[Side.red]
                            : analysis.displays[Side.white];
                        List<OfficialPointDisplay> extracted = [];
                        if (displays != null) {
                          for (int k = 0; k < displays.length; k++) {
                            extracted.add(
                              OfficialPointDisplay(
                                displays[k].mark,
                                k == 0 && isRowFirst,
                              ),
                            );
                          }
                        }

                        final bool isSummary = m.note.contains('[SUMMARY]');
                        if (isSummary || extracted.isEmpty) {
                          extracted.clear();
                          for (int k = 0; k < (isRowRed ? rs : ws); k++) {
                            extracted.add(OfficialPointDisplay('◯', false));
                          }
                        }
                        techs.addAll(extracted);
                      }
                    }

                    String result = 'draw';
                    Color symbolColor = const Color(0xFFD4AF37);
                    if (rWins > cWins) {
                      result = 'win';
                      symbolColor = const Color(0xFFE53935);
                    } else if (cWins > rWins) {
                      result = 'loss';
                      symbolColor = isDark
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF3F51B5);
                    } else if (rPoints != cPoints) {
                      if (rPoints > cPoints) {
                        result = 'win';
                        symbolColor = const Color(0xFFE53935);
                      } else {
                        result = 'loss';
                        symbolColor = isDark
                            ? const Color(0xFF2196F3)
                            : const Color(0xFF3F51B5);
                      }
                    }

                    if (!bouts.every(
                      (m) => m.status == 'approved' || m.status == 'finished',
                    )) {
                      return const SizedBox(height: 65);
                    }

                    final textColor = isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: '閉じる',
                          barrierColor: AppKendoColors.pureBlack.withValues(
                            alpha: 0.7,
                          ),
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
                                  constraints: const BoxConstraints(
                                    maxWidth: 550,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : const Color(0xFFFFFFFF),
                                    borderRadius: AppRadius.round,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppKendoColors.pureBlack
                                            .withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(
                                    AppSpacing.roundValue,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: isIndiv
                                            ? BunaiksenIndividualMatchesList(
                                                groupName:
                                                    '$rowTeam vs $colTeam',
                                                matches: bouts,
                                                cardColor:
                                                    AppKendoColors.transparent,
                                                isDark: isDark,
                                              )
                                            : (buildScoreTableCallback != null
                                                  ? buildScoreTableCallback!(
                                                      '$rowTeam vs $colTeam',
                                                      bouts,
                                                    )
                                                  : const SizedBox()),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark
                                              ? const Color(0xFFFFFFFF)
                                              : const Color(0x33000000),
                                          foregroundColor: isDark
                                              ? const Color(0xFFFFFFFF)
                                              : const Color(0xFF000000),
                                          shape: const StadiumBorder(),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: AppSpacing.md,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          '閉じる',
                                          style: TextStyle(
                                            fontWeight: AppFontWeight.bold,
                                          ),
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
                                scale: Tween<double>(begin: 0.9, end: 1.0)
                                    .animate(
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
                      child: Container(
                        height: 65,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(45, 45),
                              painter: ResultShapePainter(
                                result: result,
                                color: symbolColor,
                              ),
                            ),
                            if (isIndiv)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  techs.isNotEmpty
                                      ? OfficialTechMarkBadge(
                                          point: techs[0],
                                          color: textColor,
                                        )
                                      : const SizedBox(height: AppSpacing.md),
                                  Container(
                                    height: 0.5,
                                    width: 18,
                                    color: textColor.withValues(alpha: 0.5),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xxs,
                                    ),
                                  ),
                                  techs.length > 1
                                      ? OfficialTechMarkBadge(
                                          point: techs[1],
                                          color: textColor,
                                        )
                                      : const SizedBox(height: AppSpacing.md),
                                ],
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$rPoints',
                                    style: TextStyle(
                                      fontSize: AppFontSize.small,
                                      fontWeight: AppFontWeight.bold,
                                      height: 1.1,
                                      color: textColor,
                                    ),
                                  ),
                                  Container(
                                    height: 0.5,
                                    width: 18,
                                    color: textColor.withValues(alpha: 0.5),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xxs,
                                    ),
                                  ),
                                  Text(
                                    '$rWinners',
                                    style: TextStyle(
                                      fontSize: AppFontSize.small,
                                      fontWeight: AppFontWeight.bold,
                                      height: 1.1,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  _buildStatCell('${stat.matchWins}', isDark),
                  _buildStatCell('${stat.individualWinners}', isDark),
                  _buildStatCell('${stat.totalPointsScored}', isDark),
                  if (hasMatchPoints)
                    _buildStatCell('$customTeamPoints', isDark),
                  _buildStatCell(rankStr, isDark, isRank: true),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          text,
          style: TextStyle(
            fontSize: AppFontSize.badge,
            color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCell(String text, bool isDark, {bool isRank = false}) {
    return Container(
      height: 65,
      alignment: Alignment.center,
      color: isRank
          ? (isDark
                ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                : const Color(0xFFFF9800))
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: AppFontWeight.bold,
          fontSize: isRank ? 16 : 13,
          color: isRank
              ? const Color(0xFFFF9800)
              : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000)),
        ),
      ),
    );
  }
}
