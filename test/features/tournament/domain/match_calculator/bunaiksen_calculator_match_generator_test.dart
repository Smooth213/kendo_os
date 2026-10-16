import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/bunaiksen_calculator_match_generator.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_allocation_engine.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';

void main() {
  group('[Unit] 計算機試合作成ジェネレーターの挙動検証', () {
    test('1リーグ総当たり戦の試合モデルが正しく生成されること', () {
      const settings = CalculatorSettings(
        format: MatchFormatType.singleLeague,
        participantCount: 4,
        courtCount: 1,
        matchDurationMinutes: 3.0,
      );
      final result = MatchAllocationEngine.calculate(settings);
      const rule = MatchRule(matchTimeMinutes: 3.0, winPoint: 3.0);

      // 1. 仮名モードでの生成
      final matches = BunaiksenCalculatorMatchGenerator.generateMatches(
        result: result,
        settings: settings,
        rule: rule,
        tournamentId: 'bunaiksen_20261016',
      );

      // 4人の総当たり = 6試合
      expect(matches.length, 6);
      expect(matches.first.note, contains('第1コート'));
      expect(matches.first.matchType, 'リーグ戦');
      expect(matches.first.matchTimeMinutes, 3.0);
      expect(matches.first.rule?.winPoint, 3.0);
      expect(matches.first.status, 'waiting');
      expect(matches.first.redName, '1番選手');
      expect(matches.first.whiteName, '4番選手');

      // 2. 本名リスト指定時の生成
      final namedMatches = BunaiksenCalculatorMatchGenerator.generateMatches(
        result: result,
        settings: settings,
        rule: rule,
        tournamentId: 'bunaiksen_20261016',
        playerNames: ['山田', '佐藤', '田中', '鈴木'],
      );

      expect(namedMatches.length, 6);
      expect(namedMatches.first.redName, '山田');
      expect(namedMatches.first.whiteName, '鈴木');
    });

    test('予選L＋決勝Tで勝者タグおよび抽選枠が正しく組み込まれること', () {
      const settings = CalculatorSettings(
        format: MatchFormatType.prelimLeagueAndTournament,
        participantCount: 8, // 4人×2リーグ
        courtCount: 2,
        advancingCountPerLeague: 2, // 各2名進出 -> 準決勝2試合 + 決勝1試合
        matchDurationMinutes: 2.0,
      );
      final result = MatchAllocationEngine.calculate(settings);
      const rule = MatchRule(matchTimeMinutes: 2.0);

      // 順位直結方式
      final rankMatches = BunaiksenCalculatorMatchGenerator.generateMatches(
        result: result,
        settings: settings,
        rule: rule,
        tournamentId: 'bunaiksen_20261016',
        advancementMethod: TournamentAdvancementMethod.directRank,
      );

      // 決勝戦を検索
      final finalMatch = rankMatches.firstWhere(
        (m) => m.note.contains('決勝戦') && !m.note.contains('準'),
      );
      // 決勝戦には準決勝の winner タグが含まれていること
      expect(finalMatch.redName, contains('winner('));
      expect(finalMatch.whiteName, contains('winner('));
      expect(finalMatch.matchType, 'トーナメント');

      // 抽選枠方式
      final lotteryMatches = BunaiksenCalculatorMatchGenerator.generateMatches(
        result: result,
        settings: settings,
        rule: rule,
        tournamentId: 'bunaiksen_20261016',
        advancementMethod: TournamentAdvancementMethod.lottery,
      );

      // 準決勝（進出枠）を検索
      final semiMatches = lotteryMatches
          .where((m) => m.note.contains('準決勝'))
          .toList();
      expect(semiMatches.isNotEmpty, true);
      expect(semiMatches.first.redName, contains('抽選枠 1番'));
      expect(semiMatches.first.whiteName, contains('抽選枠 2番'));
    });
  });
}
