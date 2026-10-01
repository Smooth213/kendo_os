import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_team_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] Timeline Extracted Components テスト', () {
    testWidgets('TimelineIndividualPlayerCard 正しく描画されること', (tester) async {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: '佐藤',
        whiteName: '鈴木',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        matchType: 'individual',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TimelineIndividualPlayerCard(
                playerName: '佐藤',
                playerMatches: [match],
                playerComments: const [],
                categoryName: '一般の部',
                teamName: 'A道場',
                isReadOnlyUI: false,
                isDark: false,
                permissions: const PermissionState(
                  isReadOnly: false,
                  canManageTournament: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('佐'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('佐藤'),
        ),
        findsOneWidget,
      );
      expect(find.text('終了'), findsOneWidget);
    });

    testWidgets('TimelineTeamCardにおいて ヘッダーおよび試合情報が正しく描画されること', (tester) async {
      final match = MatchModel(
        id: 'm1',
        matchOrder: 1,
        redName: 'A道場 : 佐藤',
        whiteName: 'B道場 : 鈴木',
        redScore: 0,
        whiteScore: 0,
        status: 'waiting',
        matchType: 'team',
        groupName: '第1試合場',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TimelineTeamCard(
                  teamName: 'A道場',
                  teamMatchesList: [match],
                  categoryName: '一般の部',
                  tournamentId: 't1',
                  sanitizedQuery: '',
                  matchedMatchIds: const {},
                  matchedGroupNames: const {},
                  ownTeams: const ['A道場'],
                  comments: const [],
                  isReadOnlyUI: false,
                  canManageTournamentUI: true,
                  isDark: false,
                  permissions: const PermissionState(
                    isReadOnly: false,
                    canManageTournament: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('A道場'), findsOneWidget);
    });
  });
}
