import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合カード上部の補足メモ・種別名（例: "第1試合 【先鋒】"）および運営メモを表示する純粋UIコンポーネント
class MatchCardNoteRow extends StatelessWidget {
  final String displayNote;
  final String? privateNote;
  final String matchType;
  final Color noteColor;

  const MatchCardNoteRow({
    super.key,
    required this.displayNote,
    this.privateNote,
    required this.matchType,
    required this.noteColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasNote = displayNote.isNotEmpty;
    final bool hasType = matchType.isNotEmpty && matchType != '選手';
    final bool hasPrivateNote =
        privateNote != null && privateNote!.trim().isNotEmpty;

    if (!hasNote && !hasType && !hasPrivateNote) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        if (hasNote || hasType)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text.rich(
              TextSpan(
                children: [
                  if (hasNote) TextSpan(text: displayNote),
                  if (hasNote && hasType) const TextSpan(text: ' '),
                  if (hasType) TextSpan(text: '【$matchType】'),
                ],
              ),
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: noteColor,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        // 📝 運営メモ（内部特記事項: 相手先鋒上段、主審交代注意など）
        if (hasPrivateNote) ...[
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notes_rounded, size: 12, color: noteColor),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    privateNote!.trim(),
                    style: TextStyle(
                      fontSize: AppFontSize.micro,
                      color: noteColor,
                      fontWeight: AppFontWeight.semiBold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
