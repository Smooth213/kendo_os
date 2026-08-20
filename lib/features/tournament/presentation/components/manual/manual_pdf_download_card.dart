import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 📥 総合マニュアルPDFダウンロード案内カード（純粋UIコンポーネント）
class ManualPdfDownloadCard extends StatelessWidget {
  final VoidCallback onDownloadPressed;
  final VoidCallback onTextFallbackPressed;

  const ManualPdfDownloadCard({
    super.key,
    required this.onDownloadPressed,
    required this.onTextFallbackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            color: isDark
                ? context.appColors.textColor.withValues(alpha: 0.05)
                : context.appColors.cardBackground.withValues(alpha: 0.02),
            borderRadius: AppRadius.xlarge,
            border: Border.all(
              color: isDark
                  ? context.appColors.textColor.withValues(alpha: 0.1)
                  : context.appColors.cardBackground.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 80,
                color: context.appColors.primaryAccent.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kendo Sync 総合取扱説明書',
                style: TextStyle(
                  fontSize: AppFontSize.titleLarge,
                  fontWeight: AppFontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                '印刷や文字検索、高倍率ズームが可能な公式PDF版マニュアルをダウンロードできます。一度保存すると、オフラインでも閲覧可能です。',
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  color: AppKendoColors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'ファイルサイズ: 約 2.6 MB',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.primaryAccent,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.primaryAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.large,
                    ),
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text(
                    'PDF版をダウンロード (無料)',
                    style: TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  onPressed: onDownloadPressed,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                icon: const Icon(Icons.chrome_reader_mode_outlined),
                label: const Text('テキスト簡易版（オフライン対応）を読む'),
                onPressed: onTextFallbackPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
