import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/viewer_team_scoreboard_score_box.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 観客用団体戦スコアボックス視覚整合性テスト', () {
    testWidgets('赤側二本勝ちおよび反則表示がダークテーマにおいて正確な記号と枠線で描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Center(
              child: ViewerTeamScoreboardScoreBox.build(
                pts: ['メ', 'コ', '△'],
                isWinner: true,
                isDraw: false,
                isRed: true,
                isDark: true,
                firstSide: 'red',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('メ'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);
      expect(find.text('△'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('不戦勝時の二重丸記号および引き分け表示がライトテーマにおいて明瞭に描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 不戦勝（◯◯）
                  ViewerTeamScoreboardScoreBox.build(
                    pts: ['◯'],
                    isWinner: true,
                    isDraw: false,
                    isRed: false,
                    isDark: false,
                  ),
                  const SizedBox(width: 24),
                  // 引き分け（Red側で引分文字表示）
                  ViewerTeamScoreboardScoreBox.build(
                    pts: [],
                    isWinner: false,
                    isDraw: true,
                    isRed: true,
                    isDark: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('◯'), findsNWidgets(2));
      expect(find.text('✕'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
