import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_score_marks.dart';

void main() {
  group('🛡️ BunaiksenScoreMarks Widget Tests', () {
    testWidgets('Renders draw icon (close) when both scores are 0', (
      WidgetTester tester,
    ) async {
      const match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒',
        redScore: 0,
        whiteScore: 0,
        redName: '選手A',
        whiteName: '選手B',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BunaiksenScoreMarks(
              match: match,
              isDark: false,
              isFinished: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets(
      'Renders score marks accurately with strike types and close icon on draw',
      (WidgetTester tester) async {
        final now = DateTime.now();
        final events = [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'e2',
            side: Side.white,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: now.add(const Duration(seconds: 10)),
          ),
        ];

        final match = MatchModel(
          id: 'm2',
          tournamentId: 't1',
          matchType: '先鋒',
          redScore: 1,
          whiteScore: 1,
          redName: '選手A',
          whiteName: '選手B',
          events: events,
          rule: const MatchRule(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BunaiksenScoreMarks(
                match: match,
                isDark: true,
                isFinished: true,
              ),
            ),
          ),
        );

        // 赤は初打突で '㋱'、白は2本目で 'コ'
        expect(find.textContaining('㋱'), findsOneWidget);
        expect(find.textContaining('コ'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget); // drawなのでcloseアイコン
      },
    );

    testWidgets('Renders victory match with remove icon', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final events = [
        ScoreEvent(
          id: 'e1',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: now,
        ),
        ScoreEvent(
          id: 'e2',
          side: Side.red,
          strikeType: StrikeType.dou,
          isIppon: true,
          timestamp: now.add(const Duration(seconds: 10)),
        ),
      ];

      final match = MatchModel(
        id: 'm3',
        tournamentId: 't1',
        matchType: '先鋒',
        redScore: 2,
        whiteScore: 0,
        redName: '選手A',
        whiteName: '選手B',
        events: events,
        rule: const MatchRule(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenScoreMarks(
              match: match,
              isDark: false,
              isFinished: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.textContaining('㋱'), findsOneWidget);
      expect(find.textContaining('ド'), findsOneWidget);
    });
  });
}
