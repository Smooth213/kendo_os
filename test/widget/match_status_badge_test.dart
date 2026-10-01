import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] MatchStatusBadge ウィジェットテスト', () {
    testWidgets('【isPlaying is true】試合中 (LIVE)が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: MatchStatusBadge(
              isPlaying: true,
              isFinished: false,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('試合中 (LIVE)'), findsOneWidget);
    });

    testWidgets('【isFinished is true】終了が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: MatchStatusBadge(
              isPlaying: false,
              isFinished: true,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('終了'), findsOneWidget);
    });

    testWidgets('【試合 is pending】待機中が正しく描画されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: MatchStatusBadge(
              isPlaying: false,
              isFinished: false,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('⏳ 待機中'), findsOneWidget);
    });

    testWidgets('【provided】customFinishedText ( 全試合終了)が正しく描画されること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: MatchStatusBadge(
              isPlaying: false,
              isFinished: true,
              isDark: false,
              customFinishedText: '🏁 全試合終了',
            ),
          ),
        ),
      );

      expect(find.text('🏁 全試合終了'), findsOneWidget);
    });
  });
}
