import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_speed_dial_item.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyPrograms = [
    ProgramModel(
      id: 'prog_1',
      tournamentId: 'tour_123',
      title: '進行表・トーナメント表',
      fileUrl: 'https://example.com/prog1.png',
      fileType: 'image',
      pageCount: 1,
      createdAt: DateTime(2026, 9, 1),
    ),
  ];

  Widget createTestWidget({
    required Widget child,
    bool isDark = false,
    int unreadCount = 0,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    return ProviderScope(
      overrides: [
        programListProvider(
          'tour_123',
        ).overrideWith((ref) => Stream.value(dummyPrograms)),
        unreadAnnouncementCountProvider((
          tournamentId: 'tour_123',
          isStaffRoom: true,
        )).overrideWith((ref) => Stream.value(unreadCount)),
        unreadAnnouncementCountProvider((
          tournamentId: 'tour_123',
          isStaffRoom: false,
        )).overrideWith((ref) => Stream.value(unreadCount)),
      ],
      child: MaterialApp(
        theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
          extensions: [themeColors],
        ),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Center(child: Text('Main Content Area')),
              child,
            ],
          ),
        ),
      ),
    );
  }

  group('🥋 FloatingProgramDockButton ウィジェットテスト', () {
    testWidgets('初期状態で丸型ボタンが表示され、アイコンが存在すること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(tournamentId: 'tour_123'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingProgramDockButton), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets('タップすると流動的スピードダイヤルが展開され、子アイコン群と✕ボタンが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(tournamentId: 'tour_123'),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態では✕アイコンは無く、本アイコンのみ
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // ドックボタンをタップして展開
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      // 親ボタンが✕マークに回転変形していること
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // 子アイコン群（チーム状況、対戦表、メモ、お知らせ、ヘルプ、設定）が展開されていること
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
      expect(find.byIcon(Icons.scoreboard_rounded), findsOneWidget);
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

      // 背景バリア（画面左上 X=50, Y=50）をタップすると収納されること
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // 収納後は✕アイコンが消え、通常状態に戻ること
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('画面外側へスワイプするとドック収納状態になり、タップで再展開されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(
            tournamentId: 'tour_123',
            initialDockedLeft: false, // 右側配置
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 右端外側へドラッグ（dx > 5）
      await tester.drag(
        find.byType(FloatingProgramDockButton),
        const Offset(20, 0),
      );
      await tester.pumpAndSettle();

      // ドック状態のボタン（画面端のツマミ部: X=790, Y=700）をタップして再展開
      await tester.tapAt(const Offset(790, 700));
      await tester.pumpAndSettle();

      // 再展開後にタップするとスピードダイヤルが展開される
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('水平方向に大きくドラッグすると右端から左端へスナップ移動すること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(
            tournamentId: 'tour_123',
            initialDockedLeft: false, // 初期は右側
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 右端から左方向へ大きくドラッグ（-100px）
      await tester.drag(
        find.byType(FloatingProgramDockButton),
        const Offset(-100, 0),
      );
      await tester.pumpAndSettle();

      // 左端位置（X座標が画面左側 < 100）に移動していることを検証
      final topLeft = tester.getTopLeft(find.byType(FloatingProgramDockButton));
      expect(topLeft.dx < 100.0, isTrue);
    });

    testWidgets('ProgramHeaderAction をタップするとボトムシートが開くこと', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            programListProvider(
              'tour_123',
            ).overrideWith((ref) => Stream.value(dummyPrograms)),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [ProgramHeaderAction(tournamentId: 'tour_123')],
              ),
              body: const Center(child: Text('Content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProgramHeaderAction), findsOneWidget);
      await tester.tap(find.byType(ProgramHeaderAction));
      await tester.pumpAndSettle();

      expect(find.byType(ProgramBottomSheet), findsOneWidget);
    });

    testWidgets('左端配置から右方向へドラッグすると右端へスーッとスナップ移動すること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(
            tournamentId: 'tour_123',
            initialDockedLeft: true, // 初期は左側
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期位置が画面左側にあることを検証
      final initialPos = tester.getTopLeft(
        find.byType(FloatingProgramDockButton),
      );
      expect(initialPos.dx < 100.0, isTrue);

      // 左端から右方向へ大きくドラッグ（+100px）
      await tester.drag(
        find.byType(FloatingProgramDockButton),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();

      // 右端位置（X座標 > 700）に移動していることを検証
      final newPos = tester.getTopLeft(find.byType(FloatingProgramDockButton));
      expect(newPos.dx > 700.0, isTrue);
    });

    testWidgets('上下（Y軸）ドラッグでボタンの垂直位置が調整できること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(tournamentId: 'tour_123'),
        ),
      );
      await tester.pumpAndSettle();

      final initialY = tester
          .getTopLeft(find.byType(FloatingProgramDockButton))
          .dy;

      // 上方向へドラッグ（-100px）
      await tester.drag(
        find.byType(FloatingProgramDockButton),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      final newY = tester.getTopLeft(find.byType(FloatingProgramDockButton)).dy;
      expect(newY < initialY, isTrue);
    });

    testWidgets('AnimatedPositioned が使用され、スムーズなアニメーションが設定されていること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(tournamentId: 'tour_123'),
        ),
      );
      await tester.pumpAndSettle();

      // AnimatedPositioned ウィジェットが存在すること
      final animatedPosFinder = find.descendant(
        of: find.byType(FloatingProgramDockButton),
        matching: find.byType(AnimatedPositioned),
      );
      expect(animatedPosFinder, findsOneWidget);

      final animatedPos = tester.widget<AnimatedPositioned>(animatedPosFinder);
      expect(animatedPos.curve, Curves.easeOutCubic);
    });

    testWidgets('未読アナウンスがある場合、iPhone風の数字バッジが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(tournamentId: 'tour_123'),
          unreadCount: 5,
        ),
      );
      await tester.pumpAndSettle();

      // バッジの数字 '5' が描画されていること
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('左端配置（initialDockedLeft: true）でもタップで流動的L字展開されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(
            tournamentId: 'tour_123',
            initialDockedLeft: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      // ✕アイコンと子アイコン群が展開されること
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
      expect(find.byIcon(Icons.scoreboard_rounded), findsOneWidget);
    });

    testWidgets('画面中央寄りでは縦一列(vertical)、画面下端寄りではL字(lShape)に流動的展開されること', (
      tester,
    ) async {
      // 十分な高さのある画面サイズを設定
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(tournamentId: 'tour_123'),
        ),
      );
      await tester.pumpAndSettle();

      // ① 中央付近でタップして展開 ➔ 縦1列(vertical)
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      final centerItemWidgets = tester.widgetList<DockSpeedDialItemWidget>(
        find.byType(DockSpeedDialItemWidget),
      );
      expect(centerItemWidgets, isNotEmpty);
      expect(centerItemWidgets.first.layoutMode, DockLayoutMode.vertical);

      // 一旦閉じる
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // ② 下端へ大きくドラッグ（+400px）
      await tester.drag(
        find.byType(FloatingProgramDockButton),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();

      // 下端でタップして展開 ➔ L字(lShape)
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      final edgeItemWidgets = tester.widgetList<DockSpeedDialItemWidget>(
        find.byType(DockSpeedDialItemWidget),
      );
      expect(edgeItemWidgets, isNotEmpty);
      expect(edgeItemWidgets.first.layoutMode, DockLayoutMode.lShape);
    });

    testWidgets('親ドックアイコンにipponGold（金色）枠線ハイライトが適用されていること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          child: const FloatingProgramDockButton(tournamentId: 'tour_123'),
        ),
      );
      await tester.pumpAndSettle();

      // 親ボタンのAnimatedContainerのdecorationにipponGoldが含まれていること
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      final border = decoration.border as Border;
      expect(
        border.top.color.toARGB32(),
        AppKendoColors.ipponGold.withValues(alpha: 0.95).toARGB32(),
      );
    });
  });
}
