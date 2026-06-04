import 'package:flutter/material.dart';
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

    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade400;
    final headerColor = isDark
        ? const Color(0xFF2C2C2E)
        : Colors.indigo.shade50;
    final blankColor = isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
                      padding: const EdgeInsets.all(4),
                      child: VerticalNameText(text: t.teamName, isDark: isDark),
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
            ...teams.map((rowTeam) {
              return TableRow(
                children: [
                  Container(
                    height: 65,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: headerColor),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        rowTeam.teamName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isDark ? Colors.white : Colors.black87,
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

                    final textColor = isDark ? Colors.white : Colors.black87;

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
                                    : const SizedBox(height: 12),
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
                                    : const SizedBox(height: 12),
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
                                    fontWeight: FontWeight.bold,
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
                                    fontWeight: FontWeight.bold,
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
                  _buildStatCell(rowTeam.matchWins, isDark),
                  _buildStatCell(rowTeam.individualWinners, isDark),
                  _buildStatCell(rowTeam.totalPoints, isDark),
                  if (hasMatchPoints)
                    _buildStatCell(rowTeam.customPoints ?? '', isDark),
                  _buildStatCell(rowTeam.rank, isDark, isRank: true),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
                ? Colors.orange.withValues(alpha: 0.2)
                : Colors.orange.shade50)
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isRank ? 16 : 13,
          color: isRank
              ? Colors.orange.shade800
              : (isDark ? Colors.white : Colors.black87),
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
