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
            // ★ Phase 4: Undo(取り消し)を親指圏内・常時表示の特等席へ配置
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

// ★ Phase 2: 長押し確定UI（究極の誤操作防止ボタン）
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
    // 0.4秒で確定（現場の体感として最も「待たされず、誤爆しない」絶妙な時間）
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact(); // 確定時の強い振動
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
    HapticFeedback.lightImpact(); // 触れた瞬間の軽い振動（プレビュー）
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _cancelHold() {
    if (widget.disabled || !_isHolding) return; // 既にfalseなら何もしない
    _controller.reverse(); // 離すと滑らかに戻る（キャンセル）
    setState(() => _isHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: () => _cancelHold(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * 0.05);
          final buttonColor = widget.disabled 
              ? Colors.grey.withValues(alpha: 0.3) 
              : (_isHolding ? widget.color.withValues(alpha: 0.85) : widget.color);

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: widget.disabled || _isHolding ? [] : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 4))
                ],
                border: Border.all(
                  color: _isHolding ? widget.textColor.withValues(alpha: 0.5) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isHolding || _controller.value > 0)
                    Positioned.fill(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1.0, 
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: CircularProgressIndicator(
                              value: _controller.value,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (widget.isFoul 
                                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey.shade600) 
                                    : widget.textColor).withValues(alpha: 0.7)
                              ),
                              strokeWidth: 4, 
                            ),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isFoul ? '反則' : widget.label,
                        style: TextStyle(
                          fontSize: widget.isFoul ? (isTablet ? 24 : 20) : (isTablet ? 36 : 30), 
                          fontWeight: FontWeight.w900,
                          color: widget.disabled 
                              ? Colors.grey 
                              : (widget.isFoul 
                                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600) 
                                  : widget.textColor),
                          letterSpacing: widget.isFoul ? 0.0 : 2.0, 
                        ),
                      ),
                    ],
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