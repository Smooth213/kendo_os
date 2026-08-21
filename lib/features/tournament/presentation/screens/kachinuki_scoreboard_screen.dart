import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_provider.dart';

import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_center_battle_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_team_life_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

export '../components/kachinuki/kachinuki_bracket_painter.dart'
    show KachinukiBracketPainter, PlayerSpan;

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
                Tab(
                  text: 'リアルタイム進行 (スマホ用)',
                  icon: Icon(Icons.view_timeline_outlined),
                ),
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
        ),
      ),
    );
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

  Widget _buildTimelineTab(
    BuildContext context,
    WidgetRef ref,
    List<MatchProjection> matches,
    bool isDark,
  ) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          '試合データがありません',
          style: TextStyle(
            color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF64748B),
          ),
        ),
      );
    }

    final latestMatch = matches.last;
    final rTeam = latestMatch.redName.contains(':')
        ? latestMatch.redName.split(':').first.trim()
        : '赤チーム';
    final wTeam = latestMatch.whiteName.contains(':')
        ? latestMatch.whiteName.split(':').first.trim()
        : '白チーム';

    final List<String> rAllRaw = matches.map((m) => m.redName).toList()
      ..addAll(latestMatch.redRemaining);
    final List<String> wAllRaw = matches.map((m) => m.whiteName).toList()
      ..addAll(latestMatch.whiteRemaining);
    final redLastNames = rAllRaw
        .map((n) => _parseName(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();
    final whiteLastNames = wAllRaw
        .map((n) => _parseName(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();

    final uiStates = <Map<String, dynamic>>[];
    int curRStreak = 0, curWStreak = 0;
    int redDead = 0, whiteDead = 0;

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final rName = m.redName, wName = m.whiteName;
      final isDone = m.status == 'finished' || m.status == 'approved';
      final isApproved = m.status == 'approved';

      int rPts = m.redScore;
      int wPts = m.whiteScore;

      bool rWin = isDone && rPts > wPts;
      bool wWin = isDone && wPts > rPts;
      bool isDraw = isDone && rPts == wPts;

      if (rWin) {
        curRStreak++;
        curWStreak = 0;
        if (isApproved) whiteDead++;
      } else if (wWin) {
        curWStreak++;
        curRStreak = 0;
        if (isApproved) redDead++;
      } else if (isDraw) {
        curRStreak = 0;
        curWStreak = 0;
        if (isApproved) {
          redDead++;
          whiteDead++;
        }
      }

      uiStates.add({
        'match': m,
        'isDone': isDone,
        'rName': rName,
        'wName': wName,
        'rStreak': curRStreak,
        'wStreak': curWStreak,
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
        KachinukiTeamLifeCard(
          redTeamName: rTeam,
          whiteTeamName: wTeam,
          redTotal: redTotal,
          redDead: redDead,
          whiteTotal: whiteTotal,
          whiteDead: whiteDead,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            itemCount: uiStates.length,
            itemBuilder: (context, index) => KachinukiCenterBattleCard(
              uiState: uiStates[index],
              matchNumber: index + 1,
              isDark: isDark,
              rLasts: redLastNames,
              wLasts: whiteLastNames,
            ),
          ),
        ),
      ],
    );
  }

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
