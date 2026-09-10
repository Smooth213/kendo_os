import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_items_order_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// 🥋 ドックアイテムのドラッグ＆ドロップ並べ替えボトムシート
class DockItemsReorderBottomSheet extends ConsumerWidget {
  const DockItemsReorderBottomSheet({super.key});

  static void show(BuildContext context) {
    FloatingDockSheetManager.show(
      context: context,
      builder: (_) => const DockItemsReorderBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final itemsOrder = ref.watch(dockItemsOrderProvider);
    final orderNotifier = ref.read(dockItemsOrderProvider.notifier);

    return DockDraggableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.50,
      maxChildSize: 0.95,
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
                  DockBottomSheetHeader(
                    title: 'ドックの並び替え',
                    icon: Icons.sort_rounded,
                    iconColor: AppKendoColors.indigo,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '右のハンドルをつまんで上下に並べ替えます。',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: themeColors.subTextColor,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          AppHaptics.selection();
                          orderNotifier.resetToDefault();
                          AppSnackBar.show(context, '標準の並び順に戻しました');
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text(
                          '初期順に戻す',
                          style: TextStyle(fontSize: AppFontSize.caption),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.8,
              color: themeColors.separatorColor.withValues(alpha: 0.4),
            ),
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
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: themeColors.cardBackground,
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: themeColors.separatorColor.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
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
                            color: themeColors.subTextColor.withValues(
                              alpha: 0.7,
                            ),
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
