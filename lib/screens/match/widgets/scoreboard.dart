import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/match_model.dart';
import '../../../../models/score_event.dart';
import '../../../../domain/kendo_rule_engine.dart';
import '../../../../providers/match_provider.dart';
import '../../../../usecase/match_usecase.dart'; // ★ 追加: UseCaseの参照

class MatchScoreboard extends ConsumerWidget {
  final MatchModel match;
  final String? myUserId;
  final Function(String side) onNameTap;

  const MatchScoreboard({
    super.key,
    required this.match,
    required this.myUserId,
    required this.onNameTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ Phase 4: エンジンから表示用データを直接取得する
    final engine = ref.watch(kendoRuleEngineProvider);
    final ptsMap = MatchUseCase.calculatePointDisplays(match, engine);
    final isDone = match.status == 'finished' || match.status == 'approved';

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Row(
          children: [
            _buildScoreColumn(context, Side.red, match, ptsMap),
            _buildScoreColumn(context, Side.white, match, ptsMap),
          ],
        ),
        if (isDone) _buildResultOverlay(context, ptsMap),
      ],
    );
  }

  // ★ 修正：引数 side を Side 型へ
  Widget _buildScoreColumn(BuildContext context, Side side, MatchModel match, Map<Side, List<PointDisplay>> allPts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pts = allPts[side] ?? []; // ★ Side型でMapへアクセス
    
    final rScore = (match.redScore as num).toInt();
    final wScore = (match.whiteScore as num).toInt();
    final isWinner = (side == Side.red && rScore > wScore) || (side == Side.white && wScore > rScore);
    final isFinished = match.status == 'approved' || match.status == 'finished';

    final nameColor = side == Side.red 
        ? (isDark ? Colors.red.shade400 : Colors.red.shade700) 
        : (isDark ? Colors.grey.shade300 : Colors.blueGrey.shade800);

    return Expanded(
      child: FittedBox( // ★ Phase 8-1: 横画面で縦幅が足りない場合、自動で縮小させてエラーを防ぐ
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => onNameTap(side.name),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: // ★ Step 6-2: 長い名前（特に外部選手や道場名付き）でも枠をはみ出さない動的スケーリング
                    FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _cleanName(side == Side.red ? match.redName : match.whiteName),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: nameColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isFinished && isWinner)
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: nameColor.withValues(alpha: 0.6), width: 6),
                      ),
                    ),
                  
                  SizedBox(
                    width: 100, 
                    height: 100,
                    child: Stack(
                      children: [
                        if (pts.isNotEmpty)
                          Positioned(top: 0, left: 0, child: _buildPointMark(pts[0], nameColor, isDark)),
                        if (pts.length > 1)
                          Positioned(bottom: 0, right: 0, child: _buildPointMark(pts[1], nameColor, isDark)),
                        if (pts.length > 2)
                          Positioned(top: 25, left: 25, child: _buildPointMark(pts[2], nameColor, isDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              height: 36, 
              child: Text(
                List.filled(match.events.where((e) => e.side == side && e.type == PointType.hansoku).length, '▲').join(''),
                style: const TextStyle(fontSize: 24, color: Colors.amber),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanName(String name) {
    if (name.contains('欠員')) return '(欠員)';
    if (!name.contains(':')) return name.trim();
    return name.split(':').last.replaceAll(')', '').trim();
  }

  Widget _buildPointMark(PointDisplay pd, Color color, bool isDark) {
    final double fs = pd.mark.length > 1 ? 16 : (pd.isFirstMatchPoint ? 28 : 38);

    if (pd.isFirstMatchPoint) {
      return Container(
        width: 50, height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          border: Border.all(color: color.withValues(alpha: isDark ? 0.5 : 1.0), width: 3)
        ),
        child: Text(pd.mark, style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: color)),
      );
    }
    return SizedBox(
      width: 50, height: 50,
      child: Center(
        child: Text(pd.mark, style: TextStyle(fontSize: fs, fontWeight: FontWeight.w900, color: color)),
      ),
    );
  }

  // ★ 修正：Mapのキー型を変更
  Widget _buildResultOverlay(BuildContext context, Map<Side, List<PointDisplay>> ptsMap) {
    final r = ptsMap[Side.red]!.length;
    final w = ptsMap[Side.white]!.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 24, 
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? Colors.indigo.shade900 : Colors.indigo.shade700,
          borderRadius: BorderRadius.circular(22),
          border: isDark ? Border.all(color: Colors.indigo.shade400, width: 1) : null,
          boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 8)],
        ),
        child: Text(
          r > w ? '赤 の勝ち' : (w > r ? '白 の勝ち' : '引き分け'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
        ),
      ),
    );
  }
}