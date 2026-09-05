import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_ui_tiles.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/thermal_status_badge.dart';

/// 🥋 観客用 表示設定ボトムシート (省エネ・サーマル・サンシャイン対応)
class ViewerSettingsBottomSheet extends ConsumerWidget {
  const ViewerSettingsBottomSheet({super.key});

  static Future<T?> show<T>(BuildContext context) {
    return showAppBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ViewerSettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final Color dynamicTextColor = context.appColors.textColor;

    return AppBottomSheetContent(
      showDragHandle: true,
      title: '表示設定',
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.xxl,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              SettingsBlock(
                enableLiquidGlass: settings.enableLiquidGlass,
                themeColors: themeColors,
                children: [
                  SettingsListTile(
                    title: 'テーマの切り替え',
                    icon: Icons.palette_outlined,
                    iconBgColor: AppKendoColors.blueAccent,
                    trailing: DropdownButton<String>(
                      value: settings.themeMode,
                      isDense: true,
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
                          child: Text('📱 端末連動'),
                        ),
                        DropdownMenuItem(value: 'light', child: Text('☀️ ライト')),
                        DropdownMenuItem(value: 'dark', child: Text('🌙 ダーク')),
                        DropdownMenuItem(
                          value: 'sunshine',
                          child: Text('☀️ サンシャイン'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          notifier.updateField(themeMode: val);
                        }
                      },
                    ),
                  ),
                  SettingsSwitchTile(
                    title: '省エネモード（背景アニメーション停止）',
                    value: !settings.enableLiquidGlass,
                    onChanged: (val) =>
                        notifier.updateField(enableLiquidGlass: !val),
                    icon: Icons.eco,
                    iconBgColor: AppKendoColors.green,
                  ),
                  SettingsListTile(
                    title: 'サーマル冷却・省電力制御',
                    icon: Icons.shield_rounded,
                    iconBgColor: AppKendoColors.teal,
                    subtitle: '猛暑体育館での熱暴走・バッテリー枯渇を自動防止',
                    trailing: const ThermalStatusBadge(isSwitchSize: true),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const SettingsSectionFooter(
                text:
                    '☀️ サンシャインモードは直射日光や反射光に負けない最高コントラストを提供します。\n'
                    '省エネモードをオンにすると背景アニメーションを停止し、端末の熱暴走とバッテリー急減を防止します。',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
