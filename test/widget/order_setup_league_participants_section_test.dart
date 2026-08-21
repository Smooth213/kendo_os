import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_league_participants_section.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets(
    'OrderSetupLeagueParticipantsSection renders league participants list',
    (WidgetTester tester) async {
      final participants = ['自チーム', '相手チームA'];
      final teamOrders = <String, List<String>>{
        '自チーム': ['選手1', '選手2'],
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OrderSetupLeagueParticipantsSection(
                  themeColors: AppThemeColors.ofMode(
                    isDark: false,
                    mode: 'normal',
                  ),
                  leagueParticipants: participants,
                  leagueTeamOrders: teamOrders,
                  positions: const ['先鋒', '中堅', '大将'],
                  ruleTeamName: '自チーム',
                  matchType: '団体戦',
                  opponentTeamSuggestions: const ['相手チームA', '相手チームB'],
                  onParticipantsChanged: () {},
                  isDark: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('1. リーグ参加者リストの作成'), findsOneWidget);
      expect(find.text('自チーム'), findsOneWidget);
      expect(find.text('相手チームA'), findsOneWidget);
      expect(find.text('リストに追加'), findsOneWidget);
    },
  );
}
