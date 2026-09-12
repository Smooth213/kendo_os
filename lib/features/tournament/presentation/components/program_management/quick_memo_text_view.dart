import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_text_toolbar.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

class QuickMemoTextView extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final AppThemeColors themeColors;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onInsertTimestamp;
  final VoidCallback onCopy;
  final VoidCallback onClear;

  const QuickMemoTextView({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.themeColors,
    required this.isDark,
    required this.onChanged,
    required this.onInsertTimestamp,
    required this.onCopy,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              80,
            ),
            child: AppTextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              expands: true,
              style: TextStyle(
                fontSize: AppFontSize.body,
                color: themeColors.textColor,
                height: 1.6,
              ),
              hintText: 'ここに試合メモ・連絡事項・確認事項を入力できます...',
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0
              ? MediaQuery.of(context).viewInsets.bottom + AppSpacing.sm
              : MediaQuery.of(context).padding.bottom + AppSpacing.md,
          child: Center(
            child: QuickMemoTextToolbar(
              themeColors: themeColors,
              isDark: isDark,
              charCount: controller.text.length,
              onInsertTimestamp: onInsertTimestamp,
              onCopy: controller.text.isNotEmpty ? onCopy : null,
              onClear: controller.text.isNotEmpty ? onClear : null,
            ),
          ),
        ),
      ],
    );
  }
}
