import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/band/presentation/components/band_share_button.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_team_match_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import '../../../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const kataFinishedMatch = MatchModel(
    id: 'm_kata_fin_1',
    tournamentId: 'tourney_kata_1',
    matchType: '形・基本判定',
    status: 'finished',
    redName: '道上剣友会:皿田 脩人・塚本 大道',
    whiteName: '友道館:相手 太郎・相手 次郎',
    redScore: 3,
    whiteScore: 0,
    note: '第2試合場 (第2試合)',
    groupName: 'group_kata_1',
    order: 1.0,
    rule: MatchRule(isKataMatch: true, teamName: '道上剣友会'),
  );

  group('[Widget] TimelineKataAndBadgeComponents 統合テスト', () {
    testWidgets('剣道形がペア単位のアコーディオンとして個人戦形式で描画され、本数表記なし・BAND/スコアボタンが正しく備わること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionProvider.overrideWithValue(
              const PermissionState(
                canManageTournament: true,
                isReadOnly: false,
              ),
            ),
            matchListProvider.overrideWith((ref) => [kataFinishedMatch]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: createTestApp(
            Theme(
              data: ThemeData.light().copyWith(extensions: [themeColors]),
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: TimelineIndividualPlayerCard(
                    playerName: '皿田 脩人・塚本 大道',
                    playerMatches: [kataFinishedMatch],
                    playerComments: [],
                    categoryName: '小学生低学年の部',
                    teamName: '道上剣友会',
                    isReadOnlyUI: false,
                    isDark: false,
                    permissions: PermissionState(
                      canManageTournament: true,
                      isReadOnly: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      // 1. ヘッダーの丸アバター頭文字「皿」
      expect(find.text('皿'), findsOneWidget);

      // 2. ペア名「皿田 脩人・塚本 大道」が表示されること
      expect(
        find.textContaining('皿田 脩人・塚本 大道', findRichText: true),
        findsWidgets,
      );

      // 3. 通算戦績「（全1試合 • 1勝0敗）」が表示されること
      expect(
        find.textContaining('全1試合 • 1勝0敗', findRichText: true),
        findsOneWidget,
      );

      // 4. コート情報「第2試合場 (第2試合)」が表示されること
      expect(find.textContaining('第2試合場 (第2試合)'), findsOneWidget);

      // 5. 終了バッジが存在すること
      expect(find.byType(MatchStatusBadge), findsWidgets);

      // 6. 全試合終了サマリーで「本数 (〇本)」が付かず、「🏁 全試合終了: 通算 1勝 0敗 0分」となること
      expect(find.text('🏁 全試合終了: 通算 1勝 0敗 0分'), findsOneWidget);
      expect(find.textContaining('3本'), findsNothing);

      // 7. アコーディオンを展開
      await tester.tap(find.byType(ExpansionTile));
      await tester.safePumpAndSettle();

      // 8. 展開された MatchListTileCard が個人戦スタイルで描画されること
      expect(find.byType(MatchListTileCard), findsOneWidget);
      expect(find.text('道上剣友会'), findsWidgets);
      expect(find.text('友道館'), findsWidgets);

      // 9. BAND共有ボタン・スコアボタンが存在すること
      expect(find.byType(BandShareButton), findsOneWidget);
      expect(find.text('スコア'), findsOneWidget);
    });

    testWidgets(
      '団体戦・勝ち抜き戦カード（TimelineMatchGroupCard）の左上に錬成において ・申合せにおいて バッジが表示されること',
      (tester) async {
        // 錬成会団体戦
        final renseiGroup = [
          const MatchModel(
            id: 'rensei_m1',
            groupName: 'group_rensei_1',
            matchType: '先鋒戦',
            redName: '道上剣友会A: 選手1',
            whiteName: '相手チーム02: 選手2',
            status: 'in_progress',
            matchScene: 'renseikai',
            order: 1.0,
          ),
        ];

        // 申合せ団体戦
        final moushiawaseGroup = [
          const MatchModel(
            id: 'moushiawase_m1',
            groupName: 'group_moushiawase_1',
            matchType: '先鋒戦',
            redName: '道上剣友会A: 選手1',
            whiteName: '相手チーム03: 選手3',
            status: 'waiting',
            matchScene: 'moushiawase',
            order: 2.0,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: [
                    TimelineMatchGroupCard(
                      groupId: 'group_rensei_1',
                      groupList: renseiGroup,
                      groupComments: const [],
                      categoryName: '小学生の部',
                      teamName: '道上剣友会A',
                      label: '団体戦',
                      isReadOnlyUI: false,
                      canManageTournamentUI: true,
                      isDark: false,
                      tournamentId: 't1',
                      ownTeams: const ['道上剣友会A'],
                    ),
                    TimelineMatchGroupCard(
                      groupId: 'group_moushiawase_1',
                      groupList: moushiawaseGroup,
                      groupComments: const [],
                      categoryName: '小学生の部',
                      teamName: '道上剣友会A',
                      label: '団体戦',
                      isReadOnlyUI: false,
                      canManageTournamentUI: true,
                      isDark: false,
                      tournamentId: 't1',
                      ownTeams: const ['道上剣友会A'],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.safePumpAndSettle();

        // カード上段の左上に【錬成】バッジが表示されていること
        expect(find.text('【錬成】'), findsOneWidget);
        // カード上段の左上に【申合せ】バッジが表示されていること
        expect(find.text('【申合せ】'), findsOneWidget);
      },
    );

    testWidgets(
      '個人戦カード（TimelineIndividualPlayerCard）のサブタイトルに錬成において ・申合せにおいて が表示されること',
      (tester) async {
        final renseiIndivMatches = [
          const MatchModel(
            id: 'rensei_indiv_1',
            matchType: '個人戦',
            redName: '皿田 脩人',
            whiteName: '相手 太郎',
            status: 'finished',
            matchScene: 'renseikai',
            order: 1.0,
          ),
        ];

        final moushiawaseIndivMatches = [
          const MatchModel(
            id: 'moushiawase_indiv_1',
            matchType: '個人戦',
            redName: '久安 智也',
            whiteName: '相手 次郎',
            status: 'waiting',
            matchScene: 'moushiawase',
            order: 2.0,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: [
                    TimelineIndividualPlayerCard(
                      playerName: '皿田 脩人',
                      playerMatches: renseiIndivMatches,
                      playerComments: const [],
                      categoryName: '小学生個人の部',
                      teamName: '道上剣友会A',
                      isReadOnlyUI: false,
                      isDark: false,
                      permissions: const PermissionState(
                        canManageTournament: true,
                      ),
                    ),
                    TimelineIndividualPlayerCard(
                      playerName: '久安 智也',
                      playerMatches: moushiawaseIndivMatches,
                      playerComments: const [],
                      categoryName: '小学生個人の部',
                      teamName: '道上剣友会A',
                      isReadOnlyUI: false,
                      isDark: false,
                      permissions: const PermissionState(
                        canManageTournament: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.safePumpAndSettle();

        // 1段目のバッジに【錬成】および【申合せ】が表示されること
        expect(find.text('【錬成】'), findsWidgets);
        expect(find.text('【申合せ】'), findsWidgets);
      },
    );

    testWidgets(
      'リーグ団体戦ヘッダー（TimelineLeagueTeamMatchHeader）に錬成において ・申合せにおいて バッジが表示されること',
      (tester) async {
        final leagueBouts = [
          const MatchModel(
            id: 'league_bout_1',
            groupName: 'group_league_1',
            matchType: '先鋒戦',
            redName: '道上剣友会A: 選手1',
            whiteName: '相手チーム: 選手2',
            status: 'waiting',
            matchScene: 'renseikai',
            order: 1.0,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: TimelineLeagueTeamMatchHeader(
                  bouts: leagueBouts,
                  isReadOnlyUI: false,
                  boutsAllFinished: false,
                  boutsInProgress: false,
                  t1: '道上剣友会A',
                  t2: '相手チーム',
                  ownTeams: const ['道上剣友会A'],
                  mTitleColor: Colors.black,
                  isDark: false,
                  onShowSummaryInputDialog: (ctx, ref, b) {},
                ),
              ),
            ),
          ),
        );
        await tester.safePumpAndSettle();

        // リーグ戦中枠ヘッダーにも【錬成】バッジが表示されること
        expect(find.text('【錬成】'), findsOneWidget);
        expect(find.text('1ポジション'), findsOneWidget);
      },
    );
  });
}
