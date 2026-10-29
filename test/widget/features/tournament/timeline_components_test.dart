import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_score_summary.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_team_match_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_card.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testMatches = [
    const MatchModel(
      id: 'match_1',
      tournamentId: 't_1',
      matchType: '先鋒',
      redName: '道上:選手A',
      whiteName: '相手11:選手B',
      groupName: '相手11 vs 道上',
      note: '第1試合場, 3試合目',
      status: 'in_progress',
      order: 1,
    ),
    const MatchModel(
      id: 'match_2',
      tournamentId: 't_1',
      matchType: '大将',
      redName: '道上:選手C',
      whiteName: '相手11:選手D',
      groupName: '相手11 vs 道上',
      note: '第1試合場, 3試合目',
      status: 'waiting',
      order: 2,
    ),
  ];

  group('[Widget] タイムライン主要コンポーネント統合テスト', () {
    group('TimelineMatchGroupCard 5-Tier Header テスト', () {
      testWidgets('団体戦親カードで1段目から5段目の要素が正しく配置および描画されること', (
        WidgetTester tester,
      ) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: createTestApp(
              Theme(
                data: ThemeData.light().copyWith(extensions: [themeColors]),
                child: Scaffold(
                  body: TimelineMatchGroupCard(
                    groupId: 'group_test_1',
                    groupList: testMatches,
                    label: '道上 vs 相手11',
                    groupComments: const [],
                    categoryName: '小学生の部',
                    teamName: '道上',
                    isReadOnlyUI: false,
                    canManageTournamentUI: true,
                    isDark: false,
                    tournamentId: 't_1',
                    ownTeams: const ['道上'],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.safePumpAndSettle();

        // 1段目: ステータスバッジ（赤色LIVE）
        expect(find.text('試合中 (LIVE)'), findsOneWidget);

        // 2段目: 対戦カード名
        expect(find.text('道上 vs 相手11'), findsOneWidget);

        // 3段目: コート・進行・メモ
        expect(find.text('第1試合場, 3試合目'), findsOneWidget);

        // 4段目: アクションボタン（スコアボタン、ルールボタン）
        expect(find.text('スコア'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        // 5段目: スコアサマリー（(0)）
        expect(find.text('(0)'), findsWidgets);
      });

      testWidgets('観客席ビュアー親カードでも1段目から5段目構造が描画され管理操作ボタンが非表示であること', (
        WidgetTester tester,
      ) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: createTestApp(
              Theme(
                data: ThemeData.light().copyWith(extensions: [themeColors]),
                child: Scaffold(
                  body: ViewerGroupMatchCard(
                    groupKey: 'group_test_1',
                    groupList: testMatches,
                    matchLabel: '道上 vs 相手11',
                    groupComments: const [],
                    ownTeams: const ['道上'],
                    sanitizedQuery: '',
                    matchedMatchIds: const {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.safePumpAndSettle();

        // 1段目: ステータスバッジ
        expect(find.text('試合中 (LIVE)'), findsOneWidget);

        // 2段目: 対戦カード名
        expect(find.text('道上 vs 相手11'), findsOneWidget);

        // 3段目: コート情報
        expect(find.text('第1試合場, 3試合目'), findsOneWidget);

        // 4段目: 観客用スコアボタン
        expect(find.text('スコア'), findsOneWidget);

        // 管理用ボタン（簡易入力、オーダー編集）が存在しないこと
        expect(find.text('簡易入力'), findsNothing);
        expect(find.byIcon(Icons.swap_vert), findsNothing);
      });

      testWidgets('スワイプ時に編集アクションが表示されること', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        const match = MatchModel(
          id: 'm1',
          tournamentId: 't1',
          redName: 'A Team: Player 1',
          whiteName: 'B Team: Player 2',
          matchType: '団体戦',
          groupName: 'group_1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: const [
                    TimelineMatchGroupCard(
                      groupId: 'group_1',
                      groupList: [match],
                      groupComments: [],
                      categoryName: 'General',
                      teamName: 'A Team',
                      label: '団体戦',
                      isReadOnlyUI: false,
                      canManageTournamentUI: true,
                      isDark: false,
                      tournamentId: 't1',
                      ownTeams: [],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.safePumpAndSettle();

        expect(find.byType(TimelineMatchGroupCard), findsOneWidget);

        // 左へスワイプしてスワイプアクションを表示
        await tester.drag(
          find.byType(TimelineMatchGroupCard),
          const Offset(-500, 0),
        );
        await tester.safePumpAndSettle();

        // スワイプ時に「メモ」ではなく「編集」が表示されていること
        expect(find.text('編集'), findsOneWidget);
        expect(find.text('メモ'), findsNothing);
      });
    });

    group('TimelineGroupScoreSummary ウィジェットテスト', () {
      testWidgets('勝数が計算されチーム情報およびポイントが正しく描画されること', (
        WidgetTester tester,
      ) async {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        const matches = [
          MatchModel(
            id: 'm1',
            matchType: '団体戦',
            redName: '青龍館: 山田',
            whiteName: '白虎館: 佐藤',
            redScore: 2,
            whiteScore: 0,
            status: 'finished',
          ),
          MatchModel(
            id: 'm2',
            matchType: '団体戦',
            redName: '青龍館: 鈴木',
            whiteName: '白虎館: 田中',
            redScore: 1,
            whiteScore: 1,
            status: 'finished',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: TimelineGroupScoreSummary(
                groupList: matches,
                rTeam: '青龍館',
                wTeam: '白虎館',
                ownTeams: const ['青龍館'],
                titleColor: AppKendoColors.pureBlack,
                isDark: false,
              ),
            ),
          ),
        );

        final redText = tester.widget<Text>(find.text('青龍館'));
        expect(redText.style?.color, equals(const Color(0xFFD97706)));
        expect(redText.style?.fontWeight, equals(AppFontWeight.black));

        final whiteText = tester.widget<Text>(find.text('白虎館'));
        expect(whiteText.style?.color, equals(AppKendoColors.pureBlack));

        expect(find.text('自道場'), findsNothing);
        expect(find.text('1'), findsOneWidget); // red wins: 1
        expect(find.text('(3)'), findsOneWidget); // red points: 3
        expect(find.text('0'), findsOneWidget); // white wins: 0
        expect(find.text('(1)'), findsOneWidget); // white points: 1
      });
    });

    group('TimelineLeagueTeamMatchHeader ウィジェットテスト', () {
      testWidgets('チーム名とポジション数およびステータスが正しく描画されること', (tester) async {
        const bout1 = MatchModel(
          id: 'm1',
          tournamentId: 't1',
          redName: 'Team A : Player 1',
          whiteName: 'Team B : Player 1',
          matchType: '先鋒',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: TimelineLeagueTeamMatchHeader(
                  bouts: const [bout1],
                  isReadOnlyUI: false,
                  boutsAllFinished: true,
                  boutsInProgress: false,
                  t1: 'Team A',
                  t2: 'Team B',
                  ownTeams: const ['Team A'],
                  mTitleColor: Colors.black,
                  isDark: false,
                  onShowSummaryInputDialog: (ctx, ref, list) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Team A'), findsOneWidget);
        expect(find.text('Team B'), findsOneWidget);
        expect(find.text('1ポジション'), findsOneWidget);
        expect(find.text('終了'), findsOneWidget);
      });
    });
  });
}
