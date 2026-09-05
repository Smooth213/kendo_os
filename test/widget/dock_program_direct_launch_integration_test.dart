import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('🥋 起動後直接ドックからプログラム表示＆リアルタイム更新統合テスト', () {
    tearDown(() async {
      await FloatingDockSheetManager.close(immediate: true);
    });

    testWidgets('道場ID未確定（起動直後 default_dojo_room）でも、直接ドックからプログラムを開いて全て表示され、'
        'プログラム更新時もリアルタイムに全件反映されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const tournamentId = 'tour_direct_open_999';

      // 1. 初期プログラム（3件）
      final initialPrograms = [
        ProgramModel(
          id: 'prog_1',
          tournamentId: tournamentId,
          title: '第1会場 進行表',
          fileUrl: 'https://example.com/prog1.png',
          fileType: 'image',
          pageCount: 1,
          createdAt: DateTime(2026, 9, 1),
        ),
        ProgramModel(
          id: 'prog_2',
          tournamentId: tournamentId,
          title: '男子個人 トーナメント表',
          fileUrl: 'https://example.com/prog2.jpg',
          fileType: 'image',
          pageCount: 1,
          createdAt: DateTime(2026, 9, 2),
        ),
        ProgramModel(
          id: 'prog_3',
          tournamentId: tournamentId,
          title: '女子団体 対戦表',
          fileUrl: 'https://example.com/prog3.png',
          fileType: 'image',
          pageCount: 1,
          createdAt: DateTime(2026, 9, 3),
        ),
      ];

      // リアルタイム更新用ストリームコントローラ（初期イベントを落とさないよう標準コントローラを使用）
      final programStreamController = StreamController<List<ProgramModel>>();
      addTearDown(programStreamController.close);

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      // アプリ起動直後の状態（currentDojoIdProvider は default_dojo_room のまま）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            currentDojoIdProvider.overrideWith((ref) => 'default_dojo_room'),
            programListProvider(
              tournamentId,
            ).overrideWith((ref) => programStreamController.stream),
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
            home: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: const [
                  Center(child: Text('大会ホームメイン画面')),
                  FloatingProgramDockButton(
                    tournamentId: tournamentId,
                    isViewerMode: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 初期プログラムをストリームへ投入
      programStreamController.add(initialPrograms);
      await tester.pumpAndSettle();

      // 2. 「大会プログラム管理」画面へ行かず、直接ドックボタンをタップ
      final dockButtonFinder = find.byType(FloatingProgramDockButton);
      expect(dockButtonFinder, findsOneWidget);

      // ドックボタンをタップしてスピードダイヤルを展開
      await tester.tap(find.byType(FloatingProgramDockButton));
      await tester.pumpAndSettle();

      // 親ボタンが✕マークに変わり、子アイテムに menu_book_rounded が現れること
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);

      // スピードダイヤルの「プログラム」子アイコンをタップ
      await tester.tap(find.byIcon(Icons.menu_book_rounded));
      await tester.pumpAndSettle();

      // 3. FloatingDockSheetManager により ProgramBottomSheet が開いていること
      expect(find.byType(ProgramBottomSheet), findsOneWidget);

      // 4. 初回オープン直後でもクルクルで止まらず、3件のプログラム全てがチップとして表示されていること
      expect(find.text('第1会場 進行表'), findsOneWidget);
      expect(find.text('男子個人 トーナメント表'), findsOneWidget);
      expect(find.text('女子団体 対戦表'), findsOneWidget);

      // 5. プログラムが更新（4件目「決勝トーナメント表」が追加）された場合
      final updatedPrograms = [
        ...initialPrograms,
        ProgramModel(
          id: 'prog_4',
          tournamentId: tournamentId,
          title: '決勝トーナメント表',
          fileUrl: 'https://example.com/prog4.png',
          fileType: 'image',
          pageCount: 1,
          createdAt: DateTime(2026, 9, 4),
        ),
      ];

      // ストリームへ更新データを投入
      programStreamController.add(updatedPrograms);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 6. ドック内のボトムシートに、更新された4件目のプログラムが即座に反映されること
      expect(find.text('決勝トーナメント表'), findsOneWidget);

      // チップのタップで切り替えができること
      await tester.tap(find.text('決勝トーナメント表'));
      await tester.pumpAndSettle();

      // 7. 閉じるボタンをタップするとシートが正常に閉じること
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProgramBottomSheet), findsNothing);
    });
  });
}
