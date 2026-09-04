import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_management_content_views.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ ProgramManagement Extracted Components Tests', () {
    final programs = [
      ProgramModel(
        id: 'p1',
        tournamentId: 't1',
        title: '進行表',
        fileUrl: 'https://example.com/file.pdf',
        fileType: 'pdf',
        createdAt: DateTime.now(),
      ),
      ProgramModel(
        id: 'p2',
        tournamentId: 't1',
        title: 'トーナメント表',
        fileUrl: 'https://example.com/file2.pdf',
        fileType: 'pdf',
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets(
      '1. ProgramManagementContentViews renders list view with Slidable',
      (tester) async {
        ProgramModel? deletedProgram;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    ProgramManagementContentViews.buildListView(
                      context: context,
                      programs: programs,
                      getSafeUrl: (url) => url,
                      onDelete: (p) {
                        deletedProgram = p;
                      },
                      isViewerMode: false,
                    ),
              ),
            ),
          ),
        );

        expect(find.text('進行表'), findsOneWidget);
        expect(find.text('トーナメント表'), findsOneWidget);

        // 常時表示のゴミ箱アイコンは削除され、存在しないこと
        expect(find.byIcon(Icons.delete_outline), findsNothing);

        // Slidableウィジェットが存在すること
        expect(find.byType(Slidable), findsNWidgets(2));

        // スワイプ（右から左へドラッグ）して削除アクションを表示
        await tester.drag(find.text('進行表'), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // 削除アクションが表示されること
        expect(find.text('削除'), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);

        // 削除タップでコールバックが呼ばれること
        await tester.tap(find.text('削除'));
        await tester.pumpAndSettle();

        expect(deletedProgram, isNotNull);
        expect(deletedProgram!.id, 'p1');
      },
    );

    testWidgets(
      '2. ProgramManagementContentViews viewer mode disables Slidable delete',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    ProgramManagementContentViews.buildListView(
                      context: context,
                      programs: programs,
                      getSafeUrl: (url) => url,
                      onDelete: (_) {},
                      isViewerMode: true,
                    ),
              ),
            ),
          ),
        );

        expect(find.text('進行表'), findsOneWidget);

        // 閲覧専用モードではSlidableもゴミ箱ボタンも存在しない
        expect(find.byType(Slidable), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
      },
    );

    testWidgets('3. Long press triggers onLongPress callback in normal mode', (
      tester,
    ) async {
      ProgramModel? longPressedProgram;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ProgramManagementContentViews.buildListView(
                context: context,
                programs: programs,
                getSafeUrl: (url) => url,
                onDelete: (_) {},
                isViewerMode: false,
                onLongPress: (p) {
                  longPressedProgram = p;
                },
              ),
            ),
          ),
        ),
      );

      // 長押し操作
      await tester.longPress(find.text('進行表'));
      await tester.pumpAndSettle();

      expect(longPressedProgram, isNotNull);
      expect(longPressedProgram!.id, 'p1');
    });

    testWidgets(
      '4. Selection mode shows checkboxes, toggles selection, and disables Slidable',
      (tester) async {
        ProgramModel? toggledProgram;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    ProgramManagementContentViews.buildListView(
                      context: context,
                      programs: programs,
                      getSafeUrl: (url) => url,
                      onDelete: (_) {},
                      isViewerMode: false,
                      isSelectionMode: true,
                      selectedProgramIds: {'p1'},
                      onToggleSelection: (p) {
                        toggledProgram = p;
                      },
                    ),
              ),
            ),
          ),
        );

        // 選択モード中はSlidableが無効化される
        expect(find.byType(Slidable), findsNothing);

        // p1はチェック済み、p2は未チェックのアイコンが表示されていること
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

        // p2をタップして選択切り替えコールバックが呼ばれること
        await tester.tap(find.text('トーナメント表'));
        await tester.pumpAndSettle();

        expect(toggledProgram, isNotNull);
        expect(toggledProgram!.id, 'p2');
      },
    );

    testWidgets(
      '5. ProgramManagementContentViews renders grid view with selection support',
      (tester) async {
        ProgramModel? toggledProgram;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    ProgramManagementContentViews.buildGridView(
                      context: context,
                      programs: programs,
                      getSafeUrl: (url) => url,
                      onDelete: (_) {},
                      isSelectionMode: true,
                      selectedProgramIds: {'p1'},
                      onToggleSelection: (p) {
                        toggledProgram = p;
                      },
                    ),
              ),
            ),
          ),
        );

        expect(find.text('進行表'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

        await tester.tap(find.text('トーナメント表'));
        await tester.pumpAndSettle();

        expect(toggledProgram, isNotNull);
        expect(toggledProgram!.id, 'p2');
      },
    );
  });
}
