import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_test_action_panel.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';
import 'package:kendo_os/shared/infrastructure/services/web_notification_helper.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final enableLiquidGlass = settings.enableLiquidGlass;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppThemeColors themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final Color dynamicTextColor = context.appColors.textColor;

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
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
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
                      SettingsListTile(
                        title: 'ダークモード対応',
                        icon: Icons.dark_mode,
                        iconBgColor: AppKendoColors.blue,
                        trailing: DropdownButton<String>(
                          value: settings.themeMode,
                          underline: const SizedBox(),
                          borderRadius: AppRadius.medium,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: dynamicTextColor,
                          ),
                          style: TextStyle(
                            color: dynamicTextColor,
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.body,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'system',
                              child: Text('システム依存'),
                            ),
                            DropdownMenuItem(
                              value: 'light',
                              child: Text('常にライト'),
                            ),
                            DropdownMenuItem(
                              value: 'dark',
                              child: Text('常にダーク'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateField(themeMode: val);
                            }
                          },
                        ),
                      ),
                      SettingsSwitchTile(
                        title: 'スリープ(画面消灯)防止',
                        value: settings.sleepPrevent,
                        onChanged: (val) =>
                            notifier.updateField(sleepPrevent: val),
                        icon: Icons.lightbulb,
                        iconBgColor: AppKendoColors.orange,
                      ),
                      SettingsSwitchTile(
                        title: '省エネモード（背景アニメーション停止）',
                        value: !settings.enableLiquidGlass,
                        onChanged: (val) =>
                            notifier.updateField(enableLiquidGlass: !val),
                        icon: Icons.eco,
                        iconBgColor: AppKendoColors.green,
                      ),
                    ],
                  ),
                  const SettingsSectionFooter(
                    text:
                        'ダークモードは端末本体の設定に連動させることもできます。スリープ防止をオンにすると、長時間の試合記録中に画面が暗くなるのを防ぎます。\n省エネモードをオンにする、または端末のバッテリー残量が20%以下になると自動的に省エネモード（背景アニメーション停止）になり、パフォーマンスを最優先します。',
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
                      SettingsListTile(
                        title: '音声・サウンド設定',
                        icon: Icons.volume_up,
                        iconBgColor: AppKendoColors.pinkAccent,
                        trailing: DropdownButton<String>(
                          value: settings.audioFeedbackMode,
                          underline: const SizedBox(),
                          borderRadius: AppRadius.medium,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: dynamicTextColor,
                          ),
                          style: TextStyle(
                            color: dynamicTextColor,
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.body,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'off', child: Text('OFF')),
                            DropdownMenuItem(
                              value: 'effect',
                              child: Text('効果音'),
                            ),
                            DropdownMenuItem(
                              value: 'voice',
                              child: Text('音声読み上げ'),
                            ),
                          ],
                          onChanged: (val) =>
                              notifier.updateField(audioFeedbackMode: val),
                        ),
                      ),
                      if (settings.audioFeedbackMode != 'off')
                        SettingsSwitchTile(
                          title: 'マナーモード時も強制的に鳴らす',
                          value: settings.ignoreMannerMode,
                          onChanged: (val) =>
                              notifier.updateField(ignoreMannerMode: val),
                          icon: Icons.volume_off,
                          iconBgColor: AppKendoColors.pink,
                        ),
                      SettingsSwitchTile(
                        title: 'システム操作の振動 (バイブ)',
                        value: settings.haptic,
                        onChanged: (val) => notifier.updateField(haptic: val),
                        icon: Icons.vibration,
                        iconBgColor: AppKendoColors.purpleAccent,
                      ),
                      SettingsSwitchTile(
                        title: '打突入力時の振動 (バイブ)',
                        value: settings.strikeVib,
                        onChanged: (val) =>
                            notifier.updateField(strikeVib: val),
                        icon: Icons.sports_martial_arts,
                        iconBgColor: AppKendoColors.deepPurple,
                      ),
                    ],
                  ),
                  const SettingsSectionFooter(
                    text: 'ポイント入力時や試合終了時に音や振動で知らせます。',
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ==========================================
                  // 2-2. プッシュ通知設定
                  // ==========================================
                  const SettingsSectionHeader(
                    title: 'プッシュ通知設定 (iPhone/iPad/Web対応)',
                  ),
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
                ],
              ),
            ),

            // ==========================================
            // 6. テスト用インタラクティブエリア（画面下部固定）
            // ==========================================
            SettingsTestActionPanel(
              settings: settings,
              enableLiquidGlass: enableLiquidGlass,
              themeColors: themeColors,
            ),
          ],
        ),
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
