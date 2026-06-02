import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/services/pdf/widgets/pdf_individual_list.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
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

  group('PdfIndividualList Widget Tests', () {
    test('引き分けの試合で正しい引き分け記号「×」が表示されるべき', () {
      final matches = [
        createMockMatch(
          id: 'm1',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 0,
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      final result = PdfIndividualList.build('個人戦', matches, ttf, ttfBold);
      final container = result as pw.Container;
      final column = container.child as pw.Column;
      final rowContainer = column.children[1] as pw.Container;
      final row = rowContainer.child as pw.Row;

      // Find the draw symbol widget
      final drawSymbolWidget = row.children[4];
      expect(drawSymbolWidget, isA<pw.Padding>());
      final drawSymbolText = (drawSymbolWidget as pw.Padding).child as pw.Text;

      // U+00D7 is the multiplication sign '×'
      expect(drawSymbolText.text.toPlainText(), '×');
    });

    test('ヘッダータイトルが正しく生成されるべき', () {
      // Case 1: Normal individual match
      final matches1 = [
        createMockMatch(id: 'm1', redName: '選手A', whiteName: '選手B'),
      ];
      final result1 =
          PdfIndividualList.build('個人戦グループA', matches1, ttf, ttfBold)
              as pw.Container;
      final header1 =
          (result1.child as pw.Column).children.first as pw.Container;
      final headerText1 = (header1.child as pw.Text).text.toPlainText();
      expect(headerText1, '【個人戦】 個人戦グループA');

      // Case 2: League match with note
      final matches2 = [
        createMockMatch(
          id: 'm2',
          redName: '選手C',
          whiteName: '選手D',
          note: '[リーグ戦] 予選',
        ),
      ];
      final result2 =
          PdfIndividualList.build('リーグA', matches2, ttf, ttfBold)
              as pw.Container;
      final header2 =
          (result2.child as pw.Column).children.first as pw.Container;
      final headerText2 = (header2.child as pw.Text).text.toPlainText();
      expect(headerText2, '【リーグ個人戦】 リーグA');
    });
  });
}
