import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:kendo_os/main.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart'
    as legacy_sync;

import 'package:kendo_os/features/viewer/screens/viewer_bunaiksen_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MockUser extends Mock implements firebase_auth.User {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockLegacySyncEngine extends Mock implements legacy_sync.SyncEngine {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class MockAuthSessionNotifier extends AuthSessionNotifier {
  MockAuthSessionNotifier(UserSession? initialSession) {
    state = initialSession;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(<MatchModel>[]);
    registerFallbackValue(
      const MatchModel(id: '', matchType: '', redName: '', whiteName: ''),
    );
  });

  group('🛡️ Viewer Bunaiksen Calendar Integration Tests', () {
    late MockTournamentRepository mockTournamentRepo;
    late MockPlayerRepository mockPlayerRepo;
    late MockSyncEngine mockSyncEngine;
    late MockLegacySyncEngine mockLegacySyncEngine;
    late MockLocalMatchRepository mockLocalRepo;
    late List<MatchModel> mockMatchesToday;
    late List<MatchModel> mockMatchesPast;
    late List<MatchModel> allMatches;
    late TournamentModel mockTournamentToday;
    late TournamentModel mockTournamentPast;

    final now = DateTime.now();
    final todayId = 'bunaiksen_${DateFormat('yyyyMMdd').format(now)}';

    // Day in the same month that is in the past (yesterday or 2 days ago depending on date)
    final targetDate = now.day > 1
        ? now.subtract(const Duration(days: 1))
        : now.subtract(const Duration(days: 2));
    final pastId = 'bunaiksen_${DateFormat('yyyyMMdd').format(targetDate)}';

    setUp(() {
      mockTournamentRepo = MockTournamentRepository();
      mockPlayerRepo = MockPlayerRepository();
      mockSyncEngine = MockSyncEngine();
      mockLegacySyncEngine = MockLegacySyncEngine();
      mockLocalRepo = MockLocalMatchRepository();

      mockMatchesToday = [
        MatchModel(
          id: 'test_match_today',
          tournamentId: todayId,
          category: '部内戦',
          redName: '本日赤選手',
          whiteName: '本日白選手',
          matchType: '個人戦',
          status: 'waiting',
          order: 1.0,
          note: '本日試合',
        ),
      ];

      mockMatchesPast = [
        MatchModel(
          id: 'test_match_past',
          tournamentId: pastId,
          category: '部内戦',
          redName: '過去赤選手',
          whiteName: '過去白選手',
          matchType: '個人戦',
          status: 'waiting',
          order: 1.0,
          note: '過去試合',
        ),
      ];

      allMatches = [...mockMatchesToday, ...mockMatchesPast];

      mockTournamentToday = TournamentModel(
        id: todayId,
        name: '今日の特設部内戦',
        date: now,
        venue: '道場',
        categories: const ['部内戦'],
        organizationId: 'dojo_123',
      );

      mockTournamentPast = TournamentModel(
        id: pastId,
        name: '過去の特設部内戦',
        date: targetDate,
        venue: '道場',
        categories: const ['部内戦'],
        organizationId: 'dojo_123',
      );

      when(
        () => mockTournamentRepo.getTournamentStream(todayId),
      ).thenAnswer((_) => Stream.value(mockTournamentToday));
      when(
        () => mockTournamentRepo.getTournamentStream(pastId),
      ).thenAnswer((_) => Stream.value(mockTournamentPast));
      when(
        () => mockPlayerRepo.watchCustomTeamNames(),
      ).thenAnswer((_) => Stream.value(<String>[]));
      when(() => mockLocalRepo.watchLocalMatches(any())).thenAnswer((
        invocation,
      ) {
        final id = invocation.positionalArguments[0] as String;
        if (id == todayId) return Stream.value(mockMatchesToday);
        if (id == pastId) return Stream.value(mockMatchesPast);
        return Stream.value([]);
      });
      when(
        () => mockLocalRepo.watchAllLocalMatches(),
      ).thenAnswer((_) => Stream.value(allMatches));
      when(
        () => mockLocalRepo.saveMatchesBulk(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockLocalRepo.getPendingMatches(),
      ).thenAnswer((_) => Future.value(<MatchModel>[]));
      when(
        () => mockLegacySyncEngine.syncNow(),
      ).thenAnswer((_) => Future.value());
    });

    testWidgets('1. 観客席カレンダー切り替え：過去日付の試合が正しくロードされ、試合作成ボタンがないこと', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
            playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
            syncEngineProvider.overrideWithValue(mockSyncEngine),
            legacy_sync.syncEngineProvider.overrideWithValue(
              mockLegacySyncEngine,
            ),
            localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
            dojoRoomSyncProvider.overrideWithValue(null),
            commentStreamProvider.overrideWith((ref, arg) => Stream.value([])),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: true,
                canManageTournament: false,
                canCreateMatch: false,
                canChangeSettings: false,
                canDeleteData: false,
              ),
            ),
            currentDojoIdProvider.overrideWith((ref) => 'dojo_123'),
            currentTournamentIdProvider.overrideWith((ref) => todayId),
            matchListProvider.overrideWith((ref) => allMatches),
            matchListByTournamentProvider.overrideWith(
              (ref, id) => Stream.value(
                id == todayId ? mockMatchesToday : mockMatchesPast,
              ),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
            authSessionProvider.overrideWith(
              (ref) => MockAuthSessionNotifier(
                UserSession(
                  role: UserRole.viewer, // ★ 観客権限
                  loginAt: DateTime.now(),
                  expiresAt: DateTime.now().add(const Duration(hours: 1)),
                ),
              ),
            ),
            firestoreRoleStreamProvider.overrideWith(
              (ref) => Stream.value(UserRole.viewer),
            ),
          ],
          child: const KendoOSApp(),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // GoRouterを取得して初期観客用部内戦ホームへ遷移
      final routerContext = tester.element(find.byType(Navigator).first);
      GoRouter.of(
        routerContext,
      ).go('/bunaiksen-viewer-home/$todayId?role=viewer&dojoId=dojo_123');

      await tester.pump();
      await tester.pumpAndSettle();

      // ViewerBunaiksenHomeScreen が表示されていること
      expect(find.byType(ViewerBunaiksenHomeScreen), findsOneWidget);
      // 今日の試合が表示されていること
      expect(find.text('本日赤選手'), findsOneWidget);
      expect(find.text('過去赤選手'), findsNothing);

      // 「試合作成」を司る FloatingActionButton が存在しないこと
      expect(find.byType(FloatingActionButton), findsNothing);

      // AppBar内のカレンダーアイコンをタップ
      final calendarButton = find.byIcon(Icons.calendar_month);
      expect(calendarButton, findsOneWidget);
      await tester.tap(calendarButton);
      await tester.pumpAndSettle();

      // カレンダーダイアログ(DatePickerDialog)が表示されること
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // 前の月へ移動（targetDateが前月の場合は前の月ボタンをタップ）
      if (targetDate.month != now.month) {
        final prevMonthButton = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              (widget.tooltip == 'Previous month' || widget.tooltip == '前の月'),
        );
        expect(prevMonthButton, findsOneWidget);
        await tester.tap(prevMonthButton);
        await tester.pumpAndSettle();
      }

      // targetDateの日のセルを探してタップ
      final dayStr = targetDate.day.toString();
      final dayFinder = find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text(dayStr),
      );
      // カレンダーセルを確実に特定してタップ
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();

      // 「OK」ボタンをタップして確定
      final okButton = find.text('OK');
      expect(okButton, findsOneWidget);
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      // 遷移後の ViewerBunaiksenHomeScreen で過去の試合が表示されていること
      expect(find.byType(ViewerBunaiksenHomeScreen), findsOneWidget);
      expect(find.text('過去赤選手'), findsOneWidget);
      expect(find.text('本日赤選手'), findsNothing);

      // 過去日付が ViewerBunaiksenHomeScreen に引き渡されていることをアサーション
      final viewerScreen = tester.widget<ViewerBunaiksenHomeScreen>(
        find.byType(ViewerBunaiksenHomeScreen),
      );
      expect(viewerScreen.tournamentId, pastId);

      // 「試合作成」ボタンは引き続き存在しないこと
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
