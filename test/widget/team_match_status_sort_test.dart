import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';

void main() {
  group('🥋 TeamMatchStatusScreen Sort UI Tests (会場・試合順ソート機能テスト)', () {
    TeamProgressStatus makeStatus({
      required String teamName,
      required String courtName,
      bool hasLive = false,
      bool isFinished = false,
    }) {
      return TeamProgressStatus(
        teamName: teamName,
        currentCourtName: courtName,
        matches: [
          MatchModel(
            id: 'm_$teamName',
            matchType: '先鋒',
            redName: '$teamName: 選手A',
            whiteName: '相手チーム: 選手B',
            status: isFinished
                ? 'finished'
                : (hasLive ? 'in_progress' : 'waiting'),
            order: 1.0,
          ),
        ],
        completedCount: isFinished ? 1 : 0,
        totalCount: 1,
        hasLiveMatch: hasLive,
      );
    }

    testWidgets('並び替えチップのタップにより、会場順・試合順・進行状況順にリストが正しく並び替わること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // モックデータ:
      // 1. チームA: 第2コート (第1試合) - LIVE
      // 2. チームB: 第1コート (第3試合) - 待機中
      // 3. チームC: 第1コート (第1試合) - 待機中
      final mockTeams = [
        makeStatus(teamName: 'チームA', courtName: '第2コート (第1試合)', hasLive: true),
        makeStatus(teamName: 'チームB', courtName: '第1コート (第3試合)', hasLive: false),
        makeStatus(teamName: 'チームC', courtName: '第1コート (第1試合)', hasLive: false),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamProgressListProvider.overrideWithValue(mockTeams),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                canCreateMatch: true,
                canManageTournament: true,
                isReadOnly: false,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
          ],
          child: const MaterialApp(
            home: TeamMatchStatusScreen(
              tournamentId: 'test_tournament',
              isBottomSheet: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 初期状態: 進行状況順（status） -> チームA (LIVE) が先頭
      expect(find.text('並び替え:'), findsOneWidget);
      expect(find.text('⚡ 進行状況順'), findsOneWidget);
      expect(find.text('🏟️ 試合会場順'), findsOneWidget);
      expect(find.text('🔢 試合順'), findsOneWidget);

      // ListView内の並び順を確認する関数
      List<String> getRenderedTeamNames() {
        final teamNames = <String>[];
        final widgets = tester.widgetList<Text>(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.data != null &&
                (w.data == 'チームA' || w.data == 'チームB' || w.data == 'チームC'),
          ),
        );
        for (final w in widgets) {
          if (!teamNames.contains(w.data)) {
            teamNames.add(w.data!);
          }
        }
        return teamNames;
      }

      // 1. 初期順序 (進行状況順: チームA (LIVE) が最上位)
      expect(getRenderedTeamNames().first, 'チームA');

      // 2. 「試合会場順」をタップ
      await tester.tap(find.text('🏟️ 試合会場順'));
      await tester.pumpAndSettle();

      // 会場順: 第1コート (第1試合: チームC, 第3試合: チームB) -> 第2コート (チームA)
      final courtOrdered = getRenderedTeamNames();
      expect(courtOrdered[0], 'チームC');
      expect(courtOrdered[1], 'チームB');
      expect(courtOrdered[2], 'チームA');

      // 3. 「試合順」をタップ
      await tester.tap(find.text('🔢 試合順'));
      await tester.pumpAndSettle();

      // 試合順: 第1試合 (第1コート: チームC, 第2コート: チームA) -> 第3試合 (チームB)
      final matchOrdered = getRenderedTeamNames();
      expect(matchOrdered[0], 'チームC'); // 第1試合 第1コート
      expect(matchOrdered[1], 'チームA'); // 第1試合 第2コート
      expect(matchOrdered[2], 'チームB'); // 第3試合 第1コート

      // 4. 「進行状況順」に戻す
      await tester.tap(find.text('⚡ 進行状況順'));
      await tester.pumpAndSettle();

      // LIVE (チームA) が再び最上位
      expect(getRenderedTeamNames().first, 'チームA');
    });
  });
}
