import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/vertical_name_text.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

class LeagueGridTeamInfo {
  final String teamName;
  final String matchWins;
  final String individualWinners;
  final String totalPoints;
  final String? customPoints;
  final String rank;

  const LeagueGridTeamInfo({
    required this.teamName,
    required this.matchWins,
    required this.individualWinners,
    required this.totalPoints,
    this.customPoints,
    required this.rank,
  });
}

class LeagueGridCellData {
  final String result; // 'win', 'loss', 'draw'
  final bool isIndiv;
  final List<PointMark> techMarks;
  final int rPoints;
  final int rWinners;
  final VoidCallback? onTap;

  const LeagueGridCellData({
    required this.result,
    required this.isIndiv,
    this.techMarks = const [],
    this.rPoints = 0,
    this.rWinners = 0,
    this.onTap,
  });
}

class LeagueGridCard extends StatelessWidget {
  final List<LeagueGridTeamInfo> teams;
  final Map<String, Map<String, LeagueGridCellData>> matrix;
  final bool hasMatchPoints;
  final Color? cardColor;
  final bool isDark;

  const LeagueGridCard({
    super.key,
    required this.teams,
    required this.matrix,
    required this.hasMatchPoints,
    this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) return const SizedBox();

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final borderColor = themeColors.separatorColor;
    final headerColor = themeColors.softAccent;
    final blankColor = themeColors.cardBackground;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
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
            for (int i = 1; i <= teams.length; i++)
              i: const FixedColumnWidth(65),
            teams.length + 1: const FixedColumnWidth(45),
            teams.length + 2: const FixedColumnWidth(45),
            teams.length + 3: const FixedColumnWidth(45),
            if (hasMatchPoints) teams.length + 4: const FixedColumnWidth(45),
            teams.length + (hasMatchPoints ? 5 : 4): const FixedColumnWidth(45),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerColor),
              children: [
                const SizedBox(height: 50),
                ...teams.map(
                  (t) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: VerticalNameText(text: t.teamName, isDark: isDark),
                    ),
                  ),
                ),
                _buildHeaderCell(context, '勝数', isDark),
                _buildHeaderCell(context, '勝者', isDark),
                _buildHeaderCell(context, '本数', isDark),
                if (hasMatchPoints) _buildHeaderCell(context, '勝点', isDark),
                _buildHeaderCell(context, '順位', isDark),
              ],
            ),
            ...teams.map((rowTeam) {
              return TableRow(
                children: [
                  Container(
                    height: 65,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: headerColor),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Text(
                        rowTeam.teamName,
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: 11,
                          color: themeColors.textColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  ...teams.map((colTeam) {
                    if (rowTeam.teamName == colTeam.teamName) {
                      return Container(
                        height: 65,
                        color: blankColor,
                        child: CustomPaint(
                          painter: DiagonalLinePainter(color: borderColor),
                        ),
                      );
                    }

                    final cellData =
                        matrix[rowTeam.teamName]?[colTeam.teamName];
                    if (cellData == null) return const SizedBox(height: 65);

                    Color symbolColor = isDark
                        ? Colors.amber.shade300
                        : Colors.amber.shade700;
                    if (cellData.result == 'win') {
                      symbolColor = isDark
                          ? Colors.red.shade300
                          : Colors.red.shade700;
                    } else if (cellData.result == 'loss') {
                      symbolColor = isDark
                          ? Colors.blue.shade300
                          : Colors.indigo.shade700;
                    }

                    final textColor = themeColors.textColor;

                    Widget cellContent = Container(
                      height: 65,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(45, 45),
                            painter: ResultShapePainter(
                              result: cellData.result,
                              color: symbolColor,
                            ),
                          ),
                          if (cellData.isIndiv)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                cellData.techMarks.isNotEmpty
                                    ? PointMarkBadge(
                                        point: cellData.techMarks[0],
                                        color: textColor,
                                        isDark: isDark,
                                      )
                                    : const SizedBox(height: AppSpacing.md),
                                Container(
                                  height: 0.5,
                                  width: 18,
                                  color: textColor.withValues(alpha: 0.5),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                ),
                                cellData.techMarks.length > 1
                                    ? PointMarkBadge(
                                        point: cellData.techMarks[1],
                                        color: textColor,
                                        isDark: isDark,
                                      )
                                    : const SizedBox(height: AppSpacing.md),
                              ],
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${cellData.rPoints}',
                                  style: TextStyle(
                                    fontSize: 12,
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
                                    vertical: 2,
                                  ),
                                ),
                                Text(
                                  '${cellData.rWinners}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: AppFontWeight.bold,
                                    height: 1.1,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );

                    if (cellData.onTap != null) {
                      cellContent = GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: cellData.onTap,
                        child: cellContent,
                      );
                    }

                    return cellContent;
                  }),
                  _buildStatCell(context, rowTeam.matchWins, isDark),
                  _buildStatCell(context, rowTeam.individualWinners, isDark),
                  _buildStatCell(context, rowTeam.totalPoints, isDark),
                  if (hasMatchPoints)
                    _buildStatCell(context, rowTeam.customPoints ?? '', isDark),
                  _buildStatCell(context, rowTeam.rank, isDark, isRank: true),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text, bool isDark) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: TextStyle(fontSize: 10, color: themeColors.subTextColor),
        ),
      ),
    );
  }

  Widget _buildStatCell(
    BuildContext context,
    String text,
    bool isDark, {
    bool isRank = false,
  }) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return Container(
      height: 65,
      alignment: Alignment.center,
      color: isRank
          ? (isDark
                ? Colors.orange.withValues(alpha: 0.2)
                : Colors.orange.shade50)
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: AppFontWeight.bold,
          fontSize: isRank ? 16 : 13,
          color: isRank ? Colors.orange.shade800 : themeColors.textColor,
        ),
      ),
    );
  }
}

class DiagonalLinePainter extends CustomPainter {
  final Color color;
  DiagonalLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ResultShapePainter extends CustomPainter {
  final String result; // 'win', 'loss', 'draw'
  final Color color;
  ResultShapePainter({required this.result, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    if (result == 'win') {
      canvas.drawCircle(center, radius, bgPaint);
      canvas.drawCircle(center, radius, strokePaint);
    } else if (result == 'loss') {
      final path = Path();
      path.moveTo(center.dx, center.dy - radius);
      path.lineTo(center.dx + radius * 1.1, center.dy + radius * 0.8);
      path.lineTo(center.dx - radius * 1.1, center.dy + radius * 0.8);
      path.close();
      canvas.drawPath(path, bgPaint);
      canvas.drawPath(path, strokePaint);
    } else {
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 1.8,
        height: radius * 1.8,
      );
      canvas.drawRect(rect, bgPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
