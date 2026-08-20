import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_preview_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_dynamic_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_section_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_selection_card.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ SetupMatchFormat Components Widget Tests', () {
    testWidgets('MatchFormatDynamicHeader renders header texts and progress', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFormatDynamicHeader(
              currentPage: 0,
              themeColors: themeColors,
            ),
          ),
        ),
      );

      expect(find.text('試合ルールの設定'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('MatchFormatSectionHeader renders title and accent bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchFormatSectionHeader(
              title: '試合時間の設定',
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('試合時間の設定'), findsOneWidget);
    });

    testWidgets('MatchFormatCategoryPreviewCard renders category text', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchFormatCategoryPreviewCard(
              category: '小学生 低学年 (1-4年)',
              themeColors: themeColors,
              textColor: Colors.black,
            ),
          ),
        ),
      );

      expect(find.text('設定されるカテゴリ名'), findsOneWidget);
      expect(find.text('小学生 低学年 (1-4年)'), findsOneWidget);
    });

    testWidgets(
      'MatchFormatTeamSelectionCard renders team info and triggers callbacks',
      (tester) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        const team = TeamModel(
          id: 'team1',
          tournamentId: 't1',
          teamName: '洗心道場 A',
          category: '小学生',
          matchType: '5人制',
          playerNames: ['先鋒', '次鋒', '中堅', '副将', '大将'],
        );

        bool tappedSelect = false;
        bool tappedAdjust = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MatchFormatTeamSelectionCard(
                team: team,
                isSelected: true,
                themeColors: themeColors,
                textColor: Colors.black,
                isDark: false,
                onSelect: () {
                  tappedSelect = true;
                },
                onAdjustOrder: () {
                  tappedAdjust = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('洗心道場 A'), findsOneWidget);
        expect(find.text('オーダーを調整'), findsOneWidget);

        await tester.tap(find.text('オーダーを調整'));
        await tester.pump();
        expect(tappedAdjust, isTrue);

        await tester.tap(find.text('洗心道場 A'));
        await tester.pump();
        expect(tappedSelect, isTrue);
      },
    );
  });
}
