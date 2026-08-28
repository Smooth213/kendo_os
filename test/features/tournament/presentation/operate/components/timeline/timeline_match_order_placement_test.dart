import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_list_tile_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_group_children_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/domain/entities/user_role.dart';

void main() {
  group('Timeline Match Placement & Sorting Tests', () {
    test('① チームカード内の対戦枠: 新しく作成した対戦カード（グループ）が最上位（先頭）に配置されること', () {
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

    testWidgets('② 団体戦アコーディオン内: 先鋒〜大将の後に、代表戦および追加試合が正しく後方に追加されること', (
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
  });
}
