import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 設定画面用 インラインアコーディオン選択タイル
/// ボトムシート（OverlayEntry）内でも Navigator.push を使わず安全にインライン展開し、
/// ドロップダウンのポップアップ消失・無反応問題を100%根本解決します。
class SettingsAccordionSelector<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconBgColor;
  final T selectedValue;
  final List<SettingsAccordionItem<T>> items;
  final ValueChanged<T> onSelected;

  const SettingsAccordionSelector({
    super.key,
    required this.title,
    required this.icon,
    required this.iconBgColor,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
  });

  @override
  State<SettingsAccordionSelector<T>> createState() =>
      _SettingsAccordionSelectorState<T>();
}

class _SettingsAccordionSelectorState<T>
    extends State<SettingsAccordionSelector<T>> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final currentItem = widget.items.firstWhere(
      (item) => item.value == widget.selectedValue,
      orElse: () => widget.items.first,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          onTap: () {
            AppHaptics.selection();
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.subValue),
            decoration: BoxDecoration(
              color: widget.iconBgColor,
              borderRadius: AppRadius.small,
            ),
            child: Icon(widget.icon, size: 20, color: AppKendoColors.pureWhite),
          ),
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppFontSize.bodyMedium,
              fontWeight: AppFontWeight.medium,
              color: themeColors.textColor,
            ),
          ),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.48,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: themeColors.inputBackground,
                borderRadius: AppRadius.medium,
                border: Border.all(color: themeColors.separatorColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentItem.label,
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.textColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: themeColors.subTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: themeColors.inputBackground,
              borderRadius: AppRadius.medium,
              border: Border.all(color: themeColors.separatorColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.medium,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.items.map((item) {
                  final isSelected = item.value == widget.selectedValue;
                  return InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      widget.onSelected(item.value);
                      setState(() {
                        _isExpanded = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      color: isSelected
                          ? themeColors.primaryAccent.withValues(alpha: 0.12)
                          : null,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: AppFontSize.bodySmall,
                                fontWeight: isSelected
                                    ? AppFontWeight.bold
                                    : AppFontWeight.regular,
                                color: isSelected
                                    ? themeColors.primaryAccent
                                    : themeColors.textColor,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: themeColors.primaryAccent,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class SettingsAccordionItem<T> {
  final T value;
  final String label;

  const SettingsAccordionItem({required this.value, required this.label});
}
