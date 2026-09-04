import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kendo_os/bootstrap/app_startup.dart';
import 'package:kendo_os/features/pdf/services/pdf_font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('📦 [Phase 6 Performance Governance] フォント・アセット最適化テスト', () {
    test('1. PdfFontLoader がメモ化キャッシュにより2回目以降を即座（同一インスタンス）に返却すること', () async {
      PdfFontLoader.clearCache();

      final firstLoad = await PdfFontLoader.loadFonts();
      expect(firstLoad, isNotNull);
      expect(firstLoad.regular, isNotNull);
      expect(firstLoad.bold, isNotNull);

      final secondLoad = await PdfFontLoader.loadFonts();
      // メモ化により完全に同一のインスタンスが返されること
      expect(identical(firstLoad, secondLoad), isTrue);
    });

    test('2. PdfFontLoader.clearCache でキャッシュが安全に破棄され再生成できること', () async {
      final firstLoad = await PdfFontLoader.loadFonts();

      PdfFontLoader.clearCache();

      final reloaded = await PdfFontLoader.loadFonts();
      // キャッシュクリア後は新規ロードされること
      expect(reloaded, isNotNull);
      expect(identical(firstLoad, reloaded), isFalse);
    });

    test(
      '3. AppStartup.configureFontOptimization が GoogleFonts の設定を制御できること',
      () {
        AppStartup.configureFontOptimization(allowRuntimeFetching: false);
        expect(GoogleFonts.config.allowRuntimeFetching, isFalse);

        AppStartup.configureFontOptimization(allowRuntimeFetching: true);
        expect(GoogleFonts.config.allowRuntimeFetching, isTrue);
      },
    );
  });
}
