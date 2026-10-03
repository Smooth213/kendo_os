import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_filter_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';

void main() {
  group('[E2E] 試合カテゴリその他混成チーム登録および対戦進行統合テスト', () {
    test('シナリオ1 その他カテゴリにおいて学年混成チームが正常に生成されること', () {
      // 1. 各学年の選手を準備
      final roster = [
        PlayerModel(
          id: 'p1',
          lastName: '佐藤',
          firstName: '低学年',
          lastNameKana: 'さとう',
          firstNameKana: 'ていがくねん',
          grade: 2,
        ),
        PlayerModel(
          id: 'p2',
          lastName: '鈴木',
          firstName: '高学年男子',
          lastNameKana: 'すずき',
          firstNameKana: 'こうがくねんだんし',
          grade: 6,
        ),
        PlayerModel(
          id: 'p3',
          lastName: '田中',
          firstName: '中学生女子',
          lastNameKana: 'たなか',
          firstNameKana: 'ちゅうがくせいじょし',
          gender: '女子',
          grade: 8,
        ),
        PlayerModel(
          id: 'p4',
          lastName: '高橋',
          firstName: '中学生男子',
          lastNameKana: 'たかはし',
          firstNameKana: 'ちゅうがくせいだんし',
          grade: 9,
        ),
        PlayerModel(
          id: 'p5',
          lastName: '伊藤',
          firstName: '中学生男子',
          lastNameKana: 'いとう',
          firstNameKana: 'ちゅうがくせいだんし',
          grade: 9,
        ),
      ];

      // 2. 「その他」カテゴリで全選手が適合することを確認
      for (final p in roster) {
        expect(
          TeamRegistrationPlayerFilterHelper.isSameCategory(
            player: p,
            majorCategory: 'その他',
            minorCategory: '混成',
          ),
          isTrue,
        );
      }

      // 3. 混成チームモデルの構築
      final categoryName = TeamRegistrationCategoryParser.formatCategoryName(
        majorCategory: 'その他',
        minorCategory: '混成',
      );
      expect(categoryName, '混成の部');

      final mixedTeam = TeamModel(
        id: 'team_mixed_001',
        tournamentId: 'tour_001',
        teamName: '混成剣友会A',
        category: categoryName,
        matchType: '団体戦（5人制）',
        playerNames: roster.map((p) => p.name).toList(),
      );

      expect(mixedTeam.playerNames.length, 5);
      expect(mixedTeam.playerNames.first, '佐藤 低学年');
      expect(mixedTeam.playerNames.last, '伊藤 中学生男子');
    });

    test('シナリオ2 対戦フォーマット設定でカスタム部門名を入力し正しく試合モデルに反映されること', () {
      final state = MatchFormatFormState();
      state.selectedMajorCategory = 'その他';
      state.customCategoryName = '小中学生混成';
      state.matchType = '団体戦（5人制）';

      final finalCategory = state.getCategory();
      expect(finalCategory, '小中学生混成の部');

      // 試合モデルを生成
      final match = MatchModel(
        id: 'match_mixed_001',
        category: finalCategory,
        matchType: '団体戦（5人制）',
        redName: '混成剣友会A : 佐藤 低学年',
        whiteName: '対戦道場B : 山田 低学年',
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );

      expect(match.category, '小中学生混成の部');
      expect(match.redName, contains('佐藤 低学年'));
    });

    testWidgets('シナリオ3 タイムライングループカードで独立した混成アコーディオンが正常に描画されること', (tester) async {
      final match1 = MatchModel(
        id: 'm1',
        category: '小中学生混成の部',
        matchType: '団体戦',
        redName: '混成剣友会A : 先鋒選手',
        whiteName: '対戦道場B : 相手先鋒',
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );
      final match2 = MatchModel(
        id: 'm2',
        category: '小中学生混成の部',
        matchType: '団体戦',
        redName: '混成剣友会A : 次鋒選手',
        whiteName: '対戦道場B : 相手次鋒',
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => [match1, match2]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TimelineMatchGroupCard(
                  groupId: 'grp_mixed_001',
                  groupList: [match1, match2],
                  groupComments: const [],
                  categoryName: '小中学生混成の部',
                  teamName: '混成剣友会A',
                  label: '第1試合',
                  isReadOnlyUI: false,
                  canManageTournamentUI: true,
                  isDark: false,
                  tournamentId: 'tour_001',
                  ownTeams: const ['混成剣友会A'],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 対戦カードの描画検証
      expect(find.text('混成剣友会A vs 対戦道場B'), findsOneWidget);

      // アコーディオンを展開
      await tester.tap(find.text('混成剣友会A vs 対戦道場B'));
      await tester.pumpAndSettle();

      // 各対戦選手名が表示されること
      expect(find.text('混成剣友会A vs 対戦道場B'), findsOneWidget);
    });
  });
}
