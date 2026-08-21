import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_tie_break_dialog.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DummyTeam {
  final String name;
  DummyTeam(this.name);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TimelineTieBreakDialog renders properly', (tester) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final prefs = await SharedPreferences.getInstance();

    final firstMatch = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      matchType: '先鋒戦',
      order: 1,
      redName: 'チームA : 選手1',
      whiteName: 'チームB : 選手2',
      status: 'pending',
      note: '',
    );

    final tieTeams = [DummyTeam('チームA'), DummyTeam('チームB')];
    final baseRule = MatchRule();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () {
                    TimelineTieBreakDialog.show(
                      context,
                      ref,
                      firstMatch,
                      tieTeams,
                      baseRule,
                    );
                  },
                  child: const Text('決定戦ダイアログを開く'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('決定戦ダイアログを開く'));
    await tester.pumpAndSettle();

    expect(find.text('決定戦の形式を選択'), findsOneWidget);
    expect(find.text('代表戦（1名）'), findsOneWidget);
    expect(find.text('チーム再試合'), findsOneWidget);
    expect(find.text('何もしない'), findsOneWidget);
  });
}
