import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_view_state_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    ProgramViewStateService.instance.resetForTesting();
    await ProgramViewStateService.instance.init(prefs: mockPrefs);
    ProgramViewerPdfPageCache.shared.clear();
  });

  group(
    '[Governance] 第6条 ガバナンス規約 5/5において ドックプログラム閲覧位置端末保存・自動復元 ＆ PDFページキャッシュ契約保証規約',
    () {
      test(
        '規約1: ProgramViewStateService はシングルトンであり、ストレージキー規約に従いメモリと端末ストレージを二重同期すること',
        () async {
          final service1 = ProgramViewStateService.instance;
          final service2 = ProgramViewStateService.instance;
          expect(
            identical(service1, service2),
            isTrue,
            reason: '単一インスタンス（Singleton）規約違反',
          );

          const tournamentId = 'tour_gov_001';
          const programKey = 'prog_gov_001';

          // 1. プログラム選択インデックスの検証
          final initialIdx = service1.getLastProgramIndex(tournamentId);
          expect(initialIdx, 0, reason: '未選択時はデフォルト0インデックスであること');

          service1.setLastProgramIndex(tournamentId, 2);
          expect(
            service1.getLastProgramIndex(tournamentId),
            2,
            reason: 'メモリキャッシュ即時反映規約',
          );
          expect(
            mockPrefs.getInt('kendo_os_prog_last_idx_$tournamentId'),
            2,
            reason: 'SharedPreferences プログラムインデックスキー規約違反',
          );

          // 2. ページ番号（1-indexed）の検証
          final initialPage = service1.getLastPageNumber(programKey);
          expect(initialPage, 1, reason: '未閲覧時はデフォルト1ページ目（1-indexed）であること');

          service1.setLastPageNumber(programKey, 5);
          expect(
            service1.getLastPageNumber(programKey),
            5,
            reason: 'メモリキャッシュ即時反映規約',
          );
          expect(
            mockPrefs.getInt('kendo_os_prog_last_page_$programKey'),
            5,
            reason: 'SharedPreferences ページ番号キー規約違反',
          );
        },
      );

      test(
        '規約2: ProgramViewerPdfPageCache.clearUrl は keepDocumentInfo: true をデフォルトとし、破棄時もメタデータを保持する契約こと',
        () {
          const testUrl = 'https://example.com/governance_sample.pdf';

          // テスト用PDF（3ページ）を生成
          final document = PdfDocument();
          document.pages.add();
          document.pages.add();
          document.pages.add();
          final bytes = Uint8List.fromList(document.saveSync());
          document.dispose();

          // キャッシュにパースして登録
          final pageCount = ProgramViewerPdfPageCache.shared.parseDocumentInfo(
            testUrl,
            bytes,
          );
          expect(pageCount, 3);
          expect(
            ProgramViewerPdfPageCache.shared.getCachedPageCount(testUrl),
            3,
          );
          expect(
            ProgramViewerPdfPageCache.shared.getPageCanvasSize(testUrl, 0),
            isA<Size>(),
          );

          // デフォルト引数で clearUrl を実行（ボトムシート終了時の動作）
          ProgramViewerPdfPageCache.shared.clearUrl(testUrl);

          // keepDocumentInfo: true がデフォルトのため、pageCount とキャンバスサイズは保持されていること
          expect(
            ProgramViewerPdfPageCache.shared.getCachedPageCount(testUrl),
            3,
            reason: 'PDF破棄時にメタデータが消失すると再描画時に1ページ目へ巻き戻るため保持が必須',
          );
          expect(
            ProgramViewerPdfPageCache.shared.getPageCanvasSize(testUrl, 0),
            isA<Size>(),
            reason: 'キャンバスサイズキャッシュが保持されていること',
          );

          // 明示的に keepDocumentInfo: false を指定した場合のみ完全にクリアされること
          ProgramViewerPdfPageCache.shared.clearUrl(
            testUrl,
            keepDocumentInfo: false,
          );
          expect(
            ProgramViewerPdfPageCache.shared.getCachedPageCount(testUrl),
            isNull,
            reason: '完全クリア指定時はメタデータも解放されること',
          );
        },
      );

      test('規約3: 大会・プログラムごとにキーが完全分離され、相互に干渉・混信しない空間分離規約こと', () {
        final service = ProgramViewStateService.instance;

        service.setLastProgramIndex('tour_alpha', 1);
        service.setLastProgramIndex('tour_beta', 3);

        service.setLastPageNumber('prog_alpha_1', 4);
        service.setLastPageNumber('prog_alpha_2', 9);
        service.setLastPageNumber('prog_beta_1', 6);

        expect(service.getLastProgramIndex('tour_alpha'), 1);
        expect(service.getLastProgramIndex('tour_beta'), 3);

        expect(service.getLastPageNumber('prog_alpha_1'), 4);
        expect(service.getLastPageNumber('prog_alpha_2'), 9);
        expect(service.getLastPageNumber('prog_beta_1'), 6);
      });

      test('規約4: アプリ再起動（サービス再インスタンス化）時、端末ストレージから保存位置が確実に復元される契約こと', () async {
        // 端末ストレージに事前値を保存
        await mockPrefs.setInt('kendo_os_prog_last_idx_tour_cold_boot', 2);
        await mockPrefs.setInt('kendo_os_prog_last_page_prog_cold_boot', 7);

        // メモリキャッシュをクリアして再初期化
        ProgramViewStateService.instance.resetForTesting();
        await ProgramViewStateService.instance.init(prefs: mockPrefs);

        final restoredIdx = ProgramViewStateService.instance
            .getLastProgramIndex('tour_cold_boot');
        final restoredPage = ProgramViewStateService.instance.getLastPageNumber(
          'prog_cold_boot',
        );

        expect(restoredIdx, 2, reason: 'アプリ再起動時のプログラムインデックス復元保証規約');
        expect(restoredPage, 7, reason: 'アプリ再起動時のページ番号復元保証規約');
      });

      test('規約5: 空文字や不正なキーに対する安全フォールバック規約こと', () {
        final service = ProgramViewStateService.instance;

        // 空文字の安全ハンドリング
        expect(service.getLastProgramIndex('', defaultIndex: 0), 0);
        expect(service.getLastPageNumber('', defaultPage: 1), 1);

        // 例外が発生しないこと
        service.setLastProgramIndex('', 5);
        service.setLastPageNumber('', 10);

        expect(service.getLastProgramIndex(''), 0);
        expect(service.getLastPageNumber(''), 1);
      });
    },
  );
}
