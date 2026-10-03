import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_step.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] その他カテゴリおよび混成チーム入力画面の視覚整合性テスト', () {
    testWidgets('ライトテーマにおいて試合形式設定のその他カテゴリ選択時に小分類と自由入力欄が崩れず描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final theme = ThemeData.light().copyWith(extensions: [themeColors]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registeredTeamsProvider(
              'tourney_golden_1',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: MatchFormatCategoryStep(
                tournamentId: 'tourney_golden_1',
                category: '小中学生混成の部',
                selectedMajorCategory: 'その他',
                selectedMinorCategory: '混成',
                customCategoryName: '小中学生混成',
                selectedTeamId: null,
                majorCategories: MatchFormatSetupHelper.majorCategories,
                getMinorCategories: MatchFormatSetupHelper.getMinorCategories,
                onCategoryChanged: (major, minor) {},
                onCustomCategoryChanged: (_) {},
                onTeamSelected: (_) {},
                onAdjustOrder: (_) {},
                onEditTeam: (_) {},
                onDeleteTeam: (_) {},
                onNavigateToTeamRegistration: () {},
                themeColors: themeColors,
                isDark: false,
                buildSectionTitle: (title) => Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MatchFormatCategoryStep), findsOneWidget);
      expect(find.text('その他'), findsWidgets);
      expect(find.text('混成'), findsWidgets);
      expect(find.text('小中学生混成'), findsOneWidget);
      expect(find.text('設定されるカテゴリ名'), findsOneWidget);
      expect(find.text('小中学生混成の部'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ダークテーマにおいてチーム登録のその他カテゴリ選択時に破綻なく視覚的整合性が維持されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');
      final theme = ThemeData.dark().copyWith(extensions: [themeColors]);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              backgroundColor: const Color(0xFF121212),
              body: TeamRegistrationCategoryStep(
                selectedMajorCategory: 'その他',
                selectedMinorCategory: '自由',
                selectedCategory: '道場選抜混成の部',
                customCategoryName: '道場選抜混成',
                matchType: '団体戦',
                showExtraMajorCategories: true,
                showExtraMatchTypes: false,
                themeColors: themeColors,
                onMajorCategoryChanged: (_) {},
                onMinorCategoryChanged: (_) {},
                onCustomCategoryChanged: (_) {},
                onMatchTypeChanged: (_) {},
                onToggleExtraMajorCategories: () {},
                onToggleExtraMatchTypes: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TeamRegistrationCategoryStep), findsOneWidget);
      expect(find.text('その他'), findsWidgets);
      expect(find.text('自由'), findsWidgets);
      expect(find.text('道場選抜混成'), findsOneWidget);
      expect(find.text('生成されるカテゴリ名'), findsOneWidget);
      expect(find.text('道場選抜混成の部'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('モバイル横幅375pxにおいてその他カテゴリ入力欄がオーバーフローなく完全に収まること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final theme = ThemeData.light().copyWith(extensions: [themeColors]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registeredTeamsProvider(
              'tourney_golden_2',
            ).overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: MatchFormatCategoryStep(
                tournamentId: 'tourney_golden_2',
                category: '地域親善オープン選抜の部',
                selectedMajorCategory: 'その他',
                selectedMinorCategory: '直接入力',
                customCategoryName: '地域親善オープン選抜',
                selectedTeamId: null,
                majorCategories: MatchFormatSetupHelper.majorCategories,
                getMinorCategories: MatchFormatSetupHelper.getMinorCategories,
                onCategoryChanged: (major, minor) {},
                onCustomCategoryChanged: (_) {},
                onTeamSelected: (_) {},
                onAdjustOrder: (_) {},
                onEditTeam: (_) {},
                onDeleteTeam: (_) {},
                onNavigateToTeamRegistration: () {},
                themeColors: themeColors,
                isDark: false,
                buildSectionTitle: (title) => Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MatchFormatCategoryStep), findsOneWidget);
      expect(find.text('地域親善オープン選抜'), findsOneWidget);
      expect(find.text('設定されるカテゴリ名'), findsOneWidget);
      expect(find.text('地域親善オープン選抜の部'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
