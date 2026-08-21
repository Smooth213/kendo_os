import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'dart:io' as io;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kendo_os/shared/utils/file_download_helper.dart'
    if (dart.library.html) 'package:kendo_os/shared/utils/file_download_helper_web.dart'
    as download_helper;

import 'package:kendo_os/features/pdf/helpers/pdf_page_layout_helper.dart';
import 'package:kendo_os/features/pdf/services/pdf_font_loader.dart';

class PdfService {
  static bool get _isTest {
    if (kIsWeb) return false;
    return io.Platform.environment.containsKey('FLUTTER_TEST');
  }

  static Future<Uint8List> _generatePdfBytes(
    String categoryName,
    List<Map<String, dynamic>> groupDataList, {
    String? tournamentName,
    String? tournamentDate,
    String? tournamentVenue,
    required DateTime outputTime,
  }) async {
    final fontPair = await PdfFontLoader.loadFonts();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(AppSpacing.xxl),
        theme: pw.ThemeData.withFont(
          base: fontPair.regular,
          bold: fontPair.bold,
        ),
        header: (pw.Context context) => PdfPageLayoutHelper.buildHeader(
          categoryName: categoryName,
          tournamentName: tournamentName,
          tournamentDate: tournamentDate,
          tournamentVenue: tournamentVenue,
          outputTime: outputTime,
        ),
        footer: (pw.Context context) =>
            PdfPageLayoutHelper.buildFooter(context),
        build: (pw.Context context) => PdfPageLayoutHelper.buildContentWidgets(
          groupDataList: groupDataList,
          ttf: fontPair.regular,
          ttfBold: fontPair.bold,
        ),
      ),
    );
    return pdf.save();
  }

  static Future<void> printOfficialRecord(
    String categoryName,
    List<Map<String, dynamic>> groupDataList, {
    String? tournamentName,
    String? tournamentDate,
    String? tournamentVenue,
    required DateTime outputTime,
  }) async {
    if (_isTest) {
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // テスト時にダイアログ描画を待たせるためのダミー遅延
      return;
    }
    final pdfBytes = await _generatePdfBytes(
      categoryName,
      groupDataList,
      tournamentName: tournamentName,
      tournamentDate: tournamentDate,
      tournamentVenue: tournamentVenue,
      outputTime: outputTime,
    );

    if (kIsWeb) {
      // Webブラウザではポップアップブロックにより Printing.layoutPdf が
      // 動作しないため、PDFを直接ダウンロードとして提供します。
      // ブラウザは PDF をダウンロード後に標準の印刷機能で印刷できます。
      download_helper.downloadFileWeb(
        pdfBytes,
        '公式記録_$categoryName.pdf',
        'application/pdf',
      );
    } else {
      // ネイティブ（iOS/Android/macOS）では従来通り印刷プレビューを表示します。
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdfBytes,
        name: '公式記録_$categoryName.pdf',
        usePrinterSettings: true,
      );
    }
  }

  static Future<void> shareOfficialRecordAsImage(
    String categoryName,
    List<Map<String, dynamic>> groupDataList, {
    String? tournamentName,
    String? tournamentDate,
    String? tournamentVenue,
    required DateTime outputTime,
  }) async {
    if (_isTest) {
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // テスト時にダイアログ描画を待たせるためのダミー遅延
      return;
    }
    final pdfBytes = await _generatePdfBytes(
      categoryName,
      groupDataList,
      tournamentName: tournamentName,
      tournamentDate: tournamentDate,
      tournamentVenue: tournamentVenue,
      outputTime: outputTime,
    );
    final outputFiles = <XFile>[];
    int pageNum = 1;
    await for (final page in Printing.raster(pdfBytes, dpi: 300)) {
      final pngBytes = await page.toPng();
      outputFiles.add(
        XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: '公式記録_${categoryName}_$pageNum.png',
        ),
      );
      pageNum++;
    }
    if (kIsWeb) {
      // Web環境の場合は、まずブラウザ組み込みの navigator.share (画像共有) の直接起動を試みます。
      // これにより、iPhoneのSafari(Webアプリ)等でOS標準の複数枚画像共有シートを重複なく起動させます。
      final List<Uint8List> filesBytes = [];
      final List<String> filenames = [];
      for (final file in outputFiles) {
        filesBytes.add(await file.readAsBytes());
        filenames.add(file.name);
      }

      final String text = '【$categoryName】の公式記録です。';
      final shared = await download_helper.shareFilesWeb(
        filesBytes,
        filenames,
        'image/png',
        text,
      );

      // デスクトップChromeなど、navigator.share が非対応の環境では、
      // フォールバックとして独自のWebダウンロード処理（重複なく1枚ずつ確実に保存）を実行します。
      if (!shared) {
        for (int i = 0; i < filesBytes.length; i++) {
          download_helper.downloadFileWeb(
            filesBytes[i],
            filenames[i],
            'image/png',
          );
        }
      }
    } else {
      await SharePlus.instance.share(
        ShareParams(files: outputFiles, text: '【$categoryName】の公式記録です。'),
      );
    }
  }
}
