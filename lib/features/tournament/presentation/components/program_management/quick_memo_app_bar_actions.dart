import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_tab_bar.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 クイックメモ AppBar アクションボタン群（戻す・進む・時刻挿入・コピー・全消去）
class QuickMemoAppBarActions extends StatelessWidget {
  final QuickMemoMode mode;
  final bool hasStrokes;
  final bool hasUndo;
  final bool hasText;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onInsertTimestamp;
  final VoidCallback onCopyText;
  final VoidCallback onClearAll;

  const QuickMemoAppBarActions({
    super.key,
    required this.mode,
    required this.hasStrokes,
    required this.hasUndo,
    required this.hasText,
    required this.onUndo,
    required this.onRedo,
    required this.onInsertTimestamp,
    required this.onCopyText,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mode == QuickMemoMode.drawing) ...[
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: '1つ戻す',
            onPressed: hasStrokes ? onUndo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded),
            tooltip: 'やり直す',
            onPressed: hasUndo ? onRedo : null,
          ),
        ],
        if (mode == QuickMemoMode.text) ...[
          IconButton(
            icon: const Icon(Icons.schedule_rounded),
            tooltip: '時刻を挿入',
            onPressed: onInsertTimestamp,
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'コピー',
            onPressed: hasText ? onCopyText : null,
          ),
        ],
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded),
          tooltip: '全消去',
          onPressed:
              (mode == QuickMemoMode.drawing && hasStrokes) ||
                  (mode == QuickMemoMode.text && hasText)
              ? onClearAll
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
