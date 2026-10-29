import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_timeline_list.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_heading_history_provider.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_list_tile_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] 試合会場・試合順及び運営メモ表示境界統合テスト', () {
    testWidgets('チーム別履歴引き継ぎにおいて複数チーム間で前回値が独立保持され次の試合順が自動計算されること', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(teamHeadingHistoryProvider.notifier);

      // Team A: 第1試合場, 1試合目を設定・記録
      notifier.recordHeading(teamId: 'team_a', courtNumber: 1, matchOrder: 1);

      // Team B: 第2試合場, 3試合目を設定・記録
      notifier.recordHeading(teamId: 'team_b', courtNumber: 2, matchOrder: 3);

      // Team A の履歴取得: 第1試合場, 1試合目が記憶されており次回は 2試合目が計算可能
      final historyA = notifier.getHistory('team_a');
      expect(historyA, isNotNull);
      expect(historyA?.courtNumber, 1);
      expect(historyA?.lastMatchOrder, 1);
      expect(historyA?.nextMatchOrder, 2);

      // Team B の履歴取得: 第2試合場, 3試合目が記憶されており次回は 4試合目が計算可能
      final historyB = notifier.getHistory('team_b');
      expect(historyB, isNotNull);
      expect(historyB?.courtNumber, 2);
      expect(historyB?.lastMatchOrder, 3);
      expect(historyB?.nextMatchOrder, 4);

      // 未知のチーム Team C の履歴取得: 直近（Team B）の内容が安全にフォールバックされること
      final historyC = notifier.getHistory('team_c');
      expect(historyC, isNotNull);
      expect(historyC?.courtNumber, 2);
      expect(historyC?.lastMatchOrder, 3);
      expect(historyC?.nextMatchOrder, 4);
    });

    testWidgets('運営メモの表示境界において管理側カードには運営メモが表示されること', (tester) async {
      const sampleMatchWithPrivateNote = MatchModel(
        id: 'test_isolation_match_1',
        tournamentId: 'tour_test_1',
        matchType: '個人戦',
        redName: '勇武館: 佐藤',
        whiteName: '修道館: 田中',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
        order: 1,
        note: '第1試合場, 1試合目, 準決勝\n相手先鋒上段、主審交代注意',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionProvider.overrideWithValue(
              const PermissionState(canManageTournament: true),
            ),
            matchListProvider.overrideWith(
              (ref) => [sampleMatchWithPrivateNote],
            ),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: MatchListTileCard(initialMatch: sampleMatchWithPrivateNote),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      // 公開見出しが表示されていること
      expect(find.textContaining('第1試合場, 1試合目, 準決勝'), findsOneWidget);
      // 管理側カードには運営メモが表示されていること
      expect(find.textContaining('相手先鋒上段、主審交代注意'), findsOneWidget);
    });

    testWidgets('運営メモの表示境界においてビュアー側カードには内部特記事項が完全非表示となること', (tester) async {
      const sampleMatchWithPrivateNote = MatchModel(
        id: 'test_isolation_match_2',
        tournamentId: 'tour_test_1',
        matchType: '個人戦',
        redName: '勇武館: 佐藤',
        whiteName: '修道館: 田中',
        redScore: 1,
        whiteScore: 0,
        status: 'in_progress',
        order: 1,
        note: '第1試合場, 1試合目, 準決勝\n相手先鋒上段、主審交代注意',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith(
              (ref) => [sampleMatchWithPrivateNote],
            ),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: const Scaffold(
              body: ViewerMatchListTileCard(
                initialMatch: sampleMatchWithPrivateNote,
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      // 公開見出しが表示されていること
      expect(find.textContaining('第1試合場, 1試合目, 準決勝'), findsOneWidget);
      // ビュアー側カードには内部特記事項（運営メモ）が【絶対に表示されない（0件）】こと
      expect(find.textContaining('相手先鋒上段、主審交代注意'), findsNothing);
    });

    testWidgets('チーム試合状況カードにおいて対象試合の運営メモがコート情報下に正しく表示されること', (tester) async {
      const liveMatch = MatchModel(
        id: 'test_team_status_match_1',
        tournamentId: 'tour_test_1',
        matchType: '先鋒',
        redName: '勇武館: 佐藤',
        whiteName: '修道館: 田中',
        redScore: 0,
        whiteScore: 0,
        status: 'in_progress',
        order: 1,
        note: '第2試合場, 3試合目\n主審交代注意、延長無制限',
      );

      const status = TeamProgressStatus(
        teamName: '勇武館',
        categoryName: '男子団体',
        currentCourtName: '第2試合場',
        matches: [liveMatch],
        inProgressMatch: liveMatch,
        completedCount: 0,
        totalCount: 5,
        hasLiveMatch: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: const Scaffold(
            body: TeamStatusCard(status: status, isDark: false),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      // チーム名が表示されていること
      expect(find.text('勇武館'), findsWidgets);
      // 運営メモが表示されていること
      expect(find.textContaining('主審交代注意、延長無制限'), findsOneWidget);
    });
  });
}
