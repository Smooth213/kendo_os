import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/team_scoreboard_screen.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🥋 チーム試合状況ボトムシート 完全動作保証テスト (TeamMatchStatus BottomSheet Flow)', () {
    late MatchModel taishoMatch;
    late MatchModel senpoMatch;
    late TeamProgressStatus teamProgress;

    setUp(() {
      taishoMatch = MatchModel(
        id: 'match_taisho_flow',
        matchType: '大将',
        groupName: '団体戦_道上vs吉舎',
        tournamentId: 'tourney_123',
        redName: '道上剣友会:皿田 唯人',
        whiteName: '吉舎剣友会:平岡',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        order: 5,
        events: [],
      );

      senpoMatch = MatchModel(
        id: 'match_senpo_flow',
        matchType: '先鋒',
        groupName: '団体戦_道上vs吉舎',
        tournamentId: 'tourney_123',
        redName: '道上剣友会:佐藤',
        whiteName: '吉舎剣友会:田中',
        redScore: 1,
        whiteScore: 1,
        status: 'finished',
        order: 1,
        events: [],
      );

      teamProgress = TeamProgressStatus(
        teamName: '道上剣友会',
        tournamentId: 'tourney_123',
        targetGroupId: '団体戦_道上vs吉舎',
        matches: [senpoMatch, taishoMatch],
        categoryName: '中学生男子の部',
        currentCourtName: '第1試合場',
        lastFinishedMatch: taishoMatch,
        completedCount: 5,
        totalCount: 5,
        hasLiveMatch: false,
      );
    });

    Widget createTestApp(SharedPreferences prefs) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentTournamentIdProvider.overrideWith((ref) => 'tourney_123'),
          webCurrentTournamentIdProvider.overrideWith((ref) => 'tourney_123'),
          teamProgressListProvider.overrideWith((ref) => [teamProgress]),
          matchListProvider.overrideWith((ref) => [senpoMatch, taishoMatch]),
          matchListByTournamentProvider(
            'tourney_123',
          ).overrideWith((ref) => Stream.value([senpoMatch, taishoMatch])),
          playerListProvider.overrideWith((ref) => Stream.value([])),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            ),
          ),
          matchViewStateProvider('match_taisho_flow').overrideWith(
            (ref) => MatchViewState(
              scoreText: '1 - 0',
              redScore: 1,
              whiteScore: 0,
              isEncho: false,
              winner: 'red',
              lastEventText: 'メ',
              canUndo: false,
              statusText: '終了',
              syncStatus: SyncStatus.synced,
              isViewOnly: false,
              isInputLocked: true,
              isAllDone: true,
              isTie: false,
              redCleanName: '皿田 唯人',
              whiteCleanName: '平岡',
            ),
          ),
          matchViewStateProvider('match_senpo_flow').overrideWith(
            (ref) => MatchViewState(
              scoreText: '1 - 1',
              redScore: 1,
              whiteScore: 1,
              isEncho: false,
              winner: 'draw',
              lastEventText: '引き分け',
              canUndo: false,
              statusText: '終了',
              syncStatus: SyncStatus.synced,
              isViewOnly: false,
              isInputLocked: true,
              isAllDone: true,
              isTie: true,
              redCleanName: '佐藤',
              whiteCleanName: '田中',
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open_team_status_sheet_button'),
                onPressed: () {
                  FloatingDockSheetManager.show(
                    context: context,
                    builder: (_) => const TeamMatchStatusScreen(
                      tournamentId: 'tourney_123',
                      isBottomSheet: true,
                    ),
                  );
                },
                child: const Text('チーム試合状況を開く'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      '① ボトムシート展開 ➔ 団体戦カードタップ ➔ スコアボード ➔ 対戦詳細(MatchScreen)の2段階ネスト遷移と完全復帰',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createTestApp(prefs));

        // 1. ボトムシートを開く
        await tester.tap(
          find.byKey(const Key('open_team_status_sheet_button')),
        );
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.text('チーム試合状況'), findsOneWidget);
        expect(find.text('道上剣友会'), findsWidgets);

        // 2. 団体戦カードをタップ ➔ TeamScoreboardScreen にネスト遷移
        await tester.tap(find.text('道上剣友会').first);
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(TeamScoreboardScreen), findsOneWidget);
        expect(find.text('チーム試合状況'), findsNothing);

        // 3. スコアボード内の対戦セルをタップ ➔ MatchScreen にさらにネスト遷移
        final taishoCell = find.text('大将');
        expect(taishoCell, findsOneWidget);
        await tester.tap(taishoCell);
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(MatchScreen), findsOneWidget);

        // 4. MatchScreen の戻るボタン押下 ➔ TeamScoreboardScreen に戻る
        final backButton = find.byIcon(Icons.arrow_back_ios_new);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(MatchScreen), findsNothing);
        expect(find.byType(TeamScoreboardScreen), findsOneWidget);

        // 5. TeamScoreboardScreen の戻るボタン押下 ➔ TeamMatchStatusScreen (一覧) に戻る
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(TeamScoreboardScreen), findsNothing);
        expect(find.text('チーム試合状況'), findsOneWidget);
        expect(find.text('道上剣友会'), findsWidgets);

        FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '② 直前の結果タップ ➔ MatchScreen への直接遷移 & 画面リサイズ(needsScroll)でもシートが勝手に閉じないことの保証',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createTestApp(prefs));

        // 1. ボトムシートを開く
        await tester.tap(
          find.byKey(const Key('open_team_status_sheet_button')),
        );
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.text('直前の結果: 【大将】'), findsOneWidget);
        expect(find.text('記録を開く 👉'), findsOneWidget);

        // 2. 「記録を開く 👉」をタップ ➔ MatchScreen へ直接遷移
        await tester.tap(find.text('記録を開く 👉'));
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(MatchScreen), findsOneWidget);

        // 3. 【再発防止検証】: MatchScreen 描画中に複数回の画面再描画・レイアウト計算が発生しても
        // FloatingProgramDockButton が非表示かつ安全に保護され、シートが絶対に即時クローズしないこと
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 300));
        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(MatchScreen), findsOneWidget);

        // 4. 戻るボタンで復帰
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();

        expect(FloatingDockSheetManager.isOpen, isTrue);
        expect(find.byType(MatchScreen), findsNothing);
        expect(find.text('直前の結果: 【大将】'), findsOneWidget);

        FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('③ カテゴリフィルタとステータスフィルタがボトムシート内で正しく連動することの保証', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createTestApp(prefs));

      // ボトムシートを開く
      await tester.tap(find.byKey(const Key('open_team_status_sheet_button')));
      await tester.pumpAndSettle();

      expect(FloatingDockSheetManager.isOpen, isTrue);
      expect(find.text('すべて表示'), findsOneWidget);
      expect(find.text('全カテゴリ (1)'), findsOneWidget);
      expect(find.text('中学生男子の部 (1)'), findsOneWidget);

      // カテゴリタブ「中学生男子の部 (1)」をタップ
      await tester.tap(find.text('中学生男子の部 (1)'));
      await tester.pumpAndSettle();

      expect(FloatingDockSheetManager.isOpen, isTrue);
      expect(find.text('道上剣友会'), findsWidgets);

      // カテゴリタブ「全カテゴリ (1)」をタップして戻る
      await tester.tap(find.text('全カテゴリ (1)'));
      await tester.pumpAndSettle();

      expect(FloatingDockSheetManager.isOpen, isTrue);
      expect(find.text('道上剣友会'), findsWidgets);

      FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });
  });
}
