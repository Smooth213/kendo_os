import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 アナウンスのタイトル・本文入力セクション（Undo ＆ クリア機能付き）
class TimelineAnnounceInputSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final FocusNode titleFocusNode;
  final FocusNode bodyFocusNode;
  final bool hasHistory;
  final VoidCallback onUndo;
  final VoidCallback onClearTitle;
  final AppThemeColors themeColors;

  const TimelineAnnounceInputSection({
    super.key,
    required this.titleController,
    required this.bodyController,
    required this.titleFocusNode,
    required this.bodyFocusNode,
    required this.hasHistory,
    required this.onUndo,
    required this.onClearTitle,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── タイトルヘッダー行（1つ戻す・クリア） ──
        Row(
          children: [
            Text(
              'タイトル',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
                color: context.appColors.textColor,
              ),
            ),
            const Spacer(),
            if (hasHistory)
              InkWell(
                key: const Key('timeline_title_undo_button'),
                onTap: onUndo,
                borderRadius: AppRadius.small,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.undo,
                        size: 14,
                        color: themeColors.primaryAccent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '1つ戻す',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: themeColors.primaryAccent,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (titleController.text.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                key: const Key('timeline_title_clear_button'),
                onTap: onClearTitle,
                borderRadius: AppRadius.small,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.clear,
                        size: 14,
                        color: context.appColors.subTextColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'クリア',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // タイトル入力欄
        AppTextField(
          controller: titleController,
          focusNode: titleFocusNode,
          style: TextStyle(color: context.appColors.textColor),
          decoration: const InputDecoration(
            labelText: 'タイトル（例：【緊急】会場変更）',
            hintText: '空欄の場合は自動で見出しになります',
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 本文入力欄
        AppTextField(
          controller: bodyController,
          focusNode: bodyFocusNode,
          maxLines: 3,
          style: TextStyle(color: context.appColors.textColor),
          decoration: const InputDecoration(
            labelText: 'アナウンス本文内容',
            hintText: '例：3会場へ移動になりました。選手は速やかに移動してください。',
          ),
        ),
      ],
    );
  }
}
