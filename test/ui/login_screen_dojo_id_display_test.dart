import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/auth/presentation/screens/role_select_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/login_screen.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';

void main() {
  group('🛡️ Dojo ID Display & Dark Mode Regression Tests', () {
    testWidgets(
      '1. Verify active Dojo ID is clearly displayed on LoginScreen (Light & Dark Mode)',
      (WidgetTester tester) async {
        const testDojoId = 'tokyo_kendo_dojo_2026';

        // Light Mode Test
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => testDojoId),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const LoginScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('接続中の道場ID'), findsOneWidget);
        expect(find.text(testDojoId), findsOneWidget);

        // Dark Mode Test
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentDojoIdProvider.overrideWith((ref) => testDojoId),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const LoginScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('接続中の道場ID'), findsOneWidget);
        expect(find.text(testDojoId), findsOneWidget);
      },
    );

    testWidgets(
      '2. Verify 2-line Dojo ID card on RoleSelectScreen without overflow (Light & Dark Mode)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        const testDojoId = 'test204';

        // Light Mode Test on RoleSelectScreen
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => testDojoId),
              dojoRoomSyncProvider.overrideWith((ref) {}),
            ],
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const RoleSelectScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('接続中の道場ID (ルーム)'), findsOneWidget);
        expect(find.text(testDojoId), findsOneWidget);
        expect(find.text('変更'), findsOneWidget);

        // Dark Mode Test on RoleSelectScreen
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              currentDojoIdProvider.overrideWith((ref) => testDojoId),
              dojoRoomSyncProvider.overrideWith((ref) {}),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const RoleSelectScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('接続中の道場ID (ルーム)'), findsOneWidget);
        expect(find.text(testDojoId), findsOneWidget);
        expect(find.text('変更'), findsOneWidget);
      },
    );
  });
}
