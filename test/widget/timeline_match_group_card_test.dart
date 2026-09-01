import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimelineMatchGroupCard Widget Tests', () {
    testWidgets(
      'renders TimelineMatchGroupCard successfully and shows 編集 on swipe',
      (tester) async {
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
        await tester.pumpAndSettle();

        expect(find.byType(TimelineMatchGroupCard), findsOneWidget);

        // 左へスワイプしてスワイプアクションを表示
        await tester.drag(
          find.byType(TimelineMatchGroupCard),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        // スワイプ時に「メモ」ではなく「編集」が表示されていること
        expect(find.text('編集'), findsOneWidget);
        expect(find.text('メモ'), findsNothing);
      },
    );
  });
}
