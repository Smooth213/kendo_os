import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/widgets/pdf_team_table_cell_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] PdfTeamTableCellRenderer テスト', () {
    final ttf = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();

    test('チームセルにチーム名が正しく描画されること', () {
      final widget = PdfTeamTableCellRenderer.buildTeamCell(
        '東京道場',
        PdfColors.red900,
        ttfBold,
      );
      expect(widget, isNotNull);
      expect(widget, isA<pw.Widget>());
    });

    test('buildTeamResultCellにおいて draw and win casesが適切に処理されること', () {
      final drawWidget = PdfTeamTableCellRenderer.buildTeamResultCell(
        'draw',
        ttfBold,
      );
      expect(drawWidget, isNotNull);

      final winWidget = PdfTeamTableCellRenderer.buildTeamResultCell(
        'red',
        ttfBold,
      );
      expect(winWidget, isNotNull);
    });

    test('buildNameCellにおいて single and duplicated last namesが適切に処理されること', () {
      final nameWidget = PdfTeamTableCellRenderer.buildNameCell('東京道場 : 佐藤 健', [
        '佐藤',
        '武田',
      ], ttf);
      expect(nameWidget, isNotNull);
    });

    test('延長していない代表戦には延長表記を表示しないこと', () {
      const match = MatchModel(
        id: 'representative-match',
        matchType: '代表戦',
        redName: '赤チーム : 山田',
        whiteName: '白チーム : 鈴木',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
      );

      final widget =
          PdfTeamTableCellRenderer.buildScoreCell(match, ttfBold)
              as pw.Container;
      final stack = widget.child as pw.Stack;

      expect(stack.children, hasLength(2));
    });

    test('延長記録がある代表戦には延長表記を表示すること', () {
      const match = MatchModel(
        id: 'representative-match',
        matchType: '代表戦',
        redName: '赤チーム : 山田',
        whiteName: '白チーム : 鈴木',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        note: '延長戦',
      );

      final widget =
          PdfTeamTableCellRenderer.buildScoreCell(match, ttfBold)
              as pw.Container;
      final stack = widget.child as pw.Stack;

      expect(stack.children, hasLength(3));
      final extensionLabel = stack.children[1] as pw.Container;
      final labelColumn = extensionLabel.child as pw.Column;
      expect((labelColumn.children.first as pw.Text).text.toPlainText(), '延');
    });
  });
}
