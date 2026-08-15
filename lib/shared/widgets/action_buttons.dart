import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

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
    final isProcessing = ref.watch(isMatchCommandProcessingProvider);
    final effectiveLocked = isLocked || isProcessing;

    return Expanded(
      child: Padding(
        // ★ 左右の余白を完全にゼロ化し、縦のクッションをタイトに締める
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: AppSpacing.xxs,
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildScoreBtn(
                    context,
                    ref,
                    effectiveLocked,
                    'メ',
                    'メ',
                    PointType.men,
                  ),
                  _buildScoreBtn(
                    context,
                    ref,
                    effectiveLocked,
                    'コ',
                    'コ',
                    PointType.kote,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildScoreBtn(
                    context,
                    ref,
                    effectiveLocked,
                    'ド',
                    'ド',
                    PointType.doIdo,
                  ),
                  _buildScoreBtn(
                    context,
                    ref,
                    effectiveLocked,
                    'ツ',
                    'ツ',
                    PointType.tsuki,
                  ),
                ],
              ),
            ),
            SizedBox(
              // ★ 反則ボタンの高さを60から46に縮小し、19.5:9の垂直全収まりを物理保証
              height: 46,
              child: Row(
                children: [
                  _buildFoulBtn(
                    context,
                    ref,
                    effectiveLocked,
                    '反',
                    PointType.hansoku,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBtn(
    BuildContext context,
    WidgetRef ref,
    bool effectiveLocked,
    String label,
    String mark,
    PointType type,
  ) {
    // 共通のHoldConfirmButtonのロジックをボタンに適用
    return Expanded(
      child: Padding(
        // ★ 左右の隙間を1.0に詰め、ボタン自体の横幅を最大化
        padding: const EdgeInsets.symmetric(
          horizontal: 1.0,
          vertical: AppSpacing.xxs,
        ),
        child: HoldConfirmButton(
          label: label,
          color: color,
          textColor: textColor ?? AppKendoColors.pureWhite,
          disabled: effectiveLocked,
          onConfirm: () =>
              ref.read(matchCommandProvider).addScoreEvent(matchId, side, type),
        ),
      ),
    );
  }

  Widget _buildFoulBtn(
    BuildContext context,
    WidgetRef ref,
    bool effectiveLocked,
    String label,
    PointType type,
  ) {
    return Expanded(
      child: Padding(
        // ★ 反則ボタンの横隙間も完全にフィットさせる
        padding: const EdgeInsets.symmetric(
          horizontal: 1.0,
          vertical: AppSpacing.xxs,
        ),
        child: HoldConfirmButton(
          label: label,
          color: const Color(0xFFD97706),
          textColor: AppKendoColors.pureBlack,
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

class _HoldConfirmButtonState extends State<HoldConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    // 0.35秒で確定（現場の緊迫感に合わせて、少しだけ応答速度を上げつつ誤爆を防ぐ）
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
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

  Color _getDisplayColor(bool isDark) {
    if (widget.disabled) {
      return isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    }
    return _isHolding
        ? Color.lerp(widget.color, AppKendoColors.pureBlack, 0.2)!
        : widget.color;
  }

  TextStyle _getTextStyle(bool isTablet, bool isDark) {
    return TextStyle(
      fontSize: widget.isFoul ? (isTablet ? 32 : 24) : (isTablet ? 56 : 48),
      fontWeight: AppFontWeight.bold,
      color: widget.disabled
          ? (isDark ? const Color(0x66FFFFFF) : const Color(0x4D000000))
          : widget.textColor,
      letterSpacing: 2.0,
      height: 1.3,
    );
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
          final scale = 1.0 - (_controller.value * 0.08);

          // ボタンの外観を定義（ClipRRectで残像をカット）
          return Transform.scale(
            scale: scale,
            child: ClipRRect(
              borderRadius: AppRadius.medium,
              child: Container(
                alignment: Alignment.center,
                constraints: const BoxConstraints(minHeight: 72),
                decoration: BoxDecoration(
                  color: _getDisplayColor(isDark),
                  border: Border.all(
                    color: _isHolding
                        ? context.appColors.textColor
                        : (isDark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.12)
                              : const Color(
                                  0xFF000000,
                                ).withValues(alpha: 0.12)),
                    width: _isHolding ? 4 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. ボタン本体のテキスト（上下左右完全中央ロック構造）
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center, // 🌟 垂直・水平方向の完全な中央に強制整列
                      child: Text(
                        widget.isFoul ? '反則' : widget.label,
                        textAlign: TextAlign.center,
                        style: _getTextStyle(isTablet, isDark).copyWith(
                          height: 1.0, // 🌟 フォント固有の暗黙の上下余白（ベースラインの遊び）を完全に均等化
                        ),
                      ),
                    ),
                    // 2. ゲージ（最前面）
                    if (_isHolding)
                      Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: _controller.value,
                            strokeWidth: 6,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppKendoColors.pureWhite,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
