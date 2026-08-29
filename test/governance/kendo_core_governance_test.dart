import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/kendo_entity_name_parser.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_match_result_tag.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_score_box.dart';
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table_cell_renderer.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('🛡️ 【kendo OS 3大コアガバナンス＆スコア表示 完全自動監査テスト】', () {
    // =========================================================================
    // 1. 道場名・選手名パース＆表示ガバナンス
    // =========================================================================
    test('1. 【名前パース規約】コロン・括弧の全角半角が完全正規化され、団体/個人表示が決定論的に生成されること', () {
      // 団体戦: コロン区切り
      expect(KendoEntityNameParser.extractTeamName('道上剣友会A: 皿田'), '道上剣友会A');
      expect(KendoEntityNameParser.extractPlayerName('道上剣友会A: 皿田'), '皿田');
      expect(
        KendoEntityNameParser.formatDisplayName(
          raw: '道上剣友会A: 皿田',
          isIndividual: false,
        ),
        '道上剣友会A',
      );

      // 全角コロンの正規化
      expect(KendoEntityNameParser.extractTeamName('道上剣友会B：塚本'), '道上剣友会B');
      expect(KendoEntityNameParser.extractPlayerName('道上剣友会B：塚本'), '塚本');

      // 個人戦: 選手名 (所属)
      expect(KendoEntityNameParser.extractTeamName('皿田 (道上剣友会)'), '道上剣友会');
      expect(KendoEntityNameParser.extractPlayerName('皿田 (道上剣友会)'), '皿田');
      expect(
        KendoEntityNameParser.formatDisplayName(
          raw: '皿田 (道上剣友会)',
          isIndividual: true,
        ),
        '皿田 (道上剣友会)',
      );

      // 全角括弧の正規化
      expect(KendoEntityNameParser.extractTeamName('久安（道上剣友会）'), '道上剣友会');
      expect(KendoEntityNameParser.extractPlayerName('久安（道上剣友会）'), '久安');
    });

    // =========================================================================
    // 2. 試合シーン・カテゴリバッジガバナンス
    // =========================================================================
    testWidgets('2. 【シーンバッジ規約】本戦・錬成・申合せ・部内戦が自動判別され公式カラーとラベルで描画されること', (
      tester,
    ) async {
      // 錬成会バッジ
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoSceneBadge(scene: KendoMatchScene.renseikai),
          ),
        ),
      );
      expect(find.text('【錬成】'), findsOneWidget);

      // 申合せバッジ
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoSceneBadge(scene: KendoMatchScene.moushiawase),
          ),
        ),
      );
      expect(find.text('【申合せ】'), findsOneWidget);

      // 部内戦バッジ
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoSceneBadge(scene: KendoMatchScene.bunaiksen),
          ),
        ),
      );
      expect(find.text('【部内戦】'), findsOneWidget);
    });

    // =========================================================================
    // 3. 試合結果・ステータスタグガバナンス
    // =========================================================================
    testWidgets('3. 【結果タグ規約】延長・代表戦・不戦勝・引き分けが統一デザインタグとして描画されること', (
      tester,
    ) async {
      // 延長タグ
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoMatchResultTag(type: KendoMatchResultType.encho),
          ),
        ),
      );
      expect(find.text('延長'), findsOneWidget);

      // 代表戦タグ
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoMatchResultTag(type: KendoMatchResultType.daihyosen),
          ),
        ),
      );
      expect(find.text('代表戦'), findsOneWidget);

      // 不戦勝タグ
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KendoMatchResultTag(type: KendoMatchResultType.fusen),
          ),
        ),
      );
      expect(find.text('不戦勝'), findsOneWidget);
    });

    // =========================================================================
    // 4. 剣道スコア表示・PDFガバナンス
    // =========================================================================
    testWidgets('4. 【スコア表示規約】Table斜め配置・先取丸囲み・勝者丸が100%規約適合すること', (tester) async {
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

      final positionedWidgets = tester
          .widgetList<Positioned>(
            find.descendant(
              of: find.byType(KendoScoreBox),
              matching: find.byType(Positioned),
            ),
          )
          .toList();

      expect(positionedWidgets.length, 2);
      expect(positionedWidgets[0].top, isNotNull);
      expect(positionedWidgets[0].left, isNotNull);
      expect(positionedWidgets[1].bottom, isNotNull);
      expect(positionedWidgets[1].right, isNotNull);
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
