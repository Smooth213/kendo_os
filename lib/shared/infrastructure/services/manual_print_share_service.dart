import 'dart:io';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// 🖨️ マニュアルPDF印刷・共有ヘルパーサービス
class ManualPrintShareService {
  const ManualPrintShareService();

  Future<void> printPdf({
    required bool isAsset,
    String? assetPath,
    File? file,
    required String fileName,
  }) async {
    if (isAsset) {
      final data = await rootBundle.load(assetPath!);
      await Printing.layoutPdf(
        onLayout: (_) => data.buffer.asUint8List(),
        name: fileName,
      );
    } else {
      final bytes = await file!.readAsBytes();
      await Printing.layoutPdf(onLayout: (_) => bytes, name: fileName);
    }
  }

  Future<void> sharePdf({
    required bool isAsset,
    String? assetPath,
    File? file,
    required String fileName,
  }) async {
    Uint8List bytes;
    if (isAsset) {
      final data = await rootBundle.load(assetPath!);
      bytes = data.buffer.asUint8List();
    } else {
      bytes = await file!.readAsBytes();
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf'),
        ],
        text: '$fileName を共有します。',
      ),
    );
  }
}
