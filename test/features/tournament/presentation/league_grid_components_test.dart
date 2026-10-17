import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_league_grid_cell_renderer.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_league_grid_table.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_league_grid_table.dart';
import 'package:kendo_os/features/viewer/components/viewer_league_grid_table.dart';
import 'package:kendo_os/features/viewer/components/viewer_league_grid_table_card.dart';
import 'package:kendo_os/features/viewer/painters/league_table_painters.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] リーグ対戦星取表コンポーネント統合テスト', () {
    group('ViewerLeagueGridTable ウィジェットテスト', () {
      testWidgets('観客席リーググリッドカードが試合データとともに正しく描画されること', (tester) async {
        final matches = [
          const MatchListProjection(
            id: 'm1',
            tournamentId: 't1',
            matchOrder: 1,
            matchType: 'team',
            redName: 'チームA',
            whiteName: 'チームB',
            redScore: 2,
            whiteScore: 1,
            status: 'finished',
            note: '',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ViewerLeagueGridTable(
                groupName: 'リーグA',
                matches: matches,
                isDark: false,
                stats: const [],
                isLeagueRule: true,
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('viewer_match_card_リーグA')), findsOneWidget);
      });
    });

    group('ViewerLeagueGridTableCard ウィジェットテスト', () {
      testWidgets('リーグ対戦グリッドテーブルのヘッダーおよびチーム名が正しく描画されること', (
        WidgetTester tester,
      ) async {
        const match1 = MatchModel(
          id: 'm1',
          redName: 'チームA: 山田',
          whiteName: 'チームB: 佐藤',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          matchType: 'リーグ戦',
          note: '[リーグ戦]',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ViewerLeagueGridTableCard(
                groupName: 'Aブロック',
                matches: [match1],
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('勝数'), findsOneWidget);
        expect(find.text('勝者'), findsOneWidget);
        expect(find.text('本数'), findsOneWidget);
        expect(find.text('順位'), findsOneWidget);
        expect(find.text('チームA'), findsWidgets);
        expect(find.text('チームB'), findsWidgets);
      });
    });

    group('OfficialRecordLeagueGridTable ウィジェットテスト', () {
      testWidgets('公式記録リーグ対戦表のチーム名セルが正しく描画されること', (WidgetTester tester) async {
        const rule = MatchRule(isLeague: true, matchTimeMinutes: 3.0);

        const matches = [
          MatchModel(
            id: 'm1',
            tournamentId: 't1',
            matchType: '団体戦',
            redName: '東京A',
            whiteName: '大阪B',
            redScore: 2,
            whiteScore: 1,
            status: 'approved',
            rule: rule,
            note: '[リーグ戦]',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: OfficialRecordLeagueGridTable(
                  groupName: 'Aブロック',
                  matches: matches,
                  isDark: false,
                  scoreTableBuilder: (name, bouts) => Text('ScoreTable: $name'),
                  individualListBuilder: (name, bouts) =>
                      Text('IndivList: $name'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('東京A'), findsWidgets);
        expect(find.text('大阪B'), findsWidgets);
      });
    });

    group('BunaiksenLeagueGridTable ウィジェットテスト', () {
      testWidgets('部内戦リーグ戦グリッドテーブルのヘッダーが正しく描画されること', (
        WidgetTester tester,
      ) async {
        const matches = [
          MatchModel(
            id: 'm1',
            tournamentId: 't1',
            matchType: 'team',
            redName: 'RedTeam',
            whiteName: 'WhiteTeam',
            status: 'finished',
            redScore: 2,
            whiteScore: 1,
            order: 1,
            rule: MatchRule(isLeague: true),
          ),
        ];

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BunaiksenLeagueGridTable(
                  groupName: 'Aパート',
                  matches: matches,
                  isDark: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('勝数'), findsOneWidget);
        expect(find.text('勝者'), findsOneWidget);
        expect(find.text('本数'), findsOneWidget);
        expect(find.text('順位'), findsOneWidget);
      });
    });

    group('BunaiksenLeagueGridCellRenderer ウィジェットテスト', () {
      testWidgets('同チーム対戦の対角線セルで斜線ペインターが正しく描画されること', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    BunaiksenLeagueGridCellRenderer.buildMatchCell(
                      context: context,
                      rowTeam: 'チームA',
                      colTeam: 'チームA',
                      normalMatches: const [],
                      isIndiv: false,
                      isDark: false,
                      blankColor: Colors.grey,
                      borderColor: Colors.black,
                    ),
              ),
            ),
          ),
        );

        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is DiagonalLinePainter,
          ),
          findsOneWidget,
        );
      });

      testWidgets('試合結果セルで得点テキストが正しく描画されること', (tester) async {
        const match = MatchModel(
          id: 'm1',
          tournamentId: 't1',
          redName: 'チームA:先鋒',
          whiteName: 'チームB:先鋒',
          matchType: '先鋒',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    BunaiksenLeagueGridCellRenderer.buildMatchCell(
                      context: context,
                      rowTeam: 'チームA',
                      colTeam: 'チームB',
                      normalMatches: const [match],
                      isIndiv: false,
                      isDark: false,
                      blankColor: Colors.grey,
                      borderColor: Colors.black,
                    ),
              ),
            ),
          ),
        );

        expect(find.text('2'), findsOneWidget);
      });
    });
  });
}
