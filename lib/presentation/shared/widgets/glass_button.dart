import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../operate/providers/settings_provider.dart';

class GlassButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Widget? child; // カスタムレイアウト用
  
  // 標準レイアウト用プロパティ
  final IconData? icon;
  final String? label;
  final Widget? trailing;
  
  final Color color;
  final bool expandContent;
  final EdgeInsetsGeometry padding;
  final double? glassAlpha;
  final Color? surfaceColor;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.color,
    this.icon,
    this.label,
    this.trailing,
    this.expandContent = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.glassAlpha,
    this.surfaceColor,
  }) : child = null;

  const GlassButton.custom({
    super.key,
    required this.onPressed,
    required this.color,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.glassAlpha,
    this.surfaceColor,
  }) : icon = null,
       label = null,
       trailing = null,
       expandContent = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;

    final Color fallbackBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color fallbackBorderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    // 背景色: Liquid Glass 無効時は指定色をそのまま（不透明で）適用
    final baseBgColor = surfaceColor ?? color;
    final bgColor = enableLiquidGlass
        ? baseBgColor.withValues(alpha: glassAlpha ?? (isDark ? 0.15 : 0.05))
        : (child != null ? fallbackBgColor : baseBgColor);

    // 枠線色: Liquid Glass 無効時は枠線を消す
    final borderColor = enableLiquidGlass
        ? (isDark ? color.withValues(alpha: 0.6) : color.withValues(alpha: 0.4))
        : (child != null ? fallbackBorderColor : Colors.transparent);

    // 文字色: Liquid Glass 無効時は白文字
    final textColor = enableLiquidGlass
        ? (isDark ? Colors.white : Colors.black87)
        : Colors.white;
    
    // アイコンの色はベースカラーから少し明度を調整して視認性を高める
    final accentColor = enableLiquidGlass
        ? (isDark ? _lighten(color, 0.2) : _darken(color, 0.2))
        : Colors.white;

    Widget buttonContent = Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: (enableLiquidGlass || child != null) ? 1.5 : 0),
      ),
      child: InkWell(
        onTap: onPressed,
        // タップ時のリップルエフェクト
        splashColor: enableLiquidGlass ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2),
        highlightColor: enableLiquidGlass ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.1),
        child: Padding(
          padding: padding,
          child: child ?? _buildStandardLayout(textColor, accentColor),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: enableLiquidGlass
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
              child: buttonContent,
            )
          : buttonContent,
    );
  }

  Widget _buildStandardLayout(Color textColor, Color accentColor) {
    return Row(
      mainAxisSize: expandContent ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: expandContent ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 24, color: accentColor),
          const SizedBox(width: 16),
        ],
        if (label != null)
          if (expandContent)
            Expanded(
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            )
          else
            Text(
              label!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
        if (trailing != null) ...[
          if (!expandContent) const SizedBox(width: 16),
          trailing!,
        ],
      ],
    );
  }

  Color _lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  Color _darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}