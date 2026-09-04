import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

class LargeViewerScoreboard extends StatelessWidget {
  final MatchProjection projection;
  final MatchModel? activeMatch;
  final bool isDark;

  const LargeViewerScoreboard({
    super.key,
    required this.projection,
    required this.activeMatch,
    required this.isDark,
  });

  String _cleanName(String name) {
    if (name.contains('欠員')) return '(欠員)';
    if (!name.contains(':')) return name.trim();
    return name.split(':').last.replaceAll(')', '').trim();
  }

  int _getFoulCount(Side side) {
    if (activeMatch == null) return 0;
    final engine = KendoRuleEngine();
    final activeEvents = engine.filterActiveEvents(activeMatch!.events);
    return activeEvents
        .where(
          (e) => e.side == side && (e.isHansoku || e.type == PointType.hansoku),
        )
        .length;
  }

  String _getWinner(MatchModel? match) {
    if (match == null) {
      if (projection.redScore > projection.whiteScore) return 'red';
      if (projection.whiteScore > projection.redScore) return 'white';
      return 'none';
    }

    final isFinished = match.status == 'approved' || match.status == 'finished';
    if (!isFinished) return 'none';

    if (match.redScore > match.whiteScore) {
      return 'red';
    } else if (match.whiteScore > match.redScore) {
      return 'white';
    } else {
      final hasRedHantei = match.events.any(
        (e) =>
            !e.isCanceled && e.side == Side.red && e.type == PointType.hantei,
      );
      final hasWhiteHantei = match.events.any(
        (e) =>
            !e.isCanceled && e.side == Side.white && e.type == PointType.hantei,
      );
      final hasRedFusen = match.events.any(
        (e) => !e.isCanceled && e.side == Side.red && e.type == PointType.fusen,
      );
      final hasWhiteFusen = match.events.any(
        (e) =>
            !e.isCanceled && e.side == Side.white && e.type == PointType.fusen,
      );

      if (hasRedHantei || hasRedFusen) {
        return 'red';
      } else if (hasWhiteHantei || hasWhiteFusen) {
        return 'white';
      } else {
        return 'draw';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 【Phase 3】RepaintBoundaryによる描画境界の完全分離
    // 大画面観戦スコアボードの頻繁な打突・スコア同期描画を隔離
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxHeight > constraints.maxWidth;
          if (isPortrait) {
            return _buildPortraitLayout(context);
          } else {
            return _buildLandscapeLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    final redName = _cleanName(projection.redName);
    final whiteName = _cleanName(projection.whiteName);
    final redFouls = _getFoulCount(Side.red);
    final whiteFouls = _getFoulCount(Side.white);

    final isFinished =
        projection.status == 'approved' || projection.status == 'finished';
    final winner = _getWinner(activeMatch);
    final isRedWinner = isFinished && winner == 'red';
    final isWhiteWinner = isFinished && winner == 'white';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Expanded(
            child: _buildPlayerCard(
              context: context,
              side: Side.red,
              name: redName,
              displays: projection.redDisplays,
              foulCount: redFouls,
              isWinner: isRedWinner,
              cardColor: isDark
                  ? const Color(0xFF2C1616)
                  : const Color(0xFFFFF0F0),
              textColor: isDark
                  ? const Color(0xFFFF6B6B)
                  : AppKendoColors.hansokuRed,
            ),
          ),
          _buildCenterDivider(isPortrait: true),
          Expanded(
            child: _buildPlayerCard(
              context: context,
              side: Side.white,
              name: whiteName,
              displays: projection.whiteDisplays,
              foulCount: whiteFouls,
              isWinner: isWhiteWinner,
              cardColor: isDark
                  ? const Color(0xFF182230)
                  : const Color(0xFFF8FAFC),
              textColor: isDark
                  ? AppKendoColors.pureWhite
                  : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    final redName = _cleanName(projection.redName);
    final whiteName = _cleanName(projection.whiteName);
    final redFouls = _getFoulCount(Side.red);
    final whiteFouls = _getFoulCount(Side.white);

    final isFinished =
        projection.status == 'approved' || projection.status == 'finished';
    final winner = _getWinner(activeMatch);
    final isRedWinner = isFinished && winner == 'red';
    final isWhiteWinner = isFinished && winner == 'white';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildPlayerCard(
              context: context,
              side: Side.red,
              name: redName,
              displays: projection.redDisplays,
              foulCount: redFouls,
              isWinner: isRedWinner,
              cardColor: isDark
                  ? const Color(0xFF2C1616)
                  : const Color(0xFFFFF0F0),
              textColor: isDark
                  ? const Color(0xFFFF6B6B)
                  : AppKendoColors.hansokuRed,
            ),
          ),
          _buildCenterDivider(isPortrait: false),
          Expanded(
            child: _buildPlayerCard(
              context: context,
              side: Side.white,
              name: whiteName,
              displays: projection.whiteDisplays,
              foulCount: whiteFouls,
              isWinner: isWhiteWinner,
              cardColor: isDark
                  ? const Color(0xFF182230)
                  : const Color(0xFFF8FAFC),
              textColor: isDark
                  ? AppKendoColors.pureWhite
                  : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({
    required BuildContext context,
    required Side side,
    required String name,
    required List<PointDisplay> displays,
    required int foulCount,
    required bool isWinner,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.xlarge,
        border: Border.all(
          color: isWinner
              ? const Color(0xFFD97706)
              : (isDark
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                    : const Color(0xFF000000).withValues(alpha: 0.12)),
          width: isWinner ? 4.0 : 1.0,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isWinner)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFD97706),
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      '勝者',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: Color(0xFFD97706),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              name,
              style: TextStyle(
                fontSize: AppFontSize.scoreboardTimer,
                fontWeight: AppFontWeight.bold,
                color: textColor,
                letterSpacing: 1.5,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildLargePointBox(displays, isWinner, side),
            const SizedBox(height: AppSpacing.md),
            if (foulCount > 0)
              Text(
                List.filled(foulCount, '▲').join(''),
                style: const TextStyle(
                  fontSize: AppFontSize.hero,
                  color: Color(0xFFD97706),
                  fontWeight: AppFontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargePointBox(
    List<PointDisplay> displays,
    bool isWinner,
    Side side,
  ) {
    final color = side == Side.red
        ? (isDark ? const Color(0xFFFF6B6B) : AppKendoColors.hansokuRed)
        : (isDark ? AppKendoColors.pureWhite : const Color(0xFF334155));

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isWinner)
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.6),
                  width: 3.5,
                ),
              ),
            ),
          if (displays.isNotEmpty)
            Positioned(
              top: 14,
              left: AppSpacing.lg,
              child: _buildPointBadge(displays[0], color),
            ),
          if (displays.length > 1)
            Positioned(
              bottom: 14,
              right: AppSpacing.lg,
              child: _buildPointBadge(displays[1], color),
            ),
        ],
      ),
    );
  }

  Widget _buildPointBadge(PointDisplay pd, Color color) {
    const double fs = 24;
    const double badgeSize = 42;

    if (pd.isFirstMatchPoint) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.7 : 1.0),
            width: 2.5,
          ),
        ),
        child: Text(
          pd.mark == '判定' ? '判' : pd.mark,
          style: TextStyle(
            fontSize: fs,
            fontWeight: AppFontWeight.bold,
            color: color,
            height: 1.0,
          ),
        ),
      );
    } else {
      return Container(
        width: badgeSize,
        height: badgeSize,
        alignment: Alignment.center,
        child: Text(
          pd.mark == '判定' ? '判' : pd.mark,
          style: TextStyle(
            fontSize: fs,
            fontWeight: AppFontWeight.bold,
            color: color,
            height: 1.0,
          ),
        ),
      );
    }
  }

  Widget _buildCenterDivider({required bool isPortrait}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFE2E8F0),
        borderRadius: AppRadius.full,
        border: Border.all(
          color: isDark
              ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
              : const Color(0x33000000),
          width: 1.0,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF3F51B5),
          borderRadius: AppRadius.medium,
        ),
        child: Text(
          '${projection.redScore} - ${projection.whiteScore}',
          style: const TextStyle(
            fontSize: AppFontSize.display,
            fontWeight: AppFontWeight.bold,
            color: AppKendoColors.pureWhite,
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isPortrait ? AppSpacing.lg : 0.0,
        horizontal: isPortrait ? 0.0 : AppSpacing.lg,
      ),
      child: Center(child: content),
    );
  }
}
