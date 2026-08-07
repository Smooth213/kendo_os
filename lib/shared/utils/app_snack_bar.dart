import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// アプリ全体で統一された SnackBar を表示するユーティリティ。
///
/// 全SnackBarは以下のスタイルで統一:
///   - behavior: SnackBarBehavior.floating (画面下から浮いて表示)
///   - borderRadius: 12 (AppRadius.medium)
///   - margin: bottom:20 / left:16 / right:16
///   - duration: 3秒（エラーは4秒）
///
/// 使い方:
///   AppSnackBar.show(context, 'メッセージ');
///   AppSnackBar.showError(context, 'エラーメッセージ');
///   AppSnackBar.showSuccess(context, '成功メッセージ');
class AppSnackBar {
  AppSnackBar._();

  static const _defaultDuration = Duration(seconds: 3);
  static const _errorDuration = Duration(seconds: 4);
  static const _margin = EdgeInsets.only(
    bottom: AppSpacing.roundValue,
    left: AppSpacing.lg,
    right: AppSpacing.lg,
  );
  static const _shape = RoundedRectangleBorder(borderRadius: AppRadius.medium);

  static AppThemeColors _colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
  }

  /// 通常のインフォメーションSnackBar
  static void show(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
  }) {
    if (!context.mounted) return;
    final themeColors = _colors(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: themeColors.textColor,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
        backgroundColor: themeColors.cardBackground,
        behavior: SnackBarBehavior.floating,
        shape: _shape,
        margin: _margin,
        duration: duration,
      ),
    );
  }

  /// エラーSnackBar（テーマエラーカラー背景）
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = _errorDuration,
  }) {
    if (!context.mounted) return;
    final themeColors = _colors(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppKendoColors.pureWhite,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        backgroundColor: themeColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: _shape,
        margin: _margin,
        duration: duration,
      ),
    );
  }

  /// 成功SnackBar（テーマ成功カラー背景）
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
  }) {
    if (!context.mounted) return;
    final themeColors = _colors(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppKendoColors.pureWhite,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        backgroundColor: themeColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: _shape,
        margin: _margin,
        duration: duration,
      ),
    );
  }
}
