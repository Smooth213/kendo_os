import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// タイムライン見出し（コメント）編集シート
class TimelineEditCommentDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    MatchCommentModel comment,
  ) {
    final controller = TextEditingController(text: comment.text);

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => _EditCommentBottomSheet(
        ref: ref,
        comment: comment,
        controller: controller,
      ),
    ).then((_) => controller.dispose());
  }
}

class _EditCommentBottomSheet extends StatefulWidget {
  final WidgetRef ref;
  final MatchCommentModel comment;
  final TextEditingController controller;

  const _EditCommentBottomSheet({
    required this.ref,
    required this.comment,
    required this.controller,
  });

  @override
  State<_EditCommentBottomSheet> createState() =>
      _EditCommentBottomSheetState();
}

class _EditCommentBottomSheetState extends State<_EditCommentBottomSheet> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark
        ? const Color(0xFF1C1C1E)
        : context.appColors.cardBackground;

    final keyboardHeight = kIsWeb
        ? 0.0
        : MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible =
        _focusNode.hasFocus ||
        keyboardHeight > 0 ||
        MediaQuery.viewInsetsOf(context).bottom > 50;

    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = screenHeight * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ドラッグハンドルバー
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.2)
                      : const Color(0x33000000),
                  borderRadius: AppRadius.medium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // タイトル
            Text(
              '見出し（コメント）の編集',
              style: TextStyle(
                fontSize: AppFontSize.subhead,
                fontWeight: AppFontWeight.bold,
                color: context.appColors.textColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 入力欄
            AppTextField(
              controller: widget.controller,
              focusNode: _focusNode,
              scrollPadding: EdgeInsets.zero,
              autofocus: true,
              style: TextStyle(color: context.appColors.textColor),
              decoration: InputDecoration(
                hintText: '見出しやコメントを入力',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2C2C2E)
                    : context.appColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // アクションボタン
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: AppKendoColors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = widget.controller.text.trim();
                    if (text.isNotEmpty && text != widget.comment.text) {
                      try {
                        await widget.ref
                            .read(commentCommandProvider)
                            .updateComment(widget.comment.copyWith(text: text));
                      } catch (e) {
                        debugPrint('コメントの更新に失敗しました: $e');
                      }
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppKendoColors.indigo,
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.small,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontWeight: AppFontWeight.bold),
                  ),
                ),
              ],
            ),
            if (!kIsWeb && isKeyboardVisible) SizedBox(height: keyboardHeight),
          ],
        ),
      ),
    );
  }
}
