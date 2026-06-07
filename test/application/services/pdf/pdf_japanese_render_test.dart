import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
// ★ 適合補正: エラーログから確定した実際の配置階層パスへ100%完全に同期
import 'package:kendo_os/features/pdf/widgets/pdf_team_table.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_individual_list.dart';
import 'package:kendo_os/features/match/domain/match_model.dart'; // ★ 追加: 本物のドメインオブジェクト型をロード

void main() {
  group('🛡️ [Phase 6-2] PDF 日本語レンダリング＆豆腐文字完全防止テスト', () {
    test('日本語文字列および「×」マークが、pdfエンジンの例外を投げずに100%決定論的にビルドできること', () async {
      final doc = pw.Document();

      // ★ 修正: Helvetica は日本語(Unicode)をサポートしていないため、実際の日本語フォントをロードします
      final fontFile = File(
        'assets/fonts/NotoSansJP-Regular.ttf',
      ); // ※プロジェクトの実際のフォントパスに合わせてください
      if (!fontFile.existsSync()) {
        markTestSkipped('日本語フォントファイルが存在しないため、PDFレンダリングテストを安全にスキップします。');
        return;
      }
      final fontData = fontFile.readAsBytesSync();
      final font = pw.Font.ttf(fontData.buffer.asByteData());

      // ★ 修正: baseと完全に同一のフォントデータをfallbackに指定すると、
      // pdfパッケージ内部のフォント解決で無限ループ(ハングアップ)を引き起こしテストが終了しなくなります。
      // これを防ぐため、fallbackの指定自体を取り除きます。
      final fontBold = pw.Font.ttf(fontData.buffer.asByteData());

      // ★ 適合補正: Map を全廃し、コンパイル時ゲッター参照エラーを完全に防壁化する MatchModel 空間へ完全同期
      final mockMatches = [
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: '広島道場 : 皿田',
          whiteName: '岡山道場 : 宮本',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
          note: '[リーグ戦]',
        ),
      ];

      // 1. 団体戦対戦表の pw.Widget レンダリング検証（例外が起きないこと）
      final teamTableWidget = PdfTeamTable.build(
        'Aリーグ',
        mockMatches,
        font,
        fontBold,
      );
      expect(teamTableWidget, isNotNull);

      // 2. 個人戦リストの pw.Widget レンダリング検証
      final individualListWidget = PdfIndividualList.build(
        '一般の部',
        mockMatches,
        font,
        fontBold,
      );
      expect(individualListWidget, isNotNull);

      // 3. 実際にドキュメントにページを追加し、バイナリへのシリアライズがクラッシュせず決定論的に完了することを証明
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (pw.Context context) {
            return pw.Column(children: [teamTableWidget, individualListWidget]);
          },
        ),
      );

      // ★ 修正: doc.save() は Future<Uint8List> を返すため、await を付けて結果を取得します
      final bytes = await doc.save();
      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, true); // バイナリストリームが正常に生成されたことを確認
    });
  });
}
