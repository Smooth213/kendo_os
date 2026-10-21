import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_view_state_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_body.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/program_viewer_screen.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/domain/entities/user_role.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_stroke_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/stroke_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_user_role_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class _MockStrokeRepository extends Mock implements StrokeRepository {}

class _MockLocalStrokeRepository extends Mock
    implements LocalStrokeRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;
  late _MockStrokeRepository mockStrokeRepo;
  late _MockLocalStrokeRepository mockLocalStrokeRepo;

  const tournamentId = 'tour_e2e_dock_persist';
  const schedulePdfUrl = 'https://example.com/e2e_schedule.pdf';
  const bracketPdfUrl = 'https://example.com/e2e_bracket.pdf';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kendo_os_theme_mode': 'system',
      'kendo_os_enable_liquid_glass': true,
    });
    mockPrefs = await SharedPreferences.getInstance();
    mockStrokeRepo = _MockStrokeRepository();
    mockLocalStrokeRepo = _MockLocalStrokeRepository();

    when(
      () => mockStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockLocalStrokeRepo.watchStrokes(any()),
    ).thenAnswer((_) => Stream.value([]));

    ProgramViewStateService.instance.resetForTesting();
    await ProgramViewStateService.instance.init(prefs: mockPrefs);
    ProgramViewerMediaCache.shared.clear();
    ProgramViewerPdfPageCache.shared.clear();
  });

  tearDown(() async {
    await FloatingDockSheetManager.close(immediate: true);
  });

  final testPrograms = [
    ProgramModel(
      id: 'prog_e2e_schedule',
      tournamentId: tournamentId,
      title: '試合進行表（PDF）',
      fileUrl: schedulePdfUrl,
      fileType: 'pdf',
      pageCount: 8,
      createdAt: DateTime(2026, 9, 1),
    ),
    ProgramModel(
      id: 'prog_e2e_bracket',
      tournamentId: tournamentId,
      title: 'トーナメント表（PDF）',
      fileUrl: bracketPdfUrl,
      fileType: 'pdf',
      pageCount: 12,
      createdAt: DateTime(2026, 9, 2),
    ),
  ];

  Widget buildE2EAppScope({
    required Widget child,
    required List<ProgramModel> programs,
    SharedPreferences? customPrefs,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(customPrefs ?? mockPrefs),
        currentDojoIdProvider.overrideWith((ref) => 'test_dojo_room'),
        programListProvider(
          tournamentId,
        ).overrideWith((ref) => Stream.value(programs)),
        unreadAnnouncementCountProvider((
          tournamentId: tournamentId,
          isStaffRoom: true,
        )).overrideWith((ref) => Stream.value(0)),
        unreadAnnouncementCountProvider((
          tournamentId: tournamentId,
          isStaffRoom: false,
        )).overrideWith((ref) => Stream.value(0)),
        currentUserRoleProvider.overrideWith((ref) => UserRole.admin),
        activeRoleProvider.overrideWith((ref) => Role.admin),
        permissionProvider.overrideWith(
          (ref) => AppPermissions(isReadOnly: false),
        ),
        strokeRepositoryProvider.overrideWithValue(mockStrokeRepo),
        localStrokeRepositoryProvider.overrideWithValue(mockLocalStrokeRepo),
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: Scaffold(body: child),
      ),
    );
  }

  Future<void> openProgramFromDock(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingProgramDockButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
  }

  group('[Widget] ドックプログラム閲覧位置端末永続化 ＆ 全画面ビューア連携検証', () {
    testWidgets(
      'ドック展開 → ページ送り → ボトムシート終了 → 再展開復元 → 全画面遷移 → 全画面ページ送り → 画面復帰 → 端末再起動後完全復元シナリオこと',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // 1. ホーム画面起動（常設ドックボタン配置）
        await tester.pumpWidget(
          buildE2EAppScope(
            programs: testPrograms,
            child: const Stack(
              children: [
                Center(child: Text('Main Screen Content')),
                FloatingProgramDockButton(
                  tournamentId: tournamentId,
                  isViewerMode: false,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Main Screen Content'), findsOneWidget);
        expect(find.byType(FloatingProgramDockButton), findsOneWidget);

        // 2. ドックボタンをタップし、プログラムボトムシートを展開
        await openProgramFromDock(tester);
        expect(find.byType(ProgramBottomSheet), findsOneWidget);
        expect(find.text('試合進行表（PDF）'), findsWidgets);
        expect(find.text('1 / 8'), findsOneWidget);

        // 3. ページを 1 から 3 へ進める
        final nextButton = find.byTooltip('次のページ');
        expect(nextButton, findsOneWidget);
        await tester.tap(nextButton); // 2
        await tester.pumpAndSettle();
        await tester.tap(nextButton); // 3
        await tester.pumpAndSettle();
        expect(find.text('3 / 8'), findsOneWidget);

        expect(
          ProgramViewStateService.instance.getLastPageNumber(
            'prog_e2e_schedule',
          ),
          3,
        );

        // 4. ボトムシートを閉じる
        await FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();
        expect(find.byType(ProgramBottomSheet), findsNothing);

        // 5. 再度ドックからプログラムを展開 → 3ページ目が自動復元されていること
        await openProgramFromDock(tester);
        expect(find.byType(ProgramBottomSheet), findsOneWidget);
        expect(find.text('3 / 8'), findsOneWidget);

        // 6. ボトムシートを閉じて、全画面ビューアへ遷移
        await FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          buildE2EAppScope(
            programs: testPrograms,
            child: ProgramViewerScreen(programs: testPrograms, initialIndex: 0),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProgramViewerScreen), findsOneWidget);
        final fullscreenPdfBody = tester.widget<ProgramViewerPdfBody>(
          find.byType(ProgramViewerPdfBody),
        );
        expect(
          fullscreenPdfBody.initialPage,
          2,
          reason: '全画面ビューアへの閲覧位置引き継ぎが正常であること',
        );

        // 7. 全画面ビューア内でさらに 5ページ目へ進めたイベントをトリガー
        fullscreenPdfBody.onPageChanged?.call(4);
        await tester.pumpAndSettle();

        expect(
          ProgramViewStateService.instance.getLastPageNumber(
            'prog_e2e_schedule',
          ),
          5,
          reason: '全画面ビューアでのページ進行が端末永続化サービスに即座に同期されること',
        );

        // 8. 全画面ビューアを閉じて、メイン画面へ戻る
        await tester.pumpWidget(
          buildE2EAppScope(
            programs: testPrograms,
            child: const Stack(
              children: [
                Center(child: Text('Main Screen Content')),
                FloatingProgramDockButton(
                  tournamentId: tournamentId,
                  isViewerMode: false,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProgramViewerScreen), findsNothing);

        // 9. 再度ドックからプログラムシートを展開 → 5ページ目が引き継がれていること
        await openProgramFromDock(tester);
        expect(find.byType(ProgramBottomSheet), findsOneWidget);
        expect(
          find.text('5 / 8'),
          findsOneWidget,
          reason: '全画面でのページ進行がドックボトムシートに完全同期復元されること',
        );

        await FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();

        // 10. 【コールドブート再現】
        expect(
          mockPrefs.getInt('kendo_os_prog_last_page_prog_e2e_schedule'),
          5,
        );

        ProgramViewStateService.instance.resetForTesting();
        await ProgramViewStateService.instance.init(prefs: mockPrefs);
        ProgramViewerPdfPageCache.shared.clear();

        await tester.pumpWidget(
          buildE2EAppScope(
            programs: testPrograms,
            child: const Stack(
              children: [
                Center(child: Text('Main Screen Content')),
                FloatingProgramDockButton(
                  tournamentId: tournamentId,
                  isViewerMode: false,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openProgramFromDock(tester);

        expect(find.byType(ProgramBottomSheet), findsOneWidget);
        expect(
          find.text('5 / 8'),
          findsOneWidget,
          reason: 'アプリ再起動後も保存されたページ位置が完全に復元されること',
        );
      },
    );

    testWidgets(
      '複数ページ進行後に「最初のページに戻る」をタップ → 1ページ目復帰 ＆ ドック再展開 ＆ 全画面ビューア連携 ＆ アプリ再起動後も1ページ目維持シナリオこと',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildE2EAppScope(
            programs: testPrograms,
            child: const Stack(
              children: [
                Center(child: Text('Main Screen Content')),
                FloatingProgramDockButton(
                  tournamentId: tournamentId,
                  isViewerMode: false,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        await openProgramFromDock(tester);
        expect(find.byType(ProgramBottomSheet), findsOneWidget);
        expect(find.text('1 / 8'), findsOneWidget);

        // ページを 1 から 4 へ進める
        final nextButton = find.byTooltip('次のページ');
        await tester.tap(nextButton); // 2
        await tester.pumpAndSettle();
        await tester.tap(nextButton); // 3
        await tester.pumpAndSettle();
        await tester.tap(nextButton); // 4
        await tester.pumpAndSettle();
        expect(find.text('4 / 8'), findsOneWidget);
        expect(
          ProgramViewStateService.instance.getLastPageNumber(
            'prog_e2e_schedule',
          ),
          4,
        );

        // 「最初のページに戻る」ボタンをタップ
        final firstPageBtnFinder = find.byTooltip('最初のページに戻る');
        expect(firstPageBtnFinder, findsOneWidget);
        await tester.tap(firstPageBtnFinder);
        await tester.pumpAndSettle();

        expect(find.text('1 / 8'), findsOneWidget);
        expect(
          ProgramViewStateService.instance.getLastPageNumber(
            'prog_e2e_schedule',
          ),
          1,
        );
        expect(
          mockPrefs.getInt('kendo_os_prog_last_page_prog_e2e_schedule'),
          1,
        );

        // 1ページ目の状態でさらにタップしても 1 / 8 のまま維持
        await tester.tap(firstPageBtnFinder);
        await tester.pumpAndSettle();
        expect(find.text('1 / 8'), findsOneWidget);

        // 全画面ビューアへ遷移
        await FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          buildE2EAppScope(
            programs: testPrograms,
            child: ProgramViewerScreen(programs: testPrograms, initialIndex: 0),
          ),
        );
        await tester.pumpAndSettle();

        final fullscreenPdfBody = tester.widget<ProgramViewerPdfBody>(
          find.byType(ProgramViewerPdfBody),
        );
        expect(
          fullscreenPdfBody.initialPage,
          0,
          reason: 'ボトムシートで1ページ目に戻した状態が全画面へ引き継がれていること',
        );

        final fsFirstPageFinder = find.widgetWithIcon(
          IconButton,
          Icons.first_page,
        );
        expect(fsFirstPageFinder, findsOneWidget);
        final fsIconBtnBefore = tester.widget<IconButton>(fsFirstPageFinder);
        expect(fsIconBtnBefore.onPressed, isNull);

        // 6ページ目へ進める
        final currentPdfBody = tester.widget<ProgramViewerPdfBody>(
          find.byType(ProgramViewerPdfBody),
        );
        currentPdfBody.onPageChanged?.call(5);
        await tester.pumpAndSettle();
        expect(
          ProgramViewStateService.instance.getLastPageNumber(
            'prog_e2e_schedule',
          ),
          6,
        );

        final fsIconBtnActive = tester.widget<IconButton>(fsFirstPageFinder);
        expect(fsIconBtnActive.onPressed, isNotNull);

        // AppBarの「最初のページに戻る」ボタンをタップ
        await tester.tap(fsFirstPageFinder);
        await tester.pumpAndSettle();

        expect(
          ProgramViewStateService.instance.getLastPageNumber(
            'prog_e2e_schedule',
          ),
          1,
        );
        expect(
          mockPrefs.getInt('kendo_os_prog_last_page_prog_e2e_schedule'),
          1,
        );

        final fsIconBtnAfter = tester.widget<IconButton>(fsFirstPageFinder);
        expect(fsIconBtnAfter.onPressed, isNull);

        // 全画面ビューアを閉じてメイン画面へ戻り、再度ドックを展開
        await tester.pumpWidget(
          buildE2EAppScope(
            programs: testPrograms,
            child: const Stack(
              children: [
                Center(child: Text('Main Screen Content')),
                FloatingProgramDockButton(
                  tournamentId: tournamentId,
                  isViewerMode: false,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        await openProgramFromDock(tester);
        expect(find.byType(ProgramBottomSheet), findsOneWidget);
        expect(
          find.text('1 / 8'),
          findsOneWidget,
          reason: '全画面で1ページ目に戻した状態がドックボトムシートに完全同期復元されること',
        );

        await FloatingDockSheetManager.close(immediate: true);
        await tester.pumpAndSettle();

        // コールドブート
        ProgramViewStateService.instance.resetForTesting();
        await ProgramViewStateService.instance.init(prefs: mockPrefs);
        ProgramViewerPdfPageCache.shared.clear();

        await tester.pumpWidget(
          buildE2EAppScope(
            programs: testPrograms,
            child: const Stack(
              children: [
                Center(child: Text('Main Screen Content')),
                FloatingProgramDockButton(
                  tournamentId: tournamentId,
                  isViewerMode: false,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openProgramFromDock(tester);

        expect(find.byType(ProgramBottomSheet), findsOneWidget);
        expect(
          find.text('1 / 8'),
          findsOneWidget,
          reason: 'アプリ再起動後も1ページ目維持規約が守られていること',
        );
      },
    );
  });
}
