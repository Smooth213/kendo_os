import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/operator_action_buttons.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_quick_action_buttons.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('🥋 OperatorActionButtons & ViewerQuickActionButtons 2列グリッド検証テスト', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('1. 本部運営権限: ＋試合（対戦）を作成 と 2x2グリッドの4機能が完全表示されること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: false,
                canManageTournament: true,
                canCreateMatch: true,
              ),
            ),
            currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: OperatorActionButtons(tournamentId: 'test_tourney_1'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 最上段プライマリボタン
      expect(find.text('試合（対戦）を作成'), findsOneWidget);

      // 2x2グリッドの4機能
      expect(find.text('試合ルール設定'), findsOneWidget);
      expect(find.text('観客の画面を確認'), findsOneWidget);
      expect(find.text('試合結果一覧'), findsOneWidget);
      expect(find.text('大会プログラム管理'), findsOneWidget);
    });

    testWidgets('2. 閲覧権限(Viewer): 本部用ボタンが秘匿され、観客用アクションのみ表示されること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                isReadOnly: true,
                canManageTournament: false,
                canCreateMatch: false,
              ),
            ),
            currentUserRoleProvider.overrideWith((ref) => UserRole.viewer),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: OperatorActionButtons(tournamentId: 'test_tourney_1'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 本部用ボタンは非表示
      expect(find.text('試合（対戦）を作成'), findsNothing);
      expect(find.text('試合ルール設定'), findsNothing);

      // 共有機能は表示
      expect(find.text('観客の画面を確認'), findsOneWidget);
      expect(find.text('試合結果一覧'), findsOneWidget);
      expect(find.text('大会プログラム管理'), findsOneWidget);
    });

    testWidgets('3. 観客用ViewerQuickActionButtons: 2列横並びグリッドで2機能が表示されること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(
        isDark: false,
        mode: 'normal_viewer',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: const Scaffold(
              body: ViewerQuickActionButtons(
                tournamentId: 'test_tourney_1',
                enableLiquidGlass: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('試合結果一覧'), findsOneWidget);
      expect(find.text('大会プログラム'), findsOneWidget);
    });

    testWidgets(
      '4. 【文字切れ・はみ出しゼロ保証】 320x568の小型画面でもRenderFlex Overflowなく描画されること',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              permissionProvider.overrideWith(
                (ref) => const AppPermissions(isReadOnly: false),
              ),
              currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
            ],
            child: MaterialApp(
              theme: ThemeData.dark().copyWith(extensions: [themeColors]),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: OperatorActionButtons(
                      tournamentId: 'test_tourney_1',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('試合（対戦）を作成'), findsOneWidget);
        expect(find.text('試合ルール設定'), findsOneWidget);
        expect(find.text('観客の画面を確認'), findsOneWidget);
        expect(find.text('試合結果一覧'), findsOneWidget);
        expect(find.text('大会プログラム管理'), findsOneWidget);

        // Overflow Exception が一切発生していないこと
        expect(tester.takeException(), isNull);
      },
    );
  });
}
