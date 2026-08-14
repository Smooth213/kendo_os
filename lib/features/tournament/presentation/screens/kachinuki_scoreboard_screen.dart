import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_provider.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';

class KachinukiScoreboardScreen extends ConsumerWidget {
  final String groupName;
  const KachinukiScoreboardScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMatches = ref.watch(matchListProvider);
    final teamMatchesModels = allMatches
        .where((m) => m.groupName == groupName)
        .toList();
    teamMatchesModels.sort((a, b) => a.order.compareTo(b.order));

    if (teamMatchesModels.isEmpty) {
      return const Scaffold(body: Center(child: Text('データがありません')));
    }

    final engine = ref.read(kendoRuleEngineProvider);
    final teamMatches = teamMatchesModels.map((m) {
      final analysis = engine.analyzeHistory(m.events, m, m.rule);
      return MatchProjectionMapper.toProjection(m, analysis);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTabColor = isDark
        ? context.appColors.primaryAccent
        : context.appColors.primaryAccent;

    return DefaultTabController(
      length: 2,
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            title: groupName,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline, size: 24),
                tooltip: 'ルールを確認',
                onPressed: () =>
                    _showRuleInfoSheet(context, teamMatchesModels.first),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            bottom: TabBar(
              labelColor: activeTabColor,
              unselectedLabelColor: isDark
                  ? const Color(0xFF8E8E93)
                  : AppKendoColors.grey,
              indicatorColor: activeTabColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: '大会公式 記録表', icon: Icon(Icons.table_chart_outlined)),
                Tab(text: '試合タイムライン', icon: Icon(Icons.timeline)),
              ],
            ),
          ),
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildTraditionalPrintTab(context, ref, teamMatches, isDark),
              _buildTimelineTab(context, ref, teamMatches, isDark),
            ],
          ),
        ), // Scaffold
      ), // LiquidBackground
    ); // DefaultTabController
  }

  Map<String, String> _parseName(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':')
        ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  void _showRuleInfoSheet(BuildContext context, MatchModel match) {
    showRuleInfoBottomSheet(context, match);
  }

  // =========================================================================
  // タブ1: スマホ用タイムライン（残機表示・連勝バッジ付きリッチ版）
  // =========================================================================
  Widget _buildTimelineTab(
    BuildContext context,
    WidgetRef ref,
    List<MatchProjection> teamMatches,
    bool isDark,
  ) {
    final latestMatch = teamMatches.last;
    final rTeam = latestMatch.redName.contains(':')
        ? latestMatch.redName.split(':').first.trim()
        : '赤チーム';
    final wTeam = latestMatch.whiteName.contains(':')
        ? latestMatch.whiteName.split(':').first.trim()
        : '白チーム';

    final List<String> rAllRaw = teamMatches.map((m) => m.redName).toList()
      ..addAll(latestMatch.redRemaining);
    final List<String> wAllRaw = teamMatches.map((m) => m.whiteName).toList()
      ..addAll(latestMatch.whiteRemaining);
    final redLastNames = rAllRaw
        .map((n) => _parseName(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();
    final whiteLastNames = wAllRaw
        .map((n) => _parseName(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();

    int redDead = 0, whiteDead = 0;
    int currentRStreak = 0, currentWStreak = 0;
    String currentRName = '', currentWName = '';
    List<Map<String, dynamic>> uiStates = [];

    for (var m in teamMatches) {
      final rName = m.redName;
      final wName = m.whiteName;

      if (rName != currentRName) {
        currentRStreak = 0;
        currentRName = rName;
      }
      if (wName != currentWName) {
        currentWStreak = 0;
        currentWName = wName;
      }

      bool isDone = m.status == 'finished' || m.status == 'approved';
      if (isDone) {
        int rPts = m.redScore;
        int wPts = m.whiteScore;

        if (rPts < wPts) {
          redDead++;
          currentWStreak++;
          currentRStreak = 0;
        } else if (wPts < rPts) {
          whiteDead++;
          currentRStreak++;
          currentWStreak = 0;
        } else {
          redDead++;
          whiteDead++;
          currentRStreak = 0;
          currentWStreak = 0;
        }
      }

      uiStates.add({
        'match': m,
        'rStreak': currentRStreak,
        'wStreak': currentWStreak,
        'rName': rName,
        'wName': wName,
        'isDone': isDone,
      });
    }

    int redAlive = latestMatch.redRemaining.length + 1;
    int whiteAlive = latestMatch.whiteRemaining.length + 1;

    if (latestMatch.status == 'finished' || latestMatch.status == 'approved') {
      int rPts = latestMatch.redScore;
      int wPts = latestMatch.whiteScore;
      if (rPts < wPts) {
        redAlive--;
      } else if (wPts < rPts) {
        whiteAlive--;
      } else {
        redAlive--;
        whiteAlive--;
      }
    }

    int redTotal = redAlive + redDead;
    int whiteTotal = whiteAlive + whiteDead;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          padding: const EdgeInsets.all(AppSpacing.roundValue),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
            borderRadius: AppRadius.xlarge,
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFF3F51B5),
            ),
          ),
          child: Column(
            children: [
              Text(
                'チーム生存状況（残機）',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  fontWeight: AppFontWeight.bold,
                  color: isDark ? const Color(0xFFFFFFFF) : AppKendoColors.grey,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rTeam,
                          style: TextStyle(
                            fontWeight: AppFontWeight.black,
                            color: isDark
                                ? const Color(0xFFE53935)
                                : const Color(0xFFE53935),
                            fontSize: AppFontSize.subhead,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(
                            redTotal,
                            (i) => Icon(
                              Icons.shield,
                              color: i >= redDead
                                  ? AppKendoColors.hansokuRed
                                  : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0x33000000)),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: AppFontWeight.black,
                        fontSize: AppFontSize.display,
                        color: isDark
                            ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                            : const Color(0xFF000000).withValues(alpha: 0.12),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          wTeam,
                          style: TextStyle(
                            fontWeight: AppFontWeight.black,
                            color: isDark
                                ? const Color(0xFF607D8B)
                                : const Color(0xFF607D8B),
                            fontSize: AppFontSize.subhead,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: List.generate(
                            whiteTotal,
                            (i) => Icon(
                              Icons.shield,
                              color: i >= whiteDead
                                  ? (isDark
                                        ? const Color(0xFF607D8B)
                                        : const Color(0xFF607D8B))
                                  : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0x33000000)),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            itemCount: uiStates.length,
            itemBuilder: (context, index) => _buildCenterBattleCard(
              ref,
              uiStates[index],
              index + 1,
              isDark,
              redLastNames,
              whiteLastNames,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterBattleCard(
    WidgetRef ref,
    Map<String, dynamic> uiState,
    int matchNumber,
    bool isDark,
    List<String> rLasts,
    List<String> wLasts,
  ) {
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
        return Text(
          '(欠員)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSize.subhead,
            fontWeight: AppFontWeight.bold,
            color: const Color(0x8A000000),
          ),
        );
      }

      final parsed = _parseName(raw);
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
                      if (rWin && rStreak >= 2) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                                : const Color(0xFFD4AF37),
                            borderRadius: AppRadius.small,
                          ),
                          child: Text(
                            '🔥 $rStreak人抜き',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFD4AF37),
                              fontSize: AppFontSize.badge,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (rIsStreaking) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
                                : const Color(0xFFD4AF37),
                            borderRadius: AppRadius.small,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFD4AF37),
                            ),
                          ),
                          child: Text(
                            '🔥 $rStreak人抜き中',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFD4AF37),
                              fontSize: AppFontSize.badge,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
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
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildScoreMarks(
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
                          _buildScoreMarks(
                            match.whiteDisplays,
                            isDark
                                ? const Color(0xFF607D8B)
                                : const Color(0xFF607D8B),
                            isDraw || rWin,
                            isDark,
                          ),
                        ],
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
                      if (wWin && wStreak >= 2) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                                : const Color(0xFFD4AF37),
                            borderRadius: AppRadius.small,
                          ),
                          child: Text(
                            '🔥 $wStreak人抜き',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFD4AF37),
                              fontSize: AppFontSize.badge,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (wIsStreaking) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
                                : const Color(0xFFD4AF37),
                            borderRadius: AppRadius.small,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFD4AF37),
                            ),
                          ),
                          child: Text(
                            '🔥 $wStreak人抜き中',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFD4AF37),
                              fontSize: AppFontSize.badge,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ),
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

  Widget _buildScoreMarks(
    List<PointDisplay> pts,
    Color color,
    bool isFaded,
    bool isDark,
  ) {
    if (pts.isEmpty) return const SizedBox(width: 20);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pts.map((p) {
        final textColor = isFaded
            ? (isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000))
            : color;
        if (p.isFirstMatchPoint && p.mark != '◯') {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: textColor, width: 2),
            ),
            child: Text(
              p.mark,
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Text(
            p.mark,
            style: TextStyle(
              fontSize: AppFontSize.subhead,
              fontWeight: AppFontWeight.black,
              color: textColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================================
  // タブ2: 大会公式 記録表（横スクロール対応）
  // =========================================================================
  Widget _buildTraditionalPrintTab(
    BuildContext context,
    WidgetRef ref,
    List<MatchProjection> teamMatches,
    bool isDark,
  ) {
    final int maxCols =
        teamMatches.length +
        math.max(
          teamMatches.last.redRemaining.length,
          teamMatches.last.whiteRemaining.length,
        );
    final double estimatedWidth = 60.0 + (maxCols * 60.0) + 120.0;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.large,
        child: InteractiveViewer(
          constrained: false,
          minScale: 0.5,
          maxScale: 3.0,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: estimatedWidth < MediaQuery.of(context).size.width
                  ? MediaQuery.of(context).size.width
                  : estimatedWidth,
              height: 550,
              child: CustomPaint(
                painter: KachinukiBracketPainter(
                  matches: teamMatches,
                  isDark: isDark,
                  ref: ref,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// ★ 究極の伝統的スコア描画エンジン（デザイン改修・スクロール対応版）
// =========================================================================
class PlayerSpan {
  final String rawName;
  final String lastName;
  final String initial;
  final int startIndex;
  int endIndex;
  PlayerSpan(
    this.rawName,
    this.lastName,
    this.initial,
    this.startIndex,
    this.endIndex,
  );
}

class KachinukiBracketPainter extends CustomPainter {
  final List<MatchProjection> matches;
  final bool isDark;
  // ★ nullable: shouldRepaintのみのテスト時はnullを渡す（paint()内でのみ使用）
  final WidgetRef? ref;
  KachinukiBracketPainter({
    required this.matches,
    this.isDark = false,
    this.ref,
  });

  Map<String, String> _parse(String raw) {
    if (raw.contains('欠員')) {
      return {'last': '', 'first': ''};
    }
    String clean = raw.contains(':')
        ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (matches.isEmpty) return;

    // --- 🎨 カラーパレット定義 ---
    final Color redWinColor = isDark
        ? const Color(0xFFE53935)
        : const Color(0xFFE53935);
    final Color whiteWinColor = isDark
        ? const Color(0xFF3F51B5)
        : const Color(0xFF3F51B5);
    final Color centerLineColor = isDark
        ? const Color(0xFF3F51B5)
        : const Color(0xFF3F51B5);
    final Color baseLineColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0x33000000);
    // ★ 修正2：引き分けの対戦線を濃いグレーに
    final Color drawLineColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0x8A000000);
    final Color drawCrossColor = isDark
        ? const Color(0xFFD4AF37)
        : const Color(0xFFD4AF37);

    final redBgPaint = Paint()
      ..color = isDark
          ? const Color(0xFFE53935).withValues(alpha: 0.08)
          : const Color(0xFFE53935).withValues(alpha: 0.03);
    final whiteBgPaint = Paint()
      ..color = isDark
          ? const Color(0xFF3F51B5).withValues(alpha: 0.12)
          : const Color(0xFF3F51B5).withValues(alpha: 0.03);

    final thickLinePaint = Paint()
      ..color = centerLineColor
      ..strokeWidth = 2.5;
    final thinLinePaint = Paint()
      ..color = baseLineColor
      ..strokeWidth = 1.0;

    final double dx = 60.0;
    final double startX = 60.0;
    final double y0 = 0.0;
    final double y1 = 150.0;
    final double y2 = 350.0;
    final double y3 = 500.0;

    // 背景の塗り分け
    canvas.drawRect(
      Rect.fromLTRB(0, y0, size.width, (y1 + y2) / 2),
      redBgPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, (y1 + y2) / 2, size.width, y3),
      whiteBgPaint,
    );

    final String rTeam = matches.first.redName.contains(':')
        ? matches.first.redName.split(':').first.trim()
        : '赤チーム';
    final String wTeam = matches.first.whiteName.contains(':')
        ? matches.first.whiteName.split(':').first.trim()
        : '白チーム';

    List<String> rAllRaw = matches.map((m) => m.redName).toList()
      ..addAll(matches.last.redRemaining);
    List<String> wAllRaw = matches.map((m) => m.whiteName).toList()
      ..addAll(matches.last.whiteRemaining);
    List<String> rLasts = rAllRaw
        .map((n) => _parse(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();
    List<String> wLasts = wAllRaw
        .map((n) => _parse(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();

    List<PlayerSpan> redSpans = [];
    List<PlayerSpan> whiteSpans = [];
    String currentRed = "", currentWhite = "";

    for (int i = 0; i < matches.length; i++) {
      final rRaw = matches[i].redName;
      final wRaw = matches[i].whiteName;
      final rP = _parse(rRaw);
      final rShow =
          rLasts.where((n) => n == rP['last']).length > 1 &&
          rP['first']!.isNotEmpty;
      if (rRaw != currentRed) {
        redSpans.add(
          PlayerSpan(
            rRaw,
            rP['last']!,
            rShow ? rP['first']!.substring(0, 1) : '',
            i,
            i,
          ),
        );
        currentRed = rRaw;
      } else {
        redSpans.last.endIndex = i;
      }

      final wP = _parse(wRaw);
      final wShow =
          wLasts.where((n) => n == wP['last']).length > 1 &&
          wP['first']!.isNotEmpty;
      if (wRaw != currentWhite) {
        whiteSpans.add(
          PlayerSpan(
            wRaw,
            wP['last']!,
            wShow ? wP['first']!.substring(0, 1) : '',
            i,
            i,
          ),
        );
        currentWhite = wRaw;
      } else {
        whiteSpans.last.endIndex = i;
      }
    }

    int currentRedIdx = matches.length;
    for (String name in matches.last.redRemaining) {
      final p = _parse(name);
      final show =
          rLasts.where((n) => n == p['last']).length > 1 &&
          p['first']!.isNotEmpty;
      redSpans.add(
        PlayerSpan(
          name,
          p['last']!,
          show ? p['first']!.substring(0, 1) : '',
          currentRedIdx,
          currentRedIdx,
        ),
      );
      currentRedIdx++;
    }

    int currentWhiteIdx = matches.length;
    for (String name in matches.last.whiteRemaining) {
      final p = _parse(name);
      final show =
          wLasts.where((n) => n == p['last']).length > 1 &&
          p['first']!.isNotEmpty;
      whiteSpans.add(
        PlayerSpan(
          name,
          p['last']!,
          show ? p['first']!.substring(0, 1) : '',
          currentWhiteIdx,
          currentWhiteIdx,
        ),
      );
      currentWhiteIdx++;
    }

    int totalCols = currentRedIdx > currentWhiteIdx
        ? currentRedIdx
        : currentWhiteIdx;
    final totalWidth = startX + (totalCols * dx);

    // 外枠と水平線の描画
    canvas.drawRect(
      Rect.fromLTRB(0, y0, totalWidth, y3),
      thickLinePaint..style = PaintingStyle.stroke,
    );
    canvas.drawLine(Offset(0, y1), Offset(totalWidth, y1), thickLinePaint);
    canvas.drawLine(Offset(0, y2), Offset(totalWidth, y2), thickLinePaint);
    canvas.drawLine(Offset(startX, y0), Offset(startX, y3), thickLinePaint);

    // ★ 修正1：中央の横線（最も重要な仕切り）の削除
    // canvas.drawLine(Offset(startX, (y1 + y2) / 2), Offset(totalWidth, (y1 + y2) / 2), thickLinePaint);

    // ★ 修正4：赤チームのチーム名を赤色にする（引数に customColor を追加）
    _drawVerticalText(
      canvas,
      null,
      rTeam,
      Offset(startX / 2, (y0 + y1) / 2),
      true,
      customColor: redWinColor,
    );
    _drawVerticalText(
      canvas,
      null,
      wTeam,
      Offset(startX / 2, (y2 + y3) / 2),
      true,
    ); // 白チームはそのまま

    for (var span in redSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(
        Rect.fromLTRB(left, y0, right, y1),
        thinLinePaint..style = PaintingStyle.stroke,
      );
      _drawVerticalText(
        canvas,
        span,
        '',
        Offset((left + right) / 2, (y0 + y1) / 2),
        false,
      );
    }

    for (var span in whiteSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(
        Rect.fromLTRB(left, y2, right, y3),
        thinLinePaint..style = PaintingStyle.stroke,
      );
      _drawVerticalText(
        canvas,
        span,
        '',
        Offset((left + right) / 2, (y2 + y3) / 2),
        false,
      );
    }

    // 試合対戦線の描画
    for (int i = 0; i < matches.length; i++) {
      var match = matches[i];
      if (match.status != 'finished' && match.status != 'approved') continue;
      var rSpan = redSpans.firstWhere(
        (s) => i >= s.startIndex && i <= s.endIndex,
      );
      var wSpan = whiteSpans.firstWhere(
        (s) => i >= s.startIndex && i <= s.endIndex,
      );
      Offset redTopVertex = Offset(
        startX + (rSpan.startIndex + rSpan.endIndex + 1) * dx / 2,
        y1,
      );
      Offset whiteBottomVertex = Offset(
        startX + (wSpan.startIndex + wSpan.endIndex + 1) * dx / 2,
        y2,
      );

      Color currentWinColor = baseLineColor;
      double strokeW = 1.0;

      if (match.redScore > match.whiteScore) {
        currentWinColor = redWinColor;
        strokeW = 2.0;
      } else if (match.whiteScore > match.redScore) {
        currentWinColor = whiteWinColor;
        strokeW = 2.0;
      } else {
        // ★ 修正2：引き分けの時は濃いグレーの線にする
        currentWinColor = drawLineColor;
        strokeW = 1.5;
      }

      canvas.drawLine(
        redTopVertex,
        whiteBottomVertex,
        Paint()
          ..color = currentWinColor
          ..strokeWidth = strokeW,
      );

      final isEncho =
          match.note.contains('延長') ||
          match.matchType == '代表戦' ||
          match.matchType == '大将延長戦' ||
          match.matchType.contains('代表') ||
          match.matchType.contains('延長');

      if (match.redScore == match.whiteScore) {
        // ★ 修正3：引き分けの✕の太さを太く（strokeWidth: 3.0）
        _drawSmallCross(
          canvas,
          Offset(
            (redTopVertex.dx + whiteBottomVertex.dx) / 2,
            (redTopVertex.dy + whiteBottomVertex.dy) / 2,
          ),
          Paint()
            ..color = drawCrossColor
            ..strokeWidth = 3.0,
        );
      } else {
        if (isEncho) {
          _drawEnchoTextCenter(
            canvas,
            Offset(
              (redTopVertex.dx + whiteBottomVertex.dx) / 2,
              (redTopVertex.dy + whiteBottomVertex.dy) / 2,
            ),
            isDark,
          );
        }
        if (match.redScore > match.whiteScore) {
          _drawScoreMarksVertical(
            canvas,
            match.redDisplays,
            Offset(startX + (i * dx) + dx / 2, y1 + 15),
            true,
          );
        } else {
          _drawScoreMarksVertical(
            canvas,
            match.whiteDisplays,
            Offset(startX + (i * dx) + dx / 2, y2 - 15),
            false,
          );
        }
      }
    }
  }

  void _drawEnchoTextCenter(Canvas canvas, Offset center, bool isDark) {
    const double width = 16.0;
    const double height = 26.0;
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final rect = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.tinyValue)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.tinyValue)),
      borderPaint,
    );

    final textStyle = TextStyle(
      color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      fontSize: AppFontSize.nano,
      fontWeight: AppFontWeight.bold,
      fontFamily: 'Noto Sans JP',
    );

    final tpEn = TextPainter(
      text: TextSpan(text: '延', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpEn.paint(canvas, Offset(center.dx - (tpEn.width / 2), center.dy - 11));

    final tpCho = TextPainter(
      text: TextSpan(text: '長', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpCho.paint(canvas, Offset(center.dx - (tpCho.width / 2), center.dy + 1));
  }

  // ★ 修正4：引数に customColor を追加
  void _drawVerticalText(
    Canvas canvas,
    PlayerSpan? span,
    String teamName,
    Offset center,
    bool isTeamName, {
    Color? customColor,
  }) {
    double availableHeight = 130.0;
    double charHeight = 22.0;
    double fontSize = isTeamName ? 18.0 : 16.0;

    // customColor があればそれを使用、なければデフォルトの色
    final Color textColor =
        customColor ??
        (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000));

    if (!isTeamName && span != null && span.rawName.contains('欠員')) {
      final tp = TextPainter(
        text: TextSpan(
          text: '(欠員)',
          style: TextStyle(
            color: const Color(0x8A000000),
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)),
      );
      return;
    }

    String text = isTeamName ? teamName : span!.lastName;
    final chars = text.split('');
    if (chars.length * charHeight > availableHeight) {
      charHeight = availableHeight / chars.length;
      fontSize = charHeight * 0.8;
    }

    final textStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: isTeamName ? AppFontWeight.black : AppFontWeight.bold,
      fontFamily: 'Noto Sans JP',
    );

    double y = center.dy - ((chars.length * charHeight) / 2) + (charHeight / 2);
    for (var char in chars) {
      final tp = TextPainter(
        text: TextSpan(text: char, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx - (tp.width / 2), y - (tp.height / 2)));
      y += charHeight;
    }

    if (!isTeamName && span != null && span.initial.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: span.initial,
          style: textStyle.copyWith(
            fontSize: fontSize * 0.65,
            color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx + (fontSize * 0.2), y - (charHeight * 0.8)),
      );
    }
  }

  void _drawSmallCross(Canvas canvas, Offset center, Paint paint) {
    const double size = 8.0;
    canvas.drawLine(
      Offset(center.dx - size, center.dy - size),
      Offset(center.dx + size, center.dy + size),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + size, center.dy - size),
      Offset(center.dx - size, center.dy + size),
      paint,
    );
  }

  void _drawScoreMarksVertical(
    Canvas canvas,
    List<PointDisplay> pts,
    Offset baseAnchor,
    bool isRed,
  ) {
    double y = isRed ? baseAnchor.dy : baseAnchor.dy - (pts.length * 24.0);
    // 技の色を統一（Red700 / Indigo800）
    final Color color = isRed
        ? (isDark ? const Color(0xFFE53935) : const Color(0xFFE53935))
        : (isDark ? const Color(0xFF3F51B5) : const Color(0xFF3F51B5));

    final textStyle = TextStyle(
      color: color,
      fontSize: AppFontSize.bodyMedium,
      fontWeight: AppFontWeight.black,
    );
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var p in pts) {
      final tp = TextPainter(
        text: TextSpan(text: p.mark, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(baseAnchor.dx - (tp.width / 2), y));
      if (p.isFirstMatchPoint && p.mark != '◯') {
        canvas.drawCircle(
          Offset(baseAnchor.dx, y + (tp.height / 2)),
          11.5,
          circlePaint,
        );
      }
      y += 24.0;
    }
  }

  @override
  bool shouldRepaint(covariant KachinukiBracketPainter oldDelegate) {
    // ★ 最適化 (Web/Native共通): 描画に影響するフィールドのみを明示的に比較
    // PointDisplayは==未実装のためlistEqualsの深い比較が参照比較になる。
    // status/score/nameのみを比較して不要な再描画を安全にスキップする。
    if (oldDelegate.isDark != isDark) return true;
    if (oldDelegate.matches.length != matches.length) return true;
    for (int i = 0; i < matches.length; i++) {
      final o = oldDelegate.matches[i];
      final n = matches[i];
      if (o.status != n.status ||
          o.redScore != n.redScore ||
          o.whiteScore != n.whiteScore ||
          o.redName != n.redName ||
          o.whiteName != n.whiteName ||
          o.note != n.note) {
        return true;
      }
    }
    return false;
  }
}
