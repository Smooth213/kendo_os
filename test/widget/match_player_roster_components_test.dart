import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_roster_list_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_selection_card.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ MatchPlayer Roster Components Tests', () {
    testWidgets('1. MatchPlayerSelectionCard renders sub player correctly', (
      tester,
    ) async {
      final player = PlayerModel(
        id: 'p1',
        lastName: '高橋',
        firstName: '健太',
        lastNameKana: 'たかはし',
        firstNameKana: 'けんた',
        grade: 5,
        organization: 'A道場',
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchPlayerSelectionCard(
              player: player,
              isSub: true,
              isCurrentPosition: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('高橋 健太'), findsOneWidget);
      await tester.tap(find.text('高橋 健太'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
      '2. MatchPlayerRosterListSection displays active and sub players',
      (tester) async {
        final p1 = PlayerModel(
          id: 'p1',
          lastName: '田中',
          firstName: '太郎',
          lastNameKana: '',
          firstNameKana: '',
          grade: 5,
        );
        final p2 = PlayerModel(
          id: 'p2',
          lastName: '佐藤',
          firstName: '次郎',
          lastNameKana: '',
          firstNameKana: '',
          grade: 5,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MatchPlayerRosterListSection(
                sameCatActive: [p1],
                dojoListSubstitutes: [p2],
                otherCategoryPlayers: const [],
                activePlayerNames: {'田中 太郎'},
                playerPositions: {'田中 太郎': '先鋒'},
                currentPlayerName: '田中 太郎',
                onPlayerSelected: (player, isSub) {},
              ),
            ),
          ),
        );

        expect(find.text('田中 太郎'), findsOneWidget);
        expect(find.text('佐藤 次郎'), findsOneWidget);
        expect(find.text('出場中の選手 (交代・スワップ)'), findsOneWidget);
        expect(find.text('同カテゴリの控え選手'), findsOneWidget);
      },
    );
  });
}
