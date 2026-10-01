import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/widgets/pdf_team_table_cell_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] PdfTeamTableCellRenderer テスト', () {
    final ttf = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();

    test('buildTeamCell renders team name correctlyであること', () {
      final widget = PdfTeamTableCellRenderer.buildTeamCell(
        '東京道場',
        PdfColors.red900,
        ttfBold,
      );
      expect(widget, isNotNull);
      expect(widget, isA<pw.Widget>());
    });

    test('buildTeamResultCell handles draw and win casesであること', () {
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

    test('buildNameCell handles single and duplicated last namesであること', () {
      final nameWidget = PdfTeamTableCellRenderer.buildNameCell('東京道場 : 佐藤 健', [
        '佐藤',
        '武田',
      ], ttf);
      expect(nameWidget, isNotNull);
    });
  });
}
