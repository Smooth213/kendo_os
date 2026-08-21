import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_league_grid_cell_renderer.dart';
import 'package:kendo_os/features/viewer/components/viewer_vertical_player_name_cell.dart';
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
                    return BunaiksenLeagueGridCellRenderer.buildMatchCell(
                      context: context,
                      rowTeam: rowTeam,
                      colTeam: colTeam,
                      normalMatches: normalMatches,
                      isIndiv: isIndiv,
                      isDark: isDark,
                      blankColor: blankColor,
                      borderColor: borderColor,
                      buildScoreTableCallback: buildScoreTableCallback,
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
