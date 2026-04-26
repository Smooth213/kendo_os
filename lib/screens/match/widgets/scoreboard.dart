import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/match_model.dart';
import '../../../../models/score_event.dart';
import '../../../../domain/kendo_rule_engine.dart';
import '../../../../providers/match_provider.dart';
import '../../../../usecase/match_usecase.dart'; // ★ 追加: UseCaseの参照
import '../../../../providers/match_view_state_provider.dart'; // ★ Phase 3: ViewStateの参照

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
    final engine = ref.watch(kendoRuleEngineProvider);
    final ptsMap = MatchUseCase.calculatePointDisplays(match, engine);
    
    // ★ 修正: ViewStateからすべての計算済み状態を取得
    final viewState = ref.watch(matchViewStateProvider(match.id));
    final isDone = match.status == 'finished' || match.status == 'approved';

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Row(
          children: [
            _buildScoreColumn(context, Side.red, match, ptsMap, viewState),
            _buildScoreColumn(context, Side.white, match, ptsMap, viewState),
          ],
        ),
        if (isDone) _buildResultOverlay(context, viewState),
      ],
    );
  }

  Widget _buildScoreColumn(BuildContext context, Side side, MatchModel match, Map<Side, List<PointDisplay>> allPts, MatchViewState viewState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pts = allPts[side] ?? []; 
    
    // ★ 修正: 計算を削除し ViewState に依存
    final isWinner = viewState.winner == side.name;
    final isFinished = match.status == 'approved' || match.status == 'finished';

    final nameColor = side == Side.red 
        ? (isDark ? Colors.red.shade400 : Colors.red.shade700) 
        : (isDark ? Colors.grey.shade300 : Colors.blueGrey.shade800);

    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            SizedBox(height: isFinished ? 72 : 24),
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
                child: FittedBox(
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
                          Positioned(top: 0, left: 0, child: _buildPoint(context, pts[0], isDark, nameColor)),
                        if (pts.length > 1)
                          Positioned(bottom: 0, right: 0, child: _buildPoint(context, pts[1], isDark, nameColor)),
                        if (pts.length > 2)
                          Positioned(top: 25, left: 25, child: _buildPoint(context, pts[2], isDark, nameColor)),
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

  Widget _buildPoint(BuildContext context, PointDisplay pd, bool isDark, Color color) {
    const double fs = 26; 
    Widget pointWidget;

    if (pd.isFirstMatchPoint) {
      pointWidget = Container(
        width: 42, height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          border: Border.all(color: color.withValues(alpha: isDark ? 0.6 : 1.0), width: 2.5)
        ),
        child: Text(pd.mark, style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: color, height: 1.0)),
      );
    } else {
      pointWidget = SizedBox(
        width: 42, height: 42,
        child: Center(
          child: Text(pd.mark, style: TextStyle(fontSize: fs, fontWeight: FontWeight.w900, color: color, height: 1.0)),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.1, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: scale.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: pointWidget,
    );
  }

  Widget _buildResultOverlay(BuildContext context, MatchViewState viewState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ★ 修正: r > w などの計算を完全削除し、ViewStateの文字列に変換するだけ
    String resultText = '引き分け';
    if (viewState.winner == 'red') resultText = '赤 の勝ち';
    if (viewState.winner == 'white') resultText = '白 の勝ち';

    return Positioned(
      top: 16,
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
          resultText,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
        ),
      ),
    );
  }
}