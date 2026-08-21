import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合編集シートの下部保存ボタン
class MatchEditSaveButton extends StatelessWidget {
  final bool isDantai;
  final Color backgroundColor;
  final Color primaryAccent;
  final bool isDark;
  final VoidCallback onSave;

  const MatchEditSaveButton({
    super.key,
    required this.isDantai,
    required this.backgroundColor,
    required this.primaryAccent,
    required this.isDark,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withAlpha(isDark ? 50 : 20),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check, color: AppKendoColors.pureWhite),
            label: Text(
              isDantai ? '団体戦全体を一括保存' : '変更内容を保存',
              style: const TextStyle(
                fontSize: AppFontSize.subhead,
                fontWeight: AppFontWeight.bold,
                color: AppKendoColors.pureWhite,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.large,
              ),
            ),
            onPressed: onSave,
          ),
        ),
      ),
    );
  }
}
