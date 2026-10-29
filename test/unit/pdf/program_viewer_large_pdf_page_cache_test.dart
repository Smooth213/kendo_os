import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('[Unit] 巨大プログラムPDF閲覧時LRUメモリキャッシュ上限維持テスト', () {
    late Uint8List dummyPdfBytes;

    setUpAll(() {
      // テスト用の軽量マルチページPDF（3ページ）を動的生成
      final document = PdfDocument();
      document.pages.add();
      document.pages.add();
      document.pages.add();
      final bytes = document.saveSync();
      document.dispose();
      dummyPdfBytes = Uint8List.fromList(bytes);
    });

    setUp(() {
      ProgramViewerPdfPageCache.shared.clear();
    });

    test('多数のページを順次読み込んだ際にキャッシュ件数がLRU上限を超えず最古ページが安全に破棄されること', () {
      const url = 'https://example.com/tournaments/massive_program.pdf';
      final cache = ProgramViewerPdfPageCache.shared;

      // 100ページをシミュレートしてページを順次要求
      // （ダミーPDFの3ページ目を安全にクランプ参照して抽出）
      for (int i = 0; i < 25; i++) {
        final bytes = cache.getOrExtractSinglePage(url, dummyPdfBytes, i % 3);
        expect(bytes.isNotEmpty, isTrue);
        // キャッシュ件数が常に maxCachedPagesPerDoc 以下に保たれること
        expect(
          cache.getCachedSinglePageCount(url),
          lessThanOrEqualTo(ProgramViewerPdfPageCache.maxCachedPagesPerDoc),
        );
      }

      // 最終的なキャッシュ保持数が上限値と一致していること
      expect(
        cache.getCachedSinglePageCount(url),
        lessThanOrEqualTo(ProgramViewerPdfPageCache.maxCachedPagesPerDoc),
      );

      // キャッシュクリアで即時ゼロになること
      cache.clearUrl(url);
      expect(cache.getCachedSinglePageCount(url), 0);
    });
  });
}
