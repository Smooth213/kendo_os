import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// アプリ全体で統一されたデザインと配色を提供する標準 AppBar ヘッダー
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0.0,
  }) : assert(
         title == null || titleWidget == null,
         'Cannot provide both title and titleWidget',
       );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveBgColor = backgroundColor ?? themeColors.scaffoldBackground;
    final effectiveFgColor = foregroundColor ?? themeColors.textColor;

    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;

    final Widget? effectiveLeading =
        leading ??
        (canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: effectiveFgColor,
                onPressed: () {
                  AppHaptics.light();
                  Navigator.maybePop(context);
                },
              )
            : null);

    return AppBar(
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: AppFontWeight.semiBold,
                    color: effectiveFgColor,
                  ),
                )
              : null),
      centerTitle: centerTitle,
      backgroundColor: effectiveBgColor,
      foregroundColor: effectiveFgColor,
      elevation: elevation,
      scrolledUnderElevation: 0.0,
      leading: effectiveLeading,
      iconTheme: IconThemeData(color: effectiveFgColor),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
