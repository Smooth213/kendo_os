import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('[Unit] CategoryRuleSetおよびTournamentModel シリアライズテスト', () {
    test('CategoryRuleSetのデフォルト値が正しく初期化されること', () {
      const ruleSet = CategoryRuleSet();
      expect(ruleSet.useAdvancedRule, isFalse);
      expect(ruleSet.normalRule.matchTimeMinutes, equals(3.0));
      expect(ruleSet.advancedRule.matchTimeMinutes, equals(3.0));
    });

    test('CategoryRuleSetのシリアライズおよびデシリアライズが正しく行えること', () {
      final ruleSet = CategoryRuleSet(
        normalRule: const MatchRule(matchTimeMinutes: 2.0, hasHantei: true),
        advancedRule: const MatchRule(
          matchTimeMinutes: 3.0,
          isEnchoUnlimited: true,
        ),
        useAdvancedRule: true,
      );

      final json = ruleSet.toJson();
      final decoded = CategoryRuleSet.fromJson(json);

      expect(decoded.useAdvancedRule, isTrue);
      expect(decoded.normalRule.matchTimeMinutes, equals(2.0));
      expect(decoded.normalRule.hasHantei, isTrue);
      expect(decoded.advancedRule.matchTimeMinutes, equals(3.0));
      expect(decoded.advancedRule.isEnchoUnlimited, isTrue);
    });

    test('TournamentModelにおいて 後方互換性のため空のcategoryRulesが適切に処理されること', () {
      final tournament = TournamentModel(
        id: 'test_id',
        organizationId: 'org_123',
        name: 'Test Tournament',
        date: DateTime.now(),
        venue: 'Test Venue',
      );

      final json = tournament.toJson();
      final decoded = TournamentModel.fromJson(json);

      expect(decoded.categoryRules, isEmpty);
    });

    test('TournamentModelのcategoryRulesマップのシリアライズおよびデシリアライズが正しく行えること', () {
      final ruleSet = CategoryRuleSet(
        normalRule: const MatchRule(matchTimeMinutes: 1.5),
        advancedRule: const MatchRule(matchTimeMinutes: 3.0),
        useAdvancedRule: true,
      );

      final tournament = TournamentModel(
        id: 'test_id',
        organizationId: 'org_123',
        name: 'Test Tournament',
        date: DateTime.now(),
        venue: 'Test Venue',
        categoryRules: {'小学生低学年の部': ruleSet},
      );

      final json = tournament.toJson();
      final decoded = TournamentModel.fromJson(json);

      expect(decoded.categoryRules, isNotEmpty);
      expect(decoded.categoryRules.containsKey('小学生低学年の部'), isTrue);

      final decodedRuleSet = decoded.categoryRules['小学生低学年の部']!;
      expect(decodedRuleSet.useAdvancedRule, isTrue);
      expect(decodedRuleSet.normalRule.matchTimeMinutes, equals(1.5));
      expect(decodedRuleSet.advancedRule.matchTimeMinutes, equals(3.0));
    });
  });

  group('上位回戦（準決勝・決勝等）のキーワード検知分析テスト', () {
    bool isAdvancedMatch(String note) {
      final cleanNote = note.toLowerCase();
      final keywords = [
        '準決勝',
        '準決',
        'じゅんけつ',
        'ベスト4',
        'b4',
        'sf',
        'semifinal',
        '准決',
        '順決',
        '決勝',
        'けっしょう',
        'ファイナル',
        'final',
        '結勝',
        '決勝戦',
        '3位決定',
        '3決',
        '三決',
      ];
      return keywords.any((kw) => cleanNote.contains(kw));
    }

    test('進行中の試合を正しく特定できること', () {
      expect(isAdvancedMatch('準決勝 第1試合'), isTrue);
      expect(isAdvancedMatch('Aコート 決勝'), isTrue);
      expect(isAdvancedMatch('3位決定戦'), isTrue);
      expect(isAdvancedMatch('小学生 準決'), isTrue);
      expect(isAdvancedMatch('Aコート 准決'), isTrue); // typo support
      expect(isAdvancedMatch('Bコート 順決'), isTrue); // typo support
      expect(isAdvancedMatch('1回戦 第2試合'), isFalse);
      expect(isAdvancedMatch('予選リーグ Aブロック'), isFalse);
    });

    test('カスタムキーワードによる進行中試合の特定が正しく行えること', () {
      bool isAdvancedMatchWithCustom(String note, List<String> customKeywords) {
        final cleanNote = note.toLowerCase().trim();
        final keywords = customKeywords
            .map((kw) => kw.toLowerCase().trim())
            .toList();

        String testNote = cleanNote;
        final hasSemisKeyword = keywords.any(
          (kw) =>
              kw.contains('準決') ||
              kw.contains('準決勝') ||
              kw.contains('ベスト4') ||
              kw.contains('sf'),
        );
        if (!hasSemisKeyword) {
          testNote = testNote
              .replaceAll('準決勝', '')
              .replaceAll('準決', '')
              .replaceAll('准決', '')
              .replaceAll('順決', '')
              .replaceAll('じゅんけつ', '')
              .replaceAll('semifinal', '')
              .replaceAll('sf', '')
              .replaceAll('3位決定', '')
              .replaceAll('3決', '')
              .replaceAll('三決', '');
        }
        return keywords.any((kw) => kw.isNotEmpty && testNote.contains(kw));
      }

      // Finals only mode
      final finalsOnly = ['決勝', 'final'];
      expect(isAdvancedMatchWithCustom('準決勝 第1試合', finalsOnly), isFalse);
      expect(isAdvancedMatchWithCustom('Aコート 決勝', finalsOnly), isTrue);

      // 3rd round and above mode
      final thirdRoundAndAbove = ['3回戦', '三回戦', '準決勝', '決勝'];
      expect(isAdvancedMatchWithCustom('3回戦 第2試合', thirdRoundAndAbove), isTrue);
      expect(isAdvancedMatchWithCustom('三回戦 第1試合', thirdRoundAndAbove), isTrue);
      expect(
        isAdvancedMatchWithCustom('1回戦 第2試合', thirdRoundAndAbove),
        isFalse,
      );
    });
  });

  group('全カテゴリーのルール ドメイン不変条件テスト', () {
    test('主要ルール定義がドメイン不変条件（団体代表戦、個人戦延長判定、錬成会フラグ等）を満たすこと', () {
      final sampleRules = <String, CategoryRuleSet>{
        '①トーナメント団体戦': const CategoryRuleSet(
          matchType: '団体戦',
          normalRule: MatchRule(
            matchTimeMinutes: 2.0,
            hasRepresentativeMatch: true,
          ),
        ),
        '②トーナメント個人戦': const CategoryRuleSet(
          matchType: '個人戦',
          normalRule: MatchRule(
            matchTimeMinutes: 3.0,
            hasRepresentativeMatch: false,
            hasHantei: true,
          ),
        ),
        '③錬成会': const CategoryRuleSet(
          matchType: '錬成会',
          normalRule: MatchRule(
            matchTimeMinutes: 2.0,
            isRenseikai: true,
            renseikaiType: '一試合制',
          ),
        ),
        '④リーグ戦': const CategoryRuleSet(
          matchType: 'リーグ団体戦',
          normalRule: MatchRule(
            matchTimeMinutes: 2.0,
            winPoint: 3,
            drawPoint: 1,
            lossPoint: 0,
          ),
        ),
        '⑤遠征マルチシーン': const CategoryRuleSet(
          matchType: '団体戦',
          isMultiScene: true,
          useRenseikaiRule: true,
          useMoushiawaseRule: true,
          renseikaiRule: MatchRule(isRenseikai: true),
          moushiawaseRule: MatchRule(isRenseikai: true),
        ),
      };

      for (final entry in sampleRules.entries) {
        final catName = entry.key;
        final ruleSet = entry.value;
        final normal = ruleSet.normalRule;

        if (ruleSet.matchType == '個人戦') {
          expect(
            normal.hasRepresentativeMatch,
            isFalse,
            reason: '$catName: 個人戦は代表戦なし',
          );
        } else if (ruleSet.matchType == '錬成会') {
          expect(normal.isRenseikai, isTrue, reason: '$catName: 錬成会フラグtrue');
          expect(
            normal.renseikaiType.isNotEmpty,
            isTrue,
            reason: '$catName: 進行方式が定義されていること',
          );
        } else if (ruleSet.matchType.contains('リーグ')) {
          expect(
            normal.winPoint >= 0,
            isTrue,
            reason: '$catName: 勝点が定義されていること',
          );
        }

        if (ruleSet.isMultiScene) {
          if (ruleSet.useRenseikaiRule) {
            expect(ruleSet.renseikaiRule.isRenseikai, isTrue);
          }
          if (ruleSet.useMoushiawaseRule) {
            expect(ruleSet.moushiawaseRule.isRenseikai, isTrue);
          }
        }
      }
    });
  });
}
