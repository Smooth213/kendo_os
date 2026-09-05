import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_index_pane.dart';

void main() {
  group('📖 ManualIndexPane 実データ検索統合Widgetテスト', () {
    late List<dynamic> realIndex;

    setUpAll(() {
      final file = File(
        'packages/documentation_runtime/manuals/manual_search_index.json',
      );
      realIndex = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    });

    testWidgets('【実データ検索】「ドック」入力でドックガイドが表示されタップ選択できること', (tester) async {
      final controller = TextEditingController();
      String searchQuery = '';
      String selectedPath = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ManualIndexPane(
                  searchController: controller,
                  searchQuery: searchQuery,
                  indexList: realIndex,
                  currentFilePath: '',
                  onSearchChanged: (val) {
                    setState(() => searchQuery = val);
                  },
                  onSearchCleared: () {
                    controller.clear();
                    setState(() => searchQuery = '');
                  },
                  onFileSelected: (path) {
                    selectedPath = path;
                  },
                );
              },
            ),
          ),
        ),
      );

      // 初期状態では複数のタイトルが表示されている
      expect(find.byType(ListView), findsOneWidget);

      // 「ドック」で検索
      await tester.enterText(find.byType(TextField), 'ドック');
      await tester.pumpAndSettle();

      // 「ドック」が含まれるListTileが表示されていること
      final targetTileFinder = find.widgetWithText(
        ListTile,
        'ドック＆フローティングパネル活用法',
      );
      expect(targetTileFinder, findsOneWidget);

      // ドック操作ガイドをタップ
      await tester.tap(targetTileFinder);
      await tester.pumpAndSettle();

      expect(selectedPath, contains('dock_guide.md'));

      // 検索クリアボタンのテスト
      final clearButtonFinder = find.byTooltip('検索をクリアして一覧に戻る');
      expect(clearButtonFinder, findsOneWidget);
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
    });

    testWidgets('【実データ検索】「ルール」入力で部門別ルール設定が表示されること', (tester) async {
      final controller = TextEditingController();
      String searchQuery = '';
      String selectedPath = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ManualIndexPane(
                  searchController: controller,
                  searchQuery: searchQuery,
                  indexList: realIndex,
                  currentFilePath: '',
                  onSearchChanged: (val) {
                    setState(() => searchQuery = val);
                  },
                  onSearchCleared: () {
                    controller.clear();
                    setState(() => searchQuery = '');
                  },
                  onFileSelected: (path) {
                    selectedPath = path;
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ルール設定');
      await tester.pumpAndSettle();

      final targetTileFinder = find.widgetWithText(ListTile, '部門別ルール設定');
      expect(targetTileFinder, findsOneWidget);

      await tester.tap(targetTileFinder);
      await tester.pumpAndSettle();

      expect(selectedPath, contains('category_rules.md'));
    });
  });
}
