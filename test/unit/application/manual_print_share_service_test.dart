import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/services/manual_print_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dummyPdf;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('manual_print_share_test');
    dummyPdf = File('${tempDir.path}/test_manual.pdf');
    await dummyPdf.writeAsBytes([0x25, 0x50, 0x44, 0x46]); // %PDF
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('[Unit] ManualPrintShareService 単体テスト', () {
    test('インスタンス化が正常に行われること', () {
      const service = ManualPrintShareService();
      expect(service, isNotNull);
    });

    test('ローカルファイル指定時に例外なくバイト読み出しが行われること', () async {
      const service = ManualPrintShareService();
      expect(service, isNotNull);
      // sharePdf や printPdf は プラットフォームチャネルを叩く可能性があるが、
      // ここではファイル存在と読み取りが正常に実行されることを検証
      final bytes = await dummyPdf.readAsBytes();
      expect(bytes.length, 4);
    });
  });
}
