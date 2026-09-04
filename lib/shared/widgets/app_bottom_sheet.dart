import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// アプリ全体で統一されたデザインと動作を提供する Modal Bottom Sheet 呼び出し関数
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool enableDrag = true,
  bool isDismissible = true,
  double topRadius = AppRadius.roundValue,
  BoxConstraints? constraints,
  Color? backgroundColor,
}) {
  AppHaptics.selection();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final themeColors =
      Theme.of(context).extension<AppThemeColors>() ??
      AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    isDismissible: isDismissible,
    backgroundColor: backgroundColor ?? themeColors.cardBackground,
    constraints: constraints ?? const BoxConstraints(maxWidth: double.infinity),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
    ),
    builder: builder,
  );
}

/// アプリ共通のボトムシートコンテンツ枠（ドラッグハンドル・ヘッダー・レスポンシブパディング内包）
class AppBottomSheetContent extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Widget? titleTrailing;
  final Widget child;
  final bool showDragHandle;
  final EdgeInsetsGeometry? padding;

  const AppBottomSheetContent({
    super.key,
    this.title,
    this.titleIcon,
    this.titleTrailing,
    required this.child,
    this.showDragHandle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return SafeArea(
      child: Padding(
        padding:
            padding ??
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle) ...[
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(
                    top: AppSpacing.compact,
                    bottom: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.separatorColor,
                    borderRadius: AppRadius.capsule,
                  ),
                ),
              ),
            ],
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.roundValue,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(
                        titleIcon,
                        size: 20,
                        color: themeColors.primaryAccent,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: AppFontSize.subhead,
                          fontWeight: AppFontWeight.semiBold,
                          color: themeColors.textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ?titleTrailing,
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: themeColors.separatorColor.withValues(alpha: 0.5),
              ),
            ],
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
