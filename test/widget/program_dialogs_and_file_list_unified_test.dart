import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_delete_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_reorderable_file_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_title_preview_dialog.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/program_repository.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class _MockProgramRepository extends Fake implements ProgramRepository {
  final List<String> deletedIds = [];

  @override
  Future<void> deleteProgram(ProgramModel program) async {
    deletedIds.add(program.id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] 大会プログラム 並び替え・削除ダイアログ・タイトルプレビュー統合検証テスト', () {
    testWidgets('ファイル一覧が表示されタップ選択できること', (tester) async {
      final files = [
        PlatformFile(name: '大会要項.pdf', size: 1024),
        PlatformFile(name: 'トーナメント表.pdf', size: 2048),
      ];

      int selectedIdx = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProgramReorderableFileList(
                orderedFiles: files,
                selectedIndex: 0,
                isDark: false,
                onReorder: (oldIdx, newIdx) {},
                onFileSelected: (idx) {
                  selectedIdx = idx;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('大会要項.pdf'), findsOneWidget);
      expect(find.text('トーナメント表.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

      await tester.tap(find.text('トーナメント表.pdf'));
      await tester.pump();

      expect(selectedIdx, 1);
    });

    testWidgets('ダークモードでも正しく装飾および番号バッジが描画されること', (tester) async {
      final files = [PlatformFile(name: '大会案内.pdf', size: 512)];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
          ),
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: ProgramReorderableFileList(
                orderedFiles: files,
                selectedIndex: 0,
                isDark: true,
                onReorder: (oldIdx, newIdx) {},
                onFileSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('大会案内.pdf'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('個別削除ダイアログが表示され承認時に削除処理が実行されること', (tester) async {
      final mockRepo = _MockProgramRepository();
      final program = ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: '進行表1',
        fileUrl: 'https://example.com/1.pdf',
        fileType: 'pdf',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [programRepositoryProvider.overrideWithValue(mockRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      ProgramDeleteDialogHelper.confirmSingleDelete(
                        context: context,
                        ref: ref,
                        program: program,
                      );
                    },
                    child: const Text('削除ボタン'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('削除ボタン'));
      await tester.pumpAndSettle();

      expect(find.text('プログラムの削除'), findsOneWidget);
      expect(find.text('「進行表1」を削除しますか？\nこの操作は取り消せません。'), findsOneWidget);

      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(mockRepo.deletedIds, contains('p1'));
    });

    testWidgets('一括削除ダイアログが表示され承認時に選択アイテムが削除されること', (tester) async {
      final mockRepo = _MockProgramRepository();
      final programs = [
        ProgramModel(
          id: 'p1',
          tournamentId: 't1',
          title: '進行表1',
          fileUrl: 'https://example.com/1.pdf',
          fileType: 'pdf',
          createdAt: DateTime.now(),
        ),
        ProgramModel(
          id: 'p2',
          tournamentId: 't1',
          title: '進行表2',
          fileUrl: 'https://example.com/2.pdf',
          fileType: 'pdf',
          createdAt: DateTime.now(),
        ),
      ];
      bool onDeletedCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [programRepositoryProvider.overrideWithValue(mockRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      ProgramDeleteDialogHelper.confirmBulkDelete(
                        context: context,
                        ref: ref,
                        allPrograms: programs,
                        selectedProgramIds: {'p1', 'p2'},
                        onDeleted: () {
                          onDeletedCalled = true;
                        },
                      );
                    },
                    child: const Text('一括削除ボタン'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('一括削除ボタン'));
      await tester.pumpAndSettle();

      expect(find.text('プログラムの一括削除'), findsOneWidget);
      expect(find.text('選択した 2件のプログラムを削除しますか？\nこの操作は取り消せません。'), findsOneWidget);

      await tester.tap(find.text('すべて削除'));
      await tester.pumpAndSettle();

      expect(mockRepo.deletedIds, containsAll(['p1', 'p2']));
      expect(onDeletedCalled, isTrue);
    });

    testWidgets('タイトルプレビューダイアログにおいて高コントラストで視認できること', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dummyFiles = [
        PlatformFile(
          name: '第41回大会要項.pdf',
          size: 1024,
          bytes: null,
          path: 'dummy/path/file1.pdf',
        ),
      ];

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      ProgramTitlePreviewDialog.show(
                        context: context,
                        files: dummyFiles,
                      );
                    },
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('プログラム名'), findsWidgets);
      expect(find.text('第41回大会要項.pdf'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
