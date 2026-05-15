import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:kendo_os/domain/entities/match_model.dart';
import '../providers/match_list_provider.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import '../providers/match_provider.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import '../../shared/widgets/liquid_background.dart';

class KachinukiScoreboardScreen extends ConsumerWidget {
  final String groupName;
  const KachinukiScoreboardScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMatches = ref.watch(matchListProvider);
    final teamMatchesModels = allMatches.where((m) => m.groupName == groupName).toList();
    teamMatchesModels.sort((a, b) => a.order.compareTo(b.order));

    if (teamMatchesModels.isEmpty) return const Scaffold(body: Center(child: Text('データがありません')));

    final engine = ref.read(kendoRuleEngineProvider);
    final teamMatches = teamMatchesModels.map((m) {
      final analysis = engine.analyzeHistory(m.events, m, m.rule);
      return MatchProjectionMapper.toProjection(m, analysis);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final headerTextColor = isDark ? Colors.white : Colors.indigo.shade900;
    final activeTabColor = isDark ? Colors.indigoAccent.shade100 : Colors.indigo.shade700;

    return DefaultTabController(
      length: 2,
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: headerTextColor, size: 20),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else if (teamMatchesModels.isNotEmpty && teamMatchesModels.first.tournamentId != null) {
                  context.go('/home/${teamMatchesModels.first.tournamentId}');
                } else {
                  context.go('/');
                }
              },
            ),
          title: Text('勝ち抜き戦 記録', style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor, fontSize: 16)),
          backgroundColor: appBarColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline, color: headerTextColor, size: 24),
              tooltip: 'ルールを確認',
              onPressed: () => _showRuleInfoSheet(context, teamMatchesModels.first),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: activeTabColor,
            unselectedLabelColor: isDark ? const Color(0xFF8E8E93) : Colors.grey,
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
    String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  void _showRuleInfoSheet(BuildContext context, MatchModel match) {
    HapticFeedback.mediumImpact(); 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rule = match.rule; 
    final bool isLegacyLeague = match.note.contains('[リーグ戦]');
    final bool isLeague = (rule?.isLeague ?? false) || isLegacyLeague;
    final bool isIndividual = match.matchType == 'individual' || match.matchType == '選手' || match.matchType.contains('個人戦');
    
    String formatText = isIndividual ? '個人戦' : '団体戦';
    if (match.isKachinuki || (rule?.isKachinuki ?? false)) {
      formatText = '勝ち抜き戦';
    } else if (isLeague) {
      formatText = 'リーグ戦';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            _buildRuleRow('試合形式', formatText, isDark),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('閉じる'),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8), 
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }

  // =========================================================================
  // タブ1: スマホ用タイムライン（残機表示・連勝バッジ付きリッチ版）
  // =========================================================================
  Widget _buildTimelineTab(BuildContext context, WidgetRef ref, List<MatchProjection> teamMatches, bool isDark) {
    final latestMatch = teamMatches.last;
    final rTeam = latestMatch.redName.contains(':') ? latestMatch.redName.split(':').first.trim() : '赤チーム';
    final wTeam = latestMatch.whiteName.contains(':') ? latestMatch.whiteName.split(':').first.trim() : '白チーム';

    final List<String> rAllRaw = teamMatches.map((m) => m.redName).toList()..addAll(latestMatch.redRemaining);
    final List<String> wAllRaw = teamMatches.map((m) => m.whiteName).toList()..addAll(latestMatch.whiteRemaining);
    final redLastNames = rAllRaw.map((n) => _parseName(n)['last']!).where((s) => s.isNotEmpty).toList();
    final whiteLastNames = wAllRaw.map((n) => _parseName(n)['last']!).where((s) => s.isNotEmpty).toList();

    int redDead = 0, whiteDead = 0;
    int currentRStreak = 0, currentWStreak = 0;
    String currentRName = '', currentWName = '';
    List<Map<String, dynamic>> uiStates = [];

    for (var m in teamMatches) {
      final rName = m.redName;
      final wName = m.whiteName;

      if (rName != currentRName) { currentRStreak = 0; currentRName = rName; }
      if (wName != currentWName) { currentWStreak = 0; currentWName = wName; }

      bool isDone = m.status == 'finished' || m.status == 'approved';
      if (isDone) {
        int rPts = m.redScore;
        int wPts = m.whiteScore;

        if (rPts < wPts) { redDead++; currentWStreak++; currentRStreak = 0; } 
        else if (wPts < rPts) { whiteDead++; currentRStreak++; currentWStreak = 0; } 
        else { redDead++; whiteDead++; currentRStreak = 0; currentWStreak = 0; }
      }

      uiStates.add({
        'match': m, 'rStreak': currentRStreak, 'wStreak': currentWStreak,
        'rName': rName, 'wName': wName, 'isDone': isDone,
      });
    }

    int redAlive = latestMatch.redRemaining.length + 1;
    int whiteAlive = latestMatch.whiteRemaining.length + 1;
    
    if (latestMatch.status == 'finished' || latestMatch.status == 'approved') {
      int rPts = latestMatch.redScore;
      int wPts = latestMatch.whiteScore;
      if (rPts < wPts) { redAlive--; } else if (wPts < rPts) { whiteAlive--; } else { redAlive--; whiteAlive--; }
    }

    int redTotal = redAlive + redDead;
    int whiteTotal = whiteAlive + whiteDead;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.indigo.shade50),
          ),
          child: Column(
            children: [
              Text('チーム生存状況（残機）', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey, letterSpacing: 2)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rTeam, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.red.shade400 : Colors.red.shade700, fontSize: 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: List.generate(redTotal, (i) => Icon(Icons.shield, color: i >= redDead ? Colors.red.shade500 : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200), size: 28)),
                        ),
                      ],
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: isDark ? Colors.white10 : Colors.black12, fontStyle: FontStyle.italic))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(wTeam, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade800, fontSize: 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6, runSpacing: 6, alignment: WrapAlignment.end,
                          children: List.generate(whiteTotal, (i) => Icon(Icons.shield, color: i >= whiteDead ? (isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200), size: 28)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: uiStates.length,
            itemBuilder: (context, index) => _buildCenterBattleCard(ref, uiStates[index], index + 1, isDark, redLastNames, whiteLastNames),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterBattleCard(WidgetRef ref, Map<String, dynamic> uiState, int matchNumber, bool isDark, List<String> rLasts, List<String> wLasts) {
    final MatchProjection match = uiState['match'];
    final bool isDone = uiState['isDone'];
    final int rStreak = uiState['rStreak'], wStreak = uiState['wStreak'];
    final String rNameRaw = uiState['rName'], wNameRaw = uiState['wName'];

    int rPts = match.redScore;
    int wPts = match.whiteScore;

    bool isDraw = isDone && rPts == wPts, rWin = isDone && rPts > wPts, wWin = isDone && wPts > rPts;
    bool rIsStreaking = !isDone && rStreak > 0, wIsStreaking = !isDone && wStreak > 0;

    Widget buildTimelineName(String raw, List<String> teamLastNames, bool isWin, bool isFaded, Color winColor) {
      if (raw.contains('欠員')) return Text('(欠員)', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500));
      
      final parsed = _parseName(raw);
      final showInitial = teamLastNames.where((n) => n == parsed['last']).length > 1 && parsed['first']!.isNotEmpty;
      
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 16, fontWeight: isWin ? FontWeight.w900 : FontWeight.bold, color: isFaded ? Colors.grey.shade600 : winColor),
          children: [
            TextSpan(text: parsed['last']),
            if (showInitial)
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 1),
                  child: Text(parsed['first']!.substring(0, 1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isFaded ? Colors.grey.shade500 : winColor.withValues(alpha: 0.7))),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text('$matchNumber試合目', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(color: rWin ? (isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50) : (isDark ? const Color(0xFF1C1C1E) : Colors.white), borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)), border: Border.all(color: rWin ? (isDark ? Colors.red.shade900 : Colors.red.shade200) : (isDark ? const Color(0xFF38383A) : Colors.grey.shade200))),
                  child: Column(
                    children: [
                      buildTimelineName(rNameRaw, rLasts, rWin, isDraw || wWin, isDark ? Colors.red.shade400 : Colors.red.shade700),
                      if (rWin && rStreak >= 2) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade100, borderRadius: BorderRadius.circular(8)), child: Text('🔥 $rStreak人抜き', style: TextStyle(color: isDark ? Colors.amber.shade400 : Colors.amber.shade900, fontSize: 10, fontWeight: FontWeight.bold)))]
                      else if (rIsStreaking) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isDark ? Colors.amber.shade900.withValues(alpha: 0.1) : Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.amber.shade900 : Colors.amber.shade200)), child: Text('🔥 $rStreak人抜き中', style: TextStyle(color: isDark ? Colors.amber.shade500 : Colors.amber.shade800, fontSize: 10, fontWeight: FontWeight.bold)))]
                    ],
                  ),
                ),
              ),
              Container(
                width: 90, padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: isDone ? (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100) : (isDark ? Colors.teal.shade900.withValues(alpha: 0.15) : Colors.teal.shade50), border: Border.symmetric(horizontal: BorderSide(color: isDone ? (isDark ? const Color(0xFF38383A) : Colors.grey.shade200) : (isDark ? Colors.teal.shade900 : Colors.teal.shade200)))),
                child: isDone
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildScoreMarks(match.redDisplays, isDark ? Colors.red.shade400 : Colors.red.shade700, isDraw || wWin, isDark), Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('-', style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey, fontWeight: FontWeight.bold))), _buildScoreMarks(match.whiteDisplays, isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade800, isDraw || rWin, isDark)])
                  : Center(child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.teal.shade400 : Colors.teal))),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(color: wWin ? (isDark ? Colors.blueGrey.shade900.withValues(alpha: 0.2) : Colors.blueGrey.shade50) : (isDark ? const Color(0xFF1C1C1E) : Colors.white), borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)), border: Border.all(color: wWin ? (isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200) : (isDark ? const Color(0xFF38383A) : Colors.grey.shade200))),
                  child: Column(
                    children: [
                      buildTimelineName(wNameRaw, wLasts, wWin, isDraw || rWin, isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade800),
                      if (wWin && wStreak >= 2) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade100, borderRadius: BorderRadius.circular(8)), child: Text('🔥 $wStreak人抜き', style: TextStyle(color: isDark ? Colors.amber.shade400 : Colors.amber.shade900, fontSize: 10, fontWeight: FontWeight.bold)))]
                      else if (wIsStreaking) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isDark ? Colors.amber.shade900.withValues(alpha: 0.1) : Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.amber.shade900 : Colors.amber.shade200)), child: Text('🔥 $wStreak人抜き中', style: TextStyle(color: isDark ? Colors.amber.shade500 : Colors.amber.shade800, fontSize: 10, fontWeight: FontWeight.bold)))]
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isDraw) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), decoration: BoxDecoration(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, borderRadius: BorderRadius.circular(12)), child: Text('引き分け', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildScoreMarks(List<PointDisplay> pts, Color color, bool isFaded, bool isDark) {
    if (pts.isEmpty) return const SizedBox(width: 20);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pts.map((p) {
        final textColor = isFaded ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400) : color;
        if (p.isFirstMatchPoint && p.mark != '◯') {
          return Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: textColor, width: 2)), child: Text(p.mark, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)));
        }
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text(p.mark, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)));
      }).toList(),
    );
  }

  // =========================================================================
  // タブ2: 大会公式 記録表（横スクロール対応）
  // =========================================================================
  Widget _buildTraditionalPrintTab(BuildContext context, WidgetRef ref, List<MatchProjection> teamMatches, bool isDark) {
    final int maxCols = teamMatches.length + math.max(teamMatches.last.redRemaining.length, teamMatches.last.whiteRemaining.length);
    final double estimatedWidth = 60.0 + (maxCols * 60.0) + 120.0; 

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InteractiveViewer(
          constrained: false, 
          minScale: 0.5,
          maxScale: 3.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: estimatedWidth < MediaQuery.of(context).size.width ? MediaQuery.of(context).size.width : estimatedWidth,
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
  PlayerSpan(this.rawName, this.lastName, this.initial, this.startIndex, this.endIndex);
}

class KachinukiBracketPainter extends CustomPainter {
  final List<MatchProjection> matches;
  final bool isDark; 
  final WidgetRef ref; 
  KachinukiBracketPainter({required this.matches, this.isDark = false, required this.ref});

  Map<String, String> _parse(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (matches.isEmpty) return;

    // --- 🎨 カラーパレット定義 ---
    final Color redWinColor = isDark ? Colors.red.shade400 : Colors.red.shade700;
    final Color whiteWinColor = isDark ? Colors.indigo.shade300 : Colors.indigo.shade800;
    final Color centerLineColor = isDark ? Colors.indigo.shade400 : Colors.indigo.shade900;
    final Color baseLineColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    // ★ 修正2：引き分けの対戦線を濃いグレーに
    final Color drawLineColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500; 
    final Color drawCrossColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;

    final redBgPaint = Paint()..color = isDark ? Colors.red.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.03);
    final whiteBgPaint = Paint()..color = isDark ? Colors.indigo.withValues(alpha: 0.12) : Colors.indigo.withValues(alpha: 0.03);

    final thickLinePaint = Paint()..color = centerLineColor..strokeWidth = 2.5;
    final thinLinePaint = Paint()..color = baseLineColor..strokeWidth = 1.0;
    
    final double dx = 60.0;       
    final double startX = 60.0;   
    final double y0 = 0.0;        
    final double y1 = 150.0;      
    final double y2 = 350.0;      
    final double y3 = 500.0;      

    // 背景の塗り分け
    canvas.drawRect(Rect.fromLTRB(0, y0, size.width, (y1 + y2) / 2), redBgPaint);
    canvas.drawRect(Rect.fromLTRB(0, (y1 + y2) / 2, size.width, y3), whiteBgPaint);

    final String rTeam = matches.first.redName.contains(':') ? matches.first.redName.split(':').first.trim() : '赤チーム';
    final String wTeam = matches.first.whiteName.contains(':') ? matches.first.whiteName.split(':').first.trim() : '白チーム';

    List<String> rAllRaw = matches.map((m) => m.redName).toList()..addAll(matches.last.redRemaining);
    List<String> wAllRaw = matches.map((m) => m.whiteName).toList()..addAll(matches.last.whiteRemaining);
    List<String> rLasts = rAllRaw.map((n) => _parse(n)['last']!).where((s) => s.isNotEmpty).toList();
    List<String> wLasts = wAllRaw.map((n) => _parse(n)['last']!).where((s) => s.isNotEmpty).toList();

    List<PlayerSpan> redSpans = [];
    List<PlayerSpan> whiteSpans = [];
    String currentRed = "", currentWhite = "";

    for (int i = 0; i < matches.length; i++) {
      final rRaw = matches[i].redName;
      final wRaw = matches[i].whiteName;
      final rP = _parse(rRaw);
      final rShow = rLasts.where((n) => n == rP['last']).length > 1 && rP['first']!.isNotEmpty;
      if (rRaw != currentRed) { redSpans.add(PlayerSpan(rRaw, rP['last']!, rShow ? rP['first']!.substring(0, 1) : '', i, i)); currentRed = rRaw; } 
      else { redSpans.last.endIndex = i; }

      final wP = _parse(wRaw);
      final wShow = wLasts.where((n) => n == wP['last']).length > 1 && wP['first']!.isNotEmpty;
      if (wRaw != currentWhite) { whiteSpans.add(PlayerSpan(wRaw, wP['last']!, wShow ? wP['first']!.substring(0, 1) : '', i, i)); currentWhite = wRaw; } 
      else { whiteSpans.last.endIndex = i; }
    }

    int currentRedIdx = matches.length;
    for (String name in matches.last.redRemaining) {
      final p = _parse(name);
      final show = rLasts.where((n) => n == p['last']).length > 1 && p['first']!.isNotEmpty;
      redSpans.add(PlayerSpan(name, p['last']!, show ? p['first']!.substring(0, 1) : '', currentRedIdx, currentRedIdx));
      currentRedIdx++;
    }

    int currentWhiteIdx = matches.length;
    for (String name in matches.last.whiteRemaining) {
      final p = _parse(name);
      final show = wLasts.where((n) => n == p['last']).length > 1 && p['first']!.isNotEmpty;
      whiteSpans.add(PlayerSpan(name, p['last']!, show ? p['first']!.substring(0, 1) : '', currentWhiteIdx, currentWhiteIdx));
      currentWhiteIdx++;
    }

    int totalCols = currentRedIdx > currentWhiteIdx ? currentRedIdx : currentWhiteIdx;
    final totalWidth = startX + (totalCols * dx);

    // 外枠と水平線の描画
    canvas.drawRect(Rect.fromLTRB(0, y0, totalWidth, y3), thickLinePaint..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(0, y1), Offset(totalWidth, y1), thickLinePaint);
    canvas.drawLine(Offset(0, y2), Offset(totalWidth, y2), thickLinePaint);
    canvas.drawLine(Offset(startX, y0), Offset(startX, y3), thickLinePaint); 

    // ★ 修正1：中央の横線（最も重要な仕切り）の削除
    // canvas.drawLine(Offset(startX, (y1 + y2) / 2), Offset(totalWidth, (y1 + y2) / 2), thickLinePaint);

    // ★ 修正4：赤チームのチーム名を赤色にする（引数に customColor を追加）
    _drawVerticalText(canvas, null, rTeam, Offset(startX / 2, (y0 + y1) / 2), true, customColor: redWinColor);
    _drawVerticalText(canvas, null, wTeam, Offset(startX / 2, (y2 + y3) / 2), true); // 白チームはそのまま

    for (var span in redSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(Rect.fromLTRB(left, y0, right, y1), thinLinePaint..style = PaintingStyle.stroke);
      _drawVerticalText(canvas, span, '', Offset((left + right) / 2, (y0 + y1) / 2), false);
    }

    for (var span in whiteSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(Rect.fromLTRB(left, y2, right, y3), thinLinePaint..style = PaintingStyle.stroke);
      _drawVerticalText(canvas, span, '', Offset((left + right) / 2, (y2 + y3) / 2), false);
    }

    // 試合対戦線の描画
    for (int i = 0; i < matches.length; i++) {
      var match = matches[i];
      if (match.status != 'finished' && match.status != 'approved') continue;
      var rSpan = redSpans.firstWhere((s) => i >= s.startIndex && i <= s.endIndex);
      var wSpan = whiteSpans.firstWhere((s) => i >= s.startIndex && i <= s.endIndex);
      Offset redTopVertex = Offset(startX + (rSpan.startIndex + rSpan.endIndex + 1) * dx / 2, y1);
      Offset whiteBottomVertex = Offset(startX + (wSpan.startIndex + wSpan.endIndex + 1) * dx / 2, y2);

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

      canvas.drawLine(redTopVertex, whiteBottomVertex, Paint()..color = currentWinColor..strokeWidth = strokeW);

      if (match.redScore == match.whiteScore) {
        // ★ 修正3：引き分けの✕の太さを太く（strokeWidth: 3.0）
        _drawSmallCross(canvas, Offset((redTopVertex.dx + whiteBottomVertex.dx) / 2, (redTopVertex.dy + whiteBottomVertex.dy) / 2), Paint()..color = drawCrossColor..strokeWidth = 3.0);
      } else if (match.redScore > match.whiteScore) {
        _drawScoreMarksVertical(canvas, match.redDisplays, Offset(startX + (i * dx) + dx / 2, y1 + 15), true);
      } else {
        _drawScoreMarksVertical(canvas, match.whiteDisplays, Offset(startX + (i * dx) + dx / 2, y2 - 15), false);
      }
    }
  }

  // ★ 修正4：引数に customColor を追加
  void _drawVerticalText(Canvas canvas, PlayerSpan? span, String teamName, Offset center, bool isTeamName, {Color? customColor}) {
    double availableHeight = 130.0; 
    double charHeight = 22.0;
    double fontSize = isTeamName ? 18.0 : 16.0;
    
    // customColor があればそれを使用、なければデフォルトの色
    final Color textColor = customColor ?? (isDark ? Colors.white : Colors.black87); 
    
    if (!isTeamName && span != null && span.rawName.contains('欠員')) {
      final tp = TextPainter(text: TextSpan(text: '(欠員)', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
      return;
    }
    
    String text = isTeamName ? teamName : span!.lastName;
    final chars = text.split('');
    if (chars.length * charHeight > availableHeight) { charHeight = availableHeight / chars.length; fontSize = charHeight * 0.8; }
    
    final textStyle = TextStyle(
      color: textColor, 
      fontSize: fontSize, 
      fontWeight: isTeamName ? FontWeight.w900 : FontWeight.bold,
      fontFamily: 'Noto Sans JP',
    );
    
    double y = center.dy - ((chars.length * charHeight) / 2) + (charHeight / 2);
    for (var char in chars) {
      final tp = TextPainter(text: TextSpan(text: char, style: textStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(center.dx - (tp.width / 2), y - (tp.height / 2)));
      y += charHeight;
    }
    
    if (!isTeamName && span != null && span.initial.isNotEmpty) {
      final tp = TextPainter(text: TextSpan(text: span.initial, style: textStyle.copyWith(fontSize: fontSize * 0.65, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(center.dx + (fontSize * 0.2), y - (charHeight * 0.8)));
    }
  }

  void _drawSmallCross(Canvas canvas, Offset center, Paint paint) {
    const double size = 8.0; 
    canvas.drawLine(Offset(center.dx - size, center.dy - size), Offset(center.dx + size, center.dy + size), paint);
    canvas.drawLine(Offset(center.dx + size, center.dy - size), Offset(center.dx - size, center.dy + size), paint);
  }

  void _drawScoreMarksVertical(Canvas canvas, List<PointDisplay> pts, Offset baseAnchor, bool isRed) {
    double y = isRed ? baseAnchor.dy : baseAnchor.dy - (pts.length * 24.0);
    // 技の色を統一（Red700 / Indigo800）
    final Color color = isRed ? (isDark ? Colors.red.shade400 : Colors.red.shade700) : (isDark ? Colors.indigo.shade300 : Colors.indigo.shade800);
    
    final textStyle = TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900);
    final circlePaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    
    for (var p in pts) {
      final tp = TextPainter(text: TextSpan(text: p.mark, style: textStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(baseAnchor.dx - (tp.width / 2), y));
      if (p.isFirstMatchPoint && p.mark != '◯') {
        canvas.drawCircle(Offset(baseAnchor.dx, y + (tp.height / 2)), 11.5, circlePaint);
      }
      y += 24.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}