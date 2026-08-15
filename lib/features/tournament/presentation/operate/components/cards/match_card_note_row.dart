import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合カード上部の補足メモ・種別名（例: "第1試合 【先鋒】"）を表示する純粋UIコンポーネント
class MatchCardNoteRow extends StatelessWidget {
  final String displayNote;
  final String matchType;
  final Color noteColor;

  const MatchCardNoteRow({
    super.key,
    required this.displayNote,
    required this.matchType,
    required this.noteColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasNote = displayNote.isNotEmpty;
    final bool hasType = matchType.isNotEmpty && matchType != '選手';

    if (!hasNote && !hasType) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
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
      ],
    );
  }
}
