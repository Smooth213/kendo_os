import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

/// 🥋 ドックアイコンの iPhone風ジグル（プルプル揺れ）＆ドラッグ浮遊制御ラッパー
class DockJiggleDragWrapper extends StatelessWidget {
  final Widget child;
  final int index;
  final bool isEditMode;
  final bool isDragging;
  final Animation<double>? jiggleAnimation;
  final VoidCallback? onLongPress;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const DockJiggleDragWrapper({
    super.key,
    required this.child,
    required this.index,
    required this.isEditMode,
    this.isDragging = false,
    this.jiggleAnimation,
    this.onLongPress,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // ジグルアニメーション（編集モードかつ非ドラッグ時）
    if (isEditMode && !isDragging && jiggleAnimation != null) {
      content = AnimatedBuilder(
        animation: jiggleAnimation!,
        builder: (context, currentChild) {
          // 各アイコンで位相を分散させて自然なランダム感を演出 (約 ±4.8度 = 0.084 rad)
          final double phase = (index * 0.85);
          final double wave = math.sin(
            (jiggleAnimation!.value * 2 * math.pi) + phase,
          );
          final double angle = wave * 0.084;
          final double dx =
              math.cos((jiggleAnimation!.value * 2 * math.pi) + phase) * 1.3;
          final double dy = wave * 0.9;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(angle: angle, child: currentChild),
          );
        },
        child: content,
      );
    }

    // ドラッグ中のスケールアップ（1.08倍）と浮遊シャドウ
    if (isDragging) {
      content = Transform.scale(
        scale: 1.08,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppKendoColors.pureBlack.withValues(alpha: 0.42),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: content,
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onPanStart: isEditMode ? onPanStart : null,
      onPanUpdate: isEditMode ? onPanUpdate : null,
      onPanEnd: isEditMode ? onPanEnd : null,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
