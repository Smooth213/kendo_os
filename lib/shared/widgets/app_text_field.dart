import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// kendo OS 全体で統一されたスタイルと入力体験を提供する標準 TextField
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final List<dynamic>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;
  final InputDecoration? decoration;
  final EdgeInsets scrollPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.contentPadding,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
    this.decoration,
    this.scrollPadding = const EdgeInsets.all(AppSpacing.xxl),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveBgColor = enabled
        ? themeColors.inputBackground
        : themeColors.disabledColor;

    final effectiveTextColor = enabled
        ? themeColors.textColor
        : themeColors.disabledTextColor;

    final borderRadius = AppRadius.medium;

    final defaultStyle = TextStyle(
      fontSize: AppFontSize.body,
      fontWeight: AppFontWeight.regular,
      color: effectiveTextColor,
    );

    final defaultDecoration = InputDecoration(
      hintText: hintText,
      labelText: labelText,
      errorText: errorText,
      hintStyle: TextStyle(
        fontSize: AppFontSize.body,
        color: themeColors.hintColor,
        fontWeight: AppFontWeight.regular,
      ),
      labelStyle: TextStyle(
        fontSize: AppFontSize.body,
        color: themeColors.subTextColor,
        fontWeight: AppFontWeight.regular,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: effectiveBgColor,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: themeColors.separatorColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: themeColors.separatorColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: themeColors.primaryAccent, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: themeColors.disabledColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: themeColors.errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: themeColors.errorColor, width: 1.5),
      ),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters as List<TextInputFormatter>?,
      textAlign: textAlign,
      scrollPadding: scrollPadding,
      style: style != null ? defaultStyle.merge(style) : defaultStyle,
      decoration: decoration != null
          ? defaultDecoration.copyWith(
              hintText: decoration?.hintText ?? hintText,
              labelText: decoration?.labelText ?? labelText,
              errorText: decoration?.errorText ?? errorText,
              prefixIcon: decoration?.prefixIcon ?? prefixIcon,
              suffixIcon: decoration?.suffixIcon ?? suffixIcon,
              contentPadding: decoration?.contentPadding ?? contentPadding,
            )
          : defaultDecoration,
    );
  }
}
