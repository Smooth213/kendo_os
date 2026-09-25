import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 観戦者用 団体戦スコアボード スコアボックス描画コンポーネント
class ViewerTeamScoreboardScoreBox {
  static Widget build({
    required List<String> pts,
    required bool isWinner,
    required bool isDraw,
    required bool isRed,
    required bool isDark,
    String? firstSide,
  }) {
    final color = isRed
        ? (isDark ? const Color(0xFFFF6B6B) : AppKendoColors.hansokuRed)
        : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF607D8B));

    final actualPts = pts.where((m) => m != '△' && m != '▲').toList();
    final hasHansoku = pts.any((m) => m == '△' || m == '▲');

    final isFusen = actualPts.contains('◯');
    final isThisSideFirst = firstSide == (isRed ? 'red' : 'white');

    return SizedBox(
      width: 64,
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
            child: isFusen
                ? Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: ptMark('◯', false, color, isDark),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: ptMark('◯', false, color, isDark),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      if (actualPts.isNotEmpty)
                        Positioned(
                          top: 2,
                          left: 2,
                          child: ptMark(
                            actualPts[0],
                            isThisSideFirst,
                            color,
                            isDark,
                          ),
                        ),
                      if (actualPts.length > 1)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: ptMark(actualPts[1], false, color, isDark),
                        ),
                    ],
                  ),
          ),
          if (hasHansoku)
            Positioned(
              bottom: 8,
              left: 2,
              child: Text(
                '△',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  color: color,
                  fontWeight: AppFontWeight.bold,
                  height: 1.0,
                ),
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

  static Widget ptMark(
    String mark,
    bool isFirstOverall,
    Color color,
    bool isDark,
  ) {
    final bool isSpecial =
        mark == '◯' ||
        mark == '◎' ||
        mark == '反' ||
        mark == '×' ||
        mark == '✕' ||
        mark == '△' ||
        mark == '▲';
    if (isFirstOverall && !isSpecial) {
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
}
