import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/components/score_table_cell.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

void main() {
  group('🛡️ ScoreTableCell Widget Tests', () {
    testWidgets('Renders PointBoxes for red and white with points', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: const Scaffold(
            body: ScoreTableCell(
              isFinished: true,
              redScore: 2,
              whiteScore: 0,
              redPoints: [
                PointMark(mark: 'メ'),
                PointMark(mark: 'コ'),
              ],
              whitePoints: [],
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.byType(ScoreTableCell), findsOneWidget);
      expect(find.byType(PointBox), findsNWidgets(2));
    });

    testWidgets('Renders draw mark ✕ when match finished with equal score', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: const Scaffold(
            body: ScoreTableCell(
              isFinished: true,
              redScore: 0,
              whiteScore: 0,
              redPoints: [],
              whitePoints: [],
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('✕'), findsOneWidget);
    });

    testWidgets('Renders encho badges 延 / 長 when isEncho is true', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: const Scaffold(
            body: ScoreTableCell(
              isFinished: false,
              isEncho: true,
              redScore: 0,
              whiteScore: 0,
              redPoints: [],
              whitePoints: [],
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('延'), findsOneWidget);
      expect(find.text('長'), findsOneWidget);
    });
  });
}
