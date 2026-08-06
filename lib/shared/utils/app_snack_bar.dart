import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

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
  static const _margin = EdgeInsets.only(bottom: 20, left: 16, right: 16);
  static const _shape = RoundedRectangleBorder(borderRadius: AppRadius.medium);

  /// 通常のインフォメーションSnackBar（グレー背景）
  static void show(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: AppFontWeight.semiBold),
        ),
        behavior: SnackBarBehavior.floating,
        shape: _shape,
        margin: _margin,
        duration: duration,
      ),
    );
  }

  /// エラーSnackBar（赤背景・白字・4秒）
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = _errorDuration,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: _shape,
        margin: _margin,
        duration: duration,
      ),
    );
  }

  /// 成功SnackBar（緑背景・白字）
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: _shape,
        margin: _margin,
        duration: duration,
      ),
    );
  }
}
