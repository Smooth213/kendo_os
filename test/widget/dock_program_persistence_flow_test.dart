import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_view_state_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences mockPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kendo_os_theme_mode': 'system',
      'kendo_os_enable_liquid_glass': true,
    });
    mockPrefs = await SharedPreferences.getInstance();
    ProgramViewStateService.instance.resetForTesting();
    await ProgramViewStateService.instance.init(prefs: mockPrefs);
    ProgramViewerMediaCache.shared.clear();
    ProgramViewerPdfPageCache.shared.clear();
  });

  tearDown(() async {
    await FloatingDockSheetManager.close(immediate: true);
  });

  const tournamentId = 'tour_dock_persist_test';

  final testPrograms = [
    ProgramModel(
      id: 'prog_schedule',
      tournamentId: tournamentId,
      title: '試合進行表（PDF）',
      fileUrl: 'https://example.com/schedule.pdf',
      fileType: 'pdf',
      pageCount: 6,
      createdAt: DateTime(2026, 9, 1),
    ),
    ProgramModel(
      id: 'prog_tournament_bracket',
      tournamentId: tournamentId,
      title: 'トーナメント表（PDF）',
      fileUrl: 'https://example.com/bracket.pdf',
      fileType: 'pdf',
      pageCount: 10,
      createdAt: DateTime(2026, 9, 2),
    ),
    ProgramModel(
      id: 'prog_venue_map',
      tournamentId: tournamentId,
      title: '会場案内図（画像）',
      fileUrl: 'https://example.com/map.png',
      fileType: 'image',
      pageCount: 1,
      createdAt: DateTime(2026, 9, 3),
    ),
  ];

  Widget buildDockAppScope({
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
      ],
      child: MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [themeColors]),
        home: const Scaffold(
          body: Stack(
            children: [
              Center(child: Text('Main Content')),
              FloatingProgramDockButton(
                tournamentId: tournamentId,
                isViewerMode: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openProgramFromDock(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingProgramDockButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
  }

  group('[Widget] ドックプログラム閲覧位置の端末保存・自動復元 網羅テスト', () {
    testWidgets('フローティングドックから起動時、前回選択プログラムが自動復元されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 事前に「トーナメント表（PDF）」（インデックス1）を保存
      ProgramViewStateService.instance.setLastProgramIndex(tournamentId, 1);

      await tester.pumpWidget(buildDockAppScope(programs: testPrograms));
      await tester.pumpAndSettle();

      // フローティングドックを展開して「プログラム」を開く
      await openProgramFromDock(tester);

      // ボトムシートが展開されていること
      expect(find.byType(ProgramBottomSheet), findsOneWidget);

      // 選択されているチップが「トーナメント表（PDF）」（インデックス1）であること
      final filterChips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList();
      expect(filterChips.length, 3);
      expect(filterChips[0].selected, isFalse);
      expect(filterChips[1].selected, isTrue); // トーナメント表
      expect(filterChips[2].selected, isFalse);
    });

    testWidgets('ボトムシート内でプログラムおよびページ位置を変更すると、端末に即座に永続化されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDockAppScope(programs: testPrograms));
      await tester.pumpAndSettle();

      // ドックから開く
      await openProgramFromDock(tester);

      // 1番目のプログラム「試合進行表（PDF）」で次ページへ進める
      expect(find.text('1 / 6'), findsOneWidget);
      final nextButton = find.byTooltip('次のページ');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // ページ2になり、保存値が 2 に更新されること
      expect(find.text('2 / 6'), findsOneWidget);
      expect(
        ProgramViewStateService.instance.getLastPageNumber('prog_schedule'),
        2,
      );

      // 2番目のプログラム「トーナメント表（PDF）」に切り替える
      await tester.tap(find.text('トーナメント表（PDF）'));
      await tester.pumpAndSettle();

      // 選択中インデックスが 1 として保存されていること
      expect(
        ProgramViewStateService.instance.getLastProgramIndex(tournamentId),
        1,
      );

      // 「トーナメント表（PDF）」でもページを 3 まで進める
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('3 / 10'), findsOneWidget);
      expect(
        ProgramViewStateService.instance.getLastPageNumber(
          'prog_tournament_bracket',
        ),
        3,
      );

      // 1番目の「試合進行表（PDF）」に戻した際、先ほどの「ページ2」が独立して復元されること
      await tester.tap(find.text('試合進行表（PDF）'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 6'), findsOneWidget);
    });

    testWidgets('シートを閉じて再展開しても、前回の選択プログラムとページが正しく復元されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildDockAppScope(programs: testPrograms));
      await tester.pumpAndSettle();

      // 1回目のオープン
      await openProgramFromDock(tester);

      // 2番目のプログラム「トーナメント表（PDF）」を選択し、4ページ目へ進める
      await tester.tap(find.text('トーナメント表（PDF）'));
      await tester.pumpAndSettle();

      final nextButton = find.byTooltip('次のページ');
      await tester.tap(nextButton); // 2
      await tester.pumpAndSettle();
      await tester.tap(nextButton); // 3
      await tester.pumpAndSettle();
      await tester.tap(nextButton); // 4
      await tester.pumpAndSettle();
      expect(find.text('4 / 10'), findsOneWidget);

      // ボトムシートを閉じる
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramBottomSheet), findsNothing);

      // 2回目のオープン（ドックボタンを再度タップ）
      await openProgramFromDock(tester);

      // 再展開時にも「トーナメント表（PDF）」が選択され、4ページ目で開いていること
      expect(find.byType(ProgramBottomSheet), findsOneWidget);
      final filterChips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList();
      expect(filterChips[1].selected, isTrue);
      expect(find.text('4 / 10'), findsOneWidget);
    });

    testWidgets('アプリ再起動（SharedPreferences コールドスタート）でも保存値から復元されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // SharedPreferences に事前に永続化された状態をシミュレート
      SharedPreferences.setMockInitialValues({
        'kendo_os_prog_last_idx_$tournamentId': 1,
        'kendo_os_prog_last_page_prog_tournament_bracket': 5,
      });
      final coldPrefs = await SharedPreferences.getInstance();

      // インメモリキャッシュを破棄し、コールドスタート初期化
      ProgramViewStateService.instance.resetForTesting();
      await ProgramViewStateService.instance.init(prefs: coldPrefs);

      // アプリ起動
      await tester.pumpWidget(
        buildDockAppScope(programs: testPrograms, customPrefs: coldPrefs),
      );
      await tester.pumpAndSettle();

      // ドックからプログラムを開く
      await openProgramFromDock(tester);

      // コールドスタート後でも即座に「トーナメント表（PDF）」の 5ページ目が復元されていること
      final filterChips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList();
      expect(filterChips[1].selected, isTrue);
      expect(find.text('5 / 10'), findsOneWidget);
    });
  });
}
