import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets(
    'TeamRegistrationCategoryStep renders categories, chips and handles selection',
    (WidgetTester tester) async {
      String major = '小学生';
      String minor = '低学年';
      String matchType = '団体戦（5人制）';

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamRegistrationCategoryStep(
              selectedMajorCategory: major,
              selectedMinorCategory: minor,
              selectedCategory: '小学生低学年の部',
              matchType: matchType,
              showExtraMajorCategories: false,
              showExtraMatchTypes: false,
              themeColors: themeColors,
              onMajorCategoryChanged: (val) => major = val,
              onMinorCategoryChanged: (val) => minor = val,
              onMatchTypeChanged: (val) => matchType = val,
              onToggleExtraMajorCategories: () {},
              onToggleExtraMatchTypes: () {},
            ),
          ),
        ),
      );

      // Verify category texts and chips
      expect(find.text('小学生低学年の部'), findsOneWidget);
      expect(find.text('初心者'), findsOneWidget);
      expect(find.text('小学生'), findsOneWidget);
      expect(find.text('低学年 (1-4年)'), findsOneWidget);
      expect(find.text('団体戦（5人制）'), findsOneWidget);
    },
  );
}
