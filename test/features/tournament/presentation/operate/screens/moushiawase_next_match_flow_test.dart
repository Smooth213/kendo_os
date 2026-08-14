import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';

class MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'fallback_id',
        tournamentId: 'fallback_tourney',
        matchType: '錬成会',
        redName: '赤',
        whiteName: '白',
        status: 'waiting',
      ),
    );
  });

  late MockMatchApplicationService mockMatchAppService;

  setUp(() {
    mockMatchAppService = MockMatchApplicationService();
    when(
      () => mockMatchAppService.claimScorer(any(), any()),
    ).thenAnswer((_) => Future.value(true));
    when(
      () => mockMatchAppService.releaseScorer(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockMatchAppService.approveMatch(any()),
    ).thenAnswer((_) async {});
    when(() => mockMatchAppService.saveMatch(any())).thenAnswer((_) async {});
  });

  group('🛡️ 申し合わせ・錬成会「次の申し合わせ・錬成試合を追加設定」ボタン機能性検証テスト', () {
    testWidgets(
      '1. 申し合わせ試合終了ダイアログ内の「⚔️ 次の申し合わせ・錬成試合を追加設定」ボタンを押すと、404エラーにならず選手選択ボトムシートが正しく開くこと',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1366, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final customSettings = SettingsModel(
          showConfirmDialog: false,
          confirmBehavior: 'single',
        );

        SharedPreferences.setMockInitialValues({
          'kendo_sync_settings': jsonEncode(customSettings.toJson()),
        });
        final prefs = await SharedPreferences.getInstance();

        const moushiawaseMatch = MatchModel(
          id: 'moushiawase_match_1',
          tournamentId: 'tourney_1',
          matchType: '錬成会',
          matchScene: 'moushiawase',
          groupName: 'Aコート',
          category: '小学生高学年',
          redName: '東京道場 : 山田',
          whiteName: '京都道場 : 田中',
          status: 'finished',
          order: 1.0,
        );

        final router = GoRouter(
          initialLocation: '/match/moushiawase_match_1',
          routes: [
            GoRoute(
              path: '/match/:id',
              builder: (context, state) =>
                  MatchScreen(matchId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/home/:id',
              builder: (context, state) =>
                  const Scaffold(body: Text('大会ホーム画面')),
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            matchApplicationServiceProvider.overrideWithValue(
              mockMatchAppService,
            ),
            matchListProvider.overrideWith((ref) => [moushiawaseMatch]),
            registeredTeamsProvider('tourney_1').overrideWith(
              (ref) => Stream.value([
                const TeamModel(
                  id: 't1',
                  tournamentId: 'tourney_1',
                  teamName: '東京道場',
                  category: '小学生高学年',
                  playerNames: ['山田', '佐藤', '鈴木'],
                ),
                const TeamModel(
                  id: 't2',
                  tournamentId: 'tourney_1',
                  teamName: '京都道場',
                  category: '小学生高学年',
                  playerNames: ['田中', '高橋', '伊藤'],
                ),
              ]),
            ),
            playerListProvider.overrideWith((ref) => Stream.value([])),
            matchViewStateProvider('moushiawase_match_1').overrideWith(
              (ref) => MatchViewState(
                scoreText: '2 - 1',
                redScore: 2,
                whiteScore: 1,
                isEncho: false,
                winner: 'red',
                lastEventText: '赤 面 (一本勝負)',
                canUndo: true,
                statusText: '終了',
                syncStatus: SyncStatus.synced,
                isViewOnly: false,
                isInputLocked: false,
                isAllDone: true,
                isTie: false,
                redCleanName: '山田',
                whiteCleanName: '田中',
              ),
            ),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
            isarProvider.overrideWithValue(null),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              theme: ThemeData.light(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 試合終了状態の確定ボタン（「確定・大会ホームへ」）が存在することを確認
        final confirmBtn = find.text('確定・大会ホームへ');
        expect(confirmBtn, findsOneWidget);

        // 「確定・大会ホームへ」をタップして試合を確定し、ナビゲーションダイアログを表示
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // 対戦終了ダイアログが表示され、申し合わせ用の追加設定ボタンが存在することを確認
        expect(find.text('対戦終了'), findsOneWidget);
        final nextMoushiawaseBtn = find.text('⚔️ 次の申し合わせ・錬成試合を追加設定');
        expect(nextMoushiawaseBtn, findsOneWidget);

        // 「⚔️ 次の申し合わせ・錬成試合を追加設定」ボタンをタップ
        await tester.tap(nextMoushiawaseBtn);
        await tester.pumpAndSettle();

        // 404エラーにならず、選手選択ボトムシートが正常に開いたことを検証
        expect(find.text('次の試合を追加 (錬成会)'), findsOneWidget);
        expect(find.text('東京道場 の選手を選択:'), findsOneWidget);
        expect(find.text('京都道場 の選手を選択:'), findsOneWidget);
        expect(find.text('決定して開始'), findsOneWidget);

        // 「決定して開始」ボタンをタップして新試合作成フローを実行
        await tester.tap(find.text('決定して開始'));
        await tester.pump();

        // saveMatch が呼ばれたことを検証
        verify(() => mockMatchAppService.saveMatch(any())).called(1);
      },
    );
  });
}
