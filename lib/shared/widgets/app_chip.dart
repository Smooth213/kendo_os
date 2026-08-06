import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// アプリ全体で統一されたスタイルを提供する ChoiceChip コンポーネント
class AppChoiceChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final Color? customSelectedColor;
  final Color? customTextColor;
  final Color? selectedColor;
  final Color? backgroundColor;
  final BorderSide? side;
  final TextStyle? labelStyle;

  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.padding,
    this.customSelectedColor,
    this.customTextColor,
    this.selectedColor,
    this.backgroundColor,
    this.side,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveSelectedColor =
        customSelectedColor ?? selectedColor ?? themeColors.softAccent;
    final effectiveTextColor = selected
        ? (customTextColor ?? themeColors.primaryAccent)
        : themeColors.subTextColor;

    return ChoiceChip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: effectiveTextColor)
          : null,
      label: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? AppFontWeight.semiBold : AppFontWeight.regular,
          color: effectiveTextColor,
        ),
        child: label,
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: effectiveSelectedColor,
      backgroundColor: themeColors.inputBackground,
      side: BorderSide(
        color: selected
            ? themeColors.primaryAccent
            : themeColors.separatorColor,
        width: 1,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      showCheckmark: false,
    );
  }
}

/// アプリ全体で統一されたスタイルを提供する ActionChip コンポーネント
class AppActionChip extends StatelessWidget {
  final Widget label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderSide? side;
  final TextStyle? labelStyle;

  const AppActionChip({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.iconColor,
    this.padding,
    this.backgroundColor,
    this.side,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return ActionChip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: iconColor ?? themeColors.primaryAccent)
          : null,
      label: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: 13,
          fontWeight: AppFontWeight.regular,
          color: themeColors.subTextColor,
        ),
        child: label,
      ),
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? themeColors.inputBackground,
      side: BorderSide(color: themeColors.separatorColor, width: 1),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}

/// アプリ全体で統一されたスタイルを提供する FilterChip コンポーネント
class AppFilterChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final Color? customSelectedColor;
  final Color? customTextColor;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.padding,
    this.customSelectedColor,
    this.customTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveSelectedColor =
        customSelectedColor ?? themeColors.softAccent;
    final effectiveTextColor = selected
        ? (customTextColor ?? themeColors.primaryAccent)
        : themeColors.subTextColor;

    return FilterChip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: effectiveTextColor)
          : null,
      label: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? AppFontWeight.semiBold : AppFontWeight.regular,
          color: effectiveTextColor,
        ),
        child: label,
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: effectiveSelectedColor,
      backgroundColor: themeColors.inputBackground,
      side: BorderSide(
        color: selected
            ? themeColors.primaryAccent
            : themeColors.separatorColor,
        width: 1,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      showCheckmark: false,
    );
  }
}
