import 'dart:math' as math;
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
  group('🥋 反則マーク「△」の配置位置・大丸除外保証テスト', () {
    group('1. 試合結果一覧・公式記録 (KendoScoreBox / ScoreTableCell)', () {
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

        // △のフォントサイズが小さく（9pt）設定されていることを確認
        final Text triangleText = tester.widget(find.text('△'));
        expect(triangleText.style?.fontSize, 9);

        // △の配置が左下（bottom: 0, left: 1）であることを確認
        final Positioned trianglePos = tester.widget(
          find.ancestor(of: find.text('△'), matching: find.byType(Positioned)),
        );
        expect(trianglePos.bottom, 0);
        expect(trianglePos.left, 1);

        // 幾何学的検証: KendoScoreBox(36x36)の大丸(直径32, 半径16, 中心(18, 18))
        // △の座標: left=1, bottom=0 (y = 36 - 0 = 36) -> (1, 36)
        const circleCenterX = 18.0;
        const circleCenterY = 18.0;
        const circleRadius = 16.0;
        const triangleX = 1.0;
        const triangleY = 36.0;

        final distToCenter = math.sqrt(
          math.pow(triangleX - circleCenterX, 2) +
              math.pow(triangleY - circleCenterY, 2),
        );
        // 距離 24.76 > 半径 16.0 なので確実に大丸の外側
        expect(distToCenter, greaterThan(circleRadius));

        // 技マーク「メ」が大丸の内部（左上: top: 4, left: 6）に配置されていること
        final Positioned menPos = tester.widget(
          find.ancestor(of: find.text('メ'), matching: find.byType(Positioned)),
        );
        expect(menPos.top, isNotNull);
        expect(menPos.left, 6);
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

        // ド（1本目）は左上
        final Positioned doPos = tester.widget(
          find.ancestor(of: find.text('ド'), matching: find.byType(Positioned)),
        );
        expect(doPos.top, isNotNull);
        expect(doPos.left, 6);

        // メ（2本目）は右下
        final Positioned menPos = tester.widget(
          find.ancestor(of: find.text('メ'), matching: find.byType(Positioned)),
        );
        expect(menPos.bottom, isNotNull);
        expect(menPos.right, 6);

        // △は左下に配置され、2本のスロットを奪っていないこと
        final Positioned trianglePos = tester.widget(
          find.ancestor(of: find.text('△'), matching: find.byType(Positioned)),
        );
        expect(trianglePos.bottom, 0);
        expect(trianglePos.left, 1);
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
        expect(trianglePos.bottom, 0);
        expect(trianglePos.left, 1);
      });
    });

    group('2. 団体戦スコアボード（運営画面）', () {
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

          // △のフォントサイズが小さく（11pt）設定されていること
          final Text triangleText = tester.widget(find.text('△'));
          expect(triangleText.style?.fontSize, 11);

          // △の配置が左下（bottom: 8, left: 2）であること
          final Positioned trianglePos = tester.widget(
            find.ancestor(
              of: find.text('△'),
              matching: find.byType(Positioned),
            ),
          );
          expect(trianglePos.bottom, 8);
          expect(trianglePos.left, 2);

          // 幾何学的検証: ボックスサイズ(64x84), 大丸(直径62, 半径31, 中心(32, 42))
          // △の座標: left=2, bottom=8 (y = 84 - 8 = 76) -> (2, 76)
          const circleCenterX = 32.0;
          const circleCenterY = 42.0;
          const circleRadius = 31.0;
          const triangleX = 2.0;
          const triangleY = 76.0;

          final distToCenter = math.sqrt(
            math.pow(triangleX - circleCenterX, 2) +
                math.pow(triangleY - circleCenterY, 2),
          );
          // 距離 45.34 > 半径 31.0 なので確実に大丸の外側
          expect(distToCenter, greaterThan(circleRadius));

          // メは大丸内の打突スロット（top: 2, left: 2）に配置されていること
          final Positioned menPos = tester.widget(
            find.ancestor(
              of: find.text('メ'),
              matching: find.byType(Positioned),
            ),
          );
          expect(menPos.top, 2);
          expect(menPos.left, 2);
        },
      );
    });

    group('3. 団体戦スコアボード（観戦画面）', () {
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

          // △のフォントサイズが小さく（11pt）設定されていること
          final Text triangleText = tester.widget(find.text('△'));
          expect(triangleText.style?.fontSize, 11);

          // △の配置が左下（bottom: 8, left: 2）であること
          final Positioned trianglePos = tester.widget(
            find.ancestor(
              of: find.text('△'),
              matching: find.byType(Positioned),
            ),
          );
          expect(trianglePos.bottom, 8);
          expect(trianglePos.left, 2);

          // コ（1本目）は大丸内の打突スロット（top: 2, left: 2）に配置されていること
          final Positioned kotePos = tester.widget(
            find.ancestor(
              of: find.text('コ'),
              matching: find.byType(Positioned),
            ),
          );
          expect(kotePos.top, 2);
          expect(kotePos.left, 2);
        },
      );
    });

    group('4. PDF出力（団体戦・個人戦共通セル）', () {
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
        expect(menPos.top, 3.5);
        expect(menPos.left, 4.5);

        // [2] 反則△のPositionedの確認（左下: bottom: 0.5, left: 0.5）
        final trianglePos = stack.children[2] as pw.Positioned;
        expect(trianglePos.bottom, 0.5);
        expect(trianglePos.left, 0.5);
        expect(trianglePos.child, isA<pw.Text>());
        final triangleText = trianglePos.child as pw.Text;
        expect(triangleText.text.toPlainText(), '△');
        expect(triangleText.text.style?.fontSize, 5.5);

        // 幾何学的検証: PDFボックス(28x26), 大丸(直径25, 半径12.5, 中心(14, 13))
        // △の座標: left=0.5, bottom=0.5 (y = 26 - 0.5 = 25.5) -> (0.5, 25.5)
        const circleCenterX = 14.0;
        const circleCenterY = 13.0;
        const circleRadius = 12.5;
        const triangleX = 0.5;
        const triangleY = 25.5;

        final distToCenter = math.sqrt(
          math.pow(triangleX - circleCenterX, 2) +
              math.pow(triangleY - circleCenterY, 2),
        );
        // 距離 18.39 > 半径 12.5 なので確実に大丸の外側
        expect(distToCenter, greaterThan(circleRadius));
      });
    });
  });
}
