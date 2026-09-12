import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class DockTimerWheelPicker extends StatelessWidget {
  final AppThemeColors themeColors;
  final FixedExtentScrollController minScrollController;
  final FixedExtentScrollController secScrollController;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;
  final VoidCallback onCommit;

  const DockTimerWheelPicker({
    super.key,
    required this.themeColors,
    required this.minScrollController,
    required this.secScrollController,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
    required this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('wheel_picker'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: AppKendoColors.orangeAccent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'ダイヤル調整',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onCommit,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('完了'),
              style: TextButton.styleFrom(
                foregroundColor: AppKendoColors.orangeAccent,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSingleWheel(minScrollController, 60, '分', onMinutesChanged),
              const SizedBox(width: AppSpacing.md),
              _buildSingleWheel(secScrollController, 60, '秒', onSecondsChanged),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleWheel(
    FixedExtentScrollController controller,
    int count,
    String label,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 36,
            selectionOverlay: Container(
              decoration: BoxDecoration(
                color: AppKendoColors.orangeAccent.withValues(alpha: 0.12),
                borderRadius: AppRadius.small,
              ),
            ),
            onSelectedItemChanged: onChanged,
            children: List.generate(
              count,
              (i) => Center(
                child: Text(
                  i.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: AppFontSize.titleLarge,
                    fontWeight: AppFontWeight.bold,
                    fontFamily: 'monospace',
                    color: themeColors.textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.caption,
            color: themeColors.subTextColor,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      ],
    );
  }
}
