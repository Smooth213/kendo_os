import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:kendo_os/features/match/domain/match_model.dart';
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

    test('7人制以上の多人数戦が単独フル幅（Rowにペア化されない）で配置されること', () {
      final ttf = pw.Font.helvetica();
      final ttfBold = pw.Font.helveticaBold();

      // 7人制の試合モック
      final positions = ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
      final sevenPlayerMatches = positions
          .map(
            (pos) => MatchModel(
              id: 'match-$pos',
              tournamentId: 't1',
              category: '中学生の部',
              groupName: '第1回戦',
              matchType: pos,
              redName: '福山市剣道連盟:山田',
              whiteName: '廿日市剣道連盟:佐藤',
              redScore: 0,
              whiteScore: 0,
              status: 'finished',
              order: 1.0,
              note: '',
            ),
          )
          .toList();

      final groupDataList = [
        {'groupName': '第1回戦', 'matches': sevenPlayerMatches},
        {'groupName': '第2回戦', 'matches': sevenPlayerMatches},
      ];

      final widgets = PdfPageLayoutHelper.buildContentWidgets(
        groupDataList: groupDataList,
        ttf: ttf,
        ttfBold: ttfBold,
      );

      // 各多人数戦がペア(pw.Row)に統合されず、独立した pw.Container として配置されること
      expect(widgets.length, 4); // table1 + SizedBox + table2 + SizedBox
      expect(widgets[0], isA<pw.Container>());
      expect(widgets[1], isA<pw.SizedBox>());
      expect(widgets[2], isA<pw.Container>());
      expect(widgets[3], isA<pw.SizedBox>());
    });
  });
}
