import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart';

void main() {
  group('🛡️ STEP 5-3: 部内戦モード・リーグ戦/代表戦計算ロジックの徹底検証テスト', () {
    test('1. 部内戦の個人リーグ戦（個人名形式、コロンなし）における順位/勝敗集計の検証', () {
      // 3人の総当たり（リーグ戦）をシミュレーション
      // A vs B -> Aの勝ち (2-0)
      // B vs C -> 引き分け (1-1)
      // C vs A -> Cの勝ち (2-1)
      final rule = const MatchRule(
        isLeague: true,
        winPoint: 3,
        drawPoint: 1,
        lossPoint: 0,
      );

      final matches = [
        MatchModel(
          id: 'match_a_b',
          tournamentId: 'bunaiksen_20260703',
          groupName: 'group_league_1',
          matchType: 'リーグ戦',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          rule: rule,
        ),
        MatchModel(
          id: 'match_b_c',
          tournamentId: 'bunaiksen_20260703',
          groupName: 'group_league_1',
          matchType: 'リーグ戦',
          redName: '選手B',
          whiteName: '選手C',
          redScore: 1,
          whiteScore: 1,
          status: 'finished',
          rule: rule,
        ),
        MatchModel(
          id: 'match_c_a',
          tournamentId: 'bunaiksen_20260703',
          groupName: 'group_league_1',
          matchType: 'リーグ戦',
          redName: '選手C',
          whiteName: '選手A',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          rule: rule,
        ),
      ];

      // 1. KendoRuleEngine を通しての集計
      final stats = KendoRuleEngine.calculateLeagueStandings(matches, rule);

      expect(stats.length, 3);

      // 選手C: 1勝 1分 0敗, 得本数: 3 (1+2), 得勝数: 1 (Bとは引き分け、Aに勝ち)
      final statC = stats.firstWhere((s) => s.name == '選手C');
      expect(statC.matchWins, 1);
      expect(statC.matchDraws, 1);
      expect(statC.matchLosses, 0);
      expect(statC.individualWinners, 1);
      expect(statC.totalPointsScored, 3);
      expect(statC.customPoints, 4.0); // 3 (win) + 1 (draw) = 4

      // 選手A: 1勝 0分 1敗, 得本数: 3 (2+1), 得勝数: 1 (Bに勝ち、Cに負け)
      final statA = stats.firstWhere((s) => s.name == '選手A');
      expect(statA.matchWins, 1);
      expect(statA.matchDraws, 0);
      expect(statA.matchLosses, 1);
      expect(statA.individualWinners, 1);
      expect(statA.totalPointsScored, 3);
      expect(statA.customPoints, 3.0); // 3 (win) = 3

      // 選手B: 0勝 1分 1敗, 得本数: 1 (0+1), 得勝数: 0 (Aに負け、Cと引き分け)
      final statB = stats.firstWhere((s) => s.name == '選手B');
      expect(statB.matchWins, 0);
      expect(statB.matchDraws, 1);
      expect(statB.matchLosses, 1);
      expect(statB.individualWinners, 0);
      expect(statB.totalPointsScored, 1);
      expect(statB.customPoints, 1.0); // 1 (draw) = 1

      // 順位検証 (Cが勝点4で1位、Aが勝点3で2位、Bが勝点1で3位)
      expect(stats[0].name, '選手C');
      expect(stats[0].rank, 1);
      expect(stats[1].name, '選手A');
      expect(stats[1].rank, 2);
      expect(stats[2].name, '選手B');
      expect(stats[2].rank, 3);
    });

    test('2. BunaiksenHelper を使った独自勝点計算（3/1/0ポイント）の検証', () {
      final matches = [
        MatchModel(
          id: 'match_a_b',
          tournamentId: 'bunaiksen_20260703',
          groupName: 'group_league_1',
          matchType: 'リーグ戦',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
        ),
        MatchModel(
          id: 'match_b_c',
          tournamentId: 'bunaiksen_20260703',
          groupName: 'group_league_1',
          matchType: 'リーグ戦',
          redName: '選手B',
          whiteName: '選手C',
          redScore: 1,
          whiteScore: 1,
          status: 'finished',
        ),
      ];

      final teamList = ['選手A', '選手B', '選手C'];

      final pointsA = BunaiksenHelper.calculateCustomLeaguePoints(
        '選手A',
        teamList,
        matches,
      );
      final pointsB = BunaiksenHelper.calculateCustomLeaguePoints(
        '選手B',
        teamList,
        matches,
      );
      final pointsC = BunaiksenHelper.calculateCustomLeaguePoints(
        '選手C',
        teamList,
        matches,
      );

      // A: Bに勝ち(3点), Cとは未対戦(0点) -> 3点
      expect(pointsA, 3);
      // B: Aに負け(0点), Cと引き分け(1点) -> 1点
      expect(pointsB, 1);
      // C: Aとは未対戦(0点), Bと引き分け(1点) -> 1点
      expect(pointsC, 1);
    });

    test('3. 代表戦におけるタイマーのカウントアップ/カウントダウン挙動の検証', () {
      final now = DateTime(2026, 7, 3, 15, 0, 0);

      // A: 時間制限あり (3.0分) の代表戦 -> カウントダウンされるべき
      final limitedDaihyo = MatchModel(
        id: 'daihyo_limited',
        matchType: '代表戦',
        matchTimeMinutes: 3.0,
        status: 'ready',
        redName: '選手A',
        whiteName: '選手B',
        events: const [],
      ).copyWith(timerStartedAt: now.subtract(const Duration(seconds: 45)));

      final remainingLimited = limitedDaihyo.calculateRemainingSeconds(now);
      expect(remainingLimited, 135); // 180 - 45 = 135 秒

      // B: 時間制限なし (0.0分) の代表戦 -> カウントアップされるべき
      final unlimitedDaihyo = MatchModel(
        id: 'daihyo_unlimited',
        matchType: '代表戦',
        matchTimeMinutes: 0.0,
        status: 'ready',
        redName: '選手A',
        whiteName: '選手B',
        events: const [],
      ).copyWith(timerStartedAt: now.subtract(const Duration(seconds: 45)));

      final remainingUnlimited = unlimitedDaihyo.calculateRemainingSeconds(now);
      expect(remainingUnlimited, 45); // 0 + 45 = 45 秒
    });
  });
}
