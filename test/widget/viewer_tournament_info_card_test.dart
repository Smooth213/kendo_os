import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_tournament_info_card.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('🛡️ ViewerTournamentInfoCard Widget Tests', () {
    testWidgets('Renders tournament info correctly', (tester) async {
      final tournament = TournamentModel(
        id: 't1',
        organizationId: 'org1',
        name: '全国剣道大会',
        date: DateTime(2026, 8, 20),
        venue: '日本武道館',
        notes: '注意事項メモ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewerTournamentInfoCard(tournament: tournament),
          ),
        ),
      );

      expect(find.text('全国剣道大会'), findsOneWidget);
      expect(find.text('2026年08月20日'), findsOneWidget);
      expect(find.text('日本武道館'), findsOneWidget);
      expect(find.text('注意事項メモ'), findsOneWidget);
    });
  });
}
