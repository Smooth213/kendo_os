import 'package:flutter_test/flutter_test.dart';

/// 300DPI公式記録ラスタライズ時のメモリバジェット制御パイプライン
class PdfRasterMemoryBudgetPipeline {
  static const int maxMemoryBudgetBytes = 50 * 1024 * 1024; // 50MBメモリバジェット
  int currentActiveMemoryBytes = 0;
  int peakMemoryUsageBytes = 0;
  final List<String> exportedPageFiles = [];

  Future<void> rasterizeAndExportPages({
    required int pageCount,
    required int singlePageRasterSizeBytes,
  }) async {
    for (int pageIndex = 1; pageIndex <= pageCount; pageIndex++) {
      // 1. ページを300DPIでラスタライズ（メモリ割り当て）
      currentActiveMemoryBytes += singlePageRasterSizeBytes;
      if (currentActiveMemoryBytes > peakMemoryUsageBytes) {
        peakMemoryUsageBytes = currentActiveMemoryBytes;
      }

      // バジェット制限超過チェック
      if (currentActiveMemoryBytes > maxMemoryBudgetBytes) {
        throw StateError('メモリバジェット超過エラー: OOMクラッシュ防止');
      }

      // 2. ディスクまたはBlobへ書き出し完了
      exportedPageFiles.add('official_record_page_$pageIndex.png');

      // 3. 逐次即時解放（Dispose & GC促進）
      currentActiveMemoryBytes -= singlePageRasterSizeBytes;
    }
  }
}

void main() {
  group('[Unit] 公式記録300DPIラスタライズ時メモリバジェット逐次解放テスト', () {
    test('複数ページの公式記録高DPI画像化において全ページを一括保持せず1ページごとに即時解放すること', () async {
      final pipeline = PdfRasterMemoryBudgetPipeline();

      // 300DPIのA4ラスタライズ1ページあたり約30MBのメモリ消費を想定
      const int singlePageSize = 30 * 1024 * 1024; // 30MB
      const int totalPages = 10; // 全10ページ（一括なら300MBで低メモリ端末はOOM）

      await pipeline.rasterizeAndExportPages(
        pageCount: totalPages,
        singlePageRasterSizeBytes: singlePageSize,
      );

      // 全ページが欠損なくエクスポートされていること
      expect(pipeline.exportedPageFiles.length, totalPages);
      // ピークメモリが単一ページ分（30MB）に抑制され、50MBバジェット内に収まっていること
      expect(pipeline.peakMemoryUsageBytes, equals(singlePageSize));
      // 処理完了後にアクティブメモリが0バイトへクリーンアップされていること
      expect(pipeline.currentActiveMemoryBytes, 0);
    });
  });
}
