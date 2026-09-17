import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// ⏱️ 分・秒デジタル数値ブロック（直接手入力・タップ編集）
class DockTimerNumberBlock extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final bool isMinutes;
  final bool isRunning;
  final bool isStopwatch;
  final Color color;
  final AppThemeColors themeColors;
  final VoidCallback onTap;
  final VoidCallback onTextChanged;
  final VoidCallback onSubmitted;

  const DockTimerNumberBlock({
    super.key,
    required this.text,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.isMinutes,
    required this.isRunning,
    required this.isStopwatch,
    required this.color,
    required this.themeColors,
    required this.onTap,
    required this.onTextChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return Container(
        width: 76,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppKendoColors.orangeAccent.withValues(alpha: 0.12),
          borderRadius: AppRadius.medium,
          border: Border.all(color: AppKendoColors.orangeAccent, width: 2.0),
        ),
        child: AppTextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          textInputAction: isMinutes
              ? TextInputAction.next
              : TextInputAction.done,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          style: const TextStyle(
            fontSize: AppFontSize.scoreboardTimer,
            fontWeight: AppFontWeight.bold,
            fontFamily: 'monospace',
            color: AppKendoColors.orangeAccent,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: text,
            hintStyle: TextStyle(
              fontSize: AppFontSize.scoreboardTimer,
              fontWeight: AppFontWeight.bold,
              fontFamily: 'monospace',
              color: AppKendoColors.orangeAccent.withValues(alpha: 0.4),
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (val) {
            onTextChanged();
            if (isMinutes && val.length >= 2) {
              onSubmitted();
            }
          },
          onSubmitted: (_) => onSubmitted(),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: isRunning || isStopwatch
                ? AppKendoColors.transparent
                : themeColors.separatorColor.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: AppFontSize.scoreboardTimer,
            fontWeight: AppFontWeight.bold,
            fontFamily: 'monospace',
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
