import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🥋 大会・オーダー取り込みの元テキスト直接編集・再解析ビュー
class TournamentShareImportRawView extends StatelessWidget {
  final TextEditingController rawTextController;
  final VoidCallback onReparse;
  final Color accentColor;
  final Color textColor;
  final Color subTextColor;
  final bool isDark;

  const TournamentShareImportRawView({
    super.key,
    required this.rawTextController,
    required this.onReparse,
    required this.accentColor,
    required this.textColor,
    required this.subTextColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'TimeTreeやLINE、メモ等のテキストを貼り付けて解析できます。',
          style: TextStyle(fontSize: AppFontSize.small, color: subTextColor),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: rawTextController,
          maxLines: 10,
          style: TextStyle(fontSize: AppFontSize.body, color: textColor),
          decoration: InputDecoration(
            hintText: '例:\n黒瀬杯争奪剣道大会\n日時: 令和8年9月20日\n場所: ...',
            hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.mediumValue),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFF2F2F7),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: onReparse,
          icon: const Icon(Icons.psychology),
          label: const Text('テキストを再解析する'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: AppKendoColors.pureWhite,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.mediumValue),
            ),
          ),
        ),
      ],
    );
  }
}
