import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/category_cascade_selector_view.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

  group('[Widget] CategoryCascadeSelectorView ウィジェットテスト', () {
    testWidgets('大分類チップをタップすると連動して小分類が展開されコールバックが発火すること', (tester) async {
      String selectedMajor = '小学生';
      String selectedMinor = '低学年';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategoryCascadeSelectorView(
                  selectedMajorCategory: selectedMajor,
                  selectedMinorCategory: selectedMinor,
                  themeColors: themeColors,
                  onCategoryChanged:
                      ({
                        required majorCategory,
                        required minorCategory,
                        customCategoryName,
                      }) {
                        setState(() {
                          selectedMajor = majorCategory;
                          selectedMinor = minorCategory;
                        });
                      },
                );
              },
            ),
          ),
        ),
      );

      // 初期表示で「小学生」と「低学年 (1-4年)」が表示されていること
      expect(find.text('小学生'), findsOneWidget);
      expect(find.text('低学年 (1-4年)'), findsOneWidget);

      // 「中学生」をタップ
      await tester.tap(find.text('中学生'));
      await tester.pumpAndSettle();

      expect(selectedMajor, '中学生');
      // 中学生に連動して「1年」「男子」などが表示されること
      expect(find.text('男子'), findsOneWidget);
    });
  });
}
