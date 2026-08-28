import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_floating_action_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_pdf_download_card.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// 📖 総合マニュアルタブ表示ビュー（純粋UIレイアウトコンポーネント）
class ManualFullManualTabView extends StatelessWidget {
  final Widget buildIndexPane;
  final Widget markdownPane;
  final bool isPdfDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final bool forceMarkdownFallback;
  final File? localPdfFile;
  final PdfViewerController? pdfViewerController;
  final String fullManualFileName;
  final VoidCallback onStartDownload;
  final VoidCallback onEnableMarkdownFallback;
  final VoidCallback onDisableMarkdownFallback;
  final VoidCallback onOpenPdfInBrowser;
  final VoidCallback onShareWebUrl;
  final VoidCallback onPrintPdf;
  final VoidCallback onSharePdf;

  const ManualFullManualTabView({
    super.key,
    required this.buildIndexPane,
    required this.markdownPane,
    required this.isPdfDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.forceMarkdownFallback,
    required this.localPdfFile,
    required this.pdfViewerController,
    required this.fullManualFileName,
    required this.onStartDownload,
    required this.onEnableMarkdownFallback,
    required this.onDisableMarkdownFallback,
    required this.onOpenPdfInBrowser,
    required this.onShareWebUrl,
    required this.onPrintPdf,
    required this.onSharePdf,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 600;

    if (kIsWeb) {
      return Stack(
        children: [
          Row(children: [if (isWide) buildIndexPane, markdownPane]),
          Positioned(
            bottom: AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: ManualFloatingActionBar(
              primaryLabel: 'PDF版をブラウザで開く',
              primaryIcon: Icons.open_in_new,
              onPrimaryPressed: onOpenPdfInBrowser,
              secondaryLabel: '共有する',
              secondaryIcon: Icons.ios_share,
              onSecondaryPressed: onShareWebUrl,
              isDark: isDark,
            ),
          ),
        ],
      );
    }

    if (forceMarkdownFallback) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.lg,
            ),
            color: AppKendoColors.teal.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📖 テキスト簡易版（オフライン対応）',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: const Text('PDF版に戻る'),
                  onPressed: onDisableMarkdownFallback,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(children: [if (isWide) buildIndexPane, markdownPane]),
          ),
        ],
      );
    }

    if (isDownloading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: AppRadius.xlarge,
            boxShadow: [
              BoxShadow(
                color: AppKendoColors.pureBlack.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoadingIndicator(),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'マニュアルをロード中...',
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(
                value: downloadProgress > 0 ? downloadProgress : null,
                backgroundColor: AppKendoColors.grey.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppKendoColors.ipponGold,
                ),
                borderRadius: AppRadius.micro,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${(downloadProgress * 100).toInt()}% 完了',
                style: const TextStyle(
                  fontSize: AppFontSize.small,
                  color: AppKendoColors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!isPdfDownloaded) {
      return ManualPdfDownloadCard(
        onDownloadPressed: onStartDownload,
        onTextFallbackPressed: onEnableMarkdownFallback,
      );
    }

    return Stack(
      children: [
        if (localPdfFile != null)
          SfPdfViewer.file(localPdfFile!, controller: pdfViewerController),
        Positioned(
          bottom: AppSpacing.xl,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          child: ManualFloatingActionBar(
            primaryLabel: 'A4印刷',
            primaryIcon: Icons.print,
            onPrimaryPressed: onPrintPdf,
            secondaryLabel: '共有/保存',
            secondaryIcon: Icons.ios_share,
            onSecondaryPressed: onSharePdf,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}
