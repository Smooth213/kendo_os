import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart'; // ★ 追加: UseCaseの参照
import '../../operate/providers/match_view_state_provider.dart'; // ★ Phase 3: ViewStateの参照
import '../../operate/providers/match_list_provider.dart'; // ★ 追加: matchListProvider

class MatchScoreboard extends ConsumerWidget {
  final String matchId;
  final String? myUserId;
  final Function(String side) onNameTap;

  const MatchScoreboard({
    super.key,
    required this.matchId,
    required this.myUserId,
    required this.onNameTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.id == matchId).firstOrNull
    ));
    if (match == null) return const SizedBox.shrink();

    final calculatePointDisplays = ref.watch(calculatePointDisplaysUseCaseProvider);
    final ptsMap = calculatePointDisplays.execute(match);
    final viewState = ref.watch(matchViewStateProvider(matchId));

    // ★修正：Columnの柔軟性を確保するために、ここを Stack に戻します
    // ただし、インジケーターは「結果がある時だけ」浮かび上がるようにします。
    return Stack(
      alignment: Alignment.center,
      children: [
        // スコアボード本体
        Row(
          children: [
            _buildScoreColumn(context, Side.red, match, ptsMap, viewState),
            _buildScoreColumn(context, Side.white, match, ptsMap, viewState),
          ],
        ),
        // 結果表示用：結果がある時だけ表示（Stackで重ねることでレイアウト崩れを防ぐ）
        if (viewState.winner != null || viewState.isTie)
          _buildResultOverlay(context, viewState),
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
        fit: BoxFit.contain, // ★ BoxFit.scaleDown から変更
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, 
          children: [
            SizedBox(height: isFinished ? 72 : 24),
            GestureDetector(
              onTap: () => onNameTap(side.name),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown, // ★枠からはみ出る場合のみ縮小
                  child: Text(
                    side == Side.red ? viewState.redCleanName : viewState.whiteCleanName,
                    style: TextStyle(
                      fontSize: 28, // 左右で共通の基準サイズに設定
                      fontWeight: FontWeight.w900,
                      color: nameColor,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            // ポイントアイコンの拡大
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isFinished && isWinner)
                    Container(
                      width: 180,
                      height: 180,
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
              child: Builder(
                builder: (context) {
                  // ★ 修正: KendoRuleEngineを使用して、Undoされた反則イベントを正確に除外してカウントする
                  final engine = KendoRuleEngine();
                  final activeEvents = engine.filterActiveEvents(match.events);
                  final hansokuCount = activeEvents.where((e) => e.side == side && (e.isHansoku || e.type == PointType.hansoku)).length;
                  return Text(
                    List.filled(hansokuCount, '▲').join(''),
                    style: const TextStyle(fontSize: 24, color: Colors.amber),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★ 改善: _cleanName を削除。UI側で文字列操作（ビジネス/プレゼンテーションロジック）を持たないようにする。
  // (※呼び出し元の _buildScoreColumn 内で Text() に渡す値も修正します)
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

    String resultText = '引き分け';
    if (viewState.winner == 'red') resultText = '赤 の勝ち';
    if (viewState.winner == 'white') resultText = '白 の勝ち';

    return Positioned(
      top: 20, // 呼び出し側にあった top: 20 をこちらに統合して位置を調整
      child: Container(
        height: 70, // ★ 高さを大きく
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 40), // 横幅を広げて余裕を作る
        decoration: BoxDecoration(
          color: isDark ? Colors.indigo.shade900 : Colors.indigo.shade700,
          borderRadius: BorderRadius.circular(35), // 丸みを拡大
          border: isDark ? Border.all(color: Colors.indigo.shade400, width: 2) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Text(
          resultText,
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w900, // 極太に
            fontSize: 32, // ★ フォントサイズを大幅アップ
            letterSpacing: 2.0, // 文字間隔を広げて読みやすく
          ),
        ),
      ),
    );
  }
}