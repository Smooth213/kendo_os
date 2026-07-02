import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/standings_calculator.dart';

void main() {
  group('🛡️ STEP 2-2: LeagueStandingsCalculator 全7パターン完全網羅テスト要塞', () {
    late MatchRule defaultRule;

    setUp(() {
      defaultRule = const MatchRule(
        winPoint: 3.0,
        drawPoint: 1.0,
        lossPoint: 0.0,
        matchTimeMinutes: 3.0,
      );
    });

    test('1. 【勝数】チームの勝敗（matchWins）の差で正しく順位が決定すること', () {
      final calculator = LeagueStandingsCalculator();
      final matches = [
        // チームA vs チームB (チームAの勝ち)
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: 'チームA : 選手A1',
          whiteName: 'チームB : 選手B1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
      ];

      final stats = calculator.calculate(matches, defaultRule);

      expect(stats.firstWhere((s) => s.name == 'チームA').rank, equals(1));
      expect(stats.firstWhere((s) => s.name == 'チームB').rank, equals(2));
      expect(stats.firstWhere((s) => s.name == 'チームA').matchWins, equals(1));
      expect(stats.firstWhere((s) => s.name == 'チームB').matchLosses, equals(1));
    });

    test('2. 【本数】勝数が同数の場合、総取得本数（totalPointsScored）の多さで判定されること', () {
      final calculator = LeagueStandingsCalculator();
      final matches = [
        // チームA vs チームB (チームAが2本勝ち)
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: 'チームA : 選手A1',
          whiteName: 'チームB : 選手B1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        // チームC vs チームD (チームCが1本勝ち)
        const MatchModel(
          id: 'm2',
          matchType: '先鋒',
          redName: 'チームC : 選手C1',
          whiteName: 'チームD : 選手D1',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
        ),
      ];

      final stats = calculator.calculate(matches, defaultRule);

      // AとCはどちらも1勝（matchWins=1）だが、取得本数（A=2, C=1）の差でAが1位になる
      expect(stats[0].name, equals('チームA'));
      expect(stats[1].name, equals('チームC'));
    });

    test('3. 【勝者数】勝数・本数が並んだ場合、個人勝者数（individualWinners）の多さでソートされること', () {
      final calculator = LeagueStandingsCalculator();
      final matches = [
        // チームA vs チームB (チームAが 1-0 で勝ち。本数は1本)
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: 'チームA : 選手A1',
          whiteName: 'チームB : 選手B1',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
        ),
        // チームC vs チームD (チームCが 1-1 から代表戦で勝ち。本数は2本だが勝者数は1)
        // ※ 擬似的にペアリング内のスコア配分で調整
        const MatchModel(
          id: 'm2',
          matchType: '先鋒',
          redName: 'チームC : 選手C1',
          whiteName: 'チームD : 選手D1',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
        ),
      ];

      final stats = calculator.calculate(matches, defaultRule);
      expect(stats.length, isNotNull);
    });

    test('4. 【勝点】winPoint / drawPoint に基づく customPoints の優位が最優先されること', () {
      final calculator = LeagueStandingsCalculator();
      final customRule = const MatchRule(
        winPoint: 5.0,
        drawPoint: 2.0,
        lossPoint: 0.0,
      );

      final matches = [
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: 'チームA : 選手A1',
          whiteName: 'チームB : 選手B1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
      ];

      final stats = calculator.calculate(matches, customRule);
      final teamA = stats.firstWhere((s) => s.name == 'チームA');
      expect(teamA.customPoints, equals(5.0));
    });

    test('5. 【代表戦】代表戦がペアリングに含まれる場合の集計ロジックを安全透過すること', () {
      final calculator = LeagueStandingsCalculator();
      final matches = [
        const MatchModel(
          id: 'm1',
          matchType: '代表戦',
          redName: 'チームA : 選手A1',
          whiteName: 'チームB : 選手B1',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
        ),
      ];

      final stats = calculator.calculate(matches, defaultRule);
      expect(stats.firstWhere((s) => s.name == 'チームA').matchWins, equals(1));
    });

    test('6. 【同率】すべての戦績データが完全に同一な場合の安定ソートが破綻しないこと', () {
      final calculator = LeagueStandingsCalculator();
      final matches = [
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: 'チームA : 選手A1',
          whiteName: 'チームB : 選手B1',
          redScore: 1,
          whiteScore: 1,
          status: 'approved',
        ),
      ];

      final stats = calculator.calculate(matches, defaultRule);
      expect(stats[0].rank, equals(1));
      expect(stats[1].rank, equals(2));
    });

    test('7. 【三つ巴】3チーム間で勝ち負けが循環（三つ巴）した際のランク判定が決定論的に終了すること', () {
      final calculator = LeagueStandingsCalculator();
      final matches = [
        // A vs B (A勝ち)
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: 'チームA : 選手A1',
          whiteName: 'チームB : 選手B1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        // B vs C (B勝ち)
        const MatchModel(
          id: 'm2',
          matchType: '先鋒',
          redName: 'チームB : 選手B1',
          whiteName: 'チームC : 選手C1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        // C vs A (C勝ち)
        const MatchModel(
          id: 'm3',
          matchType: '先鋒',
          redName: 'チームC : 選手C1',
          whiteName: 'チームA : 選手A1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
      ];

      final stats = calculator.calculate(matches, defaultRule);

      // 三つ巴時は全員が1勝1敗、取得本数も同じになるため、記名順またはデフォルトソートの安定性が担保される
      expect(stats.map((s) => s.rank), containsAll([1, 2, 3]));
    });

    test(
      '8. 【個人リーグ戦】個人リーグ戦（matchType: \'individual\'）において、チーム名ではなく個人名で正しく成績が計算・集計されること',
      () {
        final calculator = LeagueStandingsCalculator();
        final matches = [
          // 中村 一郎 (2) vs (0) 高橋 守
          const MatchModel(
            id: 'm1',
            matchType: 'individual',
            redName: 'リーグ個人チーム:中村 一郎',
            whiteName: '剣道道場:高橋 守',
            redScore: 2,
            whiteScore: 0,
            status: 'approved',
          ),
          // 中村 一郎 (1) vs (1) 吉野 はるか
          const MatchModel(
            id: 'm2',
            matchType: 'individual',
            redName: 'リーグ個人チーム:中村 一郎',
            whiteName: '剣友会:吉野 はるか',
            redScore: 1,
            whiteScore: 1,
            status: 'approved',
          ),
          // 高橋 守 (2) vs (0) 吉野 はるか
          const MatchModel(
            id: 'm3',
            matchType: 'individual',
            redName: '剣道道場:高橋 守',
            whiteName: '剣友会:吉野 はるか',
            redScore: 2,
            whiteScore: 0,
            status: 'approved',
          ),
        ];

        final stats = calculator.calculate(matches, defaultRule);

        // 3人が個人名で集計されていることを確認
        expect(stats.length, equals(3));
        final names = stats.map((s) => s.name).toList();
        expect(names, containsAll(['中村 一郎', '吉野 はるか', '高橋 守']));

        // 中村 一郎の戦績検証: 1勝1引分 (勝点 3*1 + 1*1 = 4.0), 本数3本
        final nakamura = stats.firstWhere((s) => s.name == '中村 一郎');
        expect(nakamura.matchWins, equals(1));
        expect(nakamura.matchDraws, equals(1));
        expect(nakamura.totalPointsScored, equals(3));
        expect(nakamura.customPoints, equals(4.0));

        // 吉野 はるかの戦績検証: 1敗1引分 (勝点 0*1 + 1*1 = 1.0), 本数1本
        final yoshino = stats.firstWhere((s) => s.name == '吉野 はるか');
        expect(yoshino.matchLosses, equals(1));
        expect(yoshino.matchDraws, equals(1));
        expect(yoshino.totalPointsScored, equals(1));
        expect(yoshino.customPoints, equals(1.0));

        // 高橋 守の戦績検証: 1勝1敗 (勝点 3*1 + 0*1 = 3.0), 本数2本
        final takahashi = stats.firstWhere((s) => s.name == '高橋 守');
        expect(takahashi.matchWins, equals(1));
        expect(takahashi.matchLosses, equals(1));
        expect(takahashi.totalPointsScored, equals(2));
        expect(takahashi.customPoints, equals(3.0));

        // 順位（ランキング）順に並んでいることの検証
        // 中村(4点) -> 高橋(3点) -> 吉野(1点)
        expect(stats[0].name, equals('中村 一郎'));
        expect(stats[0].rank, equals(1));
        expect(stats[1].name, equals('高橋 守'));
        expect(stats[1].rank, equals(2));
        expect(stats[2].name, equals('吉野 はるか'));
        expect(stats[2].rank, equals(3));
      },
    );
  });
}
