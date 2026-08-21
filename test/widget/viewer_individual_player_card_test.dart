import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_individual_player_card.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ViewerIndividualPlayerCard renders player name and matches', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

    final match = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      matchType: 'individual',
      order: 1,
      redName: '選手A',
      whiteName: '選手B',
      status: 'in_progress',
      note: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: ViewerIndividualPlayerCard(
              playerName: '選手A',
              playerMatches: [match],
              matchLabel: '個人戦',
            ),
          ),
        ),
      ),
    );

    expect(find.text('選手A'), findsOneWidget);
    expect(find.text('個人戦 • 1試合'), findsOneWidget);
    expect(find.text('進行中'), findsOneWidget);
  });
}
