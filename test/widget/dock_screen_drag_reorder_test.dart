import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_sub_item_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp({required Widget child, bool isDark = false}) {
    return ProviderScope(
      overrides: [currentUserRoleProvider.overrideWithValue(UserRole.admin)],
      child: MaterialApp(
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(
                child: Center(child: Text('Main Screen Content')),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  group('🥋 ドック機能統合改修テスト', () {
    testWidgets('大会ホームドック: 長押しでジグルモード起動し、親ボタンが完了アイコンに切り替わること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(
          child: const FloatingProgramDockButton(
            tournamentId: 'test_tour_1',
            initialDockedLeft: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 親ボタンをタップして展開
      final parentBtn = find.byType(DockParentButton);
      expect(parentBtn, findsOneWidget);
      await tester.tap(parentBtn);
      await tester.pumpAndSettle();

      // サブアイコンが表示されている
      expect(find.byType(DockSpeedDialItemWidget), findsWidgets);

      // サブアイコン（最初のアイテム）を長押し ➔ ジグルモード開始
      final firstSubItem = find.byType(DockSpeedDialItemWidget).first;
      await tester.longPress(firstSubItem);
      await tester.pump();

      // 親ボタンが完了アイコン（Icons.check_rounded）に切り替わる
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // 完了ボタンをタップして編集モードを終了
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      // 編集モード終了後は✕ボタン（展開中）に戻る
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('部内戦ドック: アイコンサイズが58px、アイコンシンボルが大会ホームと統一されていること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(
          child: const BunaiksenDockButton(
            tournamentId: 'test_bunaiksen_1',
            initialDockedLeft: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 親ボタンをタップして展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      // サブアイコンボタンのサイズが 58px であることを検証
      final subButtons = find.byType(BunaiksenSubItemButton);
      expect(subButtons, findsWidgets);

      final firstButtonSize = tester.getSize(subButtons.first);
      expect(firstButtonSize.width, 58.0);
      expect(firstButtonSize.height, 58.0);

      // 同一機能アイコンの統一確認:
      // クイックメモ: Icons.brush_rounded (筆)
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
      // 設定: Icons.settings_rounded (歯車)
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      // タイマー: Icons.timer_rounded
      expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
    });

    testWidgets('ダークモード時: 試合状況/対戦一覧が高視認性カラーで描画されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(
          isDark: true,
          child: const FloatingProgramDockButton(
            tournamentId: 'test_tour_dark',
            initialDockedLeft: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      // 試合状況アイコン (Icons.groups_rounded) の色がダークモード高視認性カラー (Color(0xFF818CF8)) であること
      final groupsIcon = tester.widget<Icon>(find.byIcon(Icons.groups_rounded));
      expect(groupsIcon.color, const Color(0xFF818CF8));

      // 設定アイコン (Icons.settings_rounded) の色がシルバーホワイト (Color(0xFFCBD5E1)) であること
      final settingsIcon = tester.widget<Icon>(
        find.byIcon(Icons.settings_rounded),
      );
      expect(settingsIcon.color, const Color(0xFFCBD5E1));

      // プログラムアイコン (Icons.menu_book_rounded) の色がバイオレット (Color(0xFFA78BFA)) であること
      final progIcon = tester.widget<Icon>(
        find.byIcon(Icons.menu_book_rounded),
      );
      expect(progIcon.color, const Color(0xFFA78BFA));
    });
  });
}
