import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 ドックから開くボトムシート共通の洗練されたヘッダー
/// シートのドラッグジェスチャー連動、ワンタップ拡大/縮小、全画面化、閉じるボタンを提供します。
class DockBottomSheetHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onFullScreen;
  final List<Widget>? extraActions;
  final VoidCallback? onClose;
  final bool showDragHandle;
  final bool showExpandToggle;

  const DockBottomSheetHeader({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.onFullScreen,
    this.extraActions,
    this.onClose,
    this.showDragHandle = false,
    this.showExpandToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveIconColor = iconColor ?? themeColors.primaryAccent;
    final sheetScope = DockSheetScope.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上部ドラッグハンドル
        if (showDragHandle)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: themeColors.separatorColor,
                borderRadius: AppRadius.full,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: sheetScope?.onDragUpdate,
                  onVerticalDragEnd: sheetScope?.onDragEnd,
                  onTap: sheetScope?.toggle,
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: effectiveIconColor),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: AppFontSize.subhead,
                            fontWeight: AppFontWeight.bold,
                            color: themeColors.textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...?extraActions,
              // シート内サイズ拡大/縮小トグルボタン（ドラッグ操作の代わりにも使える）
              if (showExpandToggle && sheetScope != null)
                IconButton(
                  icon: Icon(
                    sheetScope.isExpanded
                        ? Icons.expand_more_rounded
                        : Icons.expand_less_rounded,
                    size: 22,
                  ),
                  tooltip: sheetScope.isExpanded ? '半分の高さに戻す' : '上に広げる（最大化）',
                  color: themeColors.subTextColor,
                  onPressed: () {
                    AppHaptics.selection();
                    sheetScope.toggle();
                  },
                ),
              // 全画面ボタン（open_in_full_rounded）
              if (onFullScreen != null)
                IconButton(
                  icon: const Icon(Icons.open_in_full_rounded, size: 18),
                  tooltip: '全画面で開く',
                  color: themeColors.subTextColor,
                  onPressed: () {
                    AppHaptics.light();
                    onFullScreen!();
                  },
                ),
              // 閉じるボタン
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: '閉じる',
                color: themeColors.subTextColor,
                onPressed: () {
                  AppHaptics.light();
                  if (onClose != null) {
                    onClose!();
                  } else if (sheetScope != null) {
                    sheetScope.close();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          color: themeColors.separatorColor.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
