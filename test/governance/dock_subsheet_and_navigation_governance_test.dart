import 'dart:io';
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
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
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
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSettingsNotifier extends SettingsNotifier {
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
          if (methodCall.method == 'Clipboard.setData' ||
              methodCall.method == 'Clipboard.getData') {
            return methodCall.method == 'Clipboard.getData'
                ? <String, dynamic>{'text': ''}
                : null;
          }
          return null;
        });
  });

  group('🛡️ 【ガバナンス監査 18/18】ドックボトムシート サブシート最前面表示 ＆ ネスト遷移 永久保証テスト', () {
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

    // =========================================================================
    // 1. 静的コード規約ガード（リグレッション防止）
    // =========================================================================
    test(
      '1. [静的規約] TeamStatusCard で FloatingDockSheetManager.close() が呼ばれていないこと',
      () {
        final file = File(
          'lib/features/tournament/presentation/operate/components/court_status/team_status_card.dart',
        );
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();

        // カードタップ時の即時 close は context 破棄バグを引き起こすため禁止
        expect(
          content.contains('FloatingDockSheetManager.close'),
          isFalse,
          reason:
              'TeamStatusCard 内で FloatingDockSheetManager.close() を呼ぶと'
              'ネスト遷移前に context が破棄されるため、絶対に禁止です。',
        );
      },
    );

    test(
      '2. [静的規約] app_bottom_sheet.dart / app_dialog.dart に DockSheetScope 判定が存在すること',
      () {
        final sheetFile = File('lib/shared/widgets/app_bottom_sheet.dart');
        final dialogFile = File('lib/shared/widgets/app_dialog.dart');
        expect(sheetFile.existsSync(), isTrue);
        expect(dialogFile.existsSync(), isTrue);

        final sheetContent = sheetFile.readAsStringSync();
        final dialogContent = dialogFile.readAsStringSync();

        expect(
          sheetContent.contains('DockSheetScope.of(context)'),
          isTrue,
          reason:
              'app_bottom_sheet.dart はドックシート内の判定（DockSheetScope）を持つ必要があります。',
        );
        expect(
          dialogContent.contains('DockSheetScope.of(context)'),
          isTrue,
          reason: 'app_dialog.dart はドックシート内の判定（DockSheetScope）を持つ必要があります。',
        );
      },
    );

    test('3. [静的規約] settings_screen.dart にボトムシート用 Navigator が存在すること', () {
      final file = File(
        'lib/features/tournament/presentation/operate/settings_screen.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(
        content.contains('Navigator(') && content.contains('navKey'),
        isTrue,
        reason: 'settings_screen.dart はボトムシート展開時に内部 Navigator を保持する必要があります。',
      );
    });

    // =========================================================================
    // 2. 動的ウィジェット検証：ドックシート内からの showAppBottomSheet / showAppDialog
    // =========================================================================
    testWidgets('4. [動的検証] DockSheetScope 内のモーダル呼び出しが最前面で動作すること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockDraggableSheet(
              builder: (sheetContext, scrollController) {
                return Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute(
                    builder: (innerContext) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              showAppBottomSheet(
                                context: innerContext,
                                builder: (_) => const SizedBox(
                                  height: 200,
                                  child: Text('Front Subsheet Content'),
                                ),
                              );
                            },
                            child: const Text('Open SubSheet'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showAppDialog(
                                context: innerContext,
                                builder: (_) => const AlertDialog(
                                  title: Text('Front Dialog Title'),
                                ),
                              );
                            },
                            child: const Text('Open Dialog'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // サブシートを開く
      await tester.tap(find.text('Open SubSheet'));
      await tester.pumpAndSettle();
      expect(find.text('Front Subsheet Content'), findsOneWidget);

      // 閉じる
      Navigator.of(tester.element(find.text('Front Subsheet Content'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Front Subsheet Content'), findsNothing);

      // ダイアログを開く
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Front Dialog Title'), findsOneWidget);

      // 閉じる
      Navigator.of(tester.element(find.text('Front Dialog Title'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Front Dialog Title'), findsNothing);
    });

    // =========================================================================
    // 3. システム設定ドックシート：全サブモーダル・ダイアログ最前面表示＆復帰
    // =========================================================================
    testWidgets('5. [システム設定] BAND設定・サーマル・Google解除・ログアウトが最前面で動作すること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final rootNavKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: rootNavKey,
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
                      builder: (_) => SettingsScreen(
                        isBottomSheet: true,
                        onFullScreen: () {},
                      ),
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
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            bandGroupsStreamProvider.overrideWith((ref) => Stream.value([])),
            isGoogleLinkedProvider.overrideWith((ref) => true),
            linkedGoogleEmailProvider.overrideWith((ref) => 'test@example.com'),
            linkedGoogleUidProvider.overrideWith((ref) => 'uid123'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings Dock'));
      await tester.pumpAndSettle();
      expect(find.text('システム設定'), findsOneWidget);

      // (A) サーマル冷却
      await tester.tap(find.text('サーマル冷却・省電力制御'));
      await tester.pumpAndSettle();
      expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsOneWidget);
      Navigator.of(tester.element(find.text('🛡️ サーマル冷却＆省電力ステータス'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsNothing);

      // (B) BAND設定
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
      Navigator.of(tester.element(find.text('BANDグループ管理'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('BANDグループ管理'), findsNothing);

      // (C) Google解除
      final unlinkButton = find.text('解除');
      expect(unlinkButton, findsOneWidget);
      await tester.tap(unlinkButton);
      await tester.pumpAndSettle();
      expect(find.text('Google連携を解除しますか？'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('Google連携を解除しますか？'), findsNothing);

      // (D) ログアウト
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
    });

    // =========================================================================
    // 4. チーム試合状況ドックシート：ネスト遷移＆アンマウント禁止
    // =========================================================================
    testWidgets('6. [チーム試合状況] BANDサブシート最前面表示 ＆ カードタップ時ネスト遷移（アンマウント防止）', (
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

      final rootNavKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: rootNavKey,
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
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
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

      await tester.tap(find.text('Open Team Status Dock'));
      await tester.pumpAndSettle();

      expect(find.text('チーム試合状況'), findsOneWidget);

      // (A) BANDボタンタップ ➔ BANDグループ選択サブシートが最前面に出ること
      await tester.tap(find.text('BAND'));
      await tester.pumpAndSettle();
      expect(find.text('BANDでLIVE配信・共有'), findsOneWidget);
      await tester.tap(find.text('コピーのみで閉じる'));
      await tester.pumpAndSettle();
      expect(find.text('BANDでLIVE配信・共有'), findsNothing);

      // (B) 「【先鋒】タップして記録を開く 👉」タップ ➔ シート内で MatchScreen にネスト遷移
      final senpoSection = find.text('タップして記録を開く 👉');
      expect(senpoSection, findsOneWidget);
      await tester.tap(senpoSection);
      await tester.pumpAndSettle();

      expect(find.byType(MatchScreen), findsOneWidget);
      expect(FloatingDockSheetManager.isOpen, isTrue); // ドックはアンマウントされずに開いたまま

      // 「＜」でチーム試合状況一覧に戻る
      final backButton = find.byIcon(Icons.arrow_back_ios_new);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(MatchScreen), findsNothing);
      expect(find.text('チーム試合状況'), findsOneWidget);

      // (C) カード全体タップ ➔ シート内で TeamScoreboardScreen にネスト遷移
      await tester.tap(find.text('道上剣友会A').first);
      await tester.pumpAndSettle();

      expect(find.byType(TeamScoreboardScreen), findsOneWidget);
      expect(FloatingDockSheetManager.isOpen, isTrue); // ドックはアンマウントされずに開いたまま

      // スコアボードの「＜」で一覧に戻る
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.byType(TeamScoreboardScreen), findsNothing);
      expect(find.text('チーム試合状況'), findsOneWidget);
    });
  });
}
