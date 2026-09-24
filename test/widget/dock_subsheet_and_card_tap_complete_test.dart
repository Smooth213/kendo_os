import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';
import 'package:kendo_os/features/band/domain/entities/band_group_model.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/team_scoreboard_screen.dart';
import 'package:kendo_os/shared/bootstrap/app_bootstrap_helper.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() =>
      const SettingsModel(securityLevel: 1, enableLiquidGlass: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': ''};
          }
          return null;
        });
  });

  group('🥋 ドック内サブシート最前面表示 ＆ チーム試合状況ネスト遷移 完全動作保証テスト', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() async {
      if (FloatingDockSheetManager.isOpen) {
        await FloatingDockSheetManager.close(immediate: true);
      }
    });

    testWidgets('1. システム設定ボトムシート：BAND設定・サーマル・Google解除・ログアウトが最前面で動作すること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    FloatingDockSheetManager.show(
                      context: context,
                      builder: (_) => const SettingsScreen(isBottomSheet: true),
                    );
                  },
                  child: const Text('Open Settings Dock'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            bandGroupsStreamProvider.overrideWith((ref) => Stream.value([])),
            isGoogleLinkedProvider.overrideWith((ref) => true),
            linkedGoogleEmailProvider.overrideWith((ref) => 'test@gmail.com'),
            linkedGoogleUidProvider.overrideWith((ref) => 'uid123'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // ドックから設定を開く
      await tester.tap(find.text('Open Settings Dock'));
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);

      // (A) サーマル冷却・省電力制御タイルタップ
      await tester.tap(find.text('サーマル冷却・省電力制御'));
      await tester.pumpAndSettle();
      expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsOneWidget);
      // 閉じる
      Navigator.of(tester.element(find.text('🛡️ サーマル冷却＆省電力ステータス'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsNothing);

      // (B) BAND連携設定タイルタップ
      final bandTile = find.text('BAND連携・LIVE配信設定');
      await tester.scrollUntilVisible(
        bandTile,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(bandTile);
      await tester.pumpAndSettle();
      expect(find.text('BANDグループ管理'), findsOneWidget);
      // ダイアログを開く
      await tester.tap(find.text('最初のBandグループを追加'));
      await tester.pumpAndSettle();
      expect(find.text('新しいBANDグループを追加'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('新しいBANDグループを追加'), findsNothing);
      // サブシートを閉じる
      Navigator.of(tester.element(find.text('BANDグループ管理'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('BANDグループ管理'), findsNothing);

      // (C) Google解除ボタンタップ
      final unlinkButton = find.text('解除');
      await tester.scrollUntilVisible(
        unlinkButton,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(unlinkButton, findsOneWidget);
      await tester.tap(unlinkButton);
      await tester.pumpAndSettle();
      expect(find.text('Google連携を解除しますか？'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('Google連携を解除しますか？'), findsNothing);

      // (D) ログアウトタイルタップ
      final logoutTile = find.text('ログアウト');
      await tester.scrollUntilVisible(
        logoutTile,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(logoutTile);
      await tester.pumpAndSettle();
      expect(find.text('ログアウトしますか？'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('ログアウトしますか？'), findsNothing);
      expect(find.text('システム設定'), findsOneWidget);
    });

    testWidgets('2. チーム試合状況：BANDボタンでサブシート最前面表示 ＆ 進行中団体戦カード/先鋒タップでネスト遷移', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final liveMatch = MatchModel(
        id: 'live_match_senpo',
        tournamentId: 't1',
        matchType: '先鋒',
        order: 1,
        status: 'in_progress',
        redName: '道上剣友会A:山田',
        whiteName: '相手チーム02:選手',
        groupName: 'group_dantai_1',
      );

      final liveTeamStatus = TeamProgressStatus(
        teamName: '道上剣友会A',
        categoryName: '小学生低学年の部',
        currentCourtName: '第3試合場',
        matchupTitle: '団体戦：道上剣友会A vs 相手チーム02',
        tournamentId: 't1',
        targetGroupId: 'group_dantai_1',
        matches: [liveMatch],
        inProgressMatch: liveMatch,
        hasLiveMatch: true,
        completedCount: 0,
        totalCount: 5,
      );

      final router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    FloatingDockSheetManager.show(
                      context: context,
                      builder: (_) => const TeamMatchStatusScreen(
                        tournamentId: 't1',
                        isBottomSheet: true,
                      ),
                    );
                  },
                  child: const Text('Open Team Status Dock'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            settingsProvider.overrideWith(() => MockSettingsNotifier()),
            teamProgressListProvider.overrideWith((ref) => [liveTeamStatus]),
            matchListProvider.overrideWith((ref) => [liveMatch]),
            matchListByTournamentProvider(
              't1',
            ).overrideWith((ref) => Stream.value([liveMatch])),
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
            matchViewStateProvider('live_match_senpo').overrideWith(
              (ref) => MatchViewState(
                scoreText: '0 - 0',
                redScore: 0,
                whiteScore: 0,
                isEncho: false,
                winner: null,
                lastEventText: '',
                canUndo: false,
                statusText: '試合中',
                syncStatus: SyncStatus.synced,
                isViewOnly: false,
                isInputLocked: false,
                isAllDone: false,
                isTie: false,
                redCleanName: '山田',
                whiteCleanName: '選手',
              ),
            ),
            bandGroupsStreamProvider.overrideWith(
              (ref) => Stream.value([
                const BandGroupModel(
                  id: 'b1',
                  name: '低学年保護者',
                  url: 'https://band.us/123',
                  order: 0,
                ),
              ]),
            ),
            isarProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // ドックからチーム試合状況を開く
      await tester.tap(find.text('Open Team Status Dock'));
      await tester.pumpAndSettle();

      expect(find.text('チーム試合状況'), findsOneWidget);
      expect(find.text('道上剣友会A'), findsNWidgets(2));

      // (A) BANDボタンタップ ➔ BANDグループ選択サブシートが最前面に出ること
      await tester.tap(find.text('BAND'));
      await tester.pumpAndSettle();

      expect(find.text('BANDでLIVE配信・共有'), findsOneWidget);
      expect(find.text('低学年保護者'), findsOneWidget);
      // コピーのみで閉じる
      await tester.tap(find.text('コピーのみで閉じる'));
      await tester.pumpAndSettle();
      expect(find.text('BANDでLIVE配信・共有'), findsNothing);
      expect(find.text('チーム試合状況'), findsOneWidget);

      // (B) 「【先鋒】タップして記録を開く 👉」タップ ➔ シート内で MatchScreen にネスト遷移すること
      final senpoSection = find.text('タップして記録を開く 👉');
      expect(senpoSection, findsOneWidget);
      await tester.tap(senpoSection);
      await tester.pumpAndSettle();

      expect(find.byType(MatchScreen), findsOneWidget);
      expect(FloatingDockSheetManager.isOpen, isTrue);

      // MatchScreen の戻るボタン「＜」を押してチーム試合状況一覧に戻る
      final backButton = find.byIcon(Icons.arrow_back_ios_new);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(MatchScreen), findsNothing);
      expect(find.text('チーム試合状況'), findsOneWidget);

      // (C) カード全体タップ ➔ シート内で TeamScoreboardScreen（団体戦スコアボード）にネスト遷移すること
      await tester.tap(find.text('道上剣友会A').first);
      await tester.pumpAndSettle();

      expect(find.byType(TeamScoreboardScreen), findsOneWidget);
      expect(FloatingDockSheetManager.isOpen, isTrue);

      // スコアボードの戻るボタン「＜」を押して一覧に戻る
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.byType(TeamScoreboardScreen), findsNothing);
      expect(find.text('チーム試合状況'), findsOneWidget);
    });
  });
}
