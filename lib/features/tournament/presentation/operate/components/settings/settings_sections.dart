import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/band/presentation/components/band_settings_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_accordion_selector.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/web_app_qr_dialog.dart';
import 'package:kendo_os/shared/application/services/kendo_haptics.dart';
import 'package:kendo_os/shared/application/services/thermal_power_governor.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';
import 'package:kendo_os/shared/infrastructure/services/web_notification_helper.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/thermal_status_badge.dart';

/// 1. 表示と画面セクション
class SettingsDisplaySection extends ConsumerWidget {
  final SettingsModel settings;
  final bool enableLiquidGlass;
  final AppThemeColors themeColors;

  const SettingsDisplaySection({
    super.key,
    required this.settings,
    required this.enableLiquidGlass,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              onSelected: (val) => notifier.updateField(themeMode: val),
            ),
            SettingsAccordionSelector<String>(
              title: '文字サイズ',
              icon: Icons.format_size,
              iconBgColor: AppKendoColors.purple,
              selectedValue: settings.textSizeMode,
              items: const [
                SettingsAccordionItem(value: 'normal', label: '標準'),
                SettingsAccordionItem(value: 'large', label: '大'),
                SettingsAccordionItem(value: 'extraLarge', label: '特大'),
              ],
              onSelected: (val) => notifier.updateField(textSizeMode: val),
            ),
            SettingsSwitchTile(
              title: 'スリープ(画面消灯)防止',
              value: settings.sleepPrevent,
              onChanged: (val) => notifier.updateField(sleepPrevent: val),
              icon: Icons.lightbulb,
              iconBgColor: AppKendoColors.orange,
            ),
            SettingsSwitchTile(
              title: '省エネモード',
              subtitle: '背景アニメーション停止',
              value: !settings.enableLiquidGlass,
              onChanged: (val) => notifier.updateField(enableLiquidGlass: !val),
              icon: Icons.eco,
              iconBgColor: AppKendoColors.green,
            ),
            SettingsListTile(
              title: 'サーマル冷却・省電力制御',
              icon: Icons.shield_rounded,
              iconBgColor: AppKendoColors.teal,
              subtitle: 'タップして詳細と時間精度保証を確認',
              trailing: const ThermalStatusBadge(isSwitchSize: true),
              onTap: () {
                final governor = ref.read(thermalPowerGovernorProvider);
                ThermalStatusBadge.showThermalInfoSheet(context, governor);
              },
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '☀️ サンシャインモードは直射日光や反射光に負けない最高コントラストを提供します。\n'
              '文字サイズは体育館での遠距離視認や年長者・弱視の先生方の操作性を高めます。\n'
              'スリープ防止をオンにすると長時間の試合記録中に画面が暗くなるのを防ぎます。\n'
              'サーマル冷却制御は端末の熱暴走とバッテリー急減を完全自動で防止しています（時間精度100%保証）。',
        ),
      ],
    );
  }
}

/// 2. 音と振動セクション
class SettingsSoundHapticsSection extends ConsumerWidget {
  final SettingsModel settings;
  final bool enableLiquidGlass;
  final AppThemeColors themeColors;

  const SettingsSoundHapticsSection({
    super.key,
    required this.settings,
    required this.enableLiquidGlass,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              onSelected: (val) => notifier.updateField(audioFeedbackMode: val),
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
              title: '触覚フィードバック\n(階層化ハプティクス)',
              subtitle: 'タイマー(軽)、一本(強)、反則(2連)、取消(長)など、操作に応じた振動で通知します',
              value: settings.haptic,
              onChanged: (val) {
                notifier.updateField(haptic: val, strikeVib: val);
                if (val) KendoHaptics.viewFlip();
              },
              icon: Icons.vibration,
              iconBgColor: AppKendoColors.purpleAccent,
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '※ 体育館の寒さや騒音の中でも、指先の触覚と音で操作結果を確実に把握できます。\n'
              '※ 触覚バイブレーションはiOS/Androidアプリ版で動作します。Webブラウザ（Safari等）やPC環境では端末・ブラウザの仕様により振動が制限されます。',
        ),
      ],
    );
  }
}

/// 3. プッシュ通知設定セクション
class SettingsPushNotificationSection extends ConsumerWidget {
  final SettingsModel settings;
  final bool enableLiquidGlass;
  final AppThemeColors themeColors;

  const SettingsPushNotificationSection({
    super.key,
    required this.settings,
    required this.enableLiquidGlass,
    required this.themeColors,
  });

  void _handleNotificationToggle({
    required WidgetRef ref,
    required bool val,
    required VoidCallback update,
  }) {
    if (val) triggerWebNotificationPermission();
    update();
    if (val) {
      ref.read(notificationServiceProvider).initializeNotification();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader(title: 'プッシュ通知設定 (iPhone/iPad/Web対応)'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            SettingsSwitchTile(
              title: '緊急連絡・本部アナウンスの通知',
              value: settings.notifyOnEmergency,
              onChanged: (val) => _handleNotificationToggle(
                ref: ref,
                val: val,
                update: () => notifier.updateField(notifyOnEmergency: val),
              ),
              icon: Icons.emergency_share,
              iconBgColor: AppKendoColors.red,
            ),
            SettingsSwitchTile(
              title: '新着試合追加の通知',
              value: settings.notifyOnMatchAdded,
              onChanged: (val) => _handleNotificationToggle(
                ref: ref,
                val: val,
                update: () => notifier.updateField(notifyOnMatchAdded: val),
              ),
              icon: Icons.add_alert,
              iconBgColor: AppKendoColors.indigo,
            ),
            SettingsSwitchTile(
              title: '試合開始の通知',
              value: settings.notifyOnMatchStarted,
              onChanged: (val) => _handleNotificationToggle(
                ref: ref,
                val: val,
                update: () => notifier.updateField(notifyOnMatchStarted: val),
              ),
              icon: Icons.play_circle_outline,
              iconBgColor: AppKendoColors.green,
            ),
            SettingsSwitchTile(
              title: '試合結果・終了の通知',
              value: settings.notifyOnResult,
              onChanged: (val) => _handleNotificationToggle(
                ref: ref,
                val: val,
                update: () => notifier.updateField(notifyOnResult: val),
              ),
              icon: Icons.emoji_events,
              iconBgColor: AppKendoColors.ipponGold,
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '※ iPhone/Safariで通知を受信するには、必ず「ホーム画面に追加」して起動し、通知スイッチをオンにして表示される「通知の許可」を承諾してください。',
        ),
      ],
    );
  }
}

/// 4. 外部連携・保存・Web版セクション群
class SettingsExternalAndProtectionSection extends StatelessWidget {
  final SettingsModel settings;
  final bool enableLiquidGlass;
  final AppThemeColors themeColors;
  final BuildContext sheetContext;

  const SettingsExternalAndProtectionSection({
    super.key,
    required this.settings,
    required this.enableLiquidGlass,
    required this.themeColors,
    required this.sheetContext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader(title: '外部連携・LIVE配信'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: const [BandSettingsTile()],
        ),
        const SettingsSectionFooter(
          text:
              '※ BANDグループ（低学年・高学年など）を登録しておくと、試合カードからワンタップで対戦情報をコピーして配信を開くことができます。設定した内容は道場ID配下の全端末に自動同期されます。',
        ),
        const SizedBox(height: AppSpacing.xl),
        const SettingsSectionHeader(title: 'ローカル保存と保護'),
        Consumer(
          builder: (context, ref, _) {
            final notifier = ref.read(settingsProvider.notifier);
            return SettingsBlock(
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
            );
          },
        ),
        const SettingsSectionFooter(
          text: '記録をロックすると後からスコアを修正できなくなり、ローカル保存されたデータの安全性を高めます。',
        ),
        const SizedBox(height: AppSpacing.xl),
        const SettingsSectionHeader(title: 'Webアプリ版（他端末アクセス）'),
        SettingsBlock(
          enableLiquidGlass: enableLiquidGlass,
          themeColors: themeColors,
          children: [
            SettingsListTile(
              title: 'Webアプリ版 QRコード',
              subtitle: '他端末のブラウザでkendo_os本体を開く',
              icon: Icons.qr_code_2_rounded,
              iconBgColor: AppKendoColors.blue,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => WebAppQrDialog.show(sheetContext),
            ),
          ],
        ),
        const SettingsSectionFooter(
          text:
              '※ 閲覧専用モードではなく、アプリ本体を開きます。他のスマホやiPad、PC等のブラウザからアクセスして操作・利用できます。',
        ),
      ],
    );
  }
}
