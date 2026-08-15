import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ MatchStatusBadge Widget Tests', () {
    testWidgets('Renders 進行中 when isPlaying is true', (
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

      expect(find.text('進行中'), findsOneWidget);
    });

    testWidgets('Renders 終了 when isFinished is true', (
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

    testWidgets('Renders 待機中 when match is pending', (
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
              isFinished: false,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('待機中'), findsOneWidget);
    });
  });
}
