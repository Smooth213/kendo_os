import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_index_pane.dart';

void main() {
  group('[Widget] ManualIndexPane 目次・検索総合テスト', () {
    late List<dynamic> realIndex;

    setUpAll(() {
      final file = File(
        'packages/documentation_runtime/manuals/manual_search_index.json',
      );
      if (file.existsSync()) {
        realIndex = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      } else {
        realIndex = [];
      }
    });

    testWidgets('モックデータにおいて 目次表示と検索絞り込み・選択コールバックが正常動作すること', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      String searchQuery = '';
      String selectedFile = '';
      final mockIndex = [
        {
          'path': 'manuals/quickstart/index.md',
          'title': 'クイックスタート',
          'headings': ['導入', '初期設定'],
          'tags': ['開始', '設定'],
        },
        {
          'path': 'manuals/bunaiksen/index.md',
          'title': '部内戦ガイド',
          'headings': ['ルール', '進行'],
          'tags': ['部内戦'],
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ManualIndexPane(
                  searchController: controller,
                  searchQuery: searchQuery,
                  indexList: mockIndex,
                  currentFilePath: 'manuals/quickstart/index.md',
                  onSearchChanged: (val) {
                    setState(() => searchQuery = val);
                  },
                  onSearchCleared: () {
                    controller.clear();
                    setState(() => searchQuery = '');
                  },
                  onFileSelected: (path) {
                    selectedFile = path;
                  },
                );
              },
            ),
          ),
        ),
      );

      // 初期表示で両方のタイトルが表示されること
      expect(find.text('クイックスタート'), findsOneWidget);
      expect(find.text('部内戦ガイド'), findsOneWidget);

      // タップでコールバックが呼ばれること
      await tester.tap(find.text('部内戦ガイド'));
      expect(selectedFile, 'manuals/bunaiksen/index.md');

      // 検索入力
      await tester.enterText(find.byType(TextField), '部内戦');
      await tester.pumpAndSettle();

      expect(find.text('クイックスタート'), findsNothing);
      expect(find.text('部内戦ガイド'), findsOneWidget);
    });

    testWidgets('実データ検索において 「ドック」検索とクリアボタンが正常動作すること', (
      WidgetTester tester,
    ) async {
      if (realIndex.isEmpty) return;

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

      final targetTileFinder = find.widgetWithText(
        ListTile,
        'ドック＆フローティングパネル活用法',
      );
      expect(targetTileFinder, findsOneWidget);

      // タップ
      await tester.tap(targetTileFinder);
      await tester.pumpAndSettle();
      expect(selectedPath, contains('dock_guide.md'));

      // 検索クリア
      final clearButtonFinder = find.byTooltip('検索をクリアして一覧に戻る');
      expect(clearButtonFinder, findsOneWidget);
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
    });

    testWidgets('実データ検索において 「ルール設定」検索で部門別ルール設定が表示されること', (
      WidgetTester tester,
    ) async {
      if (realIndex.isEmpty) return;

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
