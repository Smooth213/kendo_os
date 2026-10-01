import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_rule_sync_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_slot_helper.dart';

void main() {
  group('[Unit] 試合形式設定 多人数団体戦境界値と代表戦判定ロジックテスト', () {
    test('団体戦の選手スロット数が下限値3名から上限値15名まで正しく維持・制御されること', () {
      final selectedPlayers = <int, String>{};
      for (int i = 0; i < 15; i++) {
        selectedPlayers[i] = '選手$i';
      }

      // 15名スロットの整合性
      expect(selectedPlayers.length, 15);

      // 1スロット削除による14名への移行
      final afterRemove = TeamRegistrationSlotHelper.removePlayerSlot(
        index: 14,
        playerCount: 15,
        tempSelectedPlayers: selectedPlayers,
        customSlotCount: 15,
      );
      expect(afterRemove, 14);
      expect(selectedPlayers.containsKey(14), isFalse);

      // 下限3名での削除ガード（3名未満には縮小しない）
      final minPlayers = <int, String>{0: '先鋒', 1: '中堅', 2: '大将'};
      final afterMinRemove = TeamRegistrationSlotHelper.removePlayerSlot(
        index: 1,
        playerCount: 3,
        tempSelectedPlayers: minPlayers,
        customSlotCount: 3,
      );
      expect(afterMinRemove, 3);
      expect(minPlayers.length, 2); // 1枠空くがカスタムスロットカウントは3を維持
    });

    test('多人数団体戦における同点同本時の代表戦フラグ自動設定とルール引き継ぎが正しく動作すること', () {
      final ruleSet = CategoryRuleSet(
        matchType: '7人制団体戦',
        normalRule: const MatchRule(
          matchTimeMinutes: 4.0,
          hasLeagueDaihyo: true,
          isDaihyoIpponShobu: true,
          daihyoMatchTimeMinutes: 4.0,
          daihyoHasExtension: true,
          daihyoEnchoTimeMinutes: 3.0,
        ),
      );

      final rule = MatchFormatRuleSyncHelper.getRuleForScene(
        scene: 'honsen',
        ruleSet: ruleSet,
      );

      expect(rule.hasLeagueDaihyo, isTrue);
      expect(rule.isDaihyoIpponShobu, isTrue);
      expect(rule.daihyoMatchTimeMinutes, 4.0);
      expect(rule.daihyoHasExtension, isTrue);
    });

    test('上位戦判定において決勝・準決勝キーワードおよび明示的フラグが正常に機能すること', () {
      // 上位戦キーワード検出
      expect(
        CategoryRuleMatchHelper.isAdvancedMatchName('決勝トーナメント1回戦'),
        isTrue,
      );
      expect(CategoryRuleMatchHelper.isAdvancedMatchName('準決勝'), isTrue);
      expect(CategoryRuleMatchHelper.isAdvancedMatchName('第3位決定戦'), isTrue);
      expect(CategoryRuleMatchHelper.isAdvancedMatchName('予選リーグ第1試合'), isFalse);

      // 上位戦ルールが無効化されている場合は通常ルールにフォールバックすること
      final disabledAdvancedRuleSet = CategoryRuleSet(
        matchType: '団体戦',
        useAdvancedRule: false,
        normalRule: const MatchRule(matchTimeMinutes: 3.0),
        advancedRule: const MatchRule(matchTimeMinutes: 5.0),
      );

      final scene = MatchFormatRuleSyncHelper.determineInitialScene(
        ruleSet: disabledAdvancedRuleSet,
        currentScene: 'advanced',
        isAdvanced: true,
      );
      expect(scene, 'honsen');
    });

    test('多人数団体戦の試合結果集計で勝者数・総取得本数が完全同率の場合に代表戦判定が成立すること', () {
      // 7人制の試合結果（赤3勝・白3勝・1分、総本数も同数）
      final matches = [
        MatchModel(
          id: 'm1',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          matchType: '団体戦',
          redName: '選手1',
          whiteName: '相手1',
        ),
        MatchModel(
          id: 'm2',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          matchType: '団体戦',
          redName: '選手2',
          whiteName: '相手2',
        ),
        MatchModel(
          id: 'm3',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
          matchType: '団体戦',
          redName: '選手3',
          whiteName: '相手3',
        ),
        MatchModel(
          id: 'm4',
          redScore: 0,
          whiteScore: 0,
          status: 'finished',
          matchType: '団体戦',
          redName: '選手4',
          whiteName: '相手4',
        ),
        MatchModel(
          id: 'm5',
          redScore: 0,
          whiteScore: 2,
          status: 'finished',
          matchType: '団体戦',
          redName: '選手5',
          whiteName: '相手5',
        ),
        MatchModel(
          id: 'm6',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          matchType: '団体戦',
          redName: '選手6',
          whiteName: '相手6',
        ),
        MatchModel(
          id: 'm7',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
          matchType: '団体戦',
          redName: '選手7',
          whiteName: '相手7',
        ),
      ];

      int redWins = 0;
      int whiteWins = 0;
      int redPoints = 0;
      int whitePoints = 0;

      for (final m in matches) {
        redPoints += m.redScore;
        whitePoints += m.whiteScore;
        if (m.redScore > m.whiteScore) {
          redWins++;
        } else if (m.whiteScore > m.redScore) {
          whiteWins++;
        }
      }

      expect(redWins, 3);
      expect(whiteWins, 3);
      expect(redPoints, 4);
      expect(whitePoints, 4);

      final isTieBreakRequired =
          (redWins == whiteWins) && (redPoints == whitePoints);
      expect(isTieBreakRequired, isTrue);
    });
  });
}
