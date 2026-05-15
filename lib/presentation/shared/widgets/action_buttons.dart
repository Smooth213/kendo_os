import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; 
import 'package:kendo_os/domain/entities/score_event.dart';
import '../../operate/providers/match_command_provider.dart';

class ScoreActionPanel extends ConsumerWidget {
  final String matchId;
  final Side side;
  final Color color;
  final Color? textColor; 
  final bool isLocked;

  const ScoreActionPanel({
    super.key,
    required this.matchId,
    required this.side,
    required this.color,
    this.textColor,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ Step 3-6: 書き込み処理中フラグを直接監視
    final isProcessing = ref.watch(isMatchCommandProcessingProvider);
    // 元々のロック条件に「処理中」を加える
    final effectiveLocked = isLocked || isProcessing;

    return Expanded(
      child: Padding(
        // ★ 修正：ボタン群全体を囲う上下の固定余白を最小限(2px)に
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScoreBtn(context, ref, effectiveLocked, 'メ', 'メ', PointType.men),
                  const SizedBox(width: 6), // ★ ボタン同士の横の隙間も少し締める
                  _buildScoreBtn(context, ref, effectiveLocked, 'コ', 'コ', PointType.kote),
                ],
              ),
            ),
            const SizedBox(height: 4), // ★ ボタン同士の縦の隙間を8pxから4pxに圧縮（ここで高さを確保）
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScoreBtn(context, ref, effectiveLocked, 'ド', 'ド', PointType.doIdo),
                  const SizedBox(width: 6),
                  _buildScoreBtn(context, ref, effectiveLocked, 'ツ', 'ツ', PointType.tsuki),
                ],
              ),
            ),
            const SizedBox(height: 4), 
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFoulBtn(context, ref, effectiveLocked, '反', PointType.hansoku),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBtn(BuildContext context, WidgetRef ref, bool effectiveLocked, String label, String mark, PointType type) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: HoldConfirmButton(
          label: label,
          color: color,
          textColor: textColor ?? Colors.white,
          disabled: effectiveLocked,
          onConfirm: () {
            ref.read(matchCommandProvider).addScoreEvent(matchId, side, type);
          },
        ),
      ),
    );
  }

  Widget _buildFoulBtn(BuildContext context, WidgetRef ref, bool effectiveLocked, String label, PointType type) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: HoldConfirmButton(
          label: label,
          color: Colors.amber.shade600,
          textColor: Colors.black87,
          disabled: effectiveLocked,
          isFoul: true,
          onConfirm: () {
            ref.read(matchCommandProvider).addScoreEvent(matchId, side, type);
          },
        ),
      ),
    );
  }
}

// ★ Phase 6: 高齢者・緊急時対応の究極ボタン
class HoldConfirmButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool disabled;
  final bool isFoul;
  final VoidCallback onConfirm;

  const HoldConfirmButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.disabled,
    this.isFoul = false,
    required this.onConfirm,
  });

  @override
  State<HoldConfirmButton> createState() => _HoldConfirmButtonState();
}

class _HoldConfirmButtonState extends State<HoldConfirmButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    // 0.35秒で確定（現場の緊迫感に合わせて、少しだけ応答速度を上げつつ誤爆を防ぐ）
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // ★ 触覚フィードバック：スマホ全体が「決定」を伝える強い振動
        HapticFeedback.heavyImpact(); 
        widget.onConfirm();
        _controller.reset();
        setState(() => _isHolding = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    if (widget.disabled) return;
    // ★ 指が触れた瞬間の「準備OK」の軽い振動
    HapticFeedback.selectionClick(); 
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _cancelHold() {
    if (widget.disabled || !_isHolding) return;
    _controller.reverse();
    setState(() => _isHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: () => _cancelHold(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // ★ 視認性強化: 押し込んでいる間はボタンがわずかに縮み、色が濃くなる
          final scale = 1.0 - (_controller.value * 0.08);
          final displayColor = widget.disabled 
              ? (isDark ? Colors.grey.shade900 : Colors.grey.shade200)
              : (_isHolding ? Color.lerp(widget.color, Colors.black, 0.2) : widget.color);

          return Transform.scale(
            scale: scale,
            child: Container(
              constraints: const BoxConstraints(minHeight: 72), // ★ Phase 4-3: 高齢者向けに絶対に押し間違えない巨大ボタン化(72dp)
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(12), // 角を少し鋭くして、タップ領域を視覚的に広く見せる
                boxShadow: widget.disabled || _isHolding ? [] : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 4))
                ],
                border: Border.all(
                  // ★ 高コントラスト: 押し込んでいる間は外枠を白く光らせる
                  color: _isHolding ? Colors.white : (isDark ? Colors.white12 : Colors.black12),
                  width: _isHolding ? 4 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ★ 修正: ボタンが長方形でも、最小辺に合わせた「完璧な真円」のゲージにする
                  if (_isHolding)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // 短い方の辺に合わせて正方形のサイズを決定
                          final size = constraints.maxWidth < constraints.maxHeight 
                              ? constraints.maxWidth 
                              : constraints.maxHeight;
                          return Center(
                            child: SizedBox(
                              width: size * 0.9, // ボタン枠ギリギリを避けるため少し小さめに
                              height: size * 0.9,
                              child: CircularProgressIndicator(
                                value: _controller.value,
                                strokeWidth: 8.0, // 高齢補助員にも見えやすく少し太めに
                                backgroundColor: Colors.black12,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                  // ★ 修正: 文字がボタン枠からはみ出さないように FittedBox で自動縮小させる
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.isFoul ? '反則' : widget.label,
                        style: TextStyle(
                          fontSize: widget.isFoul ? (isTablet ? 32 : 24) : (isTablet ? 56 : 48), 
                          fontWeight: FontWeight.w900,
                          color: widget.disabled 
                              ? Colors.grey.shade600 
                              : (widget.isFoul && !isDark ? Colors.black87 : widget.textColor),
                          letterSpacing: 2.0, 
                          shadows: [
                            Shadow(offset: const Offset(1, 1), blurRadius: 2, color: Colors.black.withValues(alpha: 0.3))
                          ]
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}