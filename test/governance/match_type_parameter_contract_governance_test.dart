import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';

void main() {
  group('[Governance] 試合形式6分類・パラメータ契約静的整合性ガバナンステスト', () {
    const allTypes = TournamentTeamAutoRegisterService.allCandidateMatchTypes;

    test('6大試合形式の基幹名が allCandidateMatchTypes に完全に定義されていること', () {
      final expectedKeys = [
        '団体戦（5人制）',
        '団体戦（3人制）',
        '個人戦',
        '勝ち抜き戦（5人制）',
        '勝ち抜き戦（3人制）',
        '日本剣道形',
        '木刀による剣道基本技稽古法',
        'リーグ団体戦',
      ];

      for (final key in expectedKeys) {
        expect(
          allTypes.any((t) => t.contains(key) || key.contains(t)),
          isTrue,
          reason: 'allCandidateMatchTypes must contain definition for $key',
        );
      }
    });

    test('剣道形・基本判定のパラメータ契約: isKataMatch が正しく伝搬されること', () {
      const kataRule = MatchRule(
        isKataMatch: true,
        matchTimeMinutes: 0.0,
        hasHantei: true,
      );

      const kataMatch = MatchModel(
        id: 'gov_kata_match_01',
        matchType: '日本剣道形',
        category: '形の部',
        redName: '道上剣友会 : 皿田・塚本',
        whiteName: '修道館 : 佐藤・鈴木',
        rule: kataRule,
      );

      expect(kataMatch.rule?.isKataMatch, isTrue);
      expect(kataMatch.rule?.hasHantei, isTrue);
    });

    test('勝ち抜き戦のパラメータ契約: 勝ち抜きフラグおよびスロット定義が整合すること', () {
      const kachinukiRule = MatchRule(
        isKachinuki: true,
        positions: ['先鋒', '次鋒', '中堅', '副将', '大将'],
      );

      expect(kachinukiRule.isKachinuki, isTrue);
      expect(kachinukiRule.positions.length, 5);
    });

    test('部内戦（総当たり・勝ち点）のパラメータ契約: リーグ戦設定が保持されること', () {
      const bunaiksenRule = MatchRule(isLeague: true, isIpponShobu: false);

      expect(bunaiksenRule.isLeague, isTrue);
      expect(bunaiksenRule.isIpponShobu, isFalse);
    });
  });
}
