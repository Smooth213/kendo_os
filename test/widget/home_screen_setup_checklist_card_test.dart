import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/home_screen_setup_checklist_card.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ HomeScreenSetupChecklistCard Widget Tests', () {
    testWidgets(
      'Renders HomeScreenSetupChecklistCard with completed and uncompleted steps',
      (WidgetTester tester) async {
        final sampleTournament = TournamentModel(
          id: 'tour_1',
          name: '第50回剣道大会',
          date: DateTime(2026, 8, 15),
          venue: '武道館',
          organizationId: 'org_1',
          categoryRules: const {'団体戦': CategoryRuleSet()},
        );

        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [themeColors]),
            home: Scaffold(
              body: HomeScreenSetupChecklistCard(
                tournament: sampleTournament,
                teams: const ['チームA'],
                themeColors: themeColors,
                isDark: false,
                enableLiquidGlass: false,
                tournamentId: 'tour_1',
              ),
            ),
          ),
        );

        expect(find.text('大会準備ステップ'), findsOneWidget);
        expect(
          find.text('75% 完了'),
          findsOneWidget,
        ); // 基本情報(1) + チーム(1) + ルール(1) = 3/4 (75%)
        expect(find.text('大会基本情報の登録'), findsOneWidget);
        expect(find.text('出場チーム・選手の登録'), findsOneWidget);
        expect(find.text('部門別ルールの設定'), findsOneWidget);
        expect(find.text('最初の試合枠の作成'), findsOneWidget);
      },
    );
  });
}
