import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/name_formatter.dart';

/// 観戦者用 団体戦スコアボード テーブル行ビルダー
class ViewerTeamScoreboardTableBuilder {
  static TableRow buildHeaderRow(String r, String w, bool isDark) {
    final headerBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFF3F51B5);
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    return TableRow(
      decoration: BoxDecoration(color: headerBg),
      children: [
        _cell('', isH: true, color: textColor, fs: 12),
        _cell(r, isH: true, color: const Color(0xFFE53935), fs: 16),
        _cell('赤', isH: true, color: const Color(0xFFE53935), fs: 16),
        _cell(
          '白',
          isH: true,
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF607D8B),
          fs: 16,
        ),
        _cell(
          w,
          isH: true,
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF607D8B),
          fs: 16,
        ),
      ],
    );
  }

  static TableRow buildMatchRow(
    MatchListProjection m,
    BuildContext ctx,
    bool isDark,
    List<String> redLastNames,
    List<String> whiteLastNames,
  ) {
    final isDone = m.status == 'approved' || m.status == 'finished';
    final rS = m.redScore;
    final wS = m.whiteScore;
    final isDraw = isDone && (rS == wS);

    final rPts = m.redPointMarks;
    final wPts = m.whitePointMarks;
    final firstSide = m.firstPointSide;

    final isDaihyo = m.matchType == '代表戦';
    final daihyoBgColor = isDark
        ? const Color(0xFFE53935).withValues(alpha: 0.15)
        : const Color(0xFFE53935);
    final matchTypeColor = isDaihyo
        ? const Color(0xFFE53935)
        : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E293B));

    return TableRow(
      decoration: isDaihyo ? BoxDecoration(color: daihyoBgColor) : null,
      children: [
        _clickableCell(
          ctx,
          m.id,
          _cell(
            m.matchType,
            fs: 12,
            fontWeight: AppFontWeight.bold,
            color: matchTypeColor,
          ),
        ),
        _clickableCell(
          ctx,
          m.id,
          _buildNameCell(m.redName, isDark, redLastNames),
        ),
        _clickableCell(
          ctx,
          m.id,
          _buildMatchScoreBox(
            rPts,
            isDone && rS > wS,
            isDraw,
            true,
            isDark,
            firstSide,
          ),
        ),
        _clickableCell(
          ctx,
          m.id,
          _buildMatchScoreBox(
            wPts,
            isDone && wS > rS,
            false,
            false,
            isDark,
            firstSide,
          ),
        ),
        _clickableCell(
          ctx,
          m.id,
          _buildNameCell(m.whiteName, isDark, whiteLastNames),
        ),
      ],
    );
  }

  static TableRow buildTotalRow(TeamMatchResult result, bool isDark) {
    final bg = isDark ? const Color(0xFF3A2E12) : const Color(0xFFD4AF37);
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    final isTeamTie = (result.teamWinner == 'draw');

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        const SizedBox.shrink(),
        _cell(
          '${result.redWins} / ${result.redPoints}',
          isH: true,
          color: const Color(0xFFE53935),
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
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                    )
                  else
                    _cell(
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
                  ? _cell(
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
        _cell(
          '${result.whiteWins} / ${result.whitePoints}',
          isH: true,
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF607D8B),
          fs: 18,
        ),
      ],
    );
  }

  static Widget _buildNameCell(
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
      return _cell(
        '(欠員)',
        fs: 12,
        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF9E9E9E),
      );
    }

    final parsed = NameFormatter.parse(rawName);
    final showInitial =
        parsed['first']!.isNotEmpty &&
        teamLastNames.where((ln) => ln == parsed['last']).length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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

  static Widget _buildMatchScoreBox(
    List<String> pts,
    bool isWinner,
    bool isDraw,
    bool isRed,
    bool isDark,
    String? firstSide,
  ) {
    final color = isRed
        ? const Color(0xFFE53935)
        : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF607D8B));

    final isFusen = pts.contains('◯');
    final isThisSideFirst = firstSide == (isRed ? 'red' : 'white');

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
                if (isFusen) ...[
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _ptMark('◯', false, color, isDark),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _ptMark('◯', false, color, isDark),
                  ),
                ] else ...[
                  if (pts.isNotEmpty)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: _ptMark(pts[0], isThisSideFirst, color, isDark),
                    ),
                  if (pts.length > 1)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: _ptMark(pts[1], false, color, isDark),
                    ),
                ],
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
                      ? const Color(0xFFE53935).withValues(alpha: 0.6)
                      : const Color(0xFFE53935),
                  fontWeight: AppFontWeight.light,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _clickableCell(BuildContext ctx, String matchId, Widget child) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ctx.push('/viewer/$matchId'),
        child: child,
      ),
    );
  }

  static Widget _ptMark(
    String mark,
    bool isFirstOverall,
    Color color,
    bool isDark,
  ) {
    if (isFirstOverall && mark != '◯') {
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
          mark,
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
        mark,
        style: TextStyle(
          fontSize: AppFontSize.body,
          color: color,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }

  static Widget _cell(
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
}
