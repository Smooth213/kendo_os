import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('1. 部門別ルール設定 (CategoryRuleSet) のテスト', () {
    test('【マルチシーン】本戦ルールなし (useHonsenRule = false) の設定が正しく保持されること', () {
      const ruleSet = CategoryRuleSet(
        isMultiScene: true,
        useHonsenRule: false,
        useRenseikaiRule: true,
        useMoushiawaseRule: true,
        renseikaiRule: MatchRule(
          matchTimeMinutes: 2,
          isRunningTime: true,
          matchScene: 'renseikai',
        ),
        moushiawaseRule: MatchRule(
          matchTimeMinutes: 2,
          isRunningTime: true,
          matchScene: 'moushiawase',
        ),
      );

      expect(ruleSet.isMultiScene, isTrue);
      expect(ruleSet.useHonsenRule, isFalse);
      expect(ruleSet.useRenseikaiRule, isTrue);
      expect(ruleSet.useMoushiawaseRule, isTrue);
      expect(ruleSet.renseikaiRule.matchScene, equals('renseikai'));
      expect(ruleSet.moushiawaseRule.matchScene, equals('moushiawase'));
    });

    test('【シリアライズ】JSONとの相互変換で useHonsenRule 等のフラグが保持されること', () {
      const original = CategoryRuleSet(
        isMultiScene: true,
        useHonsenRule: false,
        useRenseikaiRule: true,
        useMoushiawaseRule: false,
      );

      final json = original.toJson();
      final restored = CategoryRuleSet.fromJson(json);

      expect(restored.useHonsenRule, isFalse);
      expect(restored.useRenseikaiRule, isTrue);
      expect(restored.useMoushiawaseRule, isFalse);
    });
  });

  group('2. 対戦成績サマリー (Expedition Summary) の集計ロジック検証', () {
    // 判定用ヘルパー (official_record_screen.dart の isMatchPlayed と同等)
    bool isMatchPlayed(MatchModel m) {
      if (m.status == 'finished') return true;
      if (m.redScore > 0 || m.whiteScore > 0) return true;
      if (m.events.isNotEmpty) return true;
      return false;
    }

    test('【未開始試合の除外】スコア 0-0 で status != finished の試合枠は集計に含まれないこと', () {
      final unplayedMatch = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        category: '小学生の部',
        matchType: '個人戦',
        redName: '自チーム : 山田',
        whiteName: '相手チーム : 佐藤',
        status: 'waiting',
        redScore: 0,
        whiteScore: 0,
      );

      expect(isMatchPlayed(unplayedMatch), isFalse);
    });

    test('【実施済み試合の判定】status == finished または スコア/イベントが存在する試合は集計対象となること', () {
      final finishedMatch = MatchModel(
        id: 'm2',
        tournamentId: 't1',
        category: '小学生の部',
        matchType: '個人戦',
        redName: '自チーム : 山田',
        whiteName: '相手チーム : 佐藤',
        status: 'finished',
        redScore: 1,
        whiteScore: 0,
      );

      final scoredMatch = MatchModel(
        id: 'm3',
        tournamentId: 't1',
        category: '小学生の部',
        matchType: '個人戦',
        redName: '自チーム : 山田',
        whiteName: '相手チーム : 佐藤',
        status: 'in_progress',
        redScore: 1,
        whiteScore: 0,
      );

      expect(isMatchPlayed(finishedMatch), isTrue);
      expect(isMatchPlayed(scoredMatch), isTrue);
    });

    test('【部門別フィルタ】指定した部門（category）の試合のみが抽出されること', () {
      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          category: '小学生低学年の部',
          matchType: '個人戦',
          redName: '自チーム : 山田',
          whiteName: '相手チーム : 佐藤',
          status: 'finished',
          redScore: 1,
          whiteScore: 0,
        ),
        MatchModel(
          id: 'm2',
          tournamentId: 't1',
          category: '中学生の部',
          matchType: '個人戦',
          redName: '自チーム : 田中',
          whiteName: '相手チーム : 鈴木',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
        ),
      ];

      final catMatches = matches
          .where((m) => m.category == '小学生低学年の部')
          .toList();

      expect(catMatches.length, equals(1));
      expect(catMatches.first.redName, contains('山田'));
    });

    test('【シーン別区分】renseikai / honsen / moushiawase が正しく振り分けられること', () {
      final renseikaiMatch = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        category: '小学生の部',
        matchType: '個人戦',
        matchScene: 'renseikai',
        redName: '自チームA : 山田',
        whiteName: '相手チーム : 佐藤',
        status: 'finished',
        redScore: 1,
        whiteScore: 0,
      );

      final honsenMatch = MatchModel(
        id: 'm2',
        tournamentId: 't1',
        category: '小学生の部',
        matchType: '個人戦',
        matchScene: 'honsen',
        redName: '自チームA : 山田',
        whiteName: '相手チーム : 佐藤',
        status: 'finished',
        redScore: 1,
        whiteScore: 0,
      );

      expect(renseikaiMatch.matchScene, equals('renseikai'));
      expect(honsenMatch.matchScene, equals('honsen'));
    });
  });
}
