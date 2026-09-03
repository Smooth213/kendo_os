import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

MatchProjection _makeTestProjection({
  required String id,
  required String redName,
  required String whiteName,
  required int redScore,
  required int whiteScore,
  String status = 'finished',
}) {
  return MatchProjection(
    id: id,
    tournamentId: 't1',
    matchOrder: 1,
    matchType: '個人戦',
    status: status,
    groupName: '決勝トーナメント',
    isKachinuki: true,
    redName: redName,
    whiteName: whiteName,
    redScore: redScore,
    whiteScore: whiteScore,
    remainingSeconds: 0,
    timerIsRunning: false,
    note: '',
  );
}

void main() {
  group('📸 【Golden 3/5】勝ち上がりトーナメントツリー 描画＆境界整合性テスト', () {
    testWidgets('1. 8名規模トーナメントツリーの描画整合性（Lightモード）', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final matches = [
        _makeTestProjection(
          id: 'bracket_1',
          redName: '神武館:佐藤',
          whiteName: '修道館:田中',
          redScore: 2,
          whiteScore: 0,
        ),
        _makeTestProjection(
          id: 'bracket_2',
          redName: '勇武館:高橋',
          whiteName: '正気館:伊藤',
          redScore: 1,
          whiteScore: 2,
        ),
        _makeTestProjection(
          id: 'bracket_3',
          redName: '神武館:佐藤',
          whiteName: '正気館:伊藤',
          redScore: 2,
          whiteScore: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1000,
                height: 600,
                child: CustomPaint(
                  painter: KachinukiBracketPainter(
                    matches: matches,
                    isDark: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. 16名規模トーナメントツリーの描画整合性（Darkモード）', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final matches = List.generate(
        7,
        (i) => _makeTestProjection(
          id: 'bracket_16_$i',
          redName: '選手R$i',
          whiteName: '選手W$i',
          redScore: i.isEven ? 2 : 1,
          whiteScore: i.isEven ? 0 : 2,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1200,
                height: 700,
                child: CustomPaint(
                  painter: KachinukiBracketPainter(
                    matches: matches,
                    isDark: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
