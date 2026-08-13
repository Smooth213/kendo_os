import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// kendo OS 全体で統一されたデザインと影・背景を提供する標準カード容器
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double elevation;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.elevation = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveRadius = borderRadius ?? AppRadius.large;
    final effectiveBgColor = backgroundColor ?? themeColors.cardBackground;
    final effectiveBorderColor = borderColor ?? themeColors.borderColor;
    final effectiveBorderWidth = borderWidth ?? 1.0;

    Widget cardChild = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    if (onTap != null) {
      cardChild = InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: cardChild,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: effectiveBorderWidth,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: themeColors.cardShadowColor,
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: cardChild,
      ),
    );
  }
}
