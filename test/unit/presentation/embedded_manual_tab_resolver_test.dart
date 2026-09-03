import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_tab_resolver.dart';

void main() {
  group('EmbeddedManualTabResolver テスト', () {
    test('initialTab が指定されている場合、最優先でそのタブインデックスを返すこと', () {
      expect(
        EmbeddedManualTabResolver.resolveInitialTabIndex(initialTab: 0),
        0,
      );
      expect(
        EmbeddedManualTabResolver.resolveInitialTabIndex(initialTab: 1),
        1,
      );
      expect(
        EmbeddedManualTabResolver.resolveInitialTabIndex(initialTab: 2),
        2,
      );
      // 範囲外の場合はデフォルト(2)にフォールバック
      expect(
        EmbeddedManualTabResolver.resolveInitialTabIndex(initialTab: 99),
        2,
      );
    });

    test('initialFilePath に bunaiksen が含まれる場合、1 (部内戦) を返すこと', () {
      expect(
        EmbeddedManualTabResolver.resolveInitialTabIndex(
          initialFilePath:
              'packages/documentation_runtime/manuals/bunaiksen/index.md',
        ),
        1,
      );
    });

    test('initialFilePath に quickstart が含まれる場合、0 (通常クイック) を返すこと', () {
      expect(
        EmbeddedManualTabResolver.resolveInitialTabIndex(
          initialFilePath:
              'packages/documentation_runtime/manuals/quickstart/index.md',
        ),
        0,
      );
    });

    test('initialFilePath にどちらも含まれない場合、2 (総合マニュアル) を返すこと', () {
      expect(
        EmbeddedManualTabResolver.resolveInitialTabIndex(
          initialFilePath:
              'packages/documentation_runtime/manuals/scoring/rules.md',
        ),
        2,
      );
    });

    test('引数がすべて null の場合、デフォルトの 2 (総合マニュアル) を返すこと', () {
      expect(EmbeddedManualTabResolver.resolveInitialTabIndex(), 2);
    });

    test('shouldShowSearch の検索バー表示条件が正確に評価されること', () {
      // タブが総合マニュアル (2) かつ Web または PDFダウンロード済みの場合に true
      expect(
        EmbeddedManualTabResolver.shouldShowSearch(
          selectedTabIndex: 2,
          isWeb: true,
          isPdfDownloaded: false,
          forceMarkdownFallback: false,
        ),
        isTrue,
      );

      expect(
        EmbeddedManualTabResolver.shouldShowSearch(
          selectedTabIndex: 2,
          isWeb: false,
          isPdfDownloaded: true,
          forceMarkdownFallback: false,
        ),
        isTrue,
      );

      // 他のタブ (0 または 1) の場合は false
      expect(
        EmbeddedManualTabResolver.shouldShowSearch(
          selectedTabIndex: 0,
          isWeb: true,
          isPdfDownloaded: true,
          forceMarkdownFallback: false,
        ),
        isFalse,
      );

      // Markdownフォールバック強制時は false (ネイティブアプリ環境)
      expect(
        EmbeddedManualTabResolver.shouldShowSearch(
          selectedTabIndex: 2,
          isWeb: false,
          isPdfDownloaded: true,
          forceMarkdownFallback: true,
        ),
        isFalse,
      );
    });
  });
}
