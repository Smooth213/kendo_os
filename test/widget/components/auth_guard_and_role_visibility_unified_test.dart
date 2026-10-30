import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/auth/presentation/screens/role_select_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/start_screen.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/routing/route_guards.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthSessionNotifier extends AuthSessionNotifier {
  _MockAuthSessionNotifier(UserSession? initialSession) {
    state = initialSession;
  }
}

void main() {
  group('[Widget] 認証ガード ＆ ロール別UI露出規制 統合テスト', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('sessionが有効な場合、userがnullでも強制送還されずにchildを描画すること', (
      tester,
    ) async {
      final validSession = UserSession(
        role: UserRole.admin,
        loginAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authSessionProvider.overrideWith(
              (ref) => _MockAuthSessionNotifier(validSession),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            currentDojoIdProvider.overrideWith((ref) => 'test204'),
            dojoRoomSyncProvider.overrideWith((ref) {}),
          ],
          child: const MaterialApp(
            home: AuthGuard(child: Scaffold(body: Text('運営画面コンテンツ'))),
          ),
        ),
      );

      await tester.safePumpAndSettle();

      expect(find.text('運営画面コンテンツ'), findsOneWidget);
      expect(find.byType(RoleSelectScreen), findsNothing);
    });

    testWidgets('sessionがnullかつuserがnullの場合、RoleSelectScreenを表示すること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authSessionProvider.overrideWith(
              (ref) => _MockAuthSessionNotifier(null),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            currentDojoIdProvider.overrideWith((ref) => 'test204'),
            dojoRoomSyncProvider.overrideWith((ref) {}),
          ],
          child: const MaterialApp(
            home: AuthGuard(child: Scaffold(body: Text('運営画面コンテンツ'))),
          ),
        ),
      );

      await tester.safePumpAndSettle();

      expect(find.byType(RoleSelectScreen), findsOneWidget);
      expect(find.text('運営画面コンテンツ'), findsNothing);
    });

    Widget createTestWidget(UserRole role) {
      return ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWith((ref) => role),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: StartScreen()),
      );
    }

    testWidgets('Viewerモード時、新規作成ボタンが画面上から物理排除されていること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(UserRole.viewer));
      await tester.safePumpAndSettle();
      expect(find.text('新しい大会\nを作る'), findsNothing);
    });

    testWidgets('Operatorモード時、新規作成ボタンが正しく画面に露出すること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(UserRole.operator));
      await tester.safePumpAndSettle();
      expect(find.text('新しい大会\nを作る'), findsOneWidget);
    });

    testWidgets('Recorder（記録者）モード時、システム設定へのアクセス経路（歯車）が物理排除されていること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(UserRole.recorder));
      await tester.safePumpAndSettle();
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets(
      'Operator（運営者）モード時、Admin特権である一括破棄（delete_sweep）などの危険機能が露出しないこと',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(UserRole.operator));
        await tester.safePumpAndSettle();
        expect(find.byIcon(Icons.delete_sweep), findsNothing);
      },
    );
  });
}
