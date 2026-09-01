import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

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
    barrierColor:
        barrierColor ?? AppKendoColors.pureBlack.withValues(alpha: 0.54),
    builder: builder,
  );
}

/// アプリ共通のダイアログ枠コンポーネント（統一 Radius: 16px, テーマ背景・ヘッダー・標準ボタン）
class AppDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final IconData? titleIcon;
  final Color? iconColor;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final Clip clipBehavior;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  const AppDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.titleIcon,
    this.iconColor,
    this.content,
    this.actions,
    this.contentPadding,
    this.clipBehavior = Clip.none,
    this.padding,
    this.radius = AppRadius.largeValue,
    this.backgroundColor,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveTitle =
        titleWidget ??
        (title != null
            ? (titleIcon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          titleIcon,
                          size: 22,
                          color: iconColor ?? themeColors.primaryAccent,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            title!,
                            style: TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: AppFontWeight.semiBold,
                              color: themeColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      title!,
                      style: TextStyle(
                        fontSize: AppFontSize.title,
                        fontWeight: AppFontWeight.semiBold,
                        color: themeColors.textColor,
                      ),
                    ))
            : null);

    return AlertDialog(
      shape:
          shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      backgroundColor: backgroundColor ?? themeColors.cardBackground,
      surfaceTintColor: AppKendoColors.transparent,
      clipBehavior: clipBehavior,
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      contentPadding:
          contentPadding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      title: effectiveTitle,
      content: content,
      actions: actions,
    );
  }
}
