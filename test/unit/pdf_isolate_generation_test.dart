import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/isolate/pdf_isolate.dart';

void main() {
  group('[Unit] PDFバックグラウンドIsolateワーカー単体テスト', () {
    test('runPdfGenerationにおいてSendPort経由で完了通知と生成パスが正確に応答されること', () async {
      final receivePort = ReceivePort();

      final inputData = <String, dynamic>{
        'tournamentTitle': '春季親善剣道大会',
        'matchCount': 16,
      };

      // Isolate内部関数を直接呼び出してメッセージパッシングを検証
      await runPdfGeneration(receivePort.sendPort, inputData);

      final dynamic response = await receivePort.first;
      expect(response, isA<Map<String, dynamic>>());
      final map = response as Map<String, dynamic>;
      expect(map['status'], equals('complete'));
      expect(map['path'], equals('generated_path'));

      receivePort.close();
    });
  });
}
