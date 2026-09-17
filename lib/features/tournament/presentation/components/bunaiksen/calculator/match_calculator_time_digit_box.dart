import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// ⏱️ 時・分直接入力用デジタル数値ボックス
class MatchCalculatorTimeDigitBox extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final bool isHour;
  final String label;
  final AppThemeColors themeColors;
  final Color primaryAccent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const MatchCalculatorTimeDigitBox({
    super.key,
    required this.text,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.isHour,
    required this.label,
    required this.themeColors,
    required this.primaryAccent,
    required this.onTap,
    this.onLongPress,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 44,
            decoration: BoxDecoration(
              color: primaryAccent.withValues(alpha: 0.12),
              borderRadius: AppRadius.small,
              border: Border.all(color: primaryAccent, width: 2.0),
            ),
            alignment: Alignment.center,
            child: AppTextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              textInputAction: isHour
                  ? TextInputAction.next
                  : TextInputAction.done,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              style: TextStyle(
                fontSize: AppFontSize.display,
                fontWeight: AppFontWeight.bold,
                fontFamily: 'monospace',
                color: primaryAccent,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: text,
                hintStyle: TextStyle(
                  fontSize: AppFontSize.display,
                  fontWeight: AppFontWeight.bold,
                  fontFamily: 'monospace',
                  color: primaryAccent.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: themeColors.subTextColor,
            ),
          ),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.small,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: themeColors.cardBackground,
            borderRadius: AppRadius.small,
            border: Border.all(
              color: themeColors.subTextColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: AppFontSize.display,
                  fontWeight: AppFontWeight.bold,
                  fontFamily: 'monospace',
                  color: themeColors.textColor,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.subTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
