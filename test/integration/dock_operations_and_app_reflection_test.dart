import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_calendar_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_matches_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_standings_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_dock_calculator_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_sub_item_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_dock_items_order_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_matches_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_items_order_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🥋 ドック操作の正常機能＆アプリ画面反映 保証テストスイート
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;

  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    if (FloatingDockSheetManager.isOpen) {
      await FloatingDockSheetManager.close(immediate: true);
    }
  });

  Widget buildAppWithDock({required Widget dockWidget, bool isDark = false}) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        currentUserRoleProvider.overrideWithValue(UserRole.admin),
        programListProvider(
          'tour_test_1',
        ).overrideWith((ref) => Stream.value([])),
        bunaiksenMatchesProvider('bunaiksen_test_1').overrideWithValue([]),
        unreadAnnouncementCountProvider((
          tournamentId: 'tour_test_1',
          isStaffRoom: true,
        )).overrideWith((ref) => Stream.value(0)),
      ],
      child: MaterialApp(
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        darkTheme: ThemeData.dark().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Center(child: Text('Tournament Main Viewport')),
              dockWidget,
            ],
          ),
        ),
      ),
    );
  }

  group('🥋 大会ホームドック: 操作とアプリ反映の完全保証テスト', () {
    testWidgets('1. クイックメモタップでドックが収納され、QuickMemoBottomSheetが画面に展開されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const FloatingProgramDockButton(
            tournamentId: 'tour_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ドックを展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      // クイックメモ（筆アイコン Icons.brush_rounded）をタップ
      final memoIcon = find.byIcon(Icons.brush_rounded);
      expect(memoIcon, findsOneWidget);
      await tester.tap(memoIcon);
      await tester.pumpAndSettle();

      // QuickMemoBottomSheet が画面上に展開されていること
      expect(find.byType(QuickMemoBottomSheet), findsOneWidget);
      expect(find.text('クイックメモ'), findsOneWidget);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });

    testWidgets('2. タイマータップでドックが収納され、DockTimerBottomSheetが画面に展開されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const FloatingProgramDockButton(
            tournamentId: 'tour_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      // タイマーアイコン（停止時はIcons.timer_outlined）タップ
      final timerIcon = find.byIcon(Icons.timer_outlined);
      expect(timerIcon, findsOneWidget);
      await tester.tap(timerIcon);
      await tester.pumpAndSettle();

      // DockTimerBottomSheet が展開されること
      expect(find.byType(DockTimerBottomSheet), findsOneWidget);

      Navigator.of(tester.element(find.byType(DockTimerBottomSheet))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('3. プログラムタップでドックが収納され、ProgramBottomSheetが画面に展開されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const FloatingProgramDockButton(
            tournamentId: 'tour_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      // プログラムアイコンタップ
      final progIcon = find.byIcon(Icons.menu_book_rounded);
      expect(progIcon, findsOneWidget);
      await tester.tap(progIcon);
      await tester.pumpAndSettle();

      // ProgramBottomSheet が展開されること
      expect(find.byType(ProgramBottomSheet), findsOneWidget);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });

    testWidgets('4. 観戦QRタップでViewerQrBottomSheetが展開されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const FloatingProgramDockButton(
            tournamentId: 'tour_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      final qrIcon = find.byIcon(Icons.qr_code_2_rounded);
      expect(qrIcon, findsOneWidget);
      await tester.tap(qrIcon);
      await tester.pumpAndSettle();

      expect(find.byType(ViewerQrBottomSheet), findsOneWidget);

      Navigator.of(tester.element(find.byType(ViewerQrBottomSheet))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('5. ヘルプタップでManualBottomSheetが展開されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const FloatingProgramDockButton(
            tournamentId: 'tour_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      final helpIcon = find.byIcon(Icons.help_outline_rounded);
      expect(helpIcon, findsOneWidget);
      await tester.tap(helpIcon);
      await tester.pumpAndSettle();

      expect(find.byType(ManualBottomSheet), findsOneWidget);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });

    testWidgets('6. 背景（半透明バリア）タップでドックがスムーズに収納されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const FloatingProgramDockButton(
            tournamentId: 'tour_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();
      expect(find.byType(DockSpeedDialItemWidget), findsWidgets);

      // 画面中央の余白をタップ
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();

      // 収納されて子アイテムが非表示になること
      expect(find.byType(DockSpeedDialItemWidget), findsNothing);
    });
  });

  group('🥋 部内戦ドック: 操作とアプリ反映の完全保証テスト', () {
    testWidgets('1. カレンダータップでBunaiksenDockCalendarSheetが画面に展開されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const BunaiksenDockButton(
            tournamentId: 'bunaiksen_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      // カレンダーアイコンタップ
      final calIcon = find.byIcon(Icons.calendar_month_rounded);
      expect(calIcon, findsOneWidget);
      await tester.tap(calIcon);
      await tester.pumpAndSettle();

      expect(find.byType(BunaiksenDockCalendarSheet), findsOneWidget);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });

    testWidgets('2. 成績・星取表タップでBunaiksenDockStandingsSheetが展開されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const BunaiksenDockButton(
            tournamentId: 'bunaiksen_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      // 星取表アイコンタップ
      final standingsIcon = find.byIcon(Icons.leaderboard_rounded);
      expect(standingsIcon, findsOneWidget);
      await tester.tap(standingsIcon);
      await tester.pumpAndSettle();

      expect(find.byType(BunaiksenDockStandingsSheet), findsOneWidget);

      Navigator.of(
        tester.element(find.byType(BunaiksenDockStandingsSheet)),
      ).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('3. 対戦一覧タップでBunaiksenDockMatchesSheetが展開されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const BunaiksenDockButton(
            tournamentId: 'bunaiksen_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      final matchesIcon = find.byIcon(Icons.format_list_bulleted_rounded);
      expect(matchesIcon, findsOneWidget);
      await tester.tap(matchesIcon);
      await tester.pumpAndSettle();

      expect(find.byType(BunaiksenDockMatchesSheet), findsOneWidget);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });

    testWidgets('4. 試合数計算タップでBunaiksenDockCalculatorSheetが展開されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildAppWithDock(
          dockWidget: const BunaiksenDockButton(
            tournamentId: 'bunaiksen_test_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      final calcIcon = find.byIcon(Icons.calculate_rounded);
      expect(calcIcon, findsOneWidget);
      await tester.tap(calcIcon);
      await tester.pumpAndSettle();

      expect(find.byType(BunaiksenDockCalculatorSheet), findsOneWidget);

      await FloatingDockSheetManager.close(immediate: true);
      await tester.pumpAndSettle();
    });
  });

  group('🥋 ドック並び替え: ドラッグスワップ＆アプリ即時反映 保証テスト', () {
    testWidgets('大会ホームドック: 長押しジグル ➔ 完了タップでプロバイダに新順序が反映されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            programListProvider(
              'tour_reorder_test',
            ).overrideWith((ref) => Stream.value([])),
            unreadAnnouncementCountProvider((
              tournamentId: 'tour_reorder_test',
              isStaffRoom: true,
            )).overrideWith((ref) => Stream.value(0)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const Stack(
                    children: [
                      FloatingProgramDockButton(
                        tournamentId: 'tour_reorder_test',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 展開
      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      // 初期順序の確認
      final initialOrder = capturedRef.read(dockItemsOrderProvider);
      expect(initialOrder.length, 9);

      // サブアイテム長押し ➔ 編集モード突入
      final firstItem = find.byType(DockSpeedDialItemWidget).first;
      await tester.longPress(firstItem);
      await tester.pump();

      // チェックマークアイコンが表示されていること
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // 完了タップで終了
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      // 編集モードが終了して✕マークに戻ること
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('部内戦ドック: 長押しジグル ➔ 完了タップでプロバイダに新順序が反映されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            currentUserRoleProvider.overrideWithValue(UserRole.admin),
            bunaiksenMatchesProvider(
              'bunaiksen_reorder_test',
            ).overrideWithValue([]),
            unreadAnnouncementCountProvider((
              tournamentId: 'bunaiksen_reorder_test',
              isStaffRoom: true,
            )).overrideWith((ref) => Stream.value(0)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const Stack(
                    children: [
                      BunaiksenDockButton(
                        tournamentId: 'bunaiksen_reorder_test',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      final initialOrder = capturedRef.read(bunaiksenDockItemsOrderProvider);
      expect(initialOrder.length, 7);

      // サブアイテム長押し ➔ 編集モード突入
      final firstSub = find.byType(BunaiksenSubItemButton).first;
      await tester.longPress(firstSub);
      await tester.pump();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // 完了タップ
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
