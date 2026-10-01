import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:kendo_os/features/pdf/helpers/pdf_page_layout_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] PdfPageLayoutHelper テスト', () {
    test('buildHeaderが正しいメタデータを含むヘッダーを生成すること', () {
      final headerWidget = PdfPageLayoutHelper.buildHeader(
        categoryName: '一般男子',
        tournamentName: '第50回記念大会',
        tournamentDate: '2026/08/21',
        tournamentVenue: '日本武道館',
        outputTime: DateTime(2026, 8, 21, 10, 0),
      );

      expect(headerWidget, isNotNull);
      expect(headerWidget, isA<pw.Widget>());
    });

    test('リストが空のときにフォールバックウィジェットが生成されること', () {
      final ttf = pw.Font.helvetica();
      final ttfBold = pw.Font.helveticaBold();

      final widgets = PdfPageLayoutHelper.buildContentWidgets(
        groupDataList: [],
        ttf: ttf,
        ttfBold: ttfBold,
      );

      expect(widgets.length, 1);
    });
  });
}
