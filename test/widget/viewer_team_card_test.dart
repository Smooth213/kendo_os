import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_team_card.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ViewerTeamCard renders team header and children cards', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

    final match = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      matchType: 'team',
      order: 1,
      redName: 'チーム東京: 先鋒',
      whiteName: 'チーム大阪: 先鋒',
      groupName: 'Aグループ',
      status: 'in_progress',
      note: '1回戦',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewerTeamCard(
                teamName: 'チーム東京',
                teamMatchesList: [match],
                ownTeams: const ['チーム東京'],
                sanitizedQuery: '',
                matchedMatchIds: const {},
                matchedGroupNames: const {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('チーム東京'), findsWidgets);
    expect(find.text('進行中'), findsOneWidget);
  });
}
