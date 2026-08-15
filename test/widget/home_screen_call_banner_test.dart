import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/home_screen_call_banner.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ HomeScreenCallBanner Widget Tests', () {
    testWidgets(
      'Renders HomeScreenCallBanner with inProgress and next matches',
      (WidgetTester tester) async {
        const match1 = MatchModel(
          id: 'm1',
          tournamentId: 'tour_1',
          matchType: '個人戦',
          redName: 'チームA: 山田',
          whiteName: 'チームB: 佐藤',
          status: 'in_progress',
          note: '第1試合場',
        );

        const match2 = MatchModel(
          id: 'm2',
          tournamentId: 'tour_1',
          matchType: '個人戦',
          redName: 'チームC: 田中',
          whiteName: 'チームD: 高橋',
          status: 'waiting',
        );

        const match3 = MatchModel(
          id: 'm3',
          tournamentId: 'tour_1',
          matchType: '個人戦',
          redName: 'チームE: 渡辺',
          whiteName: 'チームF: 伊藤',
          status: 'waiting',
        );

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: Scaffold(
              body: HomeScreenCallBanner(
                uniqueInProgress: const [match1],
                uniqueWaiting: const [match2, match3],
                themeColors: themeColors,
                isDark: false,
                enableLiquidGlass: false,
              ),
            ),
          ),
        );

        expect(find.text('進行中'), findsOneWidget);
        expect(find.text('第1試合場'), findsOneWidget);
        expect(find.text('次試合'), findsOneWidget);
        expect(find.textContaining('次々試合:'), findsOneWidget);
      },
    );

    testWidgets('Renders nothing when both inProgress and waiting are empty', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: HomeScreenCallBanner(
              uniqueInProgress: const [],
              uniqueWaiting: const [],
              themeColors: themeColors,
              isDark: false,
              enableLiquidGlass: false,
            ),
          ),
        ),
      );

      expect(find.text('進行中'), findsNothing);
      expect(find.text('次試合'), findsNothing);
    });
  });
}
