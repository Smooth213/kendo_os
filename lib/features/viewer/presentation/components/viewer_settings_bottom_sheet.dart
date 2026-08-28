import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// 🥋 観客用 表示設定ボトムシート (Liquid Glass & テーマ切り替え)
class ViewerSettingsBottomSheet extends ConsumerWidget {
  const ViewerSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AppBottomSheetContent(
      showDragHandle: true,
      title: '表示設定',
      padding: const EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.xxl,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Icon(Icons.palette_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'テーマの切り替え',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppKendoColors.grey.withValues(alpha: 0.3),
                  ),
                  borderRadius: AppRadius.small,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.themeMode,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: const [
                      DropdownMenuItem(
                        value: 'system',
                        child: Text('📱 システム設定に従う'),
                      ),
                      DropdownMenuItem(
                        value: 'light',
                        child: Text('☀️ ライトモード'),
                      ),
                      DropdownMenuItem(value: 'dark', child: Text('🌙 ダークモード')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                        notifier.state = notifier.state.copyWith(
                          themeMode: value,
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '・システム: お使いの端末の設定に自動で連動します。\n'
                '・ライト: 明るく見やすい標準的なデザインです。\n'
                '・ダーク: 暗い背景で目に優しく、バッテリー消費も抑えます。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  const Icon(Icons.auto_awesome),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'すりガラス効果',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  AppSwitch(
                    value: settings.enableLiquidGlass,
                    onChanged: (value) {
                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                      notifier.state = notifier.state.copyWith(
                        enableLiquidGlass: value,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '・背景の試合状況が美しく透けて見えるモダンなデザインになります。\n'
                '・動作が重く感じる場合や、古い端末をお使いの場合は「OFF」にするとパフォーマンスが向上します。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
