import 'package:flutter/material.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_battle_card_helper.dart';

/// 🥋 勝ち抜き戦 タイムライン中央バトルカード（試合番号、赤白選手、スコアマーク、連勝バッジ表示）
class KachinukiCenterBattleCard extends StatelessWidget {
  final Map<String, dynamic> uiState;
  final int matchNumber;
  final bool isDark;
  final List<String> rLasts;
  final List<String> wLasts;

  const KachinukiCenterBattleCard({
    super.key,
    required this.uiState,
    required this.matchNumber,
    required this.isDark,
    required this.rLasts,
    required this.wLasts,
  });

  static Map<String, String> parseName(String raw) =>
      KachinukiBattleCardHelper.parseName(raw);

  @override
  Widget build(BuildContext context) {
    final MatchProjection match = uiState['match'];
    final bool isDone = uiState['isDone'];
    final int rStreak = uiState['rStreak'], wStreak = uiState['wStreak'];
    final String rNameRaw = uiState['rName'], wNameRaw = uiState['wName'];

    int rPts = match.redScore;
    int wPts = match.whiteScore;

    bool isDraw = isDone && rPts == wPts,
        rWin = isDone && rPts > wPts,
        wWin = isDone && wPts > rPts;
    bool rIsStreaking = !isDone && rStreak > 0,
        wIsStreaking = !isDone && wStreak > 0;

    Widget buildTimelineName(
      String raw,
      List<String> teamLastNames,
      bool isWin,
      bool isFaded,
      Color winColor,
    ) {
      if (raw.contains('欠員')) {
        return const Text(
          '(欠員)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSize.subhead,
            fontWeight: AppFontWeight.bold,
            color: Color(0x8A000000),
          ),
        );
      }

      final parsed = parseName(raw);
      final showInitial =
          teamLastNames.where((n) => n == parsed['last']).length > 1 &&
          parsed['first']!.isNotEmpty;

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: AppFontSize.subhead,
            fontWeight: isWin ? AppFontWeight.black : AppFontWeight.bold,
            color: isFaded ? const Color(0x8A000000) : winColor,
          ),
          children: [
            TextSpan(text: parsed['last']),
            if (showInitial)
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xxs,
                    bottom: 1,
                  ),
                  child: Text(
                    parsed['first']!.substring(0, 1),
                    style: TextStyle(
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                      color: isFaded
                          ? const Color(0x8A000000)
                          : winColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Text(
            '$matchNumber試合目',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: rWin
                        ? (isDark
                              ? const Color(0xFFE53935).withValues(alpha: 0.15)
                              : const Color(0xFFE53935))
                        : (isDark
                              ? const Color(0xFF1C1C1E)
                              : const Color(0xFFFFFFFF)),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.largeValue),
                    ),
                    border: Border.all(
                      color: rWin
                          ? (isDark
                                ? const Color(0xFFE53935)
                                : const Color(0xFFE53935))
                          : (isDark
                                ? const Color(0xFF38383A)
                                : const Color(0x33000000)),
                    ),
                  ),
                  child: Column(
                    children: [
                      buildTimelineName(
                        rNameRaw,
                        rLasts,
                        rWin,
                        isDraw || wWin,
                        isDark
                            ? const Color(0xFFE53935)
                            : const Color(0xFFE53935),
                      ),
                      if (KachinukiBattleCardHelper.buildStreakBadge(
                            isWin: rWin,
                            isStreaking: rIsStreaking,
                            streak: rStreak,
                            isDark: isDark,
                          ) !=
                          null) ...[
                        const SizedBox(height: 6),
                        KachinukiBattleCardHelper.buildStreakBadge(
                          isWin: rWin,
                          isStreaking: rIsStreaking,
                          streak: rStreak,
                          isDark: isDark,
                        )!,
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDone
                      ? (isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7))
                      : (isDark
                            ? const Color(0xFF009688).withValues(alpha: 0.15)
                            : const Color(0xFF009688)),
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: isDone
                          ? (isDark
                                ? const Color(0xFF38383A)
                                : const Color(0x33000000))
                          : (isDark
                                ? const Color(0xFF009688)
                                : const Color(0xFF009688)),
                    ),
                  ),
                ),
                child: isDone
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            KachinukiBattleCardHelper.buildScoreMarks(
                              match.redDisplays,
                              isDark
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFFE53935),
                              isDraw || wWin,
                              isDark,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                              ),
                              child: Text(
                                '-',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFFFFFFF)
                                      : AppKendoColors.grey,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            ),
                            KachinukiBattleCardHelper.buildScoreMarks(
                              match.whiteDisplays,
                              isDark
                                  ? const Color(0xFF607D8B)
                                  : const Color(0xFF607D8B),
                              isDraw || rWin,
                              isDark,
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: AppFontWeight.black,
                            color: isDark
                                ? const Color(0xFF009688)
                                : const Color(0xFF009688),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: wWin
                        ? (isDark
                              ? const Color(0xFF607D8B).withValues(alpha: 0.2)
                              : const Color(0xFF607D8B))
                        : (isDark
                              ? const Color(0xFF1C1C1E)
                              : const Color(0xFFFFFFFF)),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(AppRadius.largeValue),
                    ),
                    border: Border.all(
                      color: wWin
                          ? (isDark
                                ? const Color(0xFF607D8B)
                                : const Color(0xFF607D8B))
                          : (isDark
                                ? const Color(0xFF38383A)
                                : const Color(0x33000000)),
                    ),
                  ),
                  child: Column(
                    children: [
                      buildTimelineName(
                        wNameRaw,
                        wLasts,
                        wWin,
                        isDraw || rWin,
                        isDark
                            ? const Color(0xFF607D8B)
                            : const Color(0xFF607D8B),
                      ),
                      if (KachinukiBattleCardHelper.buildStreakBadge(
                            isWin: wWin,
                            isStreaking: wIsStreaking,
                            streak: wStreak,
                            isDark: isDark,
                          ) !=
                          null) ...[
                        const SizedBox(height: 6),
                        KachinukiBattleCardHelper.buildStreakBadge(
                          isWin: wWin,
                          isStreaking: wIsStreaking,
                          streak: wStreak,
                          isDark: isDark,
                        )!,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isDraw)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF38383A)
                    : const Color(0x33000000),
                borderRadius: AppRadius.medium,
              ),
              child: Text(
                '引き分け',
                style: TextStyle(
                  fontSize: AppFontSize.badge,
                  fontWeight: AppFontWeight.bold,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000).withValues(alpha: 0.54),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
