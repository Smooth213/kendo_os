import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show tournamentProvider;
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';

import 'package:kendo_os/shared/infrastructure/services/notification_service.dart';

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> registerPushNotification({
    required String tournamentId,
    required bool isStaff,
  }) async {}

  @override
  Future<void> initializeNotification() async {}
}

class FakeFirebasePlatform extends FirebasePlatform {
  final Map<String, FirebaseAppPlatform> _apps = {};

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (!_apps.containsKey(name)) {
      throw FirebaseException(
        plugin: 'core',
        code: 'no-app',
        message:
            "No Firebase App '$name' has been created - call Firebase.initializeApp()",
      );
    }
    return _apps[name]!;
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final appName = name ?? defaultFirebaseAppName;
    final app = FakeFirebaseAppPlatform(
      appName,
      options ??
          const FirebaseOptions(
            apiKey: 'mock_key_123',
            appId: 'mock_app_123',
            messagingSenderId: 'mock_sender_123',
            projectId: 'mock_project_123',
          ),
    );
    _apps[appName] = app;
    return app;
  }

  @override
  List<FirebaseAppPlatform> get apps => _apps.values.toList();
}

class FakeFirebaseAppPlatform extends FirebaseAppPlatform {
  FakeFirebaseAppPlatform(super.name, super.options);
}

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class MockTeamRepository extends Mock implements TeamRepository {}

Future<void> ensureFirebaseInitialized() async {
  FirebasePlatform.instance = FakeFirebasePlatform();
  await Firebase.initializeApp();
}

/// レンダリング安全性テスト用データセット＆ヘルパー
class RenderingSafetyTestHelper {
  static const String testTournamentId = 'test_tour_safety_123';

  static TournamentModel createTestTournament() {
    return TournamentModel(
      id: testTournamentId,
      name: '安全性監査テスト大会',
      date: DateTime.now(),
      venue: '日本武道館',
      categories: const ['小学生の部', '中学生の部', '一般の部'],
      organizationId: 'dojo_safety_123',
    );
  }

  /// エッジケース混入の複合試合データ群
  static List<MatchModel> createEdgeCaseMatches() {
    return [
      MatchModel(
        id: 'm_edge_1',
        tournamentId: testTournamentId,
        category: '小学生の部',
        groupName: '道上剣友会A',
        redName: '道上剣友会A:先鋒 太郎',
        whiteName: '相手チーム:先鋒 次郎',
        matchType: '先鋒',
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
        order: 10.0,
        note: '[申合せ] 第1試合',
        rule: const MatchRule(isLeague: false),
      ),
      MatchModel(
        id: 'm_edge_2',
        tournamentId: testTournamentId,
        category: '小学生の部',
        groupName: '道上剣友会A',
        redName: '道上剣友会A:大将 三郎',
        whiteName: '相手チーム:大将 四郎',
        matchType: '大将',
        status: 'in_progress',
        redScore: 1,
        whiteScore: 1,
        order: 20.0,
        note: '第2試合',
        rule: const MatchRule(isLeague: false),
      ),
      MatchModel(
        id: 'm_edge_daihyo',
        tournamentId: testTournamentId,
        category: '小学生の部',
        groupName: '道上剣友会A',
        redName: '道上剣友会A:代表戦',
        whiteName: '相手チーム:代表戦',
        matchType: '代表戦',
        status: 'waiting',
        order: 30.0,
        note: '代表戦決定',
        rule: const MatchRule(isLeague: false),
      ),
      MatchModel(
        id: 'm_edge_individual',
        tournamentId: testTournamentId,
        category: '中学生の部',
        groupName: '',
        redName: '個人選手A',
        whiteName: '個人選手B',
        matchType: '個人戦',
        status: 'waiting',
        order: 40.0,
        note: 'コート未指定',
        rule: const MatchRule(isLeague: false),
      ),
    ];
  }

  /// 見出しコメント混入データ
  static List<MatchCommentModel> createTestComments() {
    return [
      MatchCommentModel(
        id: 'c_heading_1',
        tournamentId: testTournamentId,
        category: '小学生の部',
        groupName: '道上剣友会A',
        text: '【重要連絡】次の試合は第2コートです',
        order: 15.0,
      ),
    ];
  }

  static late SharedPreferences prefs;

  static Future<void> initialize() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await ensureFirebaseInitialized();
  }

  /// 共通 ProviderScope ラッパー
  static Widget buildTestWidget({
    required Widget child,
    List<MatchModel> matches = const [],
    List<MatchCommentModel> comments = const [],
    TournamentModel? tournament,
    UserRole role = UserRole.operator,
  }) {
    final effectiveTournament = tournament ?? createTestTournament();
    final mockLocal = MockLocalMatchRepository();
    when(
      () => mockLocal.watchLocalMatches(any()),
    ).thenAnswer((_) => Stream.value(matches));
    when(
      () => mockLocal.watchAllLocalMatches(),
    ).thenAnswer((_) => Stream.value(matches));
    when(
      () => mockLocal.saveMatchesBulk(any()),
    ).thenAnswer((_) => Future.value());

    final mockTournamentRepo = MockTournamentRepository();
    when(
      () => mockTournamentRepo.getTournamentStream(any()),
    ).thenAnswer((_) => Stream.value(effectiveTournament));
    when(
      () => mockTournamentRepo.watchTournaments(),
    ).thenAnswer((_) => Stream.value([effectiveTournament]));

    final mockPlayerRepo = MockPlayerRepository();
    when(
      () => mockPlayerRepo.watchCustomTeamNames(
        organization: any(named: 'organization'),
      ),
    ).thenAnswer((_) => Stream.value(<String>['道上剣友会A']));
    when(
      () => mockPlayerRepo.getPlayers(organization: any(named: 'organization')),
    ).thenAnswer((_) => Stream.value(<PlayerModel>[]));

    final mockTeamRepo = MockTeamRepository();
    when(
      () => mockTeamRepo.watchTeamsByTournament(any()),
    ).thenAnswer((_) => Stream.value(<TeamModel>[]));

    final mockSyncEngine = MockSyncEngine();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(body: child),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localMatchRepositoryProvider.overrideWithValue(mockLocal),
        tournamentRepositoryProvider.overrideWithValue(mockTournamentRepo),
        playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
        teamRepositoryProvider.overrideWithValue(mockTeamRepo),
        syncEngineProvider.overrideWithValue(mockSyncEngine),
        matchListProvider.overrideWith((ref) => matches),
        matchListByTournamentProvider.overrideWith(
          (ref, id) => Stream.value(matches),
        ),
        tournamentProvider.overrideWith(
          (ref, id) => Stream.value(effectiveTournament),
        ),
        commentStreamProvider.overrideWith(
          (ref, arg) => Stream.value(comments),
        ),
        registeredTeamsProvider.overrideWith(
          (ref, id) => Stream.value([
            TeamModel(
              id: 't_michiue',
              tournamentId: id,
              category: '小学生の部',
              teamName: '道上剣友会A',
            ),
          ]),
        ),
        customTeamNamesProvider.overrideWith((ref) => Stream.value(['道上剣友会A'])),
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
        dojoRoomSyncProvider.overrideWithValue(null),
        activeRoleProvider.overrideWithValue(
          role == UserRole.viewer ? Role.viewer : Role.admin,
        ),
        permissionProvider.overrideWith(
          (ref) =>
              PermissionState(role: role, isReadOnly: role == UserRole.viewer),
        ),
        currentUserRoleProvider.overrideWithValue(role),
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        isarProvider.overrideWithValue(null),
        currentDojoIdProvider.overrideWith((ref) => 'dojo_safety_123'),
        currentTournamentIdProvider.overrideWith((ref) => testTournamentId),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(
          brightness: Brightness.light,
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
        ),
      ),
    );
  }
}
