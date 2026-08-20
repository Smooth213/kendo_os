import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_export_bar.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('🛡️ ViewerOfficialRecordExportBar Widget Tests', () {
    testWidgets('Renders PDF and Image export buttons properly', (
      tester,
    ) async {
      final proj = TournamentProjection(
        tournament: TournamentModel(
          id: 't1',
          name: 'テスト大会',
          date: DateTime(2026, 8, 20),
          organizationId: 'org1',
          venue: '第一武道場',
        ),
        allMatches: [],
        categoryToGroupKeys: {
          '一般の部': ['リーグA'],
        },
        teamMatches: {
          'リーグA': TeamMatchProjection(
            groupName: 'リーグA',
            redTeamName: 'チームA',
            whiteTeamName: 'チームB',
            matchType: 'team',
            note: '',
            isKachinuki: false,
            isLeague: true,
            matches: [],
            result: TeamMatchResult(
              redWins: 0,
              whiteWins: 0,
              redPoints: 0,
              whitePoints: 0,
              allFinished: true,
              hasDaihyo: false,
              isTie: false,
              teamWinner: 'draw',
            ),
          ),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ViewerOfficialRecordExportBar(
                category: '一般の部',
                sortedGroupKeys: const ['リーグA'],
                proj: proj,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('viewer_export_pdf_button')), findsOneWidget);
      expect(
        find.byKey(const Key('viewer_export_image_button')),
        findsOneWidget,
      );
      expect(find.text('PDF印刷'), findsOneWidget);
      expect(find.text('画像シェア'), findsOneWidget);
    });
  });
}
