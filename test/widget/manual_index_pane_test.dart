import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_index_pane.dart';

void main() {
  group('🛡️ ManualIndexPane Widget Tests', () {
    testWidgets('Renders manual index list and filters items on search', (
      tester,
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
  });
}
