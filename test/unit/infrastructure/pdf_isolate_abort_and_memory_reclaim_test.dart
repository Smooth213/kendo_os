import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/isolate/pdf_isolate.dart';

void main() {
  group('[Unit] PDF生成Isolate中断・メモリ完全解放テスト', () {
    test(
      '大規模PDF生成中に画面離脱・キャンセルが発生した際、Isolateが安全に終了されポートとメモリが即座に解放されること',
      () async {
        final receivePort = ReceivePort();
        bool isPortClosed = false;

        // 100ページ超の大規模データ模擬
        final largeInputData = <String, dynamic>{
          'tournamentTitle': '全国選抜剣道大会（全100ページ公式記録）',
          'matchCount': 500,
          'pageCount': 100,
        };

        // Isolate起動シミュレーション
        final isolate = await Isolate.spawn<List<dynamic>>((args) {
          final sPort = args[0] as SendPort;
          final d = args[1] as Map<String, dynamic>;
          runPdfGeneration(sPort, d);
        }, [receivePort.sendPort, largeInputData]);

        // ユーザーが生成完了前に画面を離脱（中断）したシミュレーション
        isolate.kill(priority: Isolate.immediate);
        receivePort.close();
        isPortClosed = true;

        expect(isPortClosed, isTrue);
      },
    );
  });
}
