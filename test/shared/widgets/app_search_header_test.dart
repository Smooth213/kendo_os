import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_search_header.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

void main() {
  group('🔍 AppSearchHeader Widget Tests', () {
    Widget buildTestableWidget({required Widget child, bool isDark = false}) {
      return MaterialApp(
        theme: ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          extensions: [AppThemeColors.ofMode(isDark: isDark, mode: 'normal')],
        ),
        home: Scaffold(body: child),
      );
    }

    testWidgets('1. 初期表示時に検索ヒントテキストと検索アイコン、キャンセルボタンが正しく描画されること', (
      WidgetTester tester,
    ) async {
      String query = '';
      bool isClosed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSearchHeader(
            searchQuery: query,
            onSearchQueryChanged: (val) => query = val,
            onClose: () => isClosed = true,
          ),
        ),
      );

      // ヒントテキストの確認
      expect(find.text('選手名・チーム名で検索...'), findsOneWidget);
      // 検索アイコンの確認
      expect(find.byIcon(Icons.search), findsOneWidget);
      // キャンセルボタンの確認
      expect(find.text('キャンセル'), findsOneWidget);
      // クエリが空のときはクリアアイコンが表示されないこと
      expect(find.byIcon(Icons.cancel), findsNothing);
      expect(isClosed, isFalse);
    });

    testWidgets('2. 検索テキストを入力した際に onSearchQueryChanged が発火すること', (
      WidgetTester tester,
    ) async {
      String currentQuery = '';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestableWidget(
              child: AppSearchHeader(
                searchQuery: currentQuery,
                onSearchQueryChanged: (val) {
                  setState(() {
                    currentQuery = val;
                  });
                },
                onClose: () {},
              ),
            );
          },
        ),
      );

      final textField = find.byType(AppTextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, '山田');
      await tester.pumpAndSettle();

      expect(currentQuery, '山田');
      // クエリが存在するときはクリアアイコン（Icons.cancel）が表示されること
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('3. クリアアイコン（Icons.cancel）をタップした際にクエリが空文字にリセットされること', (
      WidgetTester tester,
    ) async {
      String currentQuery = '佐々木';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestableWidget(
              child: AppSearchHeader(
                searchQuery: currentQuery,
                onSearchQueryChanged: (val) {
                  setState(() {
                    currentQuery = val;
                  });
                },
                onClose: () {},
              ),
            );
          },
        ),
      );

      expect(find.byIcon(Icons.cancel), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pumpAndSettle();

      expect(currentQuery, '');
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('4. キャンセルボタンをタップした際に onClose コールバックが実行されること', (
      WidgetTester tester,
    ) async {
      bool closedCalled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSearchHeader(
            searchQuery: '検索ワード',
            onSearchQueryChanged: (_) {},
            onClose: () {
              closedCalled = true;
            },
          ),
        ),
      );

      final cancelButton = find.text('キャンセル');
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(closedCalled, isTrue);
    });

    testWidgets('5. ダークモード設定時でも文字・アイコン・背景が破綻せずレンダリングされること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          isDark: true,
          child: AppSearchHeader(
            searchQuery: '剣道部',
            onSearchQueryChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('6. カスタム hintText が正しく反映されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: AppSearchHeader(
            searchQuery: '',
            hintText: 'カスタム検索ワードを入力...',
            onSearchQueryChanged: (_) {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('カスタム検索ワードを入力...'), findsOneWidget);
    });
  });
}
