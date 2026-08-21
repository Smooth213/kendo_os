import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_player_select_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_rule_section.dart';

void main() {
  group('BunaiksenQuickMatch Components Tests', () {
    testWidgets('renders BunaiksenQuickMatchPlayerSelectSection correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) =>
                    BunaiksenQuickMatchPlayerSelectSection(
                      redPlayer: '選手A',
                      whitePlayer: '選手B',
                      onRedPlayerSelected: (_) {},
                      onWhitePlayerSelected: (_) {},
                      ref: ref,
                    ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('選手A'), findsOneWidget);
      expect(find.text('選手B'), findsOneWidget);
    });

    testWidgets('renders BunaiksenQuickMatchRuleSection correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenQuickMatchRuleSection(
              selectedMatchTime: 3.0,
              selectedIsIpponShobu: false,
              onMatchTimeChanged: (_) {},
              onIsIpponShobuChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('3分'), findsOneWidget);
      expect(find.text('3本勝負'), findsOneWidget);
    });
  });
}
