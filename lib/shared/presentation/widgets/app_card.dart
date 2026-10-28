import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/widgets/app_glass_container.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// kendo OS デザインシステムにおける統一カードコンポーネント (Facade Widget)
///
/// 特徴:
/// 1. [AppGlassContainer] を内包し、iOS 27 スタイルのフロストガラスとソリッド背景を自動制御
/// 2. [onTap] 指定時は iOS 特有のスケールスプリングバウンス（0.98倍）と触覚フィードバックを提供
/// 3. 画面側コードから装飾ロジックを完全にカプセル化（次回デザイン変更を劇的に容易にする骨格・外装分離）
class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blur;
  final double borderWidth;
  final Color? color;
  final Color? customBackgroundColor;
  final Color? customBorderColor;
  final BoxBorder? border;
  final List<BoxShadow>? customShadows;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.padding = AppEdgeInsets.allMd,
    this.margin,
    this.width,
    this.height,
    this.blur = AppSemanticTokens.cardBlur,
    this.borderWidth = AppSemanticTokens.cardBorderWidth,
    this.color,
    this.customBackgroundColor,
    this.customBorderColor,
    this.border,
    this.customShadows,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      _controller.forward();
      AppHaptics.selection();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = AppGlassContainer(
      borderRadius: widget.borderRadius,
      padding: widget.padding,
      margin: widget.margin,
      width: widget.width,
      height: widget.height,
      blur: widget.blur,
      borderWidth: widget.borderWidth,
      color: widget.color,
      customBackgroundColor: widget.customBackgroundColor,
      customBorderColor: widget.customBorderColor,
      border: widget.border,
      customShadows: widget.customShadows,
      child: widget.child,
    );

    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          AppHaptics.light();
          widget.onTap!();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
          child: card,
        ),
      );
    }

    return card;
  }
}
