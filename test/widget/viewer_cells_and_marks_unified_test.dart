import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/viewer_point_box_cell.dart';
import 'package:kendo_os/features/viewer/components/viewer_vertical_player_name_cell.dart';

void main() {
  group('[Widget] 観戦スコアポイントセル ＆ 縦書き選手名セル 統合検証テスト', () {
    testWidgets('公式技マークバッジおよび1本目丸囲み判定が正しく描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OfficialTechMarkBadge(
                  point: OfficialPointDisplay('メ', true),
                  color: Colors.red,
                ),
                OfficialTechMarkBadge(
                  point: OfficialPointDisplay('コ', false),
                  color: Colors.blue,
                ),
                OfficialTechMarkBadge(
                  point: OfficialPointDisplay('判定', false),
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('メ'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);
      expect(find.text('判'), findsOneWidget);
    });

    testWidgets('ポイントボックスセルにおいて勝者強調および2本取得が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ViewerPointBoxCell(
              pts: [
                OfficialPointDisplay('メ', false),
                OfficialPointDisplay('ド', false),
              ],
              isWinner: true,
              isRed: true,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('メ'), findsOneWidget);
      expect(find.text('ド'), findsOneWidget);
      expect(find.byType(ViewerPointBoxCell), findsOneWidget);
    });

    testWidgets('縦書き選手名セルにおいて通常姓名および英字頭文字・括弧が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ViewerVerticalPlayerNameCell(text: '山田', isDark: false),
                ViewerVerticalPlayerNameCell(
                  text: 'リーダー(A)',
                  initial: 'Y',
                  isDark: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('山'), findsOneWidget);
      expect(find.text('田'), findsOneWidget);
      expect(find.byType(RotatedBox), findsWidgets);
      expect(find.text('Y'), findsOneWidget);
    });
  });
}
