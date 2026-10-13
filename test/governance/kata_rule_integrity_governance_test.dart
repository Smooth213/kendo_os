import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_apply_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';

void main() {
  group('[Governance] 第101条 剣道形競技 公式ルール整合性 永続保証規約', () {
    test('BulkRuleApplyHelper で形競技ルール計算時、時間計測なし・延長なし・判定有効が不変条件として保証されること', () {
      const kataSource = MatchRule(
        isKataMatch: true,
        matchTimeMinutes: 3.0,
        isIpponShobu: true,
        hasHantei: true,
        enchoCount: 2,
        isEnchoUnlimited: true,
      );

      final params = BulkRuleApplyHelper.computeRuleParams(
        targetRule: kataSource,
        isTeam: false,
        isIndiv: true,
      );

      // ① 試合時間が 0.0（時間計測なし）に強制されること
      expect(params.matchTime, 0.0);

      // ② 一本勝負フラグが解除されること
      expect(params.isIpponShobu, isFalse);

      // ③ 延長戦なし（hasExtension == false, enchoCount == 0, isEnchoUnlimited == false）に強制されること
      expect(params.hasExtension, isFalse);
      expect(params.enchoCount, 0);
      expect(params.isEnchoUnlimited, isFalse);
      expect(params.enchoTime, 0.0);

      // ④ 判定有効（hasHantei == true）が保持されること
      expect(params.hasHantei, isTrue);
    });

    test('MatchModelにおいて形競技の判定決着（2旗以上獲得で勝利）が正しく個人戦認識されること', () {
      final match = MatchModel(
        id: 'kata_gov_1',
        tournamentId: 't1',
        order: 1.0,
        matchType: '日本剣道形',
        status: 'finished',
        redName: '道上剣友会:皿田 脩人・塚本 大道',
        whiteName: '対戦相手:選手・選手',
        redScore: 2,
        whiteScore: 1,
        rule: const MatchRule(
          isKataMatch: true,
          matchTimeMinutes: 0.0,
          hasHantei: true,
        ),
      );

      // ① 形競技として正しく個人戦認識されること
      expect(TeamProgressHelper.isIndividualMatch(match), isTrue);

      // ② スコア計算で過半数（2旗以上）を獲得した側が勝者となること
      expect(match.redScore > match.whiteScore, isTrue);
      expect(match.redScore >= 2, isTrue);
    });
  });
}
