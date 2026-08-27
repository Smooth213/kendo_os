import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_match_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_match_list_header_bar.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('BunaiksenHome Components Tests', () {
    testWidgets('BunaiksenMatchListHeaderBar renders properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenMatchListHeaderBar(
              themeColors: AppThemeColors.ofMode(
                isDark: false,
                mode: 'bunaiksen',
              ),
              hasMatches: true,
              onQuickMatch: () {},
              onBulkRuleEdit: () {},
            ),
          ),
        ),
      );

      expect(find.text('本日の試合一覧'), findsOneWidget);
      expect(find.text('クイック対戦'), findsOneWidget);
      expect(find.text('ルール一括変更'), findsOneWidget);
    });

    testWidgets('BunaiksenMatchCard renders match details', (tester) async {
      const match = MatchModel(
        id: 'm1',
        tournamentId: 'bunaiksen_20260821',
        matchType: '個人戦',
        redName: '佐藤',
        whiteName: '鈴木',
        status: 'in_progress',
        note: '稽古1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenMatchCard(
              match: match,
              index: 0,
              dateId: 'bunaiksen_20260821',
              isDark: false,
              onTap: () {},
              onEditNote: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('鈴木'), findsOneWidget);
      expect(find.text('稽古1'), findsOneWidget);
      expect(find.text('第1試合'), findsOneWidget);
      expect(find.text('試合中'), findsOneWidget);
    });
  });
}
