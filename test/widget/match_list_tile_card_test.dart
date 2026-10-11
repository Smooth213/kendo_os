import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] MatchListTileCard ウィジェットテスト', () {
    testWidgets('MatchListTileCard with チーム and 選手 namesが正しく描画されること', (
      WidgetTester tester,
    ) async {
      const sampleMatch = MatchModel(
        id: 'test_match_1',
        tournamentId: 'tour_1',
        matchType: '個人戦',
        redName: 'チームA: 山田',
        whiteName: 'チームB: 佐藤',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        order: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionProvider.overrideWithValue(
              const PermissionState(canManageTournament: true),
            ),
            matchListProvider.overrideWith((ref) => [sampleMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: MatchListTileCard(initialMatch: sampleMatch),
            ),
          ),
        ),
      );

      expect(find.text('チームA'), findsOneWidget);
      expect(find.text('チームB'), findsOneWidget);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('終了'), findsOneWidget);
      // 個人戦のためBANDボタンが表示されること
      expect(find.text('BAND'), findsOneWidget);
    });

    testWidgets('団体戦の試合カード（先鋒等）ではBANDボタンが表示されないこと', (
      WidgetTester tester,
    ) async {
      const teamMatch = MatchModel(
        id: 'test_team_match_1',
        tournamentId: 'tour_1',
        matchType: '先鋒',
        groupName: 'group_1',
        redName: 'チームA: 山田',
        whiteName: 'チームB: 佐藤',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
        order: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionProvider.overrideWithValue(
              const PermissionState(canManageTournament: true),
            ),
            matchListProvider.overrideWith((ref) => [teamMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: MatchListTileCard(initialMatch: teamMatch),
            ),
          ),
        ),
      );

      expect(find.text('試合中 (LIVE)'), findsOneWidget);
      // 団体戦では試合ごとのBANDボタンは非表示
      expect(find.text('BAND'), findsNothing);
    });

    testWidgets('リーグ個人戦の試合カードでもBANDボタンが表示されること', (WidgetTester tester) async {
      const leagueIndivMatch = MatchModel(
        id: 'test_league_indiv_1',
        tournamentId: 'tour_1',
        matchType: 'individual',
        groupName: 'league_group_1',
        note: '第3試合場 [リーグ戦] 第2試合',
        redName: '道上: 橋本',
        whiteName: '相手: 三宅',
        status: 'pending',
        order: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionProvider.overrideWithValue(
              const PermissionState(canManageTournament: true),
            ),
            matchListProvider.overrideWith((ref) => [leagueIndivMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: MatchListTileCard(initialMatch: leagueIndivMatch),
            ),
          ),
        ),
      );

      expect(find.text('⏳ 待機中'), findsOneWidget);
      // リーグ個人戦でもBANDボタンが表示されること
      expect(find.text('BAND'), findsOneWidget);
    });
  });
}
