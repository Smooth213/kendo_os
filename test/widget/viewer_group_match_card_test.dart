import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_card.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ViewerGroupMatchCard renders group title and match list', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

    final match = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      matchType: 'team',
      order: 1,
      redName: 'チームA: 先鋒',
      whiteName: 'チームB: 先鋒',
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
              child: ViewerGroupMatchCard(
                groupKey: 'Aグループ',
                groupList: [match],
                matchLabel: '団体戦',
                ownTeams: const ['チームA'],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('チームA'), findsOneWidget);
    expect(find.text('チームB'), findsOneWidget);
    expect(find.text('進行中'), findsOneWidget);
    expect(find.text('1回戦'), findsOneWidget);
  });
}
