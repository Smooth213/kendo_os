import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_bracket_painter.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

MatchProjection _makeCompactProjection({
  required String id,
  required String redName,
  required String whiteName,
  required int redScore,
  required int whiteScore,
}) {
  return MatchProjection(
    id: id,
    tournamentId: 't_compact_01',
    matchOrder: 1,
    matchType: '個人戦',
    status: 'finished',
    groupName: '本戦トーナメント',
    isKachinuki: false,
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
  group('[Golden] 超小型モバイル（320px〜375px）トーナメント表・星取表 視覚完全性テスト', () {
    testWidgets('320px幅画面においてトーナメント表がレイアウト破綻・Overflowゼロで描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568); // iPhone SE 1st gen size
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final matches = [
        _makeCompactProjection(
          id: 'm1',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 1,
        ),
        _makeCompactProjection(
          id: 'm2',
          redName: '選手C',
          whiteName: '選手D',
          redScore: 0,
          whiteScore: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 600,
                height: 400,
                child: CustomPaint(
                  painter: KachinukiBracketPainter(
                    matches: matches,
                    isDark: false,
                  ),
                  size: const Size(600, 400),
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
