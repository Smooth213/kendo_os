import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_roster_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_filter_helper.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/widgets/include_graduated_filter_chip.dart';
import 'package:kendo_os/shared/widgets/multi_player_filter_helper.dart';

void main() {
  group(
    '[Widget] IncludeGraduatedFilterChip・MultiPlayerFilterHelper 卒業生切替テスト',
    () {
      testWidgets('IncludeGraduatedFilterChipのタップでON/OFFが切り替わること', (
        tester,
      ) async {
        bool includeGraduated = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return IncludeGraduatedFilterChip(
                    includeGraduated: includeGraduated,
                    onChanged: (val) => setState(() => includeGraduated = val),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('卒業生(OB/OG)を含める'), findsOneWidget);
        await tester.tap(find.text('卒業生(OB/OG)を含める'));
        await tester.pump();
        expect(includeGraduated, isTrue);

        await tester.tap(find.text('卒業生(OB/OG)を含める'));
        await tester.pump();
        expect(includeGraduated, isFalse);
      });

      test(
        'filterAndSortMasterにおいてincludeGraduatedがfalse時は現役のみ・true時は卒業生も含まれること',
        () {
          final players = [
            PlayerModel(
              id: 'active1',
              lastName: '現役',
              firstName: '太郎',
              lastNameKana: 'ゲンエキ',
              firstNameKana: 'タロウ',
              grade: 8,
            ),
            PlayerModel(
              id: 'ob1',
              lastName: '卒業',
              firstName: '先輩',
              lastNameKana: 'ソツギョウ',
              firstNameKana: 'センパイ',
              grade: 9,
              status: PlayerModel.statusGraduated,
              graduatedFiscalYear: 2026,
            ),
          ];

          final activeOnly = MultiPlayerFilterHelper.filterAndSortMaster(
            masterPlayers: players,
            searchText: '',
            selectedFilter: 'すべて',
            isAscending: true,
            includeGraduated: false,
          );
          expect(activeOnly.map((p) => p.id), equals(['active1']));

          final withOb = MultiPlayerFilterHelper.filterAndSortMaster(
            masterPlayers: players,
            searchText: '',
            selectedFilter: 'すべて',
            isAscending: true,
            includeGraduated: true,
          );
          expect(withOb.map((p) => p.id), equals(['active1', 'ob1']));

          expect(
            MultiPlayerFilterHelper.formatPlayerCandidateGrade(players[1]),
            equals('中学3年卒 (2026年度卒)'),
          );
        },
      );

      test(
        'TeamRegistrationPlayerFilterHelperとMatchPlayerRosterResolverが卒業生切替を反映すること',
        () {
          final players = [
            PlayerModel(
              id: 'a1',
              lastName: '現役',
              firstName: '中学',
              lastNameKana: 'ゲンエキ',
              firstNameKana: 'チュウガク',
              grade: 8,
              organization: '練馬道場',
            ),
            PlayerModel(
              id: 'g1',
              lastName: '先輩',
              firstName: '卒業',
              lastNameKana: 'センパイ',
              firstNameKana: 'ソツギョウ',
              grade: 9,
              organization: '練馬道場',
              status: PlayerModel.statusGraduated,
              graduatedFiscalYear: 2026,
            ),
          ];

          final teamActiveOnly =
              TeamRegistrationPlayerFilterHelper.getRecommendedPlayers(
                players: players,
                majorCategory: '中学生',
                minorCategory: '',
                query: '',
                includeGraduated: false,
              );
          expect(teamActiveOnly.map((p) => p.id), equals(['a1']));

          final teamWithOb =
              TeamRegistrationPlayerFilterHelper.getRecommendedPlayers(
                players: players,
                majorCategory: '中学生',
                minorCategory: '',
                query: '',
                includeGraduated: true,
              );
          expect(teamWithOb.map((p) => p.id), equals(['a1', 'g1']));

          final match = MatchModel(
            id: 'm1',
            redName: '練馬道場 : 現役 中学',
            whiteName: '相手道場 : 相手 選手',
            matchType: '先鋒',
            category: '中学生の部',
          );
          final rosterActiveOnly = MatchPlayerRosterResolver.resolve(
            teamName: '練馬道場',
            match: match,
            currentGroupMatches: [match],
            players: players,
            registeredTeams: const [],
            includeGraduated: false,
          );
          expect(
            rosterActiveOnly.quickAccessPlayers.map((p) => p.id),
            isNot(contains('g1')),
          );
          expect(
            rosterActiveOnly.otherCategoryPlayers.map((p) => p.id),
            isNot(contains('g1')),
          );

          final rosterWithOb = MatchPlayerRosterResolver.resolve(
            teamName: '練馬道場',
            match: match,
            currentGroupMatches: [match],
            players: players,
            registeredTeams: const [],
            includeGraduated: true,
          );
          expect(
            rosterWithOb.quickAccessPlayers.map((p) => p.id),
            contains('g1'),
          );
        },
      );
    },
  );
}
