import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:pdf/widgets.dart' as pw;

// Helper from pdf_league_table_test.dart
MatchModel createMockMatch({
  required String id,
  required String redName,
  required String whiteName,
  int redScore = 0,
  int whiteScore = 0,
  String matchType = 'individual',
  String status = 'finished',
  List<ScoreEvent> events = const [],
  MatchRule? rule,
  String note = '',
}) {
  return MatchModel(
    id: id,
    tournamentId: 'test-tournament',
    category: 'test-category',
    groupName: 'test-group',
    redName: redName,
    whiteName: whiteName,
    redScore: redScore,
    whiteScore: whiteScore,
    matchType: matchType,
    status: status,
    order: 1.0,
    note: note,
    events: events,
    rule: rule ?? const MatchRule(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.Font ttf;
  late pw.Font ttfBold;

  setUpAll(() async {
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Regular.ttf',
    );
    ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final fontBoldData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Bold.ttf',
    );
    ttfBold = pw.Font.ttf(fontBoldData.buffer.asByteData());
  });

  group('[Unit] PdfTeamTable ウィジェットテスト', () {
    test('引き分けの試合で正しい引き分け記号「×」が表示されること', () {
      final matches = [
        createMockMatch(
          id: 'm1',
          redName: 'チームA:先鋒',
          whiteName: 'チームB:先鋒',
          redScore: 0,
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      final result = PdfTeamTable.build('団体戦', matches, ttf, ttfBold);
      // ★ 適合補正: Container から内包される Column を安全に取り出してキャスト
      final column = (result as pw.Container).child as pw.Column;
      final table = column.children[1] as pw.Table;
      final scoreRow = table.children[2]; // 0: header, 1: red row, 2: score row
      final scoreCell = scoreRow.children[1] as pw.Container;
      final stack = scoreCell.child as pw.Stack;

      // Find the draw symbol widget
      final drawSymbolWidget = stack.children[1];
      expect(drawSymbolWidget, isA<pw.Container>());
      final drawSymbolText =
          (drawSymbolWidget as pw.Container).child as pw.Text;

      // U+00D7 is the multiplication sign '×'
      expect(drawSymbolText.text.toPlainText(), '×');
    });

    test('古い引き分け記号「」が入力されても、PDFでは「×」に変換されること', () {
      // This tests the pdfPointBox directly as it's hard to simulate the old data through MatchModel
      final oldDrawPoint = PdfPointData('✕', false);
      final resultWidget = PdfTeamTable.pdfPointBox(
        [oldDrawPoint],
        false,
        true,
        ttfBold,
      );

      final container = resultWidget as pw.Container;
      final stack = container.child as pw.Stack;
      final textWidget = stack.children.last as pw.Text;

      expect(textWidget.text.toPlainText(), '×');
    });

    test('ヘッダータイトルが正しく生成されること', () {
      // Case 1: Normal team match
      final matches1 = [
        createMockMatch(id: 'm1', redName: 'チームA:選手', whiteName: 'チームB:選手'),
      ];
      final result1 = PdfTeamTable.build('団体戦グループA', matches1, ttf, ttfBold);
      final column1 = (result1 as pw.Container).child as pw.Column;
      final header1 = column1.children.first as pw.Container;
      final headerText1 = (header1.child as pw.Text).text.toPlainText();
      expect(headerText1, '【団体戦】対戦スコア詳細');

      // Case 2: League match with note
      final matches2 = [
        createMockMatch(
          id: 'm2',
          redName: 'チームC:選手',
          whiteName: 'チームD:選手',
          note: '[リーグ戦] 決勝トーナメント',
        ),
      ];
      final result2 = PdfTeamTable.build('リーグA', matches2, ttf, ttfBold);
      final column2 = (result2 as pw.Container).child as pw.Column;
      final header2 = column2.children.first as pw.Container;
      final headerText2 = (header2.child as pw.Text).text.toPlainText();
      expect(headerText2, '【リーグ団体戦】対戦スコア詳細（決勝トーナメント）');
    });

    test('欠員の場合、選手名のセルは空欄で表示されること', () {
      final matches = [
        createMockMatch(id: 'm1', redName: 'チームA:山田太郎', whiteName: 'チームB:(欠員)'),
      ];

      final result = PdfTeamTable.build('団体戦', matches, ttf, ttfBold);
      final column = (result as pw.Container).child as pw.Column;
      final table = column.children[1] as pw.Table;
      final whiteNameRow =
          table.children[3]; // 0:header, 1:red, 2:score, 3:white
      final nameCell = whiteNameRow.children[1];

      // It should be an empty SizedBox
      expect(nameCell, isA<pw.SizedBox>());
    });

    test('同姓の選手がいる場合、名（イニシャル）が表示されること', () {
      final matches = [
        createMockMatch(
          id: 'm1',
          redName: 'チームA:山田 太郎',
          whiteName: 'チームB:佐藤 一',
        ),
        createMockMatch(
          id: 'm2',
          redName: 'チームA:山田 花子',
          whiteName: 'チームB:鈴木 二',
        ),
      ];

      final result = PdfTeamTable.build('団体戦', matches, ttf, ttfBold);
      final column = (result as pw.Container).child as pw.Column;
      final table = column.children[1] as pw.Table;

      // Red team names
      final redNameRow = table.children[1];

      // Check Taro Yamada
      final taroCell = redNameRow.children[1] as pw.Center;
      final taroRow = taroCell.child as pw.Padding;
      final taroInnerRow = taroRow.child as pw.Row;
      final taroLastName = (taroInnerRow.children[0] as pw.Text).text
          .toPlainText();
      final taroInitial =
          (taroInnerRow.children[1] as pw.Padding).child as pw.Text;
      expect(taroLastName, '山\n田');
      expect(taroInitial.text.toPlainText(), '太');

      // Check Hanako Yamada
      final hanakoCell = redNameRow.children[2] as pw.Center;
      final hanakoRow = hanakoCell.child as pw.Padding;
      final hanakoInnerRow = hanakoRow.child as pw.Row;
      final hanakoLastName = (hanakoInnerRow.children[0] as pw.Text).text
          .toPlainText();
      final hanakoInitial =
          (hanakoInnerRow.children[1] as pw.Padding).child as pw.Text;
      expect(hanakoLastName, '山\n田');
      expect(hanakoInitial.text.toPlainText(), '花');

      // White team names (negative case)
      final whiteNameRow = table.children[3];
      final satoCell = whiteNameRow.children[1] as pw.Center;
      expect(
        ((satoCell.child as pw.Padding).child as pw.Row).children.length,
        1,
      );
      final suzukiCell = whiteNameRow.children[2] as pw.Center;
      expect(
        ((suzukiCell.child as pw.Padding).child as pw.Row).children.length,
        1,
      );
    });

    test('多人数戦（5人制・7人制・11人制）におけるテーブル寸法とA4枠内収容が数学的に保証されること', () {
      List<MatchModel> generateMatches(int count) {
        final posList = [
          '先鋒',
          '次鋒',
          '五将',
          '中堅',
          '三将',
          '副将',
          '大将',
          '八将',
          '九将',
          '十将',
          '十一将',
        ];
        return List.generate(count, (i) {
          final pos = i < posList.length ? posList[i] : '選手$i';
          return createMockMatch(
            id: 'm_$i',
            redName: '福山市剣道連盟:山田',
            whiteName: '廿日市剣道連盟:佐藤',
            matchType: pos,
          );
        });
      }

      // 1. 5人制 (isWide == false) -> 通常レイアウト
      final fiveMatches = generateMatches(5);
      final widget5 = PdfTeamTable.build('5人制', fiveMatches, ttf, ttfBold);
      expect(widget5, isA<pw.Container>());

      // 2. 7人制 (isWide == true, 自然幅 72 + 7*36 + 36 = 360pt < 490pt)
      final sevenMatches = generateMatches(7);
      final widget7 = PdfTeamTable.build('7人制', sevenMatches, ttf, ttfBold);
      expect(widget7, isA<pw.Container>());
      final container7 = widget7 as pw.Container;
      final column7 = container7.child as pw.Column;
      final tableBox7 = column7.children[1] as pw.SizedBox;
      // 自然な適正幅でコンパクトに描画されること (無理に490ptまで引き伸ばされない)
      expect(tableBox7.width, lessThan(490.0));
      expect(tableBox7.width, 360.0);

      // 3. 11人制 (isWide == true, 自然幅 72 + 11*36 + 36 = 504pt > 490pt -> スケールダウン)
      final elevenMatches = generateMatches(11);
      final widget11 = PdfTeamTable.build('11人制', elevenMatches, ttf, ttfBold);
      expect(widget11, isA<pw.Container>());
      final container11 = widget11 as pw.Container;
      final column11 = container11.child as pw.Column;
      final tableBox11 = column11.children[1] as pw.SizedBox;
      // A4最大幅 (490.0pt) を超えずに完全収容されること
      expect(tableBox11.width, closeTo(490.0, 0.01));
    });
  });
}
