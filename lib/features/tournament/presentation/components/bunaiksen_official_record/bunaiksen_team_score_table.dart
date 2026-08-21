import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_team_score_table_row_builder.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 部内戦公式記録の団体戦・対戦スコアテーブルWidget
class BunaiksenTeamScoreTable extends StatelessWidget {
  final String groupName;
  final List<MatchModel> matches;
  final Color? cardColor;
  final bool isDark;

  const BunaiksenTeamScoreTable({
    super.key,
    required this.groupName,
    required this.matches,
    this.cardColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    String headerRed = matches.first.redName.contains(':')
        ? matches.first.redName.split(':').first.trim()
        : matches.first.redName;
    String headerWhite = matches.first.whiteName.contains(':')
        ? matches.first.whiteName.split(':').first.trim()
        : matches.first.whiteName;

    const String sideLabelRed = '赤';
    const String sideLabelWhite = '白';

    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0x33000000);
    final headerTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xDE000000);
    final daihyoBgColor = isDark
        ? const Color(0xFFE53935).withValues(alpha: 0.15)
        : const Color(0xFFE53935);

    bool allFinished = matches.every((m) {
      final hasScore =
          (m.redScore as num).toInt() > 0 || (m.whiteScore as num).toInt() > 0;
      final isOfficial = m.status == 'approved' || m.status == 'finished';
      return isOfficial || hasScore;
    });

    String teamWinner = 'draw';
    int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
    MatchModel? daihyoMatch;

    for (var m in matches) {
      if (m.matchType == '代表戦') {
        daihyoMatch = m;
        continue;
      }
      final rs = (m.redScore as num).toInt();
      final ws = (m.whiteScore as num).toInt();
      rPts += rs;
      wPts += ws;
      if (rs > ws) {
        rWins++;
      } else if (ws > rs) {
        wWins++;
      }
    }

    if (rWins > wWins) {
      teamWinner = 'red';
    } else if (wWins > rWins) {
      teamWinner = 'white';
    } else if (rPts > wPts) {
      teamWinner = 'red';
    } else if (wPts > rPts) {
      teamWinner = 'white';
    } else if (daihyoMatch != null) {
      final rs = (daihyoMatch.redScore as num).toInt();
      final ws = (daihyoMatch.whiteScore as num).toInt();
      if (rs > ws) {
        teamWinner = 'red';
      } else if (ws > rs) {
        teamWinner = 'white';
      }
    }

    final bool isSummary = matches.any((m) => m.note.contains('[SUMMARY]'));

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                width: double.infinity,
                child: Text(
                  cleanNote.isNotEmpty
                      ? '【$cleanNote】 $headerRed vs $headerWhite'
                      : '$headerRed vs $headerWhite',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xDE000000),
                  ),
                ),
              ),
              Table(
                border: TableBorder.all(color: borderColor, width: 1),
                columnWidths: {
                  0: const FlexColumnWidth(1.2),
                  for (int i = 1; i <= matches.length; i++)
                    i: const FlexColumnWidth(1.0),
                  matches.length + 1: const FlexColumnWidth(0.8),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                    ),
                    children: [
                      const SizedBox.shrink(),
                      ...matches.map(
                        (m) => Container(
                          color: m.matchType == '代表戦'
                              ? daihyoBgColor
                              : AppKendoColors.transparent,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Text(
                                m.matchType,
                                style: TextStyle(
                                  fontSize: AppFontSize.badge,
                                  fontWeight: AppFontWeight.bold,
                                  color: m.matchType == '代表戦'
                                      ? (isDark
                                            ? const Color(0xFFE53935)
                                            : const Color(0xFFE53935))
                                      : (isDark
                                            ? const Color(0xFFFFFFFF)
                                            : const Color(0xDE000000)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(
                            '本/勝',
                            style: TextStyle(
                              fontSize: AppFontSize.badge,
                              color: headerTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  BunaiksenTeamScoreTableRowBuilder.buildTeamRow(
                    matches: matches,
                    isRed: true,
                    teamName: sideLabelRed,
                    isDark: isDark,
                  ),
                  TableRow(
                    children: [
                      const SizedBox.shrink(),
                      ...matches.map(
                        (m) => BunaiksenTeamScoreTableRowBuilder.scoreCell(
                          m,
                          isDark,
                          isSummary,
                        ),
                      ),
                      BunaiksenTeamScoreTableRowBuilder.teamResultCell(
                        teamWinner,
                        isDark,
                        allFinished,
                      ),
                    ],
                  ),
                  BunaiksenTeamScoreTableRowBuilder.buildTeamRow(
                    matches: matches,
                    isRed: false,
                    teamName: sideLabelWhite,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
          if (isSummary)
            Positioned.fill(
              top: 40,
              child: Container(
                color: isDark
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.3)
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF475569),
                      borderRadius: AppRadius.small,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0x33000000),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppKendoColors.pureBlack.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '※簡易入力された結果です\n（詳細スコアはありません）',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xDE000000),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
