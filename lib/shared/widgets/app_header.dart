import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
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
  final VoidCallback? onBackPressed;
  final String? fallbackRoute;

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
    this.onBackPressed,
    this.fallbackRoute,
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
    final bool canPop =
        (parentRoute?.canPop ?? false) ||
        (GoRouter.maybeOf(context)?.canPop() ?? false);
    final bool shouldShowBack =
        canPop || onBackPressed != null || fallbackRoute != null;

    final Widget? effectiveLeading =
        leading ??
        (shouldShowBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: effectiveFgColor,
                tooltip: '戻る',
                onPressed: () {
                  AppHaptics.light();
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else {
                    final goRouter = GoRouter.maybeOf(context);
                    if (goRouter != null && goRouter.canPop()) {
                      goRouter.pop();
                    } else if (parentRoute?.canPop ?? false) {
                      Navigator.maybePop(context);
                    } else if (fallbackRoute != null) {
                      if (goRouter != null) {
                        goRouter.go(fallbackRoute!);
                      } else {
                        Navigator.maybePop(context);
                      }
                    }
                  }
                },
              )
            : null);

    final isDarkBg = effectiveBgColor.computeLuminance() < 0.5;
    final overlayStyle = isDarkBg
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: AppKendoColors.transparent,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: AppKendoColors.transparent,
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
          );

    return AppBar(
      systemOverlayStyle: overlayStyle,
      flexibleSpace: Container(color: effectiveBgColor),
      title: titleWidget != null
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: titleWidget,
            )
          : (title != null
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: AppFontSize.headline,
                          fontWeight: AppFontWeight.semiBold,
                          color: effectiveFgColor,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  )
                : null),
      centerTitle: centerTitle,
      backgroundColor: effectiveBgColor,
      foregroundColor: effectiveFgColor,
      surfaceTintColor: AppKendoColors.transparent,
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
