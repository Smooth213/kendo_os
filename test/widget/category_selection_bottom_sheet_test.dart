import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/category_selection_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  group('[Widget] CategorySelectionBottomSheet 単体検証', () {
    testWidgets('初期カテゴリが正しくパースされ大分類と小分類が選択状態になること', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CategorySelectionBottomSheet(
            title: '「テストチーム」の部門選択',
            initialCategory: '中学生男子の部',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('「テストチーム」の部門選択'), findsOneWidget);
      expect(find.text('中学生'), findsOneWidget);
      expect(find.text('中学生男子の部'), findsWidgets);
    });

    testWidgets('大分類を小学生に切り替えると小学生用の小分類が表示されること', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CategorySelectionBottomSheet(
            title: '「テストチーム」の部門選択',
            initialCategory: '中学生の部',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 小学生を選択
      await tester.tap(find.text('小学生'));
      await tester.pumpAndSettle();

      expect(find.text('低学年 (1-4年)'), findsOneWidget);
      expect(find.text('高学年 (5-6年)'), findsOneWidget);
      expect(find.text('1年'), findsOneWidget);
    });

    testWidgets('その他を選択するとカスタム部門名入力欄が表示されること', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CategorySelectionBottomSheet(
            title: '「テストチーム」の部門選択',
            initialCategory: '中学生の部',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('その他'));
      await tester.pumpAndSettle();

      expect(find.text('カスタム部門名を入力（任意）'), findsOneWidget);
    });

    testWidgets('決定ボタンをタップすると生成された部門名が返されること', (tester) async {
      String? result;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await CategorySelectionBottomSheet.show(
                    context: context,
                    title: 'テスト部門選択',
                    initialCategory: '中学生男子の部',
                  );
                },
                child: const Text('開く'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('この部門に設定'), findsOneWidget);
      await tester.tap(find.text('この部門に設定'));
      await tester.pumpAndSettle();

      expect(result, equals('中学生男子の部'));
    });
  });
}
