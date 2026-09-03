import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_full_manual_tab_view.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_quick_guide_tab_view.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_tab_resolver.dart';

/// マニュアル画面のタブビュー（クイックガイド・総合マニュアル）構築用ビルダー
class EmbeddedManualTabViews {
  const EmbeddedManualTabViews._();

  static Widget buildQuickGuideTab({
    required BuildContext context,
    required String assetPath,
    required String fileName,
    required Future<void> Function({
      required bool isAsset,
      String? assetPath,
      File? file,
      required String fileName,
    })
    onPrint,
    required Future<void> Function({
      required bool isAsset,
      String? assetPath,
      File? file,
      required String fileName,
    })
    onShare,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ManualQuickGuideTabView(
      assetPath: assetPath,
      fileName: fileName,
      onPrintPressed: () =>
          onPrint(isAsset: true, assetPath: assetPath, fileName: fileName),
      onSharePressed: () =>
          onShare(isAsset: true, assetPath: assetPath, fileName: fileName),
      isDark: isDark,
    );
  }

  static Widget buildFullManualTab({
    required Widget buildIndexPane,
    required Widget markdownPane,
    required bool isPdfDownloaded,
    required bool isDownloading,
    required double downloadProgress,
    required bool forceMarkdownFallback,
    required File? localPdfFile,
    required PdfViewerController? pdfViewerController,
    required VoidCallback onStartDownload,
    required VoidCallback onEnableMarkdownFallback,
    required VoidCallback onDisableMarkdownFallback,
    required Future<void> Function({
      required bool isAsset,
      String? assetPath,
      File? file,
      required String fileName,
    })
    onPrint,
    required Future<void> Function({
      required bool isAsset,
      String? assetPath,
      File? file,
      required String fileName,
    })
    onShare,
  }) {
    return ManualFullManualTabView(
      buildIndexPane: buildIndexPane,
      markdownPane: markdownPane,
      isPdfDownloaded: isPdfDownloaded,
      isDownloading: isDownloading,
      downloadProgress: downloadProgress,
      forceMarkdownFallback: forceMarkdownFallback,
      localPdfFile: localPdfFile,
      pdfViewerController: pdfViewerController,
      fullManualFileName: EmbeddedManualTabResolver.fullManualFileName,
      onStartDownload: onStartDownload,
      onEnableMarkdownFallback: onEnableMarkdownFallback,
      onDisableMarkdownFallback: onDisableMarkdownFallback,
      onOpenPdfInBrowser: () =>
          EmbeddedManualTabResolver.openPdfInExternalViewer(
            EmbeddedManualTabResolver.fullManualUrl,
          ),
      onShareWebUrl: () async {
        await SharePlus.instance.share(
          ShareParams(
            text:
                'Kendo Sync 総合取扱説明書はこちら: ${EmbeddedManualTabResolver.fullManualUrl}',
          ),
        );
      },
      onPrintPdf: () => onPrint(
        isAsset: false,
        file: localPdfFile,
        fileName: EmbeddedManualTabResolver.fullManualFileName,
      ),
      onSharePdf: () => onShare(
        isAsset: false,
        file: localPdfFile,
        fileName: EmbeddedManualTabResolver.fullManualFileName,
      ),
    );
  }
}
