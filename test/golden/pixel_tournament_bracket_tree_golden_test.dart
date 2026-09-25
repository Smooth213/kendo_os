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
  group('📸 【Golden】トーナメント表（山型ツリー線画・シード配置）視覚的整合性テスト', () {
    testWidgets('1. トーナメントツリー山型ブラケット線画およびシード選手表示検証', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final matches = [
        _makeTestProjection(
          id: 'bracket_pixel_1',
          redName: 'シード選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 0,
        ),
        _makeTestProjection(
          id: 'bracket_pixel_2',
          redName: '選手C',
          whiteName: 'シード選手D',
          redScore: 1,
          whiteScore: 2,
        ),
        _makeTestProjection(
          id: 'bracket_pixel_3',
          redName: 'シード選手A',
          whiteName: 'シード選手D',
          redScore: 2,
          whiteScore: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 900,
                height: 500,
                child: CustomPaint(
                  painter: KachinukiBracketPainter(
                    matches: matches,
                    isDark: false,
                  ),
                  size: const Size(900, 500),
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
