import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/auth/presentation/screens/role_select_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/auth_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/routing/route_guards.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthGuard ライフサイクル＆セッション優先判定テスト', () {
    testWidgets('1. sessionが有効な場合、userがnullでも強制送還されずにchildを描画する', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
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
            home: AuthGuard(child: Scaffold(body: Text('🛡️ 運営画面コンテンツ'))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // childが描画され、RoleSelectScreenに弾かれないこと
      expect(find.text('🛡️ 運営画面コンテンツ'), findsOneWidget);
      expect(find.byType(RoleSelectScreen), findsNothing);
    });

    testWidgets('2. sessionがnullかつuserがnullの場合、RoleSelectScreenを表示する', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
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
            home: AuthGuard(child: Scaffold(body: Text('🛡️ 運営画面コンテンツ'))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // RoleSelectScreenが表示されること
      expect(find.byType(RoleSelectScreen), findsOneWidget);
      expect(find.text('🛡️ 運営画面コンテンツ'), findsNothing);
    });
  });
}

class _MockAuthSessionNotifier extends AuthSessionNotifier {
  _MockAuthSessionNotifier(UserSession? initialSession) {
    state = initialSession;
  }
}
