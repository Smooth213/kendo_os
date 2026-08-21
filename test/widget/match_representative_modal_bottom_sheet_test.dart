import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_representative_modal_bottom_sheet.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MatchRepresentativeModalBottomSheet renders properly', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

    final match = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      matchType: '代表戦',
      order: 1,
      redName: 'チームA : 代表',
      whiteName: 'チームB : 代表',
      status: 'pending',
      note: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: MatchRepresentativeModalBottomSheet(
              match: match,
              rTeam: 'チームA',
              wTeam: 'チームB',
              redPlayers: const ['選手1', '選手2'],
              whitePlayers: const ['選手3', '選手4'],
            ),
          ),
        ),
      ),
    );

    expect(find.text('代表戦の準備'), findsOneWidget);
    expect(find.text('チームA の代表者'), findsOneWidget);
    expect(find.text('チームB の代表者'), findsOneWidget);
    expect(find.text('決定して準備完了'), findsOneWidget);
  });
}
