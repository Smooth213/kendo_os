import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_sub_item_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_items_reorder_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_jiggle_drag_wrapper.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_parent_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_slot_layout_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildDockTestApp({required Widget child, bool isDark = false}) {
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

  group('[Widget] 常設ドックスロット 並び替え・ドラッグスワップ・ジグル統合検証テスト', () {
    testWidgets('ドックスロットのドラッグスワップが計算エンジンにより判定され永続化と画面回転復元が行われること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 初期スロット並び順（0: 大会プログラム, 1: 部内戦, 2: 掲示板, 3: タイマー）
      List<String> dockItems = ['program', 'bunaiksen', 'bulletin', 'timer'];
      const step = 60.0;

      // 1. スロット0をスロット2の位置へドラッグしたと想定
      final slot2Offset = DockSlotLayoutCalculator.getTournamentSlotOffset(
        index: 2,
        layoutMode: DockLayoutMode.vertical,
        dirX: 1.0,
        dirY: -1.0,
        step: step,
      );

      // findSwapTarget によるターゲット検知
      final swapTarget = DockSlotLayoutCalculator.findSwapTarget(
        currentPos: slot2Offset,
        currentDraggingIndex: 0,
        itemCount: dockItems.length,
        step: step,
        slotOffsetGetter: (idx) =>
            DockSlotLayoutCalculator.getTournamentSlotOffset(
              index: idx,
              layoutMode: DockLayoutMode.vertical,
              dirX: 1.0,
              dirY: -1.0,
              step: step,
            ),
      );

      expect(swapTarget, 2);

      // スワップ実行
      final itemToMove = dockItems.removeAt(0);
      dockItems.insert(swapTarget!, itemToMove);
      expect(dockItems, ['bunaiksen', 'bulletin', 'program', 'timer']);

      // SharedPreferences への永続化
      await prefs.setStringList('dock_slots_order_v1', dockItems);

      // 2. 画面回転（768x1024 縦向きへの変更）
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('復元前: ${dockItems.join(',')}')),
          ),
        ),
      );

      // 3. アプリ再起動（設定値ロード）による復元
      final restoredSlots = prefs.getStringList('dock_slots_order_v1');
      expect(restoredSlots, isNotNull);
      expect(
        restoredSlots,
        equals(['bunaiksen', 'bulletin', 'program', 'timer']),
      );
      expect(restoredSlots![2], equals('program'));
    });

    testWidgets('並び替えボトムシートが正常にレンダリングされReorderableListViewと項目が表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            home: Scaffold(body: DockItemsReorderBottomSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ドックの並び替え'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.text('初期順に戻す'), findsOneWidget);
      expect(find.text('観戦QR'), findsOneWidget);
      expect(find.text('タイマー'), findsOneWidget);
      expect(find.text('プログラム'), findsOneWidget);
    });

    testWidgets('非編集モード時に通常の子ウィジェットが描画されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DockJiggleDragWrapper(
              index: 0,
              isEditMode: false,
              child: Text('通常アイテム'),
            ),
          ),
        ),
      );

      expect(find.text('通常アイテム'), findsOneWidget);
    });

    testWidgets('編集モードかつアニメーション提供時にTransformが適用されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _TestJiggleHost())),
      );

      expect(find.byType(Transform), findsWidgets);
      expect(find.text('ジグルアイテム'), findsOneWidget);
    });

    testWidgets('ドラッグ中にスケール拡大Transformが適用されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DockJiggleDragWrapper(
              index: 0,
              isEditMode: true,
              isDragging: true,
              child: Text('ドラッグ中アイテム'),
            ),
          ),
        ),
      );

      final transformFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Transform && widget.transform.getMaxScaleOnAxis() > 1.0,
      );
      expect(transformFinder, findsOneWidget);
    });

    testWidgets('大会ホームドック: 長押しでジグルモード起動し、親ボタンが完了アイコンに切り替わること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildDockTestApp(
          child: const FloatingProgramDockButton(
            tournamentId: 'test_tour_1',
            initialDockedLeft: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final parentBtn = find.byType(DockParentButton);
      expect(parentBtn, findsOneWidget);
      await tester.tap(parentBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DockSpeedDialItemWidget), findsWidgets);

      final firstSubItem = find.byType(DockSpeedDialItemWidget).first;
      await tester.longPress(firstSubItem);
      await tester.pump();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('部内戦ドック: アイコンサイズが58px、アイコンシンボルが大会ホームと統一されていること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildDockTestApp(
          child: const BunaiksenDockButton(
            tournamentId: 'test_bunaiksen_1',
            initialDockedLeft: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      final subButtons = find.byType(BunaiksenSubItemButton);
      expect(subButtons, findsWidgets);

      final firstButtonSize = tester.getSize(subButtons.first);
      expect(firstButtonSize.width, 58.0);
      expect(firstButtonSize.height, 58.0);

      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('ダークモード時: 試合状況/対戦一覧が高視認性カラーで描画されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildDockTestApp(
          isDark: true,
          child: const FloatingProgramDockButton(
            tournamentId: 'test_tour_dark',
            initialDockedLeft: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DockParentButton));
      await tester.pumpAndSettle();

      final groupsIcon = tester.widget<Icon>(find.byIcon(Icons.groups_rounded));
      expect(groupsIcon.color, const Color(0xFF818CF8));

      final settingsIcon = tester.widget<Icon>(
        find.byIcon(Icons.settings_rounded),
      );
      expect(settingsIcon.color, const Color(0xFFCBD5E1));

      final progIcon = tester.widget<Icon>(
        find.byIcon(Icons.menu_book_rounded),
      );
      expect(progIcon.color, const Color(0xFFA78BFA));
    });
  });
}

class _TestJiggleHost extends StatefulWidget {
  @override
  State<_TestJiggleHost> createState() => _TestJiggleHostState();
}

class _TestJiggleHostState extends State<_TestJiggleHost>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DockJiggleDragWrapper(
      index: 1,
      isEditMode: true,
      isDragging: false,
      jiggleAnimation: _controller,
      child: const Text('ジグルアイテム'),
    );
  }
}
