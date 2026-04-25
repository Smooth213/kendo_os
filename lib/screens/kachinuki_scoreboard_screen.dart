import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // ★ 追加: go_routerをインポートしてcontext拡張メソッドを有効化
import 'package:flutter/services.dart'; // ★ 追加: シート表示時の心地よい振動用
import '../models/match_model.dart';
import '../models/score_event.dart';
import '../providers/match_list_provider.dart';
// ★ Phase 1-3: UIロジック削除のため、ドメイン層のエンジンとプロバイダをインポート
import '../domain/kendo_rule_engine.dart';
import '../providers/match_provider.dart';

// ★ 【The Ultimate State】デジタルとアナログの完全融合（タブ切替）
class KachinukiScoreboardScreen extends ConsumerWidget {
  final String groupName;
  const KachinukiScoreboardScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMatches = ref.watch(matchListProvider);
    final teamMatches = allMatches.where((m) => m.groupName == groupName).toList();
    teamMatches.sort((a, b) => a.order.compareTo(b.order));

    if (teamMatches.isEmpty) return const Scaffold(body: Center(child: Text('データがありません')));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final appBarColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final headerTextColor = isDark ? Colors.white : Colors.indigo.shade900;
    final activeTabColor = isDark ? Colors.indigoAccent.shade100 : Colors.indigo.shade700;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: headerTextColor, size: 20),
            // ★ 真の解決: こちらも勝ち抜き戦のスコアボードで履歴消滅クラッシュを防ぐフェイルセーフを実装
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else if (teamMatches.isNotEmpty && teamMatches.first.tournamentId != null) {
                context.go('/home/${teamMatches.first.tournamentId}');
              } else {
                context.go('/');
              }
            },
          ),
          title: Text('勝ち抜き戦 記録', style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor, fontSize: 16)),
          backgroundColor: appBarColor,
          elevation: 0,
          // ★ 追加：AppBarの右上にルール確認用のインフォメーションボタンを配置
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline, color: headerTextColor, size: 24),
              tooltip: 'ルールを確認',
              onPressed: () => _showRuleInfoSheet(context, teamMatches.first),
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
      ),
    );
  }

  // ★ 追加：名前分割ヘルパー
  Map<String, String> _parseName(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  // ★ 追加：すべてのレギュレーション情報を網羅した完璧なシート
  void _showRuleInfoSheet(BuildContext context, MatchModel match) {
    HapticFeedback.mediumImpact(); 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final rule = match.rule; 

    // ★ 修正：備考欄の文字からも形式を推測する（古いデータ救済用）
    final bool isLegacyLeague = match.note.contains('[リーグ戦]');
    final bool isLeague = (rule?.isLeague ?? false) || isLegacyLeague;

    final bool isIndividual = match.matchType == 'individual' || match.matchType == '選手' || match.matchType.contains('個人戦') || (rule != null && rule.positions.length == 1 && (rule.positions.first == '選手' || rule.positions.first == '個人戦'));
    
    String formatText = isIndividual ? '個人戦' : '団体戦';
    if (rule?.isRenseikai ?? false) {
      formatText = '錬成会';
    } else if (match.isKachinuki || (rule?.isKachinuki ?? false)) {
      formatText = '勝ち抜き戦';
    } else if (isLeague) {
      formatText = 'リーグ戦（総当たり）';
    }

    final double matchTime = rule?.matchTimeMinutes ?? match.matchTimeMinutes.toDouble();
    final isRunningTime = rule?.isRunningTime ?? match.isRunningTime;
    
    String timeStr = matchTime == matchTime.toInt() ? '${matchTime.toInt()}分' : '${matchTime.toInt()}分${((matchTime % 1) * 60).toInt()}秒';
    final String timeDesc = '$timeStr (${isRunningTime ? "通し/空回し" : "都度ストップ"})';

    final bool enchoUnlimited = rule?.isEnchoUnlimited ?? false;
    final double enchoMins = rule?.enchoTimeMinutes ?? match.extensionTimeMinutes?.toDouble() ?? 0.0;
    final int enchoCount = rule?.enchoCount ?? match.extensionCount ?? 1;
    final bool enchoEnabled = match.hasExtension || enchoUnlimited || enchoMins > 0;
    
    String enchoDesc = 'なし';
    if (enchoEnabled) {
      if (enchoUnlimited) {
        enchoDesc = 'あり (無制限)';
      } else {
        String extTimeStr = enchoMins == enchoMins.toInt() ? '${enchoMins.toInt()}分' : '${enchoMins.toInt()}分${((enchoMins % 1) * 60).toInt()}秒';
        enchoDesc = 'あり ($extTimeStr・$enchoCount回)';
      }
    }
    
    final bool hanteiEnabled = rule?.hasHantei ?? match.hasHantei;

    String daihyoDesc = 'なし';
    if (rule != null) {
      final bool hasRep = rule.hasRepresentativeMatch;
      final bool isIppon = rule.isDaihyoIpponShobu;
      daihyoDesc = hasRep ? (isIppon ? 'あり (一本勝負)' : 'あり (三本勝負)') : 'なし';
    } else {
      daihyoDesc = '不明（古いデータ）';
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
            Row(
              children: [
                Icon(Icons.gavel_rounded, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700, size: 22),
                const SizedBox(width: 8),
                Text('試合レギュレーション', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const Divider(height: 32),
            
            if (rule == null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade300)),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('この試合はアップデート前に作成されたため、詳細なルールが保存されていません。新しく作成した試合では正しく表示されます。', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

            _buildRuleRow('試合形式', formatText, isDark),
            _buildRuleRow('試合時間', timeDesc, isDark),

            if (rule?.isRenseikai ?? false) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('錬成会設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))),
              _buildRuleRow('進行方式', rule!.renseikaiType, isDark),
              if (rule.renseikaiType == '時間制') _buildRuleRow('制限時間', '${rule.overallTimeMinutes} 分', isDark),
            ] else ...[
              _buildRuleRow('延長戦', enchoDesc, isDark),
              _buildRuleRow('判定', hanteiEnabled ? 'あり' : 'なし', isDark),
            ],

            if (match.isKachinuki || (rule?.isKachinuki ?? false)) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('勝ち抜き戦設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))),
              _buildRuleRow('無制限条件', rule?.kachinukiUnlimitedType ?? '大将対大将', isDark),
              // ★ 修正：ポジション表示を勝ち抜き戦の枠組みの中に統合する
              if (rule != null && rule.positions.isNotEmpty) _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],

            // ★ 修正：予備判定(isLeague)を使って、古いデータでも確実に隠す
            if (!isIndividual && !(rule?.isRenseikai ?? false) && !match.isKachinuki && !(rule?.isKachinuki ?? false) && !isLeague) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('団体戦・チーム設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))),
              _buildRuleRow('代表戦', daihyoDesc, isDark),
              if (rule != null && rule.positions.isNotEmpty) _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],

            if (!isIndividual && (rule?.isRenseikai ?? false) && rule != null && rule.positions.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('ポジション設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))),
              _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],

            if (rule != null && rule.isLeague) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('リーグ戦設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange))),
              // ★ 修正：リーグ戦のポジション表示を、リーグ戦専用枠の中に美しく統合する
              if (!isIndividual && rule.positions.isNotEmpty) _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
              _buildRuleRow('勝ち点設定', '勝: ${rule.winPoint} / 分: ${rule.drawPoint} / 負: ${rule.lossPoint}', isDark),
              _buildRuleRow('同点時代表戦', rule.hasLeagueDaihyo ? 'あり' : 'なし', isDark),
            ],

            if (match.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildRuleRow('備考・メモ', match.note, isDark),
            ],
              
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.bold)),
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
  // タブ1: スマホ用タイムライン（第1案＋バッジ）
  // =========================================================================
  Widget _buildTimelineTab(BuildContext context, WidgetRef ref, List<MatchModel> teamMatches, bool isDark) {
    final latestMatch = teamMatches.last;
    final rTeam = latestMatch.redName.contains(':') ? latestMatch.redName.split(':').first.trim() : '赤チーム';
    final wTeam = latestMatch.whiteName.contains(':') ? latestMatch.whiteName.split(':').first.trim() : '白チーム';

    // ★ 同姓判定のための全選手リスト（残機も含む）
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
        // ★ Phase 1-3: UIからビジネスロジックを削除し、ドメインエンジンを呼び出す
        final analysis = ref.read(kendoRuleEngineProvider).analyzeHistory(m.events, m, null);
        int rPts = analysis.context.redIppon;
        int wPts = analysis.context.whiteIppon;

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
      // ★ Phase 1-3: UIからビジネスロジックを削除し、ドメインエンジンを呼び出す
      final analysis = ref.read(kendoRuleEngineProvider).analyzeHistory(latestMatch.events, latestMatch, null);
      int rPts = analysis.context.redIppon;
      int wPts = analysis.context.whiteIppon;
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
            // ★ Phase 1-3: refを渡す
            itemBuilder: (context, index) => _buildCenterBattleCard(ref, uiStates[index], index + 1, isDark, redLastNames, whiteLastNames),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterBattleCard(WidgetRef ref, Map<String, dynamic> uiState, int matchNumber, bool isDark, List<String> rLasts, List<String> wLasts) {
    final MatchModel match = uiState['match'];
    final bool isDone = uiState['isDone'];
    final int rStreak = uiState['rStreak'], wStreak = uiState['wStreak'];
    final String rNameRaw = uiState['rName'], wNameRaw = uiState['wName'];

    // ★ Phase 1-3: UIからビジネスロジックを削除し、ドメインエンジンを呼び出す
    final analysis = ref.read(kendoRuleEngineProvider).analyzeHistory(match.events, match, null);
    int rPts = analysis.context.redIppon;
    int wPts = analysis.context.whiteIppon;

    bool isDraw = isDone && rPts == wPts, rWin = isDone && rPts > wPts, wWin = isDone && wPts > rPts;
    bool rIsStreaking = !isDone && rStreak > 0, wIsStreaking = !isDone && wStreak > 0;

    // ★ 修正：タイムライン用の名前描画ヘルパー
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
                      buildTimelineName(rNameRaw, rLasts, rWin, isDraw || wWin, isDark ? Colors.red.shade400 : Colors.red.shade700), // ★ 修正
                      if (rWin && rStreak >= 2) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade100, borderRadius: BorderRadius.circular(8)), child: Text('🔥 $rStreak人抜き', style: TextStyle(color: isDark ? Colors.amber.shade400 : Colors.amber.shade900, fontSize: 10, fontWeight: FontWeight.bold)))]
                      else if (rIsStreaking) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isDark ? Colors.amber.shade900.withValues(alpha: 0.1) : Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.amber.shade900 : Colors.amber.shade200)), child: Text('🔥 $rStreak人抜き中', style: TextStyle(color: isDark ? Colors.amber.shade500 : Colors.amber.shade800, fontSize: 10, fontWeight: FontWeight.bold)))]
                    ],
                  ),
                ),
              ),
              Container(
                width: 90, padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: isDone ? (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100) : (isDark ? Colors.teal.shade900.withValues(alpha: 0.15) : Colors.teal.shade50), border: Border.symmetric(horizontal: BorderSide(color: isDone ? (isDark ? const Color(0xFF38383A) : Colors.grey.shade200) : (isDark ? Colors.teal.shade900 : Colors.teal.shade200)))),
                child: isDone // ★ Phase 1-3: analysis.displays を使用
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildScoreMarks(analysis.displays[Side.red]!, isDark ? Colors.red.shade400 : Colors.red.shade700, isDraw || wWin, isDark), Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('-', style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey, fontWeight: FontWeight.bold))), _buildScoreMarks(analysis.displays[Side.white]!, isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade800, isDraw || rWin, isDark)])
                  : Center(child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.teal.shade400 : Colors.teal))),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(color: wWin ? (isDark ? Colors.blueGrey.shade900.withValues(alpha: 0.2) : Colors.blueGrey.shade50) : (isDark ? const Color(0xFF1C1C1E) : Colors.white), borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)), border: Border.all(color: wWin ? (isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200) : (isDark ? const Color(0xFF38383A) : Colors.grey.shade200))),
                  child: Column(
                    children: [
                      buildTimelineName(wNameRaw, wLasts, wWin, isDraw || rWin, isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade800), // ★ 修正
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

  // ★ Phase 1-3: UI固有の _PointData ではなく、ドメイン層の PointDisplay を使う
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
  // タブ2: アナログ印刷用（真・放射状・縦線撤廃版）
  // =========================================================================
  Widget _buildTraditionalPrintTab(BuildContext context, WidgetRef ref, List<MatchModel> teamMatches, bool isDark) {
    const double colWidth = 60.0;
    const double leftMargin = 60.0; 
    
    int redRem = teamMatches.last.redRemaining.length;
    int whiteRem = teamMatches.last.whiteRemaining.length;
    int maxRem = redRem > whiteRem ? redRem : whiteRem;
    int totalCols = teamMatches.length + maxRem;

    final canvasWidth = leftMargin + (totalCols * colWidth);

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(40),
      minScale: 0.2,
      maxScale: 3.0,
      child: Container(
        margin: const EdgeInsets.all(24),
        color: isDark ? Colors.black : Colors.white, 
        width: canvasWidth < 600 ? 600 : canvasWidth, 
        height: 500, 
        child: CustomPaint(
          // ★ Phase 1-3: refを渡してエンジンを使えるようにする
          painter: KachinukiBracketPainter(matches: teamMatches, isDark: isDark, ref: ref), 
          size: Size.infinite,
        ),
      ),
    );
  }
}

// =========================================================================
// ★ 究極の伝統的スコア描画エンジン（縦線撤廃・完全センター放射・極小✕対応・同姓対応）
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
  final List<MatchModel> matches;
  final bool isDark; 
  final WidgetRef ref; // ★ Phase 1-3: エンジンを使うためにrefを受け取る
  KachinukiBracketPainter({required this.matches, this.isDark = false, required this.ref});

  // ★ このメソッドは _drawVerticalText 内で使われているため残す
  Map<String, String> _parse(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (matches.isEmpty) return;

    final lineColor = isDark ? Colors.white : Colors.black; 
    final thickLinePaint = Paint()..color = lineColor..strokeWidth = 2.5;
    final thinLinePaint = Paint()..color = lineColor..strokeWidth = 1.0;
    
    final double dx = 60.0;       
    final double startX = 60.0;   
    final double y0 = 0.0;        
    final double y1 = 150.0;      
    final double y2 = 350.0;      
    final double y3 = 500.0;      

    final String rTeam = matches.first.redName.contains(':') ? matches.first.redName.split(':').first.trim() : '赤チーム';
    final String wTeam = matches.first.whiteName.contains(':') ? matches.first.whiteName.split(':').first.trim() : '白チーム';

    // ★ 同姓判定のための全名抽出
    List<String> rAllRaw = matches.map((m) => m.redName).toList()..addAll(matches.last.redRemaining);
    List<String> wAllRaw = matches.map((m) => m.whiteName).toList()..addAll(matches.last.whiteRemaining);
    List<String> rLasts = rAllRaw.map((n) => _parse(n)['last']!).where((s) => s.isNotEmpty).toList();
    List<String> wLasts = wAllRaw.map((n) => _parse(n)['last']!).where((s) => s.isNotEmpty).toList();

    List<PlayerSpan> redSpans = [];
    List<PlayerSpan> whiteSpans = [];
    String currentRed = "", currentWhite = "";

    // 試合に出た選手のスパン計算
    for (int i = 0; i < matches.length; i++) {
      final rRaw = matches[i].redName;
      final wRaw = matches[i].whiteName;

      final rP = _parse(rRaw);
      final rShow = rLasts.where((n) => n == rP['last']).length > 1 && rP['first']!.isNotEmpty;
      if (rRaw != currentRed) { 
        redSpans.add(PlayerSpan(rRaw, rP['last']!, rShow ? rP['first']!.substring(0, 1) : '', i, i)); 
        currentRed = rRaw; 
      } else { redSpans.last.endIndex = i; }

      final wP = _parse(wRaw);
      final wShow = wLasts.where((n) => n == wP['last']).length > 1 && wP['first']!.isNotEmpty;
      if (wRaw != currentWhite) { 
        whiteSpans.add(PlayerSpan(wRaw, wP['last']!, wShow ? wP['first']!.substring(0, 1) : '', i, i)); 
        currentWhite = wRaw; 
      } else { whiteSpans.last.endIndex = i; }
    }

    // 出場待ち選手のスパン追加
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

    // 左端にチーム名を縦書き
    _drawVerticalText(canvas, null, rTeam, Offset(startX / 2, (y0 + y1) / 2), true);
    _drawVerticalText(canvas, null, wTeam, Offset(startX / 2, (y2 + y3) / 2), true);

    // 赤チームの選手名枠
    for (var span in redSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(Rect.fromLTRB(left, y0, right, y1), thinLinePaint..style = PaintingStyle.stroke);
      _drawVerticalText(canvas, span, '', Offset((left + right) / 2, (y0 + y1) / 2), false);
    }

    // 白チームの選手名枠
    for (var span in whiteSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(Rect.fromLTRB(left, y2, right, y3), thinLinePaint..style = PaintingStyle.stroke);
      _drawVerticalText(canvas, span, '', Offset((left + right) / 2, (y2 + y3) / 2), false);
    }

    // 中央の試合エリアの描画
    for (int i = 0; i < matches.length; i++) {
      var match = matches[i];
      double leftX = startX + (i * dx);
      bool isDone = match.status == 'finished' || match.status == 'approved';
      if (!isDone) continue;

      var rSpan = redSpans.firstWhere((s) => i >= s.startIndex && i <= s.endIndex);
      var wSpan = whiteSpans.firstWhere((s) => i >= s.startIndex && i <= s.endIndex);
      
      Offset redTopVertex = Offset(startX + (rSpan.startIndex + rSpan.endIndex + 1) * dx / 2, y1);
      Offset whiteBottomVertex = Offset(startX + (wSpan.startIndex + wSpan.endIndex + 1) * dx / 2, y2);

      // ★ Phase 1-3: UIからビジネスロジックを削除し、ドメインエンジンを呼び出す
      final analysis = ref.read(kendoRuleEngineProvider).analyzeHistory(match.events, match, null);
      int rPts = analysis.context.redIppon;
      int wPts = analysis.context.whiteIppon;

      canvas.drawLine(redTopVertex, whiteBottomVertex, thinLinePaint);

      if (rPts == wPts) {
        Offset midPoint = Offset((redTopVertex.dx + whiteBottomVertex.dx) / 2, (redTopVertex.dy + whiteBottomVertex.dy) / 2);
        _drawSmallCross(canvas, midPoint, thickLinePaint);
      } else if (rPts > wPts) { // ★ Phase 1-3: analysis.displays を使用
        _drawScoreMarksVertical(canvas, analysis.displays[Side.red]!, Offset(leftX + dx / 2, y1 + 15), true);
      } else { // ★ Phase 1-3: analysis.displays を使用
        _drawScoreMarksVertical(canvas, analysis.displays[Side.white]!, Offset(leftX + dx / 2, y2 - 15), false);
      }
    }
  }

  // ★ 修正：同姓の1文字目を右下に添える完璧な縦書き描画ヘルパー
  void _drawVerticalText(Canvas canvas, PlayerSpan? span, String teamName, Offset center, bool isTeamName) {
    double availableHeight = 130.0; 
    double charHeight = 22.0;
    double fontSize = isTeamName ? 18.0 : 16.0;
    final textColor = isDark ? Colors.white : Colors.black; 

    // アプリ上の表示なので欠員はグレーで表示
    if (!isTeamName && span != null && span.rawName.contains('欠員')) {
      final tp = TextPainter(text: TextSpan(text: '(欠員)', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
      return;
    }

    String text = isTeamName ? teamName : span!.lastName;
    final chars = text.split('');
    
    if (chars.length * charHeight > availableHeight) {
      charHeight = availableHeight / chars.length;
      fontSize = charHeight * 0.8;
    }

    final textStyle = TextStyle(color: textColor, fontSize: fontSize, fontWeight: isTeamName ? FontWeight.bold : FontWeight.normal);
    double y = center.dy - ((chars.length * charHeight) / 2) + (charHeight / 2);

    for (var char in chars) {
      if (char == 'ー' || char == '-') {
        final double lineLen = fontSize * 0.7;
        canvas.drawLine(Offset(center.dx, y - lineLen / 2), Offset(center.dx, y + lineLen / 2), Paint()..color = textColor..strokeWidth = 1.5);
      } else if (char == '(' || char == ')' || char == '（' || char == '）') {
        final tp = TextPainter(text: TextSpan(text: char, style: textStyle.copyWith(fontSize: fontSize * 0.8)), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(center.dx - (tp.width / 2), y - 4));
      } else {
        final tp = TextPainter(text: TextSpan(text: char, style: textStyle), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(center.dx - (tp.width / 2), y - (tp.height / 2)));
      }
      y += charHeight;
    }

    // ★ 名前（1文字目）を右下に配置
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

  // ★ Phase 1-3: UI固有の _PointData ではなく、ドメイン層の PointDisplay を使う
  void _drawScoreMarksVertical(Canvas canvas, List<PointDisplay> pts, Offset baseAnchor, bool isRed) {
    double y = isRed ? baseAnchor.dy : baseAnchor.dy - (pts.length * 24.0);
    final textColor = isDark ? Colors.white : Colors.black; 
    final textStyle = TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold);
    final circlePaint = Paint()..color = textColor..style = PaintingStyle.stroke..strokeWidth = 1.2;

    for (var p in pts) {
      final tp = TextPainter(text: TextSpan(text: p.mark, style: textStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(baseAnchor.dx - (tp.width / 2), y));

      if (p.isFirstMatchPoint && p.mark != '◯') {
        canvas.drawCircle(Offset(baseAnchor.dx, y + (tp.height / 2)), 11.0, circlePaint);
      }
      y += 24.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}