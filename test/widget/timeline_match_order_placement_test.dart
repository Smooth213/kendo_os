import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_children_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_matchup_tile.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('[Widget] Timeline Match Placement & Sorting テスト', () {
    test('チームカード内の対戦枠: 新しく作成した対戦カード（グループ）が最上位（先頭）に配置されること', () {
      // 先に作られた団体戦グループ (group_1, order: 0)
      final group1Matches = [
        const MatchModel(
          id: 'm1_senpo',
          groupName: 'group_1',
          redName: '道上剣友会 : 山田',
          whiteName: 'ライバルA : 田中',
          matchType: '先鋒',
          order: 0,
        ),
        const MatchModel(
          id: 'm1_taisho',
          groupName: 'group_1',
          redName: '道上剣友会 : 佐藤',
          whiteName: 'ライバルA : 鈴木',
          matchType: '大将',
          order: 4,
        ),
      ];

      // あとから追加作成された団体戦グループ (group_2, order: 10)
      final group2Matches = [
        const MatchModel(
          id: 'm2_senpo',
          groupName: 'group_2',
          redName: '道上剣友会 : 高橋',
          whiteName: 'ライバルB : 伊藤',
          matchType: '先鋒',
          order: 10,
        ),
        const MatchModel(
          id: 'm2_taisho',
          groupName: 'group_2',
          redName: '道上剣友会 : 渡辺',
          whiteName: 'ライバルB : 中村',
          matchType: '大将',
          order: 14,
        ),
      ];

      final allTeamMatches = [...group1Matches, ...group2Matches];

      final classified = TimelinePlayerMatchClassifier.classifyTeamMatches(
        teamMatchesList: allTeamMatches,
        teamName: '道上剣友会',
        sanitizedQuery: '',
        matchedMatchIds: {},
        matchedGroupNames: {},
        ownTeams: ['道上剣友会'],
      );

      // sortedGroups の先頭が後から作成された group_2 になっていることを検証
      expect(classified.sortedGroups.length, 2);
      expect(classified.sortedGroups.first.key, 'group_2');
      expect(classified.sortedGroups.last.key, 'group_1');
    });

    testWidgets('団体戦アコーディオン内: 先鋒〜大将の後に、代表戦および追加試合が正しく後方に追加されること', (
      tester,
    ) async {
      final matches = [
        const MatchModel(
          id: 'm_senpo',
          groupName: 'group_team',
          redName: '道上 : 選手A',
          whiteName: '相手 : 選手1',
          matchType: '先鋒',
          order: 0,
        ),
        const MatchModel(
          id: 'm_jiho',
          groupName: 'group_team',
          redName: '道上 : 選手B',
          whiteName: '相手 : 選手2',
          matchType: '次鋒',
          order: 1,
        ),
        const MatchModel(
          id: 'm_chuken',
          groupName: 'group_team',
          redName: '道上 : 選手C',
          whiteName: '相手 : 選手3',
          matchType: '中堅',
          order: 2,
        ),
        const MatchModel(
          id: 'm_fukusho',
          groupName: 'group_team',
          redName: '道上 : 選手D',
          whiteName: '相手 : 選手4',
          matchType: '副将',
          order: 3,
        ),
        const MatchModel(
          id: 'm_taisho',
          groupName: 'group_team',
          redName: '道上 : 選手E',
          whiteName: '相手 : 選手5',
          matchType: '大将',
          order: 4,
        ),
        // あとから追加された代表戦 (order: 5)
        const MatchModel(
          id: 'm_daihyo',
          groupName: 'group_team',
          redName: '道上 : 選手E',
          whiteName: '相手 : 選手5',
          matchType: '代表戦',
          order: 5,
        ),
        // あとから「対戦を追加」で追加されたお代わり試合 (order: 6)
        const MatchModel(
          id: 'm_extra',
          groupName: 'group_team',
          redName: '道上 : 控え選手',
          whiteName: '相手 : 控え選手',
          matchType: '第6試合',
          note: '追加試合',
          order: 6,
        ),
      ];

      late BuildContext capturedCtx;
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (ctx, ref, child) {
                capturedCtx = ctx;
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final children = TimelineGroupChildrenBuilder.buildChildren(
        context: capturedCtx,
        ref: capturedRef,
        groupList: matches,
        groupComments: [],
        label: '団体戦',
        isReadOnlyUI: false,
        isDark: false,
        permissions: const PermissionState(role: UserRole.operator),
        rule: const MatchRule(positions: ['先鋒', '次鋒', '中堅', '副将', '大将']),
        firstMatch: matches.first,
      );

      // Dividerを除いた MatchListTileCard を抽出
      final matchCards = children.whereType<MatchListTileCard>().toList();

      expect(matchCards.length, 7);

      // 順序の検証：先鋒(0) ➔ 次鋒(1) ➔ 中堅(2) ➔ 副将(3) ➔ 大将(4) ➔ 代表戦(5) ➔ 追加試合(6)
      expect(matchCards[0].initialMatch.matchType, '先鋒');
      expect(matchCards[1].initialMatch.matchType, '次鋒');
      expect(matchCards[2].initialMatch.matchType, '中堅');
      expect(matchCards[3].initialMatch.matchType, '副将');
      expect(matchCards[4].initialMatch.matchType, '大将');
      expect(matchCards[5].initialMatch.matchType, '代表戦');
      expect(matchCards[6].initialMatch.matchType, '第6試合');
    });

    testWidgets(
      '団体戦/リーグ戦において、対戦カードごとにまとまり（TimelineLeagueMatchupTile）、その中に個別の試合が含まれること',
      (tester) async {
        final leagueMatches = [
          // 対戦1: 道剣 vs テスト001-1
          const MatchModel(
            id: 'm1_senpo',
            groupName: 'Bリーグ',
            redName: '道剣 : 皿田 脩人',
            whiteName: 'テスト001-1 : 選手A',
            matchType: '先鋒',
            note: '[リーグ戦] 第1試合場, 1試合目, Bリーグ',
            order: 0,
          ),
          const MatchModel(
            id: 'm1_taisho',
            groupName: 'Bリーグ',
            redName: '道剣 : 久安 智也',
            whiteName: 'テスト001-1 : 選手B',
            matchType: '大将',
            note: '[リーグ戦] 第1試合場, 1試合目, Bリーグ',
            order: 1,
          ),
          // 対戦2: 道剣 vs テスト001-2
          const MatchModel(
            id: 'm2_senpo',
            groupName: 'Bリーグ',
            redName: '道剣 : 皿田 脩人',
            whiteName: 'テスト001-2 : 選手C',
            matchType: '先鋒',
            note: '[リーグ戦] 第1試合場, 2試合目, Bリーグ',
            order: 2,
          ),
          const MatchModel(
            id: 'm2_taisho',
            groupName: 'Bリーグ',
            redName: '道剣 : 久安 智也',
            whiteName: 'テスト001-2 : 選手D',
            matchType: '大将',
            note: '[リーグ戦] 第1試合場, 2試合目, Bリーグ',
            order: 3,
          ),
        ];

        late BuildContext capturedCtx;
        late WidgetRef capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (ctx, ref, _) {
                  capturedCtx = ctx;
                  capturedRef = ref;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        final children = TimelineGroupChildrenBuilder.buildChildren(
          context: capturedCtx,
          ref: capturedRef,
          groupList: leagueMatches,
          groupComments: [],
          label: '団体戦/リーグ戦',
          isReadOnlyUI: false,
          isDark: false,
          permissions: const PermissionState(role: UserRole.operator),
          rule: const MatchRule(positions: ['先鋒', '大将']),
          firstMatch: leagueMatches.first,
          ownTeams: const ['道剣'],
        );

        // Column の中の TimelineLeagueMatchupTile を抽出
        final column = children.whereType<Column>().first;
        final matchupTiles = column.children
            .whereType<TimelineLeagueMatchupTile>()
            .toList();

        // 対戦カードが2つにまとまっていること
        expect(matchupTiles.length, 2);
        expect(matchupTiles[0].matchupName, '道剣 vs テスト001-1');
        expect(matchupTiles[0].bouts.length, 2);
        expect(matchupTiles[0].bouts[0].matchType, '先鋒');
        expect(matchupTiles[0].bouts[1].matchType, '大将');

        expect(matchupTiles[1].matchupName, '道剣 vs テスト001-2');
        expect(matchupTiles[1].bouts.length, 2);
        expect(matchupTiles[1].bouts[0].matchType, '先鋒');
        expect(matchupTiles[1].bouts[1].matchType, '大将');
      },
    );

    testWidgets(
      'リーグ戦の対戦カード（TimelineLeagueMatchupTile）が独自のSlidableを持ち、対戦単位でスワイプ操作が可能なこと',
      (tester) async {
        final bouts = [
          const MatchModel(
            id: 'm1',
            groupName: 'group_league',
            redName: '道剣 : 選手A',
            whiteName: '相手 : 選手1',
            matchType: '先鋒',
            order: 0,
            tournamentId: 'tour_123',
          ),
          const MatchModel(
            id: 'm2',
            groupName: 'group_league',
            redName: '道剣 : 選手B',
            whiteName: '相手 : 選手2',
            matchType: '大将',
            order: 1,
            tournamentId: 'tour_123',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: TimelineLeagueMatchupTile(
                  matchupName: '道剣 vs 相手',
                  bouts: bouts,
                  ownTeams: const ['道剣'],
                  isReadOnlyUI: false,
                  isDark: false,
                  permissions: const PermissionState(role: UserRole.admin),
                ),
              ),
            ),
          ),
        );

        // Slidable が存在し、対戦カードがラップされていること
        expect(find.byType(Slidable), findsOneWidget);
        expect(find.text('道剣 vs 相手'), findsOneWidget);
      },
    );

    testWidgets('全試合形式（団体リーグ戦、リーグ個人戦、勝ち抜き戦、通常団体戦）の階層構造が正しく構築されること', (
      tester,
    ) async {
      late BuildContext capturedCtx;
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (ctx, ref, _) {
                capturedCtx = ctx;
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      // 1. 団体リーグ戦（3階層：TimelineLeagueMatchupTile が生成されること）
      final leagueTeamMatches = [
        const MatchModel(
          id: 'm_lt1',
          redName: 'Aチーム : 先鋒',
          whiteName: 'Bチーム : 先鋒',
          matchType: '先鋒',
          order: 0,
        ),
      ];
      final leagueTeamChildren = TimelineGroupChildrenBuilder.buildChildren(
        context: capturedCtx,
        ref: capturedRef,
        groupList: leagueTeamMatches,
        groupComments: [],
        label: '団体戦/リーグ戦',
        isReadOnlyUI: false,
        isDark: false,
        permissions: const PermissionState(role: UserRole.operator),
        rule: const MatchRule(),
        firstMatch: leagueTeamMatches.first,
      );
      final column = leagueTeamChildren.whereType<Column>().first;
      expect(column.children.whereType<TimelineLeagueMatchupTile>().length, 1);

      // 2. リーグ個人戦（2階層：ReorderableListView で個人戦試合が直接展開されること）
      final leagueIndivMatches = [
        const MatchModel(
          id: 'm_li1',
          redName: '選手A',
          whiteName: '選手B',
          matchType: 'individual',
          order: 0,
        ),
      ];
      final leagueIndivChildren = TimelineGroupChildrenBuilder.buildChildren(
        context: capturedCtx,
        ref: capturedRef,
        groupList: leagueIndivMatches,
        groupComments: [],
        label: '個人戦/リーグ戦',
        isReadOnlyUI: false,
        isDark: false,
        permissions: const PermissionState(role: UserRole.operator),
        rule: const MatchRule(),
        firstMatch: leagueIndivMatches.first,
      );
      expect(leagueIndivChildren.whereType<ReorderableListView>().length, 1);

      // 3. 団体勝ち抜き戦（2階層：直下に MatchListTileCard が配置されること）
      final kachinukiMatches = [
        const MatchModel(
          id: 'm_k1',
          redName: '道剣 : 先鋒',
          whiteName: '相手 : 先鋒',
          matchType: '第1試合',
          order: 0,
        ),
      ];
      final kachinukiChildren = TimelineGroupChildrenBuilder.buildChildren(
        context: capturedCtx,
        ref: capturedRef,
        groupList: kachinukiMatches,
        groupComments: [],
        label: '団体戦/勝ち抜き戦',
        isReadOnlyUI: false,
        isDark: false,
        permissions: const PermissionState(role: UserRole.operator),
        rule: const MatchRule(),
        firstMatch: kachinukiMatches.first,
      );
      expect(kachinukiChildren.whereType<MatchListTileCard>().length, 1);

      // 4. 通常団体戦（2階層：直下に MatchListTileCard が配置されること）
      final teamMatches = [
        const MatchModel(
          id: 'm_t1',
          redName: '道剣 : 先鋒',
          whiteName: '相手 : 先鋒',
          matchType: '先鋒',
          order: 0,
        ),
      ];
      final teamChildren = TimelineGroupChildrenBuilder.buildChildren(
        context: capturedCtx,
        ref: capturedRef,
        groupList: teamMatches,
        groupComments: [],
        label: '団体戦',
        isReadOnlyUI: false,
        isDark: false,
        permissions: const PermissionState(role: UserRole.operator),
        rule: const MatchRule(),
        firstMatch: teamMatches.first,
      );
      expect(teamChildren.whereType<MatchListTileCard>().length, 1);
    });

    testWidgets('リーグ戦で参加チームが多く2行に収まらない場合、「+◯チーム」と省略表示されること', (tester) async {
      final matches = [
        for (int i = 1; i <= 6; i++)
          MatchModel(
            id: 'm_$i',
            redName: '道剣 : 先鋒',
            whiteName: 'ライバル剣道連盟00$i : 先鋒',
            matchType: '先鋒',
            note: '[リーグ戦] 第1試合場, Bリーグ',
            order: i.toDouble(),
          ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 280,
                child: TimelineGroupHeader(
                  groupList: matches,
                  label: '団体戦/リーグ戦',
                  allFinished: false,
                  hasInProgress: false,
                  isReadOnlyUI: false,
                  canManageTournamentUI: false,
                  isDark: false,
                  ownTeams: const ['道剣'],
                  titleColor: Colors.black,
                ),
              ),
            ),
          ),
        ),
      );

      // 自チーム（道剣）が表示されていること（タイトルおよび次の対戦帯に表示）
      expect(find.textContaining('道剣'), findsWidgets);
      // 収まらないチーム数が「+◯チーム」と省略表示されていること
      expect(find.textContaining('+'), findsWidgets);
      expect(find.textContaining('チーム'), findsWidgets);
    });
  });
}
