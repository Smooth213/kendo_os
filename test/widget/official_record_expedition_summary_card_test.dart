import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_expedition_summary_card.dart';

void main() {
  group('🛡️ OfficialRecordExpeditionSummaryCard Widget Tests', () {
    testWidgets('Renders summary items when matches provided', (tester) async {
      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '先鋒',
          redName: '剣道クラブ:山田',
          whiteName: 'ライバル道場:田中',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          groupName: '1回戦',
          matchScene: 'renseikai',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OfficialRecordExpeditionSummaryCard(
                matches: matches,
                isDark: false,
                registeredTeamNames: {'剣道クラブ'},
                registeredPlayerNames: {'山田'},
              ),
            ),
          ),
        ),
      );

      expect(find.text('成績サマリー'), findsOneWidget);
      expect(find.text('詳細分析 ›'), findsOneWidget);
      expect(find.text('⚔️ 錬成会'), findsOneWidget);
      expect(find.text('🏆 本戦'), findsOneWidget);
      expect(find.text('🤝 申し合わせ'), findsOneWidget);
    });

    testWidgets('Renders empty when matches list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfficialRecordExpeditionSummaryCard(
              matches: [],
              isDark: false,
              registeredTeamNames: {},
              registeredPlayerNames: {},
            ),
          ),
        ),
      );

      expect(find.text('成績サマリー'), findsNothing);
    });
  });
}
