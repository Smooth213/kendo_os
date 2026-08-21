import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_inner_comment_widget.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_title_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_rename_team_sheet.dart';
import 'package:kendo_os/shared/domain/entities/match_comment_model.dart';

void main() {
  group('Timeline Components & Helper Tests', () {
    test('TimelineLeagueTitleHelper generates descriptive title correctly', () {
      final matches = [
        const MatchModel(
          id: 'm1',
          tournamentId: 't1',
          order: 1,
          redName: 'Aチーム',
          whiteName: 'Bチーム',
          matchType: 'team',
        ),
        const MatchModel(
          id: 'm2',
          tournamentId: 't1',
          order: 2,
          redName: 'Bチーム',
          whiteName: 'Cチーム',
          matchType: 'team',
        ),
      ];

      final title = TimelineLeagueTitleHelper.generateDescriptiveLeagueTitle(
        matches,
        ['Aチーム'],
      );
      expect(title, contains('Aチーム'));
      expect(title, contains('3チームリーグ'));
    });

    testWidgets('TimelineRenameTeamSheet renders properly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TimelineRenameTeamSheet(
                  tournamentId: 't1',
                  oldName: '旧チーム名',
                  ref: ref,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('チーム名の修正・統合'), findsOneWidget);
      expect(find.text('一括修正して統合する'), findsOneWidget);
    });

    testWidgets('TimelineInnerCommentWidget renders text properly', (
      tester,
    ) async {
      const comment = MatchCommentModel(
        id: 'c1',
        tournamentId: 't1',
        text: 'テスト見出しコメント',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TimelineInnerCommentWidget(
                  comment: comment,
                  permissions: const PermissionState(canManageTournament: true),
                  isDark: false,
                  ref: ref,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('テスト見出しコメント'), findsOneWidget);
    });
  });
}
