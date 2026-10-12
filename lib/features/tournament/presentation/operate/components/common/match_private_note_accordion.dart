import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 運営メモ（内部特記事項: 相手先鋒上段、主審交代注意など）の折りたたみアコーディオンUI
class MatchPrivateNoteAccordion extends StatefulWidget {
  final TextEditingController noteController;
  final bool isDark;
  final Widget? trailingAction;
  final bool? initiallyExpanded;
  final String? labelText;
  final String? hintText;
  final InputDecoration Function({
    required String labelText,
    required String hintText,
    Widget? prefixIcon,
  })?
  buildTextFieldDecoration;

  const MatchPrivateNoteAccordion({
    super.key,
    required this.noteController,
    required this.isDark,
    this.trailingAction,
    this.initiallyExpanded,
    this.labelText,
    this.hintText,
    this.buildTextFieldDecoration,
  });

  @override
  State<MatchPrivateNoteAccordion> createState() =>
      _MatchPrivateNoteAccordionState();
}

class _MatchPrivateNoteAccordionState extends State<MatchPrivateNoteAccordion> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded != null) {
      _isExpanded = widget.initiallyExpanded!;
    } else if (widget.noteController.text.isNotEmpty) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    final hasText = widget.noteController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF2C2C2E)
            : themeColors.cardBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: widget.isDark
              ? const Color(0xFF38383A)
              : const Color(0x22000000),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: AppRadius.medium,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 16,
                    color: themeColors.primaryAccent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      hasText ? '📝 運営メモ・特記事項（入力あり）' : '＋ 運営メモ・特記事項を追加（任意）',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: hasText
                            ? themeColors.primaryAccent
                            : themeColors.subTextColor,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: themeColors.subTextColor,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '※このメモは大会ホーム・チーム試合状況にのみ表示され、PDFや外部試合結果には出力されません',
                          style: TextStyle(
                            fontSize: AppFontSize.micro,
                            color: themeColors.subTextColor,
                          ),
                        ),
                      ),
                      if (widget.trailingAction != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        widget.trailingAction!,
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppTextField(
                    controller: widget.noteController,
                    maxLines: 2,
                    style: TextStyle(
                      color: themeColors.textColor,
                      fontSize: AppFontSize.small,
                    ),
                    decoration: widget.buildTextFieldDecoration != null
                        ? widget.buildTextFieldDecoration!(
                            labelText: widget.labelText ?? '運営メモ・特記事項',
                            hintText: widget.hintText ?? '例: 相手先鋒上段、主審交代注意 など',
                            prefixIcon: Icon(
                              Icons.edit_note,
                              color: themeColors.primaryAccent,
                            ),
                          )
                        : InputDecoration(
                            labelText: widget.labelText ?? '運営メモ・特記事項',
                            hintText: widget.hintText ?? '例: 相手先鋒上段、主審交代注意 など',
                            filled: true,
                            fillColor: widget.isDark
                                ? const Color(0xFF1E1E20)
                                : AppKendoColors.pureWhite,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.small,
                              borderSide: BorderSide(
                                color: themeColors.primaryAccent,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
