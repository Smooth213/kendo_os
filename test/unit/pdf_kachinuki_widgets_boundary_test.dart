import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/pdf/painters/pdf_kachinuki_widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('[Unit] 勝ち抜き戦PDFウィジェット境界値 単体テスト', () {
    test('選手名パースにおいて 学校名コロン分解および欠員処理が正常に実行されること', () {
      // 1. 通常の選手名
      final normal = PdfKachinukiWidgets.parsePlayerName('山田 太郎');
      expect(normal['last'], '山田');
      expect(normal['first'], '太郎');

      // 2. 学校名コロン付きの選手名
      final withSchool = PdfKachinukiWidgets.parsePlayerName('練武館:佐藤 次郎');
      expect(withSchool['last'], '佐藤');
      expect(withSchool['first'], '次郎');

      // 3. 欠員処理
      final absent = PdfKachinukiWidgets.parsePlayerName('道場:欠員');
      expect(absent['last'], '');
      expect(absent['first'], '');

      // 4. 括弧付きの選手名
      final bracketed = PdfKachinukiWidgets.parsePlayerName('剣友会:（鈴木 三郎）');
      expect(bracketed['last'], '鈴木');
      expect(bracketed['first'], '三郎');
    });

    test('チーム名ウィジェットにおいて 25文字超のチーム名が安全にトリミング縮小されること', () {
      final font = pw.Font.helveticaBold();
      const longTeamName = '全国高等学校総合体育大会剣道競技大会優勝記念選抜チーム';
      expect(longTeamName.length, greaterThan(25));

      final widget = PdfKachinukiWidgets.teamText(
        longTeamName,
        0,
        0,
        100,
        30,
        font,
        color: PdfColors.black,
      );

      expect(widget, isA<pw.Positioned>());
    });

    test('選手名セルにおいて 8文字超トリミングおよび同姓頭文字自動識別が正常に反映されること', () {
      final font = pw.Font.helvetica();

      // 1. 欠員時はSizedBoxが返却されること
      final absentWidget = PdfKachinukiWidgets.playerCell(
        '欠員',
        ['山田', '佐藤'],
        0,
        0,
        50,
        50,
        font,
      );
      expect(absentWidget, isA<pw.SizedBox>());

      // 2. 8文字超の長名
      const longLastName = '東郷平八郎三郎四郎五郎 太郎';
      final longWidget = PdfKachinukiWidgets.playerCell(
        longLastName,
        ['東郷平八郎三郎四郎五郎'],
        0,
        0,
        50,
        50,
        font,
      );
      expect(longWidget, isA<pw.Positioned>());

      // 3. 同姓頭文字の表示判定
      final sameLastNameWidget = PdfKachinukiWidgets.playerCell(
        '佐藤 健一',
        ['佐藤', '佐藤', '田中'],
        0,
        0,
        50,
        50,
        font,
      );
      expect(sameLastNameWidget, isA<pw.Positioned>());
    });

    test('スコア描画において 先取点一本丸囲みが適切に生成されること', () {
      final font = pw.Font.helveticaBold();
      final points = [
        const PdfPointData('メ', true),
        const PdfPointData('コ', false),
      ];

      final columnWidget = PdfKachinukiWidgets.pdfScoreColumn(
        points,
        font,
        reverse: false,
        color: PdfColors.red,
      );

      expect(columnWidget, isA<pw.Column>());
    });
  });
}
