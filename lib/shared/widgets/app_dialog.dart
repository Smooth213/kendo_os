import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// アプリ全体で統一されたデザインを提供する Dialog 呼び出し関数
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black54,
    builder: builder,
  );
}

/// アプリ共通のダイアログ枠コンポーネント（統一 Radius: 16px, テーマ背景・ヘッダー・標準ボタン）
class AppDialog extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Color? iconColor;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final Clip clipBehavior;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const AppDialog({
    super.key,
    this.title,
    this.titleIcon,
    this.iconColor,
    this.content,
    this.actions,
    this.contentPadding,
    this.clipBehavior = Clip.none,
    this.padding,
    this.radius = AppRadius.largeValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      backgroundColor: themeColors.cardBackground,
      surfaceTintColor: Colors.transparent,
      clipBehavior: clipBehavior,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding:
          contentPadding ?? const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: title != null
          ? Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(
                    titleIcon,
                    size: 22,
                    color: iconColor ?? themeColors.primaryAccent,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: AppFontWeight.semiBold,
                      color: themeColors.textColor,
                    ),
                  ),
                ),
              ],
            )
          : null,
      content: content,
      actions: actions,
    );
  }
}
