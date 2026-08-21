import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';

void main() {
  group('TimelineMatchGroupCard Widget Tests', () {
    testWidgets('renders TimelineMatchGroupCard successfully', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        redName: 'A Team: Player 1',
        whiteName: 'B Team: Player 2',
        matchType: '団体戦',
        groupName: 'group_1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  TimelineMatchGroupCard(
                    groupId: 'group_1',
                    groupList: [match],
                    groupComments: const [],
                    categoryName: 'General',
                    teamName: 'A Team',
                    label: '団体戦',
                    isReadOnlyUI: false,
                    canManageTournamentUI: true,
                    isDark: false,
                    tournamentId: 't1',
                    ownTeams: const [],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TimelineMatchGroupCard), findsOneWidget);
    });
  });
}
