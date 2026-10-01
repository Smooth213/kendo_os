import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/match_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_match_screen.dart';
import 'package:kendo_os/features/viewer/providers/viewer_view_state_provider.dart';
import 'package:kendo_os/security/feature_gate.dart';
import 'package:kendo_os/security/role_permissions.dart';
import 'package:kendo_os/security/security_level.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/security_level_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/routing/match_router.dart';
import '../helpers/test_app.dart';

class _TestAuthSessionNotifier extends AuthSessionNotifier {
  _TestAuthSessionNotifier(UserSession? initial) {
    state = initial;
  }

  void setSession(UserSession? session) {
    state = session;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('[E2E] 複合動的権限降格およびリアルタイム操作遮断テスト', () {
    testWidgets('試合操作中にOperatorからViewerへ降格された際に即時操作遮断され観戦画面へ切り替わること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final operatorSession = UserSession(
        role: UserRole.operator,
        loginAt: now,
        expiresAt: now.add(const Duration(hours: 12)),
      );

      final authNotifier = _TestAuthSessionNotifier(operatorSession);
      const matchId = 'match_dynamic_e2e_1';
      const mockMatch = MatchModel(
        id: matchId,
        tournamentId: 'tourney_dynamic_1',
        matchType: '個人戦',
        redName: '赤選手',
        whiteName: '白選手',
        status: 'waiting',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          isarProvider.overrideWithValue(null),
          syncEngineProvider.overrideWithValue(FakeSyncEngine()),
          dojoRoomSyncProvider.overrideWith((ref) {}),
          viewerMatchProjectionProvider(
            matchId,
          ).overrideWith((ref) => Stream.value(null)),
          matchListByTournamentProvider.overrideWith(
            (ref, id) => Stream.value(<MatchModel>[]),
          ),
          matchListProvider.overrideWith((ref) => [mockMatch]),
          matchViewStateProvider(matchId).overrideWith(
            (ref) => MatchViewState(
              scoreText: '0 - 0',
              redScore: 0,
              whiteScore: 0,
              isEncho: false,
              winner: null,
              lastEventText: '',
              canUndo: false,
              statusText: '待機中',
              syncStatus: SyncStatus.synced,
              isViewOnly: false,
              isInputLocked: false,
              isAllDone: false,
              isTie: false,
              redCleanName: '赤選手',
              whiteCleanName: '白選手',
            ),
          ),
          authSessionProvider.overrideWith((ref) => authNotifier),
          currentUserRoleProvider.overrideWith((ref) {
            final sess = ref.watch(authSessionProvider);
            return sess?.role ?? UserRole.viewer;
          }),
          securityLevelProvider.overrideWith((ref) => SecurityLevel.event),
        ],
      );

      // 初回権限判定
      expect(
        FeatureGate.canOperateMatch(UserRole.operator, SecurityLevel.event),
        isTrue,
      );
      expect(RolePermissions.isViewer(UserRole.operator), isFalse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MatchRouter(matchId: matchId)),
        ),
      );

      await tester.pump();

      // 操作可能画面（MatchScreen）が表示されていること
      expect(find.byType(MatchScreen), findsOneWidget);
      expect(find.byType(ViewerMatchScreen), findsNothing);

      // 2. 本部・管理者によるリアルタイム降格（Viewerへ強制変更）
      authNotifier.setSession(
        UserSession(
          role: UserRole.viewer,
          loginAt: now,
          expiresAt: now.add(const Duration(minutes: 30)),
        ),
      );

      // 降格後の権限判定
      expect(
        FeatureGate.canOperateMatch(UserRole.viewer, SecurityLevel.event),
        isFalse,
      );
      expect(RolePermissions.isViewer(UserRole.viewer), isTrue);

      await tester.pump();

      // 即座にMatchScreenからViewerMatchScreenへ切り替わること
      expect(find.byType(ViewerMatchScreen), findsOneWidget);
      expect(find.byType(MatchScreen), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
    });

    testWidgets('大会セキュリティレベルがLockedへ緊急変更された場合に全入力が遮断されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final adminSession = UserSession(
        role: UserRole.admin,
        loginAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );

      final authNotifier = _TestAuthSessionNotifier(adminSession);
      const matchId = 'match_dynamic_e2e_2';
      const mockMatch = MatchModel(
        id: matchId,
        tournamentId: 'tourney_dynamic_2',
        matchType: '個人戦',
        redName: '赤選手',
        whiteName: '白選手',
        status: 'waiting',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          isarProvider.overrideWithValue(null),
          syncEngineProvider.overrideWithValue(FakeSyncEngine()),
          dojoRoomSyncProvider.overrideWith((ref) {}),
          viewerMatchProjectionProvider(
            matchId,
          ).overrideWith((ref) => Stream.value(null)),
          matchListByTournamentProvider.overrideWith(
            (ref, id) => Stream.value(<MatchModel>[]),
          ),
          matchListProvider.overrideWith((ref) => [mockMatch]),
          matchViewStateProvider(matchId).overrideWith(
            (ref) => MatchViewState(
              scoreText: '0 - 0',
              redScore: 0,
              whiteScore: 0,
              isEncho: false,
              winner: null,
              lastEventText: '',
              canUndo: false,
              statusText: '待機中',
              syncStatus: SyncStatus.synced,
              isViewOnly: false,
              isInputLocked: false,
              isAllDone: false,
              isTie: false,
              redCleanName: '赤選手',
              whiteCleanName: '白選手',
            ),
          ),
          authSessionProvider.overrideWith((ref) => authNotifier),
          currentUserRoleProvider.overrideWith((ref) {
            final sess = ref.watch(authSessionProvider);
            return sess?.role ?? UserRole.viewer;
          }),
          securityLevelProvider.overrideWith((ref) => SecurityLevel.event),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MatchRouter(matchId: matchId)),
        ),
      );

      await tester.pump();
      expect(find.byType(MatchScreen), findsOneWidget);

      // 緊急ロックダウン発動
      container.read(securityLevelProvider.notifier).state =
          SecurityLevel.locked;

      await tester.pump();

      // 管理者であってもLockdown時は操作画面が遮断されViewer画面へ切り替わること
      expect(find.byType(ViewerMatchScreen), findsOneWidget);
      expect(find.byType(MatchScreen), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
    });
  });
}
