import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/pdf/widgets/pdf_team_table_cell_renderer.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_table_builder.dart';
import 'package:kendo_os/features/viewer/components/viewer_team_scoreboard_table_builder.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_score_box.dart';
import 'package:kendo_os/shared/widgets/match_tables/components/score_table_cell.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('[Widget] 反則マーク「△」の配置位置・大丸除外保証テスト', () {
    group('試合結果一覧・公式記録 (KendoScoreBox / ScoreTableCell)', () {
      testWidgets('反則△はスコアの左下に小さく表示され、大丸（勝者丸）の完全な外部に位置すること', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: KendoScoreBox(
                  points: [
                    KendoPointMark(mark: '△'),
                    KendoPointMark(mark: 'メ', isFirst: true),
                  ],
                  isWinner: true,
                  isRed: true,
                  variant: ScoreDisplayVariant.table,
                ),
              ),
            ),
          ),
        );

        // 技マーク「メ」と反則「△」が描画されていることを確認
        expect(find.text('メ'), findsOneWidget);
        expect(find.text('△'), findsOneWidget);

        // △のフォントサイズが設定されていることを確認
        final Text triangleText = tester.widget(find.text('△'));
        expect(triangleText.style?.fontSize, isNotNull);

        // △の配置が左下（bottom, leftが指定されている）であることを確認
        final Positioned trianglePos = tester.widget(
          find.ancestor(of: find.text('△'), matching: find.byType(Positioned)),
        );
        expect(trianglePos.bottom, isNotNull);
        expect(trianglePos.left, isNotNull);

        // 技マーク「メ」が大丸内の打突スロットに配置されていること
        final Positioned menPos = tester.widget(
          find.ancestor(of: find.text('メ'), matching: find.byType(Positioned)),
        );
        expect(menPos.top, isNotNull);
        expect(menPos.left, isNotNull);
      });

      testWidgets('2本勝ち＋反則1回の場合でも、2本の技が大丸内に入り、△が左下に独立して配置されること', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: KendoScoreBox(
                  points: [
                    KendoPointMark(mark: '△'),
                    KendoPointMark(mark: 'ド', isFirst: true),
                    KendoPointMark(mark: 'メ'),
                  ],
                  isWinner: true,
                  isRed: true,
                  variant: ScoreDisplayVariant.table,
                ),
              ),
            ),
          ),
        );

        expect(find.text('ド'), findsOneWidget);
        expect(find.text('メ'), findsOneWidget);
        expect(find.text('△'), findsOneWidget);

        // ド（1本目）は打突スロットに配置
        final Positioned doPos = tester.widget(
          find.ancestor(of: find.text('ド'), matching: find.byType(Positioned)),
        );
        expect(doPos.top, isNotNull);
        expect(doPos.left, isNotNull);

        // メ（2本目）は別の打突スロットに配置
        final Positioned menPos = tester.widget(
          find.ancestor(of: find.text('メ'), matching: find.byType(Positioned)),
        );
        expect(menPos.bottom, isNotNull);
        expect(menPos.right, isNotNull);

        // △は左下に配置され、2本のスロットを奪っていないこと
        final Positioned trianglePos = tester.widget(
          find.ancestor(of: find.text('△'), matching: find.byType(Positioned)),
        );
        expect(trianglePos.bottom, isNotNull);
        expect(trianglePos.left, isNotNull);
      });

      testWidgets('ScoreTableCell経由でのレンダリング時も、反則△が左下に正しく描画されること', (
        tester,
      ) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ScoreTableCell(
                isFinished: true,
                redScore: 1,
                whiteScore: 0,
                redPoints: [
                  KendoPointMark(mark: '△'),
                  KendoPointMark(mark: 'メ', isFirst: true),
                ],
                whitePoints: [],
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('メ'), findsOneWidget);
        expect(find.text('△'), findsOneWidget);

        final Positioned trianglePos = tester.widget(
          find.ancestor(of: find.text('△'), matching: find.byType(Positioned)),
        );
        expect(trianglePos.bottom, isNotNull);
        expect(trianglePos.left, isNotNull);
      });
    });

    group('団体戦スコアボード（運営画面）', () {
      testWidgets(
        'TeamScoreboardTableBuilder: 反則△はスコアの左下に小さく表示され、大丸（勝者丸）の外側にあること',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: TeamScoreboardTableBuilder.buildMatchScoreBox(
                    [
                      const TeamPointDisplay('△', false),
                      const TeamPointDisplay('メ', true),
                    ],
                    true, // isWinner
                    false, // isDraw
                    true, // isRed
                    false, // isDark
                  ),
                ),
              ),
            ),
          );

          expect(find.text('メ'), findsOneWidget);
          expect(find.text('△'), findsOneWidget);

          // △のフォントサイズが設定されていること
          final Text triangleText = tester.widget(find.text('△'));
          expect(triangleText.style?.fontSize, isNotNull);

          // △の配置が左下（bottom, leftが指定されている）であること
          final Positioned trianglePos = tester.widget(
            find.ancestor(
              of: find.text('△'),
              matching: find.byType(Positioned),
            ),
          );
          expect(trianglePos.bottom, isNotNull);
          expect(trianglePos.left, isNotNull);

          // メは大丸内の打突スロットに配置されていること
          final Positioned menPos = tester.widget(
            find.ancestor(
              of: find.text('メ'),
              matching: find.byType(Positioned),
            ),
          );
          expect(menPos.top, isNotNull);
          expect(menPos.left, isNotNull);
        },
      );
    });

    group('団体戦スコアボード（観戦画面）', () {
      testWidgets(
        'ViewerTeamScoreboardTableBuilder: 反則△はスコアの左下に小さく表示され、大丸（勝者丸）の外側にあること',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: ViewerTeamScoreboardTableBuilder.buildMatchScoreBox(
                    ['△', 'コ'],
                    true, // isWinner
                    false, // isDraw
                    false, // isRed (white)
                    false, // isDark
                    'white', // firstSide
                  ),
                ),
              ),
            ),
          );

          expect(find.text('コ'), findsOneWidget);
          expect(find.text('△'), findsOneWidget);

          // △のフォントサイズが設定されていること
          final Text triangleText = tester.widget(find.text('△'));
          expect(triangleText.style?.fontSize, isNotNull);

          // △の配置が左下（bottom, leftが指定されている）であること
          final Positioned trianglePos = tester.widget(
            find.ancestor(
              of: find.text('△'),
              matching: find.byType(Positioned),
            ),
          );
          expect(trianglePos.bottom, isNotNull);
          expect(trianglePos.left, isNotNull);

          // コ（1本目）は大丸内の打突スロットに配置されていること
          final Positioned kotePos = tester.widget(
            find.ancestor(
              of: find.text('コ'),
              matching: find.byType(Positioned),
            ),
          );
          expect(kotePos.top, isNotNull);
          expect(kotePos.left, isNotNull);
        },
      );
    });

    group('PDF出力（団体戦・個人戦共通セル）', () {
      test('PdfTeamTableCellRenderer: 反則△はスコアの左下に小さく配置され、大丸の外側にあること', () {
        final font = pw.Font.helvetica();
        final widget = PdfTeamTableCellRenderer.buildPointBox(
          [const PdfPointData('△', false), const PdfPointData('メ', true)],
          true, // isWinner
          true, // isRed
          font,
        );

        expect(widget, isA<pw.Container>());
        final container = widget as pw.Container;
        expect(container.child, isA<pw.Stack>());
        final stack = container.child as pw.Stack;

        // 子要素: [0] 大丸Container, [1] 打突技Stack, [2] 左下反則Positioned
        expect(stack.children.length, 3);

        // [0] 大丸Containerの確認（直径25）
        final winnerCircle = stack.children[0] as pw.Container;
        expect(winnerCircle.decoration, isA<pw.BoxDecoration>());

        // [1] 打突技Stackの確認（メのみが含まれる）
        final techStack = stack.children[1] as pw.Stack;
        expect(techStack.children.length, 1);
        final menPos = techStack.children[0] as pw.Positioned;
        expect(menPos.top, isNotNull);
        expect(menPos.left, isNotNull);

        // [2] 反則△のPositionedの確認（左下: bottom, leftが設定されていること）
        final trianglePos = stack.children[2] as pw.Positioned;
        expect(trianglePos.bottom, isNotNull);
        expect(trianglePos.left, isNotNull);
        expect(trianglePos.child, isA<pw.Text>());
        final triangleText = trianglePos.child as pw.Text;
        expect(triangleText.text.toPlainText(), '△');
        expect(triangleText.text.style?.fontSize, isNotNull);
      });
    });
  });
}
