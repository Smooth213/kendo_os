import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/features/viewer/components/viewer_official_record_table_sections.dart';
import 'package:kendo_os/features/viewer/components/viewer_team_scoreboard_table_builder.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_individual_player_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_list_tile_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_team_card.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const kataMatch = MatchModel(
    id: 'viewer_kata_1',
    tournamentId: 'tourney_v_1',
    matchType: '形・基本判定',
    status: 'finished',
    redName: '道上剣友会:皿田 脩人・塚本 大道',
    whiteName: '友道館:相手 太郎・相手 次郎',
    redScore: 3,
    whiteScore: 0,
    note: '第1試合場 (第1試合)',
    groupName: 'kata_team_group_1',
    order: 1.0,
    rule: MatchRule(isKataMatch: true, teamName: '道上剣友会'),
  );

  group('[Widget] ViewerComponentsAndSections 統合テスト', () {
    testWidgets('ViewerTeamCardにおいて剣道形が個人戦形式に分類され正しく描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => [kataMatch]),
          ],
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: ViewerTeamCard(
                    teamName: '道上剣友会',
                    teamMatchesList: [kataMatch],
                    ownTeams: ['道上剣友会'],
                    sanitizedQuery: '',
                    matchedMatchIds: {},
                    matchedGroupNames: {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. 団体戦カード（ViewerGroupMatchCard）は生成されず、ViewerIndividualPlayerCard が生成されること
      expect(find.byType(ViewerGroupMatchCard), findsNothing);
      expect(find.byType(ViewerIndividualPlayerCard), findsOneWidget);

      // 2. 形・武道アイコンおよび「形・基本判定」セクションヘッダーが表示されること
      expect(find.byIcon(Icons.sports_martial_arts), findsOneWidget);
      expect(find.text('形・基本判定'), findsOneWidget);

      // 3. ペア名「皿田 脩人・塚本 大道」が表示されること
      expect(
        find.textContaining('皿田 脩人・塚本 大道', findRichText: true),
        findsWidgets,
      );

      // 4. 通算戦績および全試合終了サマリー（本数表記なし）が表示されること
      expect(find.text('🏁 全試合終了: 通算 1勝 0敗 0分'), findsOneWidget);
      expect(find.textContaining('3本'), findsNothing);

      // 5. アコーディオンを展開して ViewerMatchListTileCard の描画を確認
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.byType(ViewerMatchListTileCard), findsOneWidget);
      expect(find.text('道上剣友会'), findsWidgets);
      expect(find.text('友道館'), findsWidgets);
    });

    testWidgets(
      'ViewerOfficialScoreTableCardにおいて チームタイトルおよびスコアテーブルが適切に描画されること',
      (tester) async {
        final matches = [
          const MatchListProjection(
            id: 'm1',
            tournamentId: 't1',
            matchOrder: 1,
            matchType: '先鋒',
            redName: 'チームA : 山田',
            whiteName: 'チームB : 田中',
            redScore: 2,
            whiteScore: 1,
            status: 'finished',
            note: '1回戦',
            isKachinuki: false,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ViewerOfficialScoreTableCard(
                  groupName: 'group1',
                  matches: matches,
                  isDark: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('【団体戦】 チームA vs チームB (1回戦)'), findsOneWidget);
      },
    );

    testWidgets('観客用個人戦リストカードの試合項目が正しく描画されること', (tester) async {
      final matches = [
        const MatchListProjection(
          id: 'm1',
          tournamentId: 't1',
          matchOrder: 1,
          matchType: '個人戦',
          redName: '道場A : 佐藤',
          whiteName: '道場B : 鈴木',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          note: '',
          isKachinuki: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ViewerOfficialIndividualListCard(
                groupName: '男子個人',
                matches: matches,
                isDark: false,
                applySort: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('【個人戦】 男子個人'), findsOneWidget);
    });

    testWidgets('ViewerTeamScoreboardTableBuilderにおいてヘッダーおよび合計行が正しく描画されること', (
      tester,
    ) async {
      final headerRow = ViewerTeamScoreboardTableBuilder.buildHeaderRow(
        '赤チーム',
        '白チーム',
        false,
      );
      final totalRow = ViewerTeamScoreboardTableBuilder.buildTotalRow(
        TeamMatchResult(
          redPoints: 4,
          whitePoints: 1,
          redWins: 2,
          whiteWins: 1,
          allFinished: true,
          hasDaihyo: false,
          isTie: false,
          teamWinner: 'red',
        ),
        false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Table(children: [headerRow, totalRow])),
        ),
      );

      expect(find.text('赤チーム'), findsOneWidget);
      expect(find.text('白チーム'), findsOneWidget);
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('観客側スコアテーブルにおいて一本勝ちの技マーク表記が正しく描画されること', (tester) async {
      final matchRow = ViewerTeamScoreboardTableBuilder.buildMatchRow(
        const MatchListProjection(
          id: 'm1',
          tournamentId: 't1',
          matchOrder: 1,
          matchType: '先鋒',
          status: 'finished',
          redName: 'A道場 : 皿田',
          whiteName: 'B道場 : 選手',
          redScore: 1,
          whiteScore: 0,
          redPointMarks: ['コ'],
          firstPointSide: 'red',
        ),
        tester.element(find.byType(Container)),
        false,
        ['皿田'],
        ['選手'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Table(children: [matchRow])),
        ),
      );

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);

      final positionedWidgets = tester.widgetList<Positioned>(
        find.byType(Positioned),
      );
      expect(positionedWidgets.any((p) => p.top == 2 && p.left == 2), isTrue);
    });
  });
}
