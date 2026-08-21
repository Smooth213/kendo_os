import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 選択された試合間で設定が異なる場合に表示する警告バナー
class BulkRuleDifferingBanner extends StatelessWidget {
  final bool isDark;

  const BulkRuleDifferingBanner({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706).withAlpha(isDark ? 30 : 15),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: const Color(0xFFD4AF37).withAlpha(isDark ? 60 : 30),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '選択した対戦の中に、設定が異なる試合が含まれています（先頭の試合のルールを表示中）',
              style: TextStyle(
                fontSize: AppFontSize.small,
                color: Color(0xFFD4AF37),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
