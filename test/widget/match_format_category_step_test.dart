import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_step.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  const dummyThemeColors = AppThemeColors(
    primaryAccent: Colors.indigo,
    softAccent: Colors.indigoAccent,
    cardBackground: Colors.white,
    scaffoldBackground: Colors.white,
    textColor: Colors.black,
    subTextColor: Colors.grey,
    separatorColor: Colors.grey,
    inputBackground: Colors.white,
    hintColor: Colors.grey,
    rosePink: Colors.pink,
    successColor: Colors.green,
    warningColor: Colors.orange,
    errorColor: Colors.red,
    infoColor: Colors.blue,
  );

  testWidgets('MatchFormatCategoryStep renders correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MatchFormatCategoryStep(
              tournamentId: 'tourney1',
              category: '小学生の部',
              selectedMajorCategory: '小学生の部',
              selectedMinorCategory: '低学年の部',
              selectedTeamId: 'team1',
              majorCategories: const ['小学生の部', '中学生の部'],
              getMinorCategories: (major) => ['低学年の部', '高学年の部'],
              onCategoryChanged: (major, minor) {},
              onTeamSelected: (team) {},
              onAdjustOrder: (team) {},
              onNavigateToTeamRegistration: () {},
              themeColors: dummyThemeColors,
              isDark: false,
              buildSectionTitle: (title) => Text(title),
            ),
          ),
        ),
      ),
    );

    expect(find.text('小学生の部'), findsWidgets);
  });
}
