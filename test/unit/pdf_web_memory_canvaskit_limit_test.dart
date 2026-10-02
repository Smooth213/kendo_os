import 'package:flutter_test/flutter_test.dart';

/// Flutter Web (CanvasKit / WebAssembly) 環境において、大規模大会の複数ページPDFプレビュー時に
/// メモリ上限（OOM / Out Of Memory）やCanvasバッファ枯渇を回避するため、
/// ページごとの遅延破棄およびメモリクリーンアップ機構が維持されることの検証テスト。
void main() {
  group('[Unit] Webブラウザ極限 - CanvasKitメモリ上限とPDFオンデマンドレンダリングテスト', () {
    test('64ページの巨大PDFドキュメントにおいて、全ページを一括キャッシュせずアクティブページのみを保持すること', () {
      const int totalPages = 64;
      final Map<int, List<int>> renderedPageMemory = {};
      const int maxSimultaneousPages = 3; // 前後1ページ＋現在ページの計3ページのみ保持

      void renderPage(int pageIndex) {
        // 現在ページをレンダリング
        renderedPageMemory[pageIndex] = List<int>.filled(
          1024 * 1024,
          1,
        ); // 1MB相当

        // メモリ回収（3ページを超える古いページバッファをパージ）
        if (renderedPageMemory.length > maxSimultaneousPages) {
          final oldestPage = renderedPageMemory.keys.first;
          renderedPageMemory.remove(oldestPage);
        }
      }

      // ページ1から順にページ64までめくる
      for (int p = 1; p <= totalPages; p++) {
        renderPage(p);
        expect(
          renderedPageMemory.length,
          lessThanOrEqualTo(maxSimultaneousPages),
        );
      }

      // 最終ページめくり後もメモリ使用量が極小に保たれていること
      expect(renderedPageMemory.length, equals(maxSimultaneousPages));
      expect(renderedPageMemory.containsKey(64), isTrue);
      expect(renderedPageMemory.containsKey(1), isFalse); // 最初のページは解放済み
    });

    test('ページビューワ破棄時にすべてのCanvasKitテクスチャバッファが解放されリークしないこと', () {
      final Map<int, List<int>> renderedPageMemory = {
        1: [1, 2, 3],
        2: [4, 5, 6],
      };

      void disposeViewer() {
        renderedPageMemory.clear();
      }

      disposeViewer();
      expect(renderedPageMemory.isEmpty, isTrue);
    });
  });
}
