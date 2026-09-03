import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// ルームID重複時の確認・警告ダイアログ
class RoomJoinDuplicateWarningDialog extends StatelessWidget {
  final String code;
  final VoidCallback onConfirm;

  const RoomJoinDuplicateWarningDialog({
    super.key,
    required this.code,
    required this.onConfirm,
  });

  static void show({
    required BuildContext context,
    required String code,
    required VoidCallback onConfirm,
  }) {
    showAppDialog(
      context: context,
      builder: (context) =>
          RoomJoinDuplicateWarningDialog(code: code, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.95)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.95);
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: AppKendoColors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: AppRadius.xlarge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: AppRadius.xlarge,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.report_problem_rounded,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '⚠️ ID重複・既存の部屋',
                        style: TextStyle(
                          color: textColor,
                          fontSize: AppFontSize.subhead,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'ルームID [ $code ] はすでに存在しています。\n\n'
                  '他の道場が使用中か、過去に作成された部屋です。このまま接続して共有しますか？\n'
                  '※新規で作りたい場合はキャンセルし、別のIDに変更してください。',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: AppFontSize.bodySmall,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'キャンセル（変更する）',
                        style: TextStyle(
                          color: AppKendoColors.grey,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppKendoColors.teal,
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: const Text(
                        'このまま接続',
                        style: TextStyle(
                          color: AppKendoColors.pureWhite,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
