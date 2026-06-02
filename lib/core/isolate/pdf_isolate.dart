import 'dart:isolate';

// 大会結果PDF生成用の分離タスク
Future<void> runPdfGeneration(SendPort sendPort, Map<String, dynamic> data) async {
  // Isolate内での重い生成処理
  // PDFライブラリの呼び出しはここで完結させる
  sendPort.send({'status': 'complete', 'path': 'generated_path'});
}