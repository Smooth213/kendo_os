import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_state_holder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🥋 BulkRuleStateHolder Unit Tests', () {
    test('初期値が正しくセットアップされ、dispose可能であること', () {
      final holder = BulkRuleStateHolder();
      expect(holder.selectedCategoryFilter, 'すべて');
      expect(holder.selectedTypeFilter, 'すべて');
      expect(holder.matchTime, 3.0);
      expect(holder.ipponLimit, 2);
      expect(holder.hasRepresentativeMatch, true);
      expect(holder.isDaihyoIpponShobu, true);
      expect(holder.overallTimeController.text, '30');

      holder.dispose();
    });

    test('loadTemplateRules で試合モデルのルール値が正確にロードされること', () {
      final holder = BulkRuleStateHolder();
      const match = MatchModel(
        id: 'test_m1',
        tournamentId: 't1',
        redName: '赤チーム',
        whiteName: '白チーム',
        matchType: '団体戦',
        status: 'pending',
        rule: MatchRule(
          matchTimeMinutes: 4.0,
          isRunningTime: true,
          isIpponShobu: true,
          ipponLimit: 1,
          enchoTimeMinutes: 2.0,
          enchoCount: 3,
          hasRepresentativeMatch: true,
          daihyoMatchTimeMinutes: 3.0,
          renseikaiType: '時間制',
          overallTimeMinutes: 45,
          isLeague: true,
          winPoint: 5.0,
        ),
      );

      holder.loadTemplateRules(match);

      expect(holder.loadedMatchId, 'test_m1');
      expect(holder.matchTime, 3.0);
      expect(holder.isRunningTime, true);
      expect(holder.isIpponShobu, true);
      expect(holder.enchoTime, 3.0);
      expect(holder.enchoCount, 1);
      expect(holder.daihyoMatchTime, 3.0);
      expect(holder.renseikaiType, '時間制');
      expect(holder.overallTimeController.text, '45');
      expect(holder.isLeague, true);
      expect(holder.winPoint, 5.0);

      final builtRule = holder.buildNewRule();
      expect(builtRule.matchTimeMinutes, 3.0);
      expect(builtRule.isRunningTime, true);
      expect(builtRule.isIpponShobu, true);
      expect(builtRule.overallTimeMinutes, 45);
      expect(builtRule.winPoint, 5.0);

      holder.dispose();
    });

    test('applyCategoryRuleSet で部門別ルールが反映されること', () {
      final holder = BulkRuleStateHolder();
      const targetRule = MatchRule(
        matchTimeMinutes: 2.5,
        isRunningTime: false,
        isIpponShobu: false,
        enchoTimeMinutes: 1.5,
        enchoCount: -2,
        isEnchoUnlimited: true,
        hasRepresentativeMatch: true,
        daihyoMatchTimeMinutes: 2.0,
      );

      holder.applyCategoryRuleSet(
        targetRule,
        isTeam: true,
        sceneKey: 'renseikai',
      );

      expect(holder.matchTime, 2.5);
      expect(holder.hasExtension, true);
      expect(holder.isEnchoUnlimited, true);
      expect(holder.renseikaiType, '一試合制');

      holder.dispose();
    });
  });

  group('🏆 MatchEditStateHolder Unit Tests', () {
    test('個人戦・団体戦の判定および選手名・チーム名が正しく抽出されること', () {
      final teamMatches = <MatchModel>[
        const MatchModel(
          id: 'tm_1',
          tournamentId: 't1',
          matchType: '団体戦',
          status: 'pending',
          redName: '東京代表: 山田',
          whiteName: '大阪代表: 佐藤',
          groupName: '第1試合場 (1回戦)',
        ),
        const MatchModel(
          id: 'tm_2',
          tournamentId: 't1',
          matchType: '団体戦',
          status: 'pending',
          redName: '東京代表: 鈴木',
          whiteName: '大阪代表: 田中',
        ),
      ];

      final holder = MatchEditStateHolder(teamMatches);

      expect(holder.isDantai, true);
      expect(holder.redTeamController.text, '東京代表');
      expect(holder.whiteTeamController.text, '大阪代表');
      expect(holder.redPlayerControllers[0].text, '山田');
      expect(holder.whitePlayerControllers[0].text, '佐藤');
      expect(holder.redPlayerControllers[1].text, '鈴木');
      expect(holder.whitePlayerControllers[1].text, '田中');

      // チーム入替
      holder.swapTeamsAndPlayers();
      expect(holder.isSwapped, true);
      expect(holder.redTeamController.text, '大阪代表');
      expect(holder.whiteTeamController.text, '東京代表');
      expect(holder.redPlayerControllers[0].text, '佐藤');
      expect(holder.whitePlayerControllers[0].text, '山田');

      // プリセットトグル
      holder.toggleHeadingPreset('決勝戦');
      expect(holder.courtController.text.contains('決勝戦'), true);

      holder.dispose();
    });
  });
}
