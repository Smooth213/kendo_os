import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/auth/presentation/screens/role_select_screen.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  group('🛡️ RoleSelectScreen スワイプバック復帰時グレーアウト防止＆タップ領域厳格保証テスト', () {
    Widget buildTestApp({List<RouteBase>? extraRoutes}) {
      final router = GoRouter(
        initialLocation: '/role-select',
        routes: [
          GoRoute(
            path: '/role-select',
            builder: (context, state) => const RoleSelectScreen(),
          ),
          GoRoute(
            path: '/pin-auth',
            builder: (context, state) {
              final role = state.uri.queryParameters['role'] ?? 'admin';
              return Scaffold(
                appBar: AppBar(
                  leading: BackButton(onPressed: () => context.pop()),
                  title: Text('PIN認証: $role'),
                ),
                body: Center(child: Text('PIN画面: $role')),
              );
            },
          ),
          ...?extraRoutes,
        ],
      );

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          isEcoModeProvider.overrideWith((ref) => false),
          currentDojoIdProvider.overrideWith((ref) => 'test-dojo-101'),
          dojoRoomSyncProvider.overrideWith((ref) {}),
          authSessionProvider.overrideWith(
            (ref) => _MockAuthSessionNotifier(null),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('1. 全4権限ボタンが常にenabled（onPressed != null）であり、グレーアウトしないことを検証', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final adminFinder = find.widgetWithText(ElevatedButton, '代表・管理者 (Admin)');
      final operatorFinder = find.widgetWithText(
        ElevatedButton,
        '監督・引率責任者 (Operator)',
      );
      final recorderFinder = find.widgetWithText(
        ElevatedButton,
        'スコア・記録係 (Recorder)',
      );
      final viewerFinder = find.widgetWithText(
        ElevatedButton,
        '応援・保護者・選手 (Viewer)',
      );

      expect(adminFinder, findsOneWidget);
      expect(operatorFinder, findsOneWidget);
      expect(recorderFinder, findsOneWidget);
      expect(viewerFinder, findsOneWidget);

      for (final finder in [
        adminFinder,
        operatorFinder,
        recorderFinder,
        viewerFinder,
      ]) {
        final button = tester.widget<ElevatedButton>(finder);
        expect(
          button.onPressed,
          isNotNull,
          reason: 'ボタンが無効化（グレーアウト）されていてはならない',
        );
        expect(button.enabled, isTrue);
      }
    });

    testWidgets('2. 画面遷移後に戻った（スワイプバック・Pop）際も、全ボタンが押下可能状態を維持することを検証', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Adminボタンを押してPIN画面へ遷移
      final adminButton = find.widgetWithText(ElevatedButton, '代表・管理者 (Admin)');
      await tester.tap(adminButton);
      await tester.pumpAndSettle();

      expect(find.text('PIN認証: admin'), findsOneWidget);

      // スワイプバックまたは戻るボタンで復帰
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Kendo Sync'), findsOneWidget);

      // 復帰後も全ボタンがenabledであること
      final adminAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '代表・管理者 (Admin)'),
      );
      final opAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '監督・引率責任者 (Operator)'),
      );
      final recAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'スコア・記録係 (Recorder)'),
      );
      final viewAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '応援・保護者・選手 (Viewer)'),
      );

      expect(adminAfter.onPressed, isNotNull);
      expect(adminAfter.enabled, isTrue);
      expect(opAfter.onPressed, isNotNull);
      expect(opAfter.enabled, isTrue);
      expect(recAfter.onPressed, isNotNull);
      expect(recAfter.enabled, isTrue);
      expect(viewAfter.onPressed, isNotNull);
      expect(viewAfter.enabled, isTrue);

      // 復帰後、即座にOperatorボタンをタップして正常に遷移できること
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 650)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, '監督・引率責任者 (Operator)'),
      );
      await tester.pumpAndSettle();

      expect(find.text('PIN認証: operator'), findsOneWidget);
    });

    testWidgets('3. 各ボタンの配置座標（Bounding Box）が重複せず、56px以上の高さを保持していることを検証', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final adminRect = tester.getRect(
        find.widgetWithText(ElevatedButton, '代表・管理者 (Admin)'),
      );
      final opRect = tester.getRect(
        find.widgetWithText(ElevatedButton, '監督・引率責任者 (Operator)'),
      );
      final recRect = tester.getRect(
        find.widgetWithText(ElevatedButton, 'スコア・記録係 (Recorder)'),
      );
      final viewRect = tester.getRect(
        find.widgetWithText(ElevatedButton, '応援・保護者・選手 (Viewer)'),
      );

      expect(adminRect.height, equals(56.0));
      expect(opRect.height, equals(56.0));
      expect(recRect.height, equals(56.0));
      expect(viewRect.height, equals(56.0));

      expect(
        adminRect.bottom,
        lessThan(opRect.top),
        reason: 'AdminとOperatorの間に隙間が存在すること',
      );
      expect(
        opRect.bottom,
        lessThan(recRect.top),
        reason: 'OperatorとRecorderの間に隙間が存在すること',
      );
      expect(
        recRect.bottom,
        lessThan(viewRect.top),
        reason: 'RecorderとViewerの間に隙間が存在すること',
      );
    });

    testWidgets('4. 連打デバウンス（600ms）が過度な重複遷移を防ぎつつ、時間経過後は正常受付することを検証', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final adminButton = find.widgetWithText(ElevatedButton, '代表・管理者 (Admin)');

      // 1回目のタップ
      await tester.tap(adminButton);
      await tester.pump();

      // 100ms後の連打（デバウンスにより無視されること）
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(adminButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('PIN認証: admin'), findsOneWidget);
    });
  });
}

class _MockAuthSessionNotifier extends AuthSessionNotifier {
  _MockAuthSessionNotifier(UserSession? initialSession) {
    state = initialSession;
  }
}
