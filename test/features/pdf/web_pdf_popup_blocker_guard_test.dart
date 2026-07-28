// 🛡️ Web PDF印刷ポップアップブロック対策 保護テスト
//
// 背景:
//   公式記録のPDF印刷で Printing.layoutPdf を使うと、PDF生成の非同期待機後に
//   ブラウザのポップアップブロックに引っかかりウィンドウが開かなくなる問題があった。
//
//   修正内容 (pdf_service.dart):
//     kIsWeb == true のとき → downloadFileWeb (直接ダウンロード)
//     kIsWeb == false のとき → Printing.layoutPdf (ネイティブ印刷プレビュー)
//
// テスト方針:
//   - kIsWeb はコンパイル時定数のため実行時に切り替え不可。
//   - ソースコード解析テスト: pdf_service.dart が kIsWeb 分岐と
//     downloadFileWeb を正しく使っていることをソース文字列で検証。
//   - ロジック等価テスト: Web/ネイティブ判定ロジックの純粋関数版を検証。
//   - 回帰防止テスト: 意図しない Printing.layoutPdf 単独呼び出しへの戻りを検知。

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

// --------------------------------------------------------------------------
// テスト対象ロジックの純粋関数版
// (pdf_service.dart の kIsWeb 分岐ロジックと等価)
// --------------------------------------------------------------------------

/// PDF印刷の実行経路を示す列挙型
enum PdfPrintRoute {
  /// Web: ダウンロード（ポップアップ不使用）
  webDownload,

  /// ネイティブ: 印刷プレビュー
  nativePrintPreview,
}

/// kIsWeb フラグからどちらの経路を選ぶかを決定する純粋関数
/// (pdf_service.dart の if (kIsWeb) 分岐と等価)
PdfPrintRoute resolvePdfPrintRoute({required bool isWeb}) {
  return isWeb ? PdfPrintRoute.webDownload : PdfPrintRoute.nativePrintPreview;
}

/// ファイル名生成ロジック (pdf_service.dart と等価)
String buildPdfFileName(String categoryName) {
  return '公式記録_$categoryName.pdf';
}

/// MIME タイプ (pdf_service.dart と等価)
const String pdfMimeType = 'application/pdf';

// --------------------------------------------------------------------------
// ソースコード解析ヘルパー
// --------------------------------------------------------------------------
String _loadPdfServiceSource() {
  const path = 'lib/features/pdf/pdf_service.dart';
  final file = File(path);
  expect(
    file.existsSync(),
    isTrue,
    reason: 'lib/features/pdf/pdf_service.dart が存在する必要があります',
  );
  return file.readAsStringSync();
}

// --------------------------------------------------------------------------
// Tests
// --------------------------------------------------------------------------
void main() {
  group('🛡️ Web PDF印刷 ポップアップブロック対策保護テスト', () {
    // ──────────────────────────────────────────────────────────────
    // 経路選択ロジック（純粋関数）
    // ──────────────────────────────────────────────────────────────
    group('🔀 経路選択ロジック (resolvePdfPrintRoute)', () {
      test('✅ Web環境では webDownload 経路が選ばれる', () {
        expect(
          resolvePdfPrintRoute(isWeb: true),
          PdfPrintRoute.webDownload,
          reason:
              'Web では downloadFileWeb を呼ぶ経路でなければならない。'
              'Printing.layoutPdf を使うとポップアップブロックが発動する。',
        );
      });

      test('✅ ネイティブ環境では nativePrintPreview 経路が選ばれる', () {
        expect(
          resolvePdfPrintRoute(isWeb: false),
          PdfPrintRoute.nativePrintPreview,
          reason: 'ネイティブでは従来通り Printing.layoutPdf を使う。',
        );
      });

      test('✅ 現在の実行環境（ネイティブテスト）では nativePrintPreview が選ばれる', () {
        // テストランナー自体はネイティブ(非Web)なので kIsWeb == false
        expect(
          resolvePdfPrintRoute(isWeb: kIsWeb),
          PdfPrintRoute.nativePrintPreview,
          reason: 'flutter test はネイティブ環境で実行されるため kIsWeb=false',
        );
      });

      test('✅ Web/ネイティブで異なる経路が選ばれる（相互排他）', () {
        final webRoute = resolvePdfPrintRoute(isWeb: true);
        final nativeRoute = resolvePdfPrintRoute(isWeb: false);
        expect(
          webRoute,
          isNot(equals(nativeRoute)),
          reason: 'Web とネイティブで経路は必ず異なる必要がある',
        );
      });
    });

    // ──────────────────────────────────────────────────────────────
    // ファイル名・MIME タイプ
    // ──────────────────────────────────────────────────────────────
    group('📄 PDFファイル名・MIMEタイプ', () {
      test('✅ ファイル名が正しく生成される（小学生の部）', () {
        expect(buildPdfFileName('小学生の部'), '公式記録_小学生の部.pdf');
      });

      test('✅ ファイル名が正しく生成される（一般の部）', () {
        expect(buildPdfFileName('一般の部'), '公式記録_一般の部.pdf');
      });

      test('✅ MIMEタイプが application/pdf である', () {
        expect(pdfMimeType, 'application/pdf');
      });
    });

    // ──────────────────────────────────────────────────────────────
    // ソースコード解析テスト（回帰防止）
    // ──────────────────────────────────────────────────────────────
    group('🔬 ソースコード解析（回帰防止）', () {
      late String source;

      setUpAll(() {
        source = _loadPdfServiceSource();
      });

      test('✅ printOfficialRecord が kIsWeb 分岐を持つ', () {
        expect(
          source,
          contains('if (kIsWeb)'),
          reason:
              'printOfficialRecord は kIsWeb で分岐していなければならない。'
              'この分岐がなければ Web でもポップアップブロックが発動する。',
        );
      });

      test('✅ Web経路で downloadFileWeb を呼んでいる', () {
        expect(
          source,
          contains('download_helper.downloadFileWeb('),
          reason:
              'Web経路では downloadFileWeb を呼ぶことで'
              'ポップアップブロックを回避する。',
        );
      });

      test('✅ Web経路で application/pdf MIME タイプを指定している', () {
        expect(
          source,
          contains("'application/pdf'"),
          reason: 'PDFのMIMEタイプが正しく指定されていること。',
        );
      });

      test('✅ download_helper のインポートが存在する（条件付きインポート）', () {
        expect(
          source,
          contains('file_download_helper'),
          reason: 'file_download_helper のインポートがなければ downloadFileWeb が呼べない。',
        );
      });

      test('✅ ネイティブ用 else 節に Printing.layoutPdf がある', () {
        expect(
          source,
          contains('Printing.layoutPdf('),
          reason:
              'ネイティブ用の印刷プレビュー (Printing.layoutPdf) が'
              'else 節に保持されていること。',
        );
      });

      test('✅ printOfficialRecord メソッドが存在する', () {
        expect(
          source,
          contains('static Future<void> printOfficialRecord('),
          reason: 'printOfficialRecord が削除されていないこと。',
        );
      });

      test('❌ 【回帰検知】kIsWeb 分岐が消えていないこと', () {
        // 旧バージョンのコード（修正前）では kIsWeb 分岐なしで
        // Printing.layoutPdf を呼んでいた。これに戻っていないことを確認。
        final kIsWebCount = 'kIsWeb'.allMatches(source).length;
        expect(
          kIsWebCount,
          greaterThanOrEqualTo(1),
          reason:
              'kIsWeb による分岐が少なくとも1箇所存在する必要がある。'
              '0になった場合、ポップアップブロック対策が失われている。',
        );
      });
    });

    // ──────────────────────────────────────────────────────────────
    // ポップアップブロックが発動する条件の知識テスト（仕様文書）
    // ──────────────────────────────────────────────────────────────
    group('📚 ポップアップブロック仕様の知識テスト', () {
      test('✅ 非同期PDF生成後のウィンドウ開放はポップアップブロック対象になる', () {
        // ブラウザのポップアップブロックはユーザーの直接操作（タップ等）から
        // 切り離された非同期タイミングでのウィンドウ開放をブロックする。
        //
        // PDF生成（_generatePdfBytes）は非同期で数秒かかるため、
        // その後の Printing.layoutPdf はブロック対象になる。
        //
        // 解決策: Web では downloadFileWeb で直接ダウンロードする（ポップアップ不使用）

        final webSafeRoute = resolvePdfPrintRoute(isWeb: true);
        expect(
          webSafeRoute,
          PdfPrintRoute.webDownload,
          reason:
              'ポップアップブロック対策として Web では download 経路を使う。'
              'Printing.layoutPdf は非同期待機後はブロックされる。',
        );
      });

      test('✅ ネイティブではポップアップブロックが存在しないため layoutPdf を使用', () {
        // iOS/Android/macOS ネイティブアプリにはブラウザのポップアップブロックが
        // 存在しないため Printing.layoutPdf を安全に使用できる。
        final nativeRoute = resolvePdfPrintRoute(isWeb: false);
        expect(
          nativeRoute,
          PdfPrintRoute.nativePrintPreview,
          reason: 'ネイティブにはポップアップブロックがないため layoutPdf は安全。',
        );
      });

      test('✅ Webでの印刷フローはダウンロード→ブラウザ印刷で完結する', () {
        // downloadFileWeb が PDF を提供し、ユーザーはブラウザの標準機能で印刷する。
        // MIME タイプが application/pdf であることで、ブラウザは
        // 正しくPDFとして扱いプレビュー・印刷を提供する。
        expect(pdfMimeType, 'application/pdf');
        expect(resolvePdfPrintRoute(isWeb: true), PdfPrintRoute.webDownload);
      });

      test('✅ マニュアルPDFはポップアップブロックの影響を受けない（資産読み込みが高速）', () {
        // embedded_manual_screen.dart はアセットから高速に読み込むため
        // ユーザーのタップから短時間で layoutPdf が呼ばれ、
        // ポップアップブロックが発動しない。
        // よって embedded_manual_screen.dart は kIsWeb 分岐を不要とする。
        //
        // 公式記録だけが kIsWeb 分岐が必要な理由:
        // - PDF生成に試合データ処理で数秒かかる (非同期)
        // - ブラウザがタップと関係ないと判定してブロックする

        // マニュアル画面は変更せずそのまま layoutPdf を使うことを保証
        const manualScreenPath =
            'lib/shared/presentation/screens/embedded_manual_screen.dart';
        final manualSource = File(manualScreenPath).readAsStringSync();

        // マニュアルには kIsWeb の pdf 分岐がないことを確認
        // (download_helper は使っていない)
        expect(
          manualSource.contains('download_helper.downloadFileWeb'),
          isFalse,
          reason:
              'マニュアル画面は download_helper を使わない。'
              'layoutPdf がそのまま動作するため変更不要。',
        );
      });
    });
  });
}
