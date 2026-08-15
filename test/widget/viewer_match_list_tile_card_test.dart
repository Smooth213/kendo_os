import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ ViewerMatchListTileCard Widget Tests', () {
    testWidgets('Renders ViewerMatchListTileCard with team and player names', (
      WidgetTester tester,
    ) async {
      const sampleMatch = MatchModel(
        id: 'test_viewer_match_1',
        tournamentId: 'tour_1',
        matchType: '個人戦',
        redName: 'チームA: 山田',
        whiteName: 'チームB: 佐藤',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        order: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => [sampleMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: ViewerMatchListTileCard(initialMatch: sampleMatch),
            ),
          ),
        ),
      );

      expect(find.text('チームA'), findsOneWidget);
      expect(find.text('チームB'), findsOneWidget);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('終了'), findsOneWidget);
    });
  });
}
