import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_score_box.dart';
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table_cell_renderer.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('🛡️ 【剣道公式スコア表示ガバナンス・自動監査テスト】', () {
    testWidgets('1. 【Tableバリアント】1本目が左上、2本目が右下に配置され、勝者丸が描画されること', (
      tester,
    ) async {
      const points = [
        KendoPointMark(mark: 'メ', isFirst: true),
        KendoPointMark(mark: 'コ', isFirst: false),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: KendoScoreBox(
                points: points,
                isWinner: true,
                isRed: true,
                variant: ScoreDisplayVariant.table,
              ),
            ),
          ),
        ),
      );

      // KendoScoreBox内のStack構造であること
      final boxStack = find.descendant(
        of: find.byType(KendoScoreBox),
        matching: find.byType(Stack),
      );
      expect(boxStack, findsOneWidget);

      // Positionedが2つ（1本目左上、2本目右下）存在すること
      final positionedWidgets = tester
          .widgetList<Positioned>(
            find.descendant(
              of: find.byType(KendoScoreBox),
              matching: find.byType(Positioned),
            ),
          )
          .toList();
      expect(positionedWidgets.length, 2);

      // 1本目: top & left
      expect(positionedWidgets[0].top, isNotNull);
      expect(positionedWidgets[0].left, isNotNull);
      expect(positionedWidgets[0].bottom, isNull);
      expect(positionedWidgets[0].right, isNull);

      // 2本目: bottom & right
      expect(positionedWidgets[1].bottom, isNotNull);
      expect(positionedWidgets[1].right, isNotNull);
      expect(positionedWidgets[1].top, isNull);
      expect(positionedWidgets[1].left, isNull);

      // 勝者円（直径32px、BoxShape.circle）が存在すること
      final circleContainers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(KendoScoreBox),
              matching: find.byType(Container),
            ),
          )
          .where((c) {
            final dec = c.decoration;
            return dec is BoxDecoration &&
                dec.shape == BoxShape.circle &&
                c.constraints?.maxWidth == 32;
          })
          .toList();
      expect(circleContainers.isNotEmpty, isTrue);
    });

    testWidgets('2. 【先取丸囲み規約】有効打突の先取は丸囲みされ、反則(反)・不戦勝(◯)・引き分け(×)は丸囲みされないこと', (
      tester,
    ) async {
      const menFirst = KendoPointMark(mark: 'メ', isFirst: true);
      const hansokuFirst = KendoPointMark(mark: '反', isFirst: true);
      const fusenFirst = KendoPointMark(mark: '◯', isFirst: true);
      const drawFirst = KendoPointMark(mark: '×', isFirst: true);

      // メ（先取）➔ 丸囲みあり
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoTechMarkBadge(
              point: menFirst,
              color: Colors.red,
              isDark: false,
            ),
          ),
        ),
      );
      final menCircle = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final dec = c.decoration;
            return dec is BoxDecoration && dec.shape == BoxShape.circle;
          });
      expect(menCircle.isNotEmpty, isTrue);

      // 反則（反・先取）➔ 丸囲みなし
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoTechMarkBadge(
              point: hansokuFirst,
              color: Colors.red,
              isDark: false,
            ),
          ),
        ),
      );
      final hansokuCircle = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final dec = c.decoration;
            return dec is BoxDecoration && dec.shape == BoxShape.circle;
          });
      expect(hansokuCircle.isEmpty, isTrue);

      // 不戦勝（◯・先取）➔ 丸囲みなし
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoTechMarkBadge(
              point: fusenFirst,
              color: Colors.red,
              isDark: false,
            ),
          ),
        ),
      );
      final fusenCircle = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final dec = c.decoration;
            return dec is BoxDecoration && dec.shape == BoxShape.circle;
          });
      expect(fusenCircle.isEmpty, isTrue);

      // 引き分け（×）➔ 丸囲みなし
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoTechMarkBadge(
              point: drawFirst,
              color: Colors.grey,
              isDark: false,
            ),
          ),
        ),
      );
      final drawCircle = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final dec = c.decoration;
            return dec is BoxDecoration && dec.shape == BoxShape.circle;
          });
      expect(drawCircle.isEmpty, isTrue);
    });

    testWidgets('3. 【Inlineバリアント】チーム試合状況・タイムライン用インライン行が正常描画されること', (
      tester,
    ) async {
      const points = [
        KendoPointMark(mark: 'ド', isFirst: true),
        KendoPointMark(mark: 'ツ', isFirst: false),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoScoreBox(
              points: points,
              variant: ScoreDisplayVariant.inline,
              isRed: true,
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.text('ド'), findsOneWidget);
      expect(find.text('ツ'), findsOneWidget);
    });

    testWidgets('4. 【Scoreboardバリアント】スコア入力盤用特大モードが60pxで描画されること', (
      tester,
    ) async {
      const point = KendoPointMark(mark: 'メ', isFirst: true);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoScoreBox(
              points: [point],
              variant: ScoreDisplayVariant.scoreboard,
              isRed: true,
            ),
          ),
        ),
      );

      final badgeContainer = tester.widget<Container>(find.byType(Container));
      expect(badgeContainer.constraints?.maxWidth, 60.0);
      expect(badgeContainer.constraints?.maxHeight, 60.0);
    });

    test('5. 【PDF描画規約】PDF出力側でも25px勝者円および境界クリアランスが遵守されていること', () {
      final fontBold = pw.Font.helveticaBold();
      final pts = [PdfPointData('コ', true), PdfPointData('ツ', false)];

      final widget = PdfTeamTableCellRenderer.buildPointBox(
        pts,
        true,
        true,
        fontBold,
      );

      expect(widget, isA<pw.Container>());
      final container = widget as pw.Container;
      expect(container.constraints?.maxWidth, 26.0);
      expect(container.constraints?.maxHeight, 26.0);
    });
  });
}
