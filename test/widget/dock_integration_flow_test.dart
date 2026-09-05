import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/settings_screen.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🥋 ドック全機能の統合保証テストスイート
/// ドックボタンの展開、7機能ボトムシートの起動、拡大縮小、フリック閉じ、PC画面対応を保証します。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kendo_os_theme_mode': 'system',
      'kendo_os_enable_liquid_glass': true,
    });
    mockPrefs = await SharedPreferences.getInstance();
  });

  final dummyPrograms = [
    ProgramModel(
      id: 'prog_test_1',
      tournamentId: 't_test',
      title: '第1会場 進行表',
      fileUrl: 'https://example.com/prog.png',
      fileType: 'image',
      pageCount: 1,
      createdAt: DateTime(2026, 9, 1),
    ),
  ];

  Widget buildDockTestApp({required Widget child, bool isViewerMode = false}) {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        programListProvider(
          't_test',
        ).overrideWith((ref) => Stream.value(dummyPrograms)),
        unreadAnnouncementCountProvider((
          tournamentId: 't_test',
          isStaffRoom: !isViewerMode,
        )).overrideWith((ref) => Stream.value(0)),
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Center(child: Text('Main Screen Area')),
              child,
            ],
          ),
        ),
      ),
    );
  }

  group('🥋 ドック機能＆全画面拡大 保証テスト', () {
    testWidgets('ドック展開時に7つの全機能子アイコンが過不足なく表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildDockTestApp(
          child: const FloatingProgramDockButton(tournamentId: 't_test'),
        ),
      );
      await tester.pumpAndSettle();

      // ドックボタンをタップして展開
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      // 7つの機能アイコンがすべて存在すること
      // 1. プログラム
      expect(find.byIcon(Icons.menu_book_rounded), findsWidgets);
      // 2. 試合状況
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
      // 3. 対戦表
      expect(find.byIcon(Icons.scoreboard_rounded), findsOneWidget);
      // 4. クイックメモ
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
      // 5. お知らせ
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      // 6. ヘルプ
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      // 7. 設定
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

      // 親ボタンが✕マークになっていること
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('ドックから「クイックメモ」を開き、拡大ボタンで画面95%へ拡大できること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildDockTestApp(
          child: const FloatingProgramDockButton(tournamentId: 't_test'),
        ),
      );
      await tester.pumpAndSettle();

      // ドック展開
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      // クイックメモアイコン（brush_rounded）をタップ
      await tester.tap(find.byIcon(Icons.brush_rounded));
      await tester.pumpAndSettle();

      // クイックメモボトムシートが開いていること
      expect(find.byType(QuickMemoBottomSheet), findsOneWidget);
      expect(find.byType(DockDraggableSheet), findsOneWidget);

      // 初期状態では上に広げるボタン（expand_less_rounded）が存在すること
      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);

      // 拡大ボタンをタップ
      await tester.tap(find.byIcon(Icons.expand_less_rounded));
      await tester.pumpAndSettle();

      // 拡大後は縮小ボタン（expand_more_rounded）に切り替わること
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

      // もう一度タップして半分に戻ること
      await tester.tap(find.byIcon(Icons.expand_more_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    });

    testWidgets('ドックから「ヘルプ」を開き、タイトル行ドラッグで全開拡大できること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildDockTestApp(
          child: const FloatingProgramDockButton(tournamentId: 't_test'),
        ),
      );
      await tester.pumpAndSettle();

      // ドック展開
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      // ヘルプアイコン（help_outline_rounded）をタップ
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ManualBottomSheet), findsOneWidget);

      // タイトル行を上方向にドラッグして拡大
      await tester.drag(find.text('操作マニュアル・ヘルプ'), const Offset(0, -300));
      await tester.pumpAndSettle();

      // 最大化されていること（expand_more_rounded が表示）
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

      // 閉じるボタンをタップしてシートが閉じること
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ManualBottomSheet), findsNothing);
    });

    testWidgets('PC・タブレットのワイド画面（幅1024px）でもシートが確実に拡大・縮小できること', (tester) async {
      // 💻 PC/Macブラウザサイズ
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildDockTestApp(
          child: const FloatingProgramDockButton(tournamentId: 't_test'),
        ),
      );
      await tester.pumpAndSettle();

      // ドック展開
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      // 設定アイコン（settings_rounded）をタップ
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      // ワイド画面でも拡大ボタンが機能すること
      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.expand_less_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

      // 下へ大きくフリックして閉じること
      await tester.drag(find.text('システム設定'), const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsNothing);
    });

    testWidgets('観客モード（ViewerMode）時に表示設定ボトムシートが起動すること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildDockTestApp(
          isViewerMode: true,
          child: const FloatingProgramDockButton(
            tournamentId: 't_test',
            isViewerMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ドック展開
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      // 設定アイコン（観客モード用設定）をタップ
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ViewerSettingsBottomSheet), findsOneWidget);
      expect(find.text('表示設定'), findsOneWidget);
    });
  });
}
