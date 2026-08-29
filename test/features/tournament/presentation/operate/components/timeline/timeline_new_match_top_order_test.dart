import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_team_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';

void main() {
  group('🥋 【大会ホーム一覧】後から追加した新しい対戦・おかわりの対戦が最上位に来る保証テスト', () {
    testWidgets('1. 団体戦で後から追加した対戦カード（orderが大きい試合）が一番上に表示されること', (tester) async {
      // 1試合目（最初に追加: order 1000）
      const initialMatches = [
        MatchModel(
          id: 'm1_senpo',
          groupName: 'group_round_1',
          matchType: '先鋒戦',
          redName: '道上剣友会A: 選手1',
          whiteName: '相手チーム01: 相手1',
          status: 'finished',
          order: 1000.0,
        ),
        MatchModel(
          id: 'm1_jiho',
          groupName: 'group_round_1',
          matchType: '次鋒戦',
          redName: '道上剣友会A: 選手2',
          whiteName: '相手チーム01: 相手2',
          status: 'finished',
          order: 1001.0,
        ),
      ];

      // 2試合目（あとから追加・おかわりの対戦: order 2000）
      const extraMatches = [
        MatchModel(
          id: 'm2_senpo',
          groupName: 'group_round_2_extra',
          matchType: '先鋒戦',
          redName: '道上剣友会A: 選手1',
          whiteName: '相手チーム02: 相手2',
          status: 'waiting',
          matchScene: 'renseikai',
          order: 2000.0,
        ),
        MatchModel(
          id: 'm2_jiho',
          groupName: 'group_round_2_extra',
          matchType: '次鋒戦',
          redName: '道上剣友会A: 選手2',
          whiteName: '相手チーム02: 相手3',
          status: 'waiting',
          matchScene: 'renseikai',
          order: 2001.0,
        ),
      ];

      final allMatches = [...initialMatches, ...extraMatches];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWithValue(allMatches),
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(['道上剣友会A']),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  TimelineTeamCard(
                    teamName: '道上剣友会A',
                    teamMatchesList: allMatches,
                    categoryName: '小学生低学年の部',
                    tournamentId: 't1',
                    sanitizedQuery: '',
                    matchedMatchIds: const {},
                    matchedGroupNames: const {},
                    ownTeams: const ['道上剣友会A'],
                    comments: const [],
                    isReadOnlyUI: false,
                    canManageTournamentUI: true,
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

      // 画面内に両方の対戦カードが表示されていること
      expect(find.text('道上剣友会A vs 相手チーム02'), findsOneWidget);
      expect(find.text('道上剣友会A vs 相手チーム01'), findsOneWidget);

      // おかわり（後から追加した相手チーム02）が相手チーム01よりも上に配置されていることを検証
      final posExtra = tester.getTopLeft(find.text('道上剣友会A vs 相手チーム02'));
      final posInitial = tester.getTopLeft(find.text('道上剣友会A vs 相手チーム01'));
      expect(posExtra.dy, lessThan(posInitial.dy)); // y座標が小さい＝より上にある
    });

    testWidgets('2. 個人戦で後から追加した試合（おかわり試合）が一番上に表示されること', (tester) async {
      // 皿田 脩人の1試合目（最初: order 100）
      const indiv1 = MatchModel(
        id: 'indiv_1',
        matchType: '個人戦',
        redName: '皿田 脩人',
        whiteName: '相手 太郎',
        status: 'finished',
        order: 100.0,
      );

      // 皿田 脩人の2試合目（おかわり: order 200）
      const indivExtra = MatchModel(
        id: 'indiv_extra',
        matchType: '個人戦',
        redName: '皿田 脩人',
        whiteName: '相手 次郎',
        status: 'waiting',
        order: 200.0,
      );

      final allIndivMatches = [indiv1, indivExtra];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWithValue(allIndivMatches),
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(['道上剣友会A']),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  TimelineTeamCard(
                    teamName: '道上剣友会A',
                    teamMatchesList: allIndivMatches,
                    categoryName: '小学生個人の部',
                    tournamentId: 't1',
                    sanitizedQuery: '',
                    matchedMatchIds: const {},
                    matchedGroupNames: const {},
                    ownTeams: const ['道上剣友会A'],
                    comments: const [],
                    isReadOnlyUI: false,
                    canManageTournamentUI: true,
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

      // アコーディオンを展開
      await tester.tap(find.text('皿田 脩人'));
      await tester.pumpAndSettle();

      expect(find.text('相手 次郎'), findsOneWidget);
      expect(find.text('相手 太郎'), findsOneWidget);

      // おかわり試合（相手 次郎）が1試合目（相手 太郎）より上にあること
      final posExtra = tester.getTopLeft(find.text('相手 次郎'));
      final posInitial = tester.getTopLeft(find.text('相手 太郎'));
      expect(posExtra.dy, lessThan(posInitial.dy));
    });
  });
}
