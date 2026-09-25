import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_google_auth_tile.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_sections.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_test_action_panel.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';

class SettingsScreen extends ConsumerWidget {
  final bool isBottomSheet;
  final VoidCallback? onFullScreen;

  const SettingsScreen({
    super.key,
    this.isBottomSheet = false,
    this.onFullScreen,
  });

  static Future<void> showAsBottomSheet(BuildContext context) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: AppKendoColors.transparent,
      builder: (context) => SettingsScreen(
        isBottomSheet: true,
        onFullScreen: () {
          Navigator.of(context).pop();
          context.push('/settings');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final enableLiquidGlass = settings.enableLiquidGlass;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppThemeColors themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    Widget buildListContent(
      BuildContext sheetContext, [
      ScrollController? scrollController,
    ]) => ListView(
      controller: isBottomSheet ? scrollController : null,
      padding: EdgeInsets.symmetric(
        horizontal: isBottomSheet ? AppSpacing.sm : AppSpacing.lg,
        vertical: isBottomSheet ? AppSpacing.md : AppSpacing.xl,
      ),
      children: [
        SettingsDisplaySection(
          settings: settings,
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
        ),
        const SizedBox(height: AppSpacing.xl),
        SettingsSoundHapticsSection(
          settings: settings,
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
        ),
        const SizedBox(height: AppSpacing.xl),
        SettingsPushNotificationSection(
          settings: settings,
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
        ),
        const SizedBox(height: AppSpacing.xl),
        SettingsExternalAndProtectionSection(
          settings: settings,
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          sheetContext: sheetContext,
        ),
        const SizedBox(height: AppSpacing.xl),
        const SettingsSectionHeader(title: 'アカウント管理'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            const SettingsGoogleAuthTile(),
            SettingsListTile(
              title: 'ログアウト',
              icon: Icons.logout,
              iconBgColor: AppKendoColors.redAccent,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLogoutConfirmation(sheetContext),
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '※ Googleアカウントと連携すると、PCやiPadなどの異なる端末間でもクイックメモや通知既読が自動同期されます。\n'
              '※ ログイン画面が開かない場合は、ブラウザ（SafariやChrome）の「ポップアップブロック」を解除（許可）してください。（iPad/iPhoneの場合は「設定」アプリ→「Safari」→「ポップアップブロック」をオフ）\n'
              '※ ログアウトすると現在のセッションが終了し、次回利用時に再ログインが必要になります。',
        ),
        const SizedBox(height: AppSpacing.xl),
        if (isBottomSheet)
          SettingsTestActionPanel(
            settings: settings,
            enableLiquidGlass: enableLiquidGlass,
            themeColors: themeColors,
          ),
      ],
    );

    Widget buildBodyContent(
      BuildContext sheetContext, [
      ScrollController? scrollController,
    ]) => Column(
      children: [
        if (isBottomSheet)
          DockBottomSheetHeader(
            title: 'システム設定',
            icon: Icons.settings_rounded,
            iconColor: themeColors.subTextColor,
            onFullScreen: onFullScreen,
          ),
        Expanded(child: buildListContent(sheetContext, scrollController)),
        if (!isBottomSheet)
          SettingsTestActionPanel(
            settings: settings,
            enableLiquidGlass: enableLiquidGlass,
            themeColors: themeColors,
          ),
      ],
    );

    if (isBottomSheet) {
      final navKey = GlobalKey<NavigatorState>();
      return DockDraggableSheet(
        backgroundColor: isDark
            ? const Color(0xFF1E1E20)
            : themeColors.cardBackground,
        builder: (context, scrollController) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (navKey.currentState?.canPop() ?? false) {
                navKey.currentState!.pop();
              } else {
                FloatingDockSheetManager.close();
              }
            },
            child: Navigator(
              key: navKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (innerNavContext) =>
                    buildBodyContent(innerNavContext, scrollController),
              ),
            ),
          );
        },
      );
    }

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          title: 'システム設定',
          backgroundColor: enableLiquidGlass
              ? AppKendoColors.transparent
              : themeColors.cardBackground,
          actions: const [
            ManualHelpButton(manualPath: 'docs/manuals/operator/settings.md'),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: buildBodyContent(context),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'ログアウトしますか？',
        content: const Text('ログアウトすると、次回の利用時に再度ログインが必要になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text(
              'ログアウト',
              style: TextStyle(
                color: AppKendoColors.red,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
