import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 一括ルール変更シートの下部適用ボタンバー
class BulkRuleBottomBar extends StatelessWidget {
  final int totalSelectedUnitsCount;
  final bool hasSelection;
  final Color primaryAccent;
  final bool isDark;
  final VoidCallback onApply;

  const BulkRuleBottomBar({
    super.key,
    required this.totalSelectedUnitsCount,
    required this.hasSelection,
    required this.primaryAccent,
    required this.isDark,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withAlpha(isDark ? 50 : 20),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: hasSelection ? onApply : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAccent,
            foregroundColor: AppKendoColors.pureWhite,
            disabledBackgroundColor: context.appColors.separatorColor,
            disabledForegroundColor: isDark
                ? context.appColors.textColor.withValues(alpha: 0.3)
                : context.appColors.cardBackground.withValues(alpha: 0.38),
            minimumSize: const Size(double.infinity, 50),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
            elevation: 0,
          ),
          child: Text(
            !hasSelection
                ? '適用対象の試合を選択してください'
                : '選択した $totalSelectedUnitsCount 件にルールを適用する',
            style: const TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.subhead,
            ),
          ),
        ),
      ),
    );
  }
}
