import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_timer_section.dart';

void main() {
  group('MatchScreen Extracted Components Tests', () {
    testWidgets('renders MatchTimerSection correctly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        redName: 'Red',
        whiteName: 'White',
        matchType: '個人戦',
      );
      final rule = MatchRule(matchTimeMinutes: 3.0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            matchStreamProvider.overrideWith((ref) => Stream.value([match])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MatchTimerSection(
                match: match,
                rule: rule,
                isInputLocked: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MatchTimerSection), findsOneWidget);
    });
  });
}
