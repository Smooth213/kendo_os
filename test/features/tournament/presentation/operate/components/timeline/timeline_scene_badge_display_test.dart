import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_team_match_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';

void main() {
  group('🥋 【大会ホーム一覧】選んだルールに応じた【錬成】・【申合せ】バッジ表示完全保証テスト', () {
    testWidgets(
      '1. 団体戦・勝ち抜き戦カード（TimelineMatchGroupCard）の左上に【錬成】・【申合せ】バッジが表示されること',
      (tester) async {
        // 錬成会団体戦
        final renseiGroup = [
          const MatchModel(
            id: 'rensei_m1',
            groupName: 'group_rensei_1',
            matchType: '先鋒戦',
            redName: '道上剣友会A: 選手1',
            whiteName: '相手チーム02: 選手2',
            status: 'in_progress',
            matchScene: 'renseikai',
            order: 1.0,
          ),
        ];

        // 申合せ団体戦
        final moushiawaseGroup = [
          const MatchModel(
            id: 'moushiawase_m1',
            groupName: 'group_moushiawase_1',
            matchType: '先鋒戦',
            redName: '道上剣友会A: 選手1',
            whiteName: '相手チーム03: 選手3',
            status: 'waiting',
            matchScene: 'moushiawase',
            order: 2.0,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: [
                    TimelineMatchGroupCard(
                      groupId: 'group_rensei_1',
                      groupList: renseiGroup,
                      groupComments: const [],
                      categoryName: '小学生の部',
                      teamName: '道上剣友会A',
                      label: '団体戦',
                      isReadOnlyUI: false,
                      canManageTournamentUI: true,
                      isDark: false,
                      tournamentId: 't1',
                      ownTeams: const ['道上剣友会A'],
                    ),
                    TimelineMatchGroupCard(
                      groupId: 'group_moushiawase_1',
                      groupList: moushiawaseGroup,
                      groupComments: const [],
                      categoryName: '小学生の部',
                      teamName: '道上剣友会A',
                      label: '団体戦',
                      isReadOnlyUI: false,
                      canManageTournamentUI: true,
                      isDark: false,
                      tournamentId: 't1',
                      ownTeams: const ['道上剣友会A'],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // カード上段の左上に【錬成】バッジが表示されていること
        expect(find.text('【錬成】'), findsOneWidget);
        // カード上段の左上に【申合せ】バッジが表示されていること
        expect(find.text('【申合せ】'), findsOneWidget);
      },
    );

    testWidgets(
      '2. 個人戦カード（TimelineIndividualPlayerCard）のサブタイトルに【錬成】・【申合せ】が表示されること',
      (tester) async {
        final renseiIndivMatches = [
          const MatchModel(
            id: 'rensei_indiv_1',
            matchType: '個人戦',
            redName: '皿田 脩人',
            whiteName: '相手 太郎',
            status: 'finished',
            matchScene: 'renseikai',
            order: 1.0,
          ),
        ];

        final moushiawaseIndivMatches = [
          const MatchModel(
            id: 'moushiawase_indiv_1',
            matchType: '個人戦',
            redName: '久安 智也',
            whiteName: '相手 次郎',
            status: 'waiting',
            matchScene: 'moushiawase',
            order: 2.0,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: [
                    TimelineIndividualPlayerCard(
                      playerName: '皿田 脩人',
                      playerMatches: renseiIndivMatches,
                      playerComments: const [],
                      categoryName: '小学生個人の部',
                      teamName: '道上剣友会A',
                      isReadOnlyUI: false,
                      isDark: false,
                      permissions: const PermissionState(
                        canManageTournament: true,
                      ),
                    ),
                    TimelineIndividualPlayerCard(
                      playerName: '久安 智也',
                      playerMatches: moushiawaseIndivMatches,
                      playerComments: const [],
                      categoryName: '小学生個人の部',
                      teamName: '道上剣友会A',
                      isReadOnlyUI: false,
                      isDark: false,
                      permissions: const PermissionState(
                        canManageTournament: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1段目のバッジに【錬成】および【申合せ】が表示されること
        expect(find.text('【錬成】'), findsWidgets);
        expect(find.text('【申合せ】'), findsWidgets);
      },
    );

    testWidgets(
      '3. リーグ団体戦ヘッダー（TimelineLeagueTeamMatchHeader）に【錬成】・【申合せ】バッジが表示されること',
      (tester) async {
        final leagueBouts = [
          const MatchModel(
            id: 'league_bout_1',
            groupName: 'group_league_1',
            matchType: '先鋒戦',
            redName: '道上剣友会A: 選手1',
            whiteName: '相手チーム: 選手2',
            status: 'waiting',
            matchScene: 'renseikai',
            order: 1.0,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: TimelineLeagueTeamMatchHeader(
                  bouts: leagueBouts,
                  isReadOnlyUI: false,
                  boutsAllFinished: false,
                  boutsInProgress: false,
                  t1: '道上剣友会A',
                  t2: '相手チーム',
                  ownTeams: const ['道上剣友会A'],
                  mTitleColor: Colors.black,
                  isDark: false,
                  onShowSummaryInputDialog: (ctx, ref, b) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // リーグ戦中枠ヘッダーにも【錬成】バッジが表示されること
        expect(find.text('【錬成】'), findsOneWidget);
        expect(find.text('1ポジション'), findsOneWidget);
      },
    );
  });
}
