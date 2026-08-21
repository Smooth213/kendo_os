import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// タイムライン見出し（コメント）編集ダイアログ
class TimelineEditCommentDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    MatchCommentModel comment,
  ) {
    final controller = TextEditingController(text: comment.text);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E)
            : context.appColors.inputBackground,
        titleWidget: Text(
          '見出し（コメント）の編集',
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            color: context.appColors.textColor,
          ),
        ),
        content: AppTextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: context.appColors.textColor),
          decoration: InputDecoration(
            hintText: '見出しやコメントを入力',
            filled: true,
            fillColor: isDark
                ? const Color(0xFF2C2C2E)
                : context.appColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppKendoColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty && text != comment.text) {
                try {
                  await ref
                      .read(commentCommandProvider)
                      .updateComment(comment.copyWith(text: text));
                } catch (e) {
                  debugPrint('コメントの更新に失敗しました: $e');
                }
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppKendoColors.indigo,
              foregroundColor: AppKendoColors.pureWhite,
              elevation: 0,
            ),
            child: const Text(
              '保存',
              style: TextStyle(fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
