import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_dock_items_order_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// 🥋 部内戦ドックアイテムのiPhone風ドラッグ＆ドロップ並び替えボトムシート
class BunaiksenDockItemsReorderBottomSheet extends ConsumerWidget {
  const BunaiksenDockItemsReorderBottomSheet({super.key});

  static void show(BuildContext context) {
    FloatingDockSheetManager.show(
      context: context,
      builder: (_) => const BunaiksenDockItemsReorderBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final itemsOrder = ref.watch(bunaiksenDockItemsOrderProvider);
    final orderNotifier = ref.read(bunaiksenDockItemsOrderProvider.notifier);

    return DockDraggableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.45,
      maxChildSize: 0.90,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                children: [
                  const DockBottomSheetHeader(
                    title: '部内戦ドックの並び替え',
                    icon: Icons.sort_rounded,
                    iconColor: AppKendoColors.indigo,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '長押ししてドラッグ＆ドロップで並び替えます。',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: themeColors.subTextColor,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('リセット'),
                        style: TextButton.styleFrom(
                          foregroundColor: themeColors.subTextColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                        ),
                        onPressed: () async {
                          AppHaptics.medium();
                          await orderNotifier.resetToDefault();
                          if (context.mounted) {
                            AppSnackBar.show(context, '並び順を初期設定に戻しました');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                itemCount: itemsOrder.length,
                onReorderItem: (oldIndex, newIndex) {
                  AppHaptics.selection();
                  orderNotifier.reorder(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final item = itemsOrder[index];
                  return Container(
                    key: ValueKey(item.name),
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: themeColors.cardBackground,
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: themeColors.separatorColor.withValues(
                          alpha: 0.5,
                        ),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: item.defaultColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: item.defaultColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: themeColors.textColor,
                        ),
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: themeColors.subTextColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
