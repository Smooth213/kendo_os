import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// チーム編集ボトムシート: オーダー編成セクションの見出しおよび枠追加ボタン
class TeamEditOrderHeader extends StatelessWidget {
  final String matchType;
  final int substituteCount;
  final Color accentColor;
  final VoidCallback onAddPlayerSlot;
  final VoidCallback onAddSubstitute;

  const TeamEditOrderHeader({
    super.key,
    required this.matchType,
    required this.substituteCount,
    required this.accentColor,
    required this.onAddPlayerSlot,
    required this.onAddSubstitute,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'オーダー編成',
            style: TextStyle(
              fontSize: AppFontSize.subhead,
              fontWeight: AppFontWeight.bold,
              color: accentColor,
            ),
          ),
        ),
        if (matchType.contains('それ以上'))
          TextButton.icon(
            onPressed: onAddPlayerSlot,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('選手枠を追加'),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          )
        else if (substituteCount < 4)
          TextButton.icon(
            onPressed: onAddSubstitute,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('補欠を追加'),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          ),
      ],
    );
  }
}
