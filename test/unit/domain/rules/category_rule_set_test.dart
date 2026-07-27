import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('CategoryRuleSet & TournamentModel Serialization Tests', () {
    test('CategoryRuleSet defaults are initialized correctly', () {
      const ruleSet = CategoryRuleSet();
      expect(ruleSet.useAdvancedRule, isFalse);
      expect(ruleSet.normalRule.matchTimeMinutes, equals(3.0));
      expect(ruleSet.advancedRule.matchTimeMinutes, equals(3.0));
    });

    test('CategoryRuleSet serializes and deserializes correctly', () {
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

    test(
      'TournamentModel handles empty categoryRules correctly for backward compatibility',
      () {
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
      },
    );

    test(
      'TournamentModel serializes and deserializes categoryRules map correctly',
      () {
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
      },
    );
  });

  group('Keyword detection analysis test for advanced rounds', () {
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

    test('Identifies advanced matches correctly', () {
      expect(isAdvancedMatch('準決勝 第1試合'), isTrue);
      expect(isAdvancedMatch('Aコート 決勝'), isTrue);
      expect(isAdvancedMatch('3位決定戦'), isTrue);
      expect(isAdvancedMatch('小学生 準決'), isTrue);
      expect(isAdvancedMatch('Aコート 准決'), isTrue); // typo support
      expect(isAdvancedMatch('Bコート 順決'), isTrue); // typo support
      expect(isAdvancedMatch('1回戦 第2試合'), isFalse);
      expect(isAdvancedMatch('予選リーグ Aブロック'), isFalse);
    });

    test('Identifies advanced matches with custom keywords correctly', () {
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
}
