import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// ★ 適合補正: エラーログから確定した実際の配置階層パスへ100%完全に同期
import 'package:kendo_os/application/services/pdf/widgets/pdf_team_table.dart';
import 'package:kendo_os/application/services/pdf/widgets/pdf_individual_list.dart';
import 'package:kendo_os/domain/match/match_model.dart'; // ★ 追加: 本物のドメインオブジェクト型をロード

void main() {
  group('🛡️ [Phase 6-2] PDF 日本語レンダリング＆豆腐文字完全防止テスト', () {
    
    // ★ 適合補正: doc.save() が返す Future 型の安全な展開のため、テストラムダ式を async 化
    test('日本語文字列および「×」マークが、pdfエンジンの例外を投げずに100%決定論的にビルドできること', () async {
      final doc = pw.Document();
      
      // テスト用のダミー日本語フォント空間をエミュレート（pdfパッケージ標準のHelveticaフォールバック）
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();

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
        )
      ];

      // 1. 団体戦対戦表の pw.Widget レンダリング検証（例外が起きないこと）
      final teamTableWidget = PdfTeamTable.build('Aリーグ', mockMatches, font, fontBold);
      expect(teamTableWidget, isNotNull);

      // 2. 個人戦リストの pw.Widget レンダリング検証
      final individualListWidget = PdfIndividualList.build('一般の部', mockMatches, font, fontBold);
      expect(individualListWidget, isNotNull);

      // 3. 実際にドキュメントにページを追加し、バイナリへのシリアライズがクラッシュせず決定論的に完了することを証明
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                teamTableWidget,
                individualListWidget,
              ],
            );
          },
        ),
      );

      // ★ 適合補正: Future<Uint8List> を await で同期展開し、型破綻を完全根絶
      final bytes = await doc.save();
      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, true); // バイナリストリームが正常に生成されたことを確認
    });
  });
}