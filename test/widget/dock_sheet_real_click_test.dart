import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/auth/application/google_auth_service.dart';
import 'package:kendo_os/features/band/presentation/providers/band_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/settings/settings_google_auth_tile.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🥋 ドックボトムシート タップ操作＆子モーダル前面表示 実動作テスト', () {
    tearDown(() async {
      if (FloatingDockSheetManager.isOpen) {
        await FloatingDockSheetManager.close(immediate: true);
      }
    });

    testWidgets('1. 大会ホームのドックから設定を開き、全ボタンがタップ可能で最前面に開くこと', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
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
                        onFullScreen: () {
                          FloatingDockSheetManager.close(immediate: true);
                          context.push('/settings');
                        },
                      ),
                    );
                  },
                  child: const Text('Open Settings Dock'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            bandGroupsStreamProvider.overrideWith((ref) => Stream.value([])),
            isGoogleLinkedProvider.overrideWith((ref) => true),
            linkedGoogleEmailProvider.overrideWith(
              (ref) => 'salad213@gmail.com',
            ),
            linkedGoogleUidProvider.overrideWith((ref) => 'zSH24Uulx2'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.tap(find.text('Open Settings Dock'));
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);

      // 1. サーマル冷却・省電力制御タイルのタップテスト
      final thermalTile = find.text('サーマル冷却・省電力制御');
      expect(thermalTile, findsOneWidget);
      await tester.tap(thermalTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsOneWidget);
      // 詳細シートを閉じる
      Navigator.of(tester.element(find.text('🛡️ サーマル冷却＆省電力ステータス'))).pop();
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);

      // 2. BAND連携・LIVE配信設定タイルのタップテスト
      final bandTile = find.text('BAND連携・LIVE配信設定');
      await tester.scrollUntilVisible(
        bandTile,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(bandTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('BANDグループ管理'), findsOneWidget);
      Navigator.of(tester.element(find.text('BANDグループ管理'))).pop();
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);

      // 3. ログアウトタイルのタップテスト
      final logoutTile = find.text('ログアウト');
      await tester.scrollUntilVisible(
        logoutTile,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(logoutTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ログアウトしますか？'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);

      // 4. Googleアカウント連携「解除」ボタンのタップテスト
      expect(find.byType(SettingsGoogleAuthTile), findsOneWidget);
      final unlinkButton = find.text('解除');
      expect(unlinkButton, findsOneWidget);

      await tester.tap(unlinkButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Google連携を解除しますか？'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);
    });

    testWidgets('2. 部内戦ホーム（BunaiksenHomeScreen）のドックから設定を開き、同様に動作すること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final viewDate = DateTime(2026, 9, 11);
      final dateId = 'bunaiksen_20260911';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            currentDojoIdProvider.overrideWith((ref) => 'test_dojo'),
            permissionProvider.overrideWithValue(
              const PermissionState(role: UserRole.admin),
            ),
            bunaiksenViewDateProvider.overrideWith((ref) => viewDate),
            bunaiksenMatchesProvider(dateId).overrideWithValue([]),
            bunaiksenAvailableDatesProvider.overrideWith(
              (ref) => Stream.value({'20260911'}),
            ),
            matchListProvider.overrideWithValue([]),
            bandGroupsStreamProvider.overrideWith((ref) => Stream.value([])),
            isGoogleLinkedProvider.overrideWith((ref) => true),
            linkedGoogleEmailProvider.overrideWith(
              (ref) => 'salad213@gmail.com',
            ),
            linkedGoogleUidProvider.overrideWith((ref) => 'zSH24Uulx2'),
          ],
          child: const MaterialApp(home: BunaiksenHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 部内戦ドックボタンが存在することを確認
      expect(find.byType(BunaiksenDockButton), findsOneWidget);

      // ドックのメインボタンをタップして展開
      await tester.tap(find.byType(BunaiksenDockButton));
      await tester.pumpAndSettle();

      // 「設定」アイコン（Icons.settings_outlined）をタップ
      final settingsDockIcon = find.byIcon(Icons.settings_outlined);
      expect(settingsDockIcon, findsWidgets);
      await tester.tap(settingsDockIcon.first);
      await tester.pumpAndSettle();

      // システム設定シートが開くこと
      expect(find.text('システム設定'), findsOneWidget);

      // 1. サーマル冷却・省電力制御
      final thermalTile = find.text('サーマル冷却・省電力制御');
      expect(thermalTile, findsOneWidget);
      await tester.tap(thermalTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('🛡️ サーマル冷却＆省電力ステータス'), findsOneWidget);
      // 詳細シートを閉じる
      Navigator.of(tester.element(find.text('🛡️ サーマル冷却＆省電力ステータス'))).pop();
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);

      // 2. BAND連携・LIVE配信設定
      final bandTile = find.text('BAND連携・LIVE配信設定');
      await tester.scrollUntilVisible(
        bandTile,
        150,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      await tester.tap(bandTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('BANDグループ管理'), findsOneWidget);
      Navigator.of(tester.element(find.text('BANDグループ管理'))).pop();
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);

      // 3. ログアウト
      final logoutTile = find.text('ログアウト');
      await tester.scrollUntilVisible(
        logoutTile,
        150,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      await tester.tap(logoutTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ログアウトしますか？'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);

      // 4. 解除
      expect(find.byType(SettingsGoogleAuthTile), findsOneWidget);
      final unlinkButton = find.text('解除');
      expect(unlinkButton, findsOneWidget);

      await tester.tap(unlinkButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Google連携を解除しますか？'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('システム設定'), findsOneWidget);
    });
  });
}
