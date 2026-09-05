import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_accordion_selector.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_test_action_panel.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/shared/application/services/kendo_haptics.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';
import 'package:kendo_os/shared/infrastructure/services/web_notification_helper.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/shared/widgets/thermal_status_badge.dart';

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
    final notifier = ref.read(settingsProvider.notifier);
    final enableLiquidGlass = settings.enableLiquidGlass;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppThemeColors themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final listContent = ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isBottomSheet ? AppSpacing.sm : AppSpacing.lg,
        vertical: isBottomSheet ? AppSpacing.md : AppSpacing.xl,
      ),
      children: [
        // ==========================================
        // 1. 表示と画面
        // ==========================================
        const SettingsSectionHeader(title: '表示と画面'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            SettingsAccordionSelector<String>(
              title: '外観テーマ',
              icon: Icons.dark_mode,
              iconBgColor: AppKendoColors.blue,
              selectedValue: settings.themeMode,
              items: const [
                SettingsAccordionItem(value: 'system', label: '端末連動'),
                SettingsAccordionItem(value: 'light', label: 'ライト'),
                SettingsAccordionItem(value: 'dark', label: 'ダーク'),
                SettingsAccordionItem(value: 'sunshine', label: '☀️ サンシャイン'),
              ],
              onSelected: (val) {
                ref.read(settingsProvider.notifier).updateField(themeMode: val);
              },
            ),
            SettingsSwitchTile(
              title: 'スリープ(画面消灯)防止',
              value: settings.sleepPrevent,
              onChanged: (val) => notifier.updateField(sleepPrevent: val),
              icon: Icons.lightbulb,
              iconBgColor: AppKendoColors.orange,
            ),
            SettingsSwitchTile(
              title: '省エネモード（背景アニメーション停止）',
              value: !settings.enableLiquidGlass,
              onChanged: (val) => notifier.updateField(enableLiquidGlass: !val),
              icon: Icons.eco,
              iconBgColor: AppKendoColors.green,
            ),
            // 🔋 【設定・安心感の可視化】サーマル冷却＆バッテリー稼働状況タイル
            SettingsListTile(
              title: 'サーマル冷却・省電力制御',
              icon: Icons.shield_rounded,
              iconBgColor: AppKendoColors.teal,
              subtitle: '猛暑体育館での熱暴走・バッテリー枯渇を自動防止',
              trailing: const ThermalStatusBadge(isSwitchSize: true),
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '☀️ サンシャインモードは直射日光や反射光に負けない最高コントラストを提供します。\nスリープ防止をオンにすると長時間の試合記録中に画面が暗くなるのを防ぎます。\nサーマル冷却制御は端末の熱暴走とバッテリー急減を完全自動で防止しています（時間精度100%保証）。',
        ),
        const SizedBox(height: AppSpacing.xl),

        // ==========================================
        // 2. 音と振動・フィードバック
        // ==========================================
        const SettingsSectionHeader(title: '音と振動・フィードバック'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            SettingsAccordionSelector<String>(
              title: '音声・サウンド設定',
              icon: Icons.volume_up,
              iconBgColor: AppKendoColors.pinkAccent,
              selectedValue: settings.audioFeedbackMode,
              items: const [
                SettingsAccordionItem(value: 'off', label: 'OFF'),
                SettingsAccordionItem(value: 'effect', label: '効果音'),
                SettingsAccordionItem(value: 'voice', label: '音声読み上げ'),
              ],
              onSelected: (val) {
                notifier.updateField(audioFeedbackMode: val);
              },
            ),
            if (settings.audioFeedbackMode != 'off')
              SettingsSwitchTile(
                title: 'マナーモード時も強制的に鳴らす',
                value: settings.ignoreMannerMode,
                onChanged: (val) => notifier.updateField(ignoreMannerMode: val),
                icon: Icons.volume_off,
                iconBgColor: AppKendoColors.pink,
              ),
            SettingsSwitchTile(
              title: '触覚フィードバック (階層化ハプティクス)',
              subtitle: 'タイマー(軽)、一本(強)、反則(2連)、取消(長)など、操作に応じた振動で通知します',
              value: settings.haptic,
              onChanged: (val) {
                notifier.updateField(haptic: val, strikeVib: val);
                if (val) {
                  KendoHaptics.viewFlip();
                }
              },
              icon: Icons.vibration,
              iconBgColor: AppKendoColors.purpleAccent,
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '※ 体育館の寒さや騒音の中でも、指先の触覚と音で操作結果を確実に把握できます。\n※ 触覚バイブレーションはiOS/Androidアプリ版で動作します。Webブラウザ（Safari等）やPC環境では端末・ブラウザの仕様により振動が制限されます。',
        ),
        const SizedBox(height: AppSpacing.xl),

        // ==========================================
        // 2-2. プッシュ通知設定
        // ==========================================
        const SettingsSectionHeader(title: 'プッシュ通知設定 (iPhone/iPad/Web対応)'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            SettingsSwitchTile(
              title: '緊急連絡・本部アナウンスの通知',
              value: settings.notifyOnEmergency,
              onChanged: (val) {
                if (val) triggerWebNotificationPermission();
                notifier.updateField(notifyOnEmergency: val);
                if (val) {
                  ref
                      .read(notificationServiceProvider)
                      .initializeNotification();
                }
              },
              icon: Icons.emergency_share,
              iconBgColor: AppKendoColors.red,
            ),
            SettingsSwitchTile(
              title: '新着試合追加の通知',
              value: settings.notifyOnMatchAdded,
              onChanged: (val) {
                if (val) triggerWebNotificationPermission();
                notifier.updateField(notifyOnMatchAdded: val);
                if (val) {
                  ref
                      .read(notificationServiceProvider)
                      .initializeNotification();
                }
              },
              icon: Icons.add_alert,
              iconBgColor: AppKendoColors.indigo,
            ),
            SettingsSwitchTile(
              title: '試合開始の通知',
              value: settings.notifyOnMatchStarted,
              onChanged: (val) {
                if (val) triggerWebNotificationPermission();
                notifier.updateField(notifyOnMatchStarted: val);
                if (val) {
                  ref
                      .read(notificationServiceProvider)
                      .initializeNotification();
                }
              },
              icon: Icons.play_circle_outline,
              iconBgColor: AppKendoColors.green,
            ),
            SettingsSwitchTile(
              title: '試合結果・終了の通知',
              value: settings.notifyOnResult,
              onChanged: (val) {
                if (val) triggerWebNotificationPermission();
                notifier.updateField(notifyOnResult: val);
                if (val) {
                  ref
                      .read(notificationServiceProvider)
                      .initializeNotification();
                }
              },
              icon: Icons.emoji_events,
              iconBgColor: AppKendoColors.ipponGold,
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '※ iPhone/Safariで通知を受信するには、必ず「ホーム画面に追加」して起動し、通知スイッチをオンにして表示される「通知の許可」を承諾してください。',
        ),
        const SizedBox(height: AppSpacing.xl),

        // ==========================================
        // 3. ローカル保存と保護
        // ==========================================
        const SettingsSectionHeader(title: 'ローカル保存と保護'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            SettingsSwitchTile(
              title: '記録確定後の修正ロック',
              value: settings.isLocked,
              onChanged: (val) => notifier.updateField(isLocked: val),
              icon: Icons.lock,
              iconBgColor: AppKendoColors.redAccent,
            ),
          ],
        ),
        const SettingsSectionFooter(
          text: '記録をロックすると後からスコアを修正できなくなり、ローカル保存されたデータの安全性を高めます。',
        ),

        // ==========================================
        // 4. アカウント管理
        // ==========================================
        const SettingsSectionHeader(title: 'アカウント管理'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            SettingsListTile(
              title: 'ログアウト',
              icon: Icons.logout,
              iconBgColor: AppKendoColors.redAccent,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
        const SettingsSectionFooter(
          text: 'ログアウトすると現在のセッションが終了し、次回利用時に再ログインが必要になります。',
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

    final bodyContent = Column(
      children: [
        if (isBottomSheet)
          DockBottomSheetHeader(
            title: 'システム設定',
            icon: Icons.settings_rounded,
            iconColor: themeColors.subTextColor,
            onFullScreen: onFullScreen,
          ),
        Expanded(child: listContent),
        // ==========================================
        // 6. テスト用インタラクティブエリア（全画面時のみ画面下部固定）
        // ==========================================
        if (!isBottomSheet)
          SettingsTestActionPanel(
            settings: settings,
            enableLiquidGlass: enableLiquidGlass,
            themeColors: themeColors,
          ),
      ],
    );

    if (isBottomSheet) {
      return DockDraggableSheet(
        backgroundColor: isDark
            ? const Color(0xFF1E1E20)
            : themeColors.cardBackground,
        builder: (context, scrollController) => bodyContent,
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
        body: bodyContent,
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
