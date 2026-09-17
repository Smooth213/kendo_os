import 'package:flutter/cupertino.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// ⏱️ 開始予定時刻用ドラムロールダイヤルピッカー
class MatchCalculatorTimeDialPicker extends StatelessWidget {
  final AppThemeColors themeColors;
  final Color primaryAccent;
  final FixedExtentScrollController hourScrollController;
  final FixedExtentScrollController minuteScrollController;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  const MatchCalculatorTimeDialPicker({
    super.key,
    required this.themeColors,
    required this.primaryAccent,
    required this.hourScrollController,
    required this.minuteScrollController,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('wheel_picker_container'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: primaryAccent.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSingleWheel(
                  controller: hourScrollController,
                  count: 24,
                  label: '時',
                  onChanged: onHourChanged,
                ),
                const SizedBox(width: AppSpacing.lg),
                _buildSingleWheel(
                  controller: minuteScrollController,
                  count: 60,
                  label: '分',
                  onChanged: onMinuteChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleWheel({
    required FixedExtentScrollController controller,
    required int count,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 34,
            selectionOverlay: Container(
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.12),
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
