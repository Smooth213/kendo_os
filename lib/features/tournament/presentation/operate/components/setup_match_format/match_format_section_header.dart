import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 試合形式設定画面 セクションヘッダー（左バーアクセント付き）
class MatchFormatSectionHeader extends StatelessWidget {
  final String title;
  final Color accentColor;

  const MatchFormatSectionHeader({
    super.key,
    required this.title,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.modernValue,
        bottom: AppSpacing.subValue,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 13,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: AppRadius.micro,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.caption,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
