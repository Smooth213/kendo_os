import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/name_formatter.dart';

class TeamPointDisplay {
  final String mark;
  final bool isFirstMatchPoint;
  TeamPointDisplay(this.mark, this.isFirstMatchPoint);
}

class TeamScoreboardTableBuilder {
  static TableRow buildHeaderRow(String r, String w, bool isDark) {
    final headerBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F5F9);
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1E293B);
    return TableRow(
      decoration: BoxDecoration(color: headerBg),
      children: [
        cell('', isH: true, color: textColor, fs: 12),
        cell(
          r,
          isH: true,
          color: isDark ? const Color(0xFFFF6B6B) : AppKendoColors.hansokuRed,
          fs: 16,
        ),
        cell(
          '赤',
          isH: true,
          color: isDark ? const Color(0xFFFF6B6B) : AppKendoColors.hansokuRed,
          fs: 14,
        ),
        cell(
          '白',
          isH: true,
          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
          fs: 14,
        ),
        cell(
          w,
          isH: true,
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E293B),
          fs: 16,
        ),
      ],
    );
  }

  static Widget buildNameCell(
    String rawName,
    bool isDark,
    List<String> teamLastNames,
  ) {
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF64748B);
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);

    if (rawName.contains('欠員')) {
      return cell(
        '(欠員)',
        fs: 17,
        color: subTextColor,
        fontWeight: AppFontWeight.bold,
      );
    }

    final parsed = NameFormatter.parse(rawName);
    final count = teamLastNames.where((n) => n == parsed['last']).length;
    final showInitial = count > 1 && parsed['first']!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: AppFontSize.title,
            fontWeight: AppFontWeight.bold,
            color: textColor,
          ),
          children: [
            TextSpan(text: parsed['last']),
            if (showInitial)
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xxs,
                    bottom: AppSpacing.xxs,
                  ),
                  child: Text(
                    parsed['first']!.substring(0, 1),
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: AppFontWeight.bold,
                      color: subTextColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static TableRow buildMatchRow(
    MatchModel m,
    BuildContext ctx,
    bool isDark,
    List<String> redLastNames,
    List<String> whiteLastNames,
  ) {
    final isDone = m.status == 'approved' || m.status == 'finished';
    final rS = (m.redScore as num).toInt();
    final wS = (m.whiteScore as num).toInt();
    final isDraw = isDone && (rS == wS);

    final ptsMap = calcPts(m);
    final rPts = ptsMap['red'] ?? [];
    final wPts = ptsMap['white'] ?? [];

    final isDaihyo = m.matchType == '代表戦';
    final daihyoBgColor = isDark
        ? const Color(0xFFE53935).withValues(alpha: 0.15)
        : const Color(0xFFFFF5F5);
    final matchTypeColor = isDaihyo
        ? (isDark ? const Color(0xFFFF6B6B) : AppKendoColors.hansokuRed)
        : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E293B));

    return TableRow(
      decoration: isDaihyo ? BoxDecoration(color: daihyoBgColor) : null,
      children: [
        clickableCell(
          ctx,
          m,
          cell(
            m.matchType,
            fs: 12,
            fontWeight: AppFontWeight.bold,
            color: matchTypeColor,
          ),
        ),
        clickableCell(ctx, m, buildNameCell(m.redName, isDark, redLastNames)),
        clickableCell(
          ctx,
          m,
          buildMatchScoreBox(rPts, isDone && rS > wS, isDraw, true, isDark),
        ),
        clickableCell(
          ctx,
          m,
          buildMatchScoreBox(wPts, isDone && wS > rS, false, false, isDark),
        ),
        clickableCell(
          ctx,
          m,
          buildNameCell(m.whiteName, isDark, whiteLastNames),
        ),
      ],
    );
  }

  static Widget buildMatchScoreBox(
    List<TeamPointDisplay> pts,
    bool isWinner,
    bool isDraw,
    bool isRed,
    bool isDark,
  ) {
    final color = isRed
        ? (isDark ? const Color(0xFFFF6B6B) : AppKendoColors.hansokuRed)
        : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF607D8B));

    return SizedBox(
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isWinner)
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 2.4,
                ),
              ),
            ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                if (pts.isNotEmpty)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: ptMark(pts[0], color, isDark),
                  ),
                if (pts.length > 1)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: ptMark(pts[1], color, isDark),
                  ),
              ],
            ),
          ),
          if (isRed && isDraw)
            Positioned(
              right: -14,
              child: Text(
                '✕',
                style: TextStyle(
                  fontSize: AppFontSize.hero,
                  color: isDark
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.6)
                      : AppKendoColors.hansokuRed,
                  fontWeight: AppFontWeight.light,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget clickableCell(BuildContext ctx, MatchModel m, Widget child) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ctx.push('/match/${m.id}'),
        child: child,
      ),
    );
  }

  static Widget ptMark(TeamPointDisplay p, Color color, bool isDark) {
    if (p.isFirstMatchPoint && p.mark != '◯') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        padding: const EdgeInsets.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.4 : 1.0),
            width: 1.5,
          ),
        ),
        child: Text(
          p.mark,
          style: TextStyle(
            fontSize: AppFontSize.badge,
            color: color,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Text(
        p.mark,
        style: TextStyle(
          fontSize: AppFontSize.body,
          color: color,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }

  static Widget cell(
    String txt, {
    bool isH = false,
    Color? color,
    double fs = 13,
    FontWeight? fontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(
        txt,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fs,
          fontWeight: isH
              ? AppFontWeight.bold
              : (fontWeight ?? AppFontWeight.regular),
          color: color,
        ),
      ),
    );
  }

  static TableRow buildTotalRow(TeamMatchResult result, bool isDark) {
    final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8FAFC);
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1E293B);
    final isTeamTie = (result.teamWinner == 'draw');

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        const SizedBox.shrink(),
        cell(
          '${result.redPoints} / ${result.redWins}',
          isH: true,
          color: isDark ? const Color(0xFFFF6B6B) : AppKendoColors.hansokuRed,
          fs: 18,
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (result.allFinished) ...[
                  if (isTeamTie)
                    Positioned(
                      right: -36,
                      child: Text(
                        '引き分け',
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.headline,
                          color: isDark
                              ? AppKendoColors.ipponGold
                              : const Color(0xFFD97706),
                        ),
                      ),
                    )
                  else
                    cell(
                      result.teamWinner == 'red' ? '勝' : '負',
                      isH: true,
                      color: result.teamWinner == 'red'
                          ? AppKendoColors.red
                          : textColor,
                      fs: 20,
                    ),
                ],
              ],
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(
            height: 64,
            child: Center(
              child: (result.allFinished && !isTeamTie)
                  ? cell(
                      result.teamWinner == 'white' ? '勝' : '負',
                      isH: true,
                      color: result.teamWinner == 'white'
                          ? AppKendoColors.red
                          : textColor,
                      fs: 20,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        cell(
          '${result.whitePoints} / ${result.whiteWins}',
          isH: true,
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF607D8B),
          fs: 18,
        ),
      ],
    );
  }

  static Map<String, List<TeamPointDisplay>> calcPts(MatchModel m) {
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(m.events, m, m.rule);

    final redPts = (analysis.displays[Side.red] ?? [])
        .map(
          (d) => TeamPointDisplay(
            d.mark == '判定' ? '判' : d.mark,
            d.isFirstMatchPoint,
          ),
        )
        .toList();
    final whitePts = (analysis.displays[Side.white] ?? [])
        .map(
          (d) => TeamPointDisplay(
            d.mark == '判定' ? '判' : d.mark,
            d.isFirstMatchPoint,
          ),
        )
        .toList();

    return {'red': redPts, 'white': whitePts};
  }
}
