import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// ルール設定画面における時間設定ステッパータイル（純粋UIコンポーネント）
class CategoryTimeStepperTile extends StatelessWidget {
  final String title;
  final double value;
  final double minValue;
  final double maxValue;
  final double step;
  final ValueChanged<double> onChanged;
  final String? subtitle;
  final Color? primaryColor;

  const CategoryTimeStepperTile({
    super.key,
    required this.title,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.step,
    required this.onChanged,
    this.subtitle,
    this.primaryColor,
  });

  static String formatMinutes(double minutes) {
    if (minutes <= 0) return '0分';
    final mins = minutes.floor();
    final secs = ((minutes - mins) * 60).round();
    if (mins == 0) {
      return '$secs秒';
    }
    if (secs == 0) {
      return '$mins分';
    }
    return '$mins分$secs秒';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivePrimaryColor =
        primaryColor ?? context.appColors.primaryAccent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.modernValue,
        vertical: AppSpacing.compact,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? context.appColors.textColor.withValues(alpha: 0.05)
            : context.appColors.cardBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark
              ? context.appColors.textColor.withValues(alpha: 0.12)
              : const Color(0x33000000),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: AppFontWeight.semiBold,
                    fontSize: AppFontSize.body,
                    color: context.appColors.textColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: context.appColors.subTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : context.appColors.inputBackground,
              borderRadius: AppRadius.xlarge,
              border: Border.all(
                color: isDark
                    ? context.appColors.textColor.withValues(alpha: 0.24)
                    : const Color(0x33000000),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppKendoColors.pureBlack.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  padding: const EdgeInsets.all(AppSpacing.subValue),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  color: value > minValue
                      ? effectivePrimaryColor
                      : const Color(0x8A000000),
                  onPressed: value > minValue
                      ? () {
                          final newVal = (value - step).clamp(
                            minValue,
                            maxValue,
                          );
                          onChanged(newVal);
                        }
                      : null,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 68),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    formatMinutes(value),
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.body,
                      color: effectivePrimaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  padding: const EdgeInsets.all(AppSpacing.subValue),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  color: value < maxValue
                      ? effectivePrimaryColor
                      : const Color(0x8A000000),
                  onPressed: value < maxValue
                      ? () {
                          final newVal = (value + step).clamp(
                            minValue,
                            maxValue,
                          );
                          onChanged(newVal);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
