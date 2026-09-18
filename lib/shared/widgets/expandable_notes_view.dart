import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 長い連絡事項・メモを美しく折りたたみ・展開表示するコンポーネント
class ExpandableNotesView extends StatefulWidget {
  final String notes;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final int collapsedMaxLines;

  const ExpandableNotesView({
    super.key,
    required this.notes,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    this.collapsedMaxLines = 3,
  });

  @override
  State<ExpandableNotesView> createState() => _ExpandableNotesViewState();
}

class _ExpandableNotesViewState extends State<ExpandableNotesView> {
  bool _isExpanded = false;

  /// 折りたたみが必要な長さかどうかを判定
  bool _isLongNotes() {
    final lines = widget.notes.split('\n');
    return lines.length > widget.collapsedMaxLines || widget.notes.length > 80;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final isLong = _isLongNotes();

    return InkWell(
      onTap: isLong
          ? () {
              AppHaptics.selection();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(AppRadius.smallValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.smallValue),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 14,
                  color: widget.accentColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '連絡事項・メモ',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: widget.accentColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                widget.notes,
                maxLines: (!isLong || _isExpanded)
                    ? null
                    : widget.collapsedMaxLines,
                overflow: (!isLong || _isExpanded)
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: AppFontSize.bodySmall,
                  height: 1.4,
                ),
              ),
            ),
            if (isLong) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _isExpanded ? '閉じる' : 'もっと見る',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: widget.accentColor,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: widget.accentColor,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
