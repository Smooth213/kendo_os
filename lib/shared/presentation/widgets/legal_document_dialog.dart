import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 利用規約・プライバシーポリシー・アプリ情報などを表示するスクロール対応ダイアログ
class LegalDocumentDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;

  const LegalDocumentDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
  });

  /// ダイアログを表示するヘルパー関数
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    IconData? icon,
  }) {
    return showAppDialog(
      context: context,
      builder: (ctx) =>
          LegalDocumentDialog(title: title, content: content, icon: icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);

    return AppDialog(
      title: title,
      titleIcon: icon,
      iconColor: themeColors.primaryAccent,
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: screenSize.height * 0.65,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? themeColors.inputBackground.withValues(alpha: 0.5)
                : themeColors.inputBackground.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.mediumValue),
            border: Border.all(
              color: themeColors.separatorColor.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: TextStyle(
                  color: themeColors.textColor,
                  fontSize: AppFontSize.small,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '閉じる',
            style: TextStyle(
              color: themeColors.primaryAccent,
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.body,
            ),
          ),
        ),
      ],
    );
  }
}
