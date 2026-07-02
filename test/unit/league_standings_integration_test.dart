import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('🛡️ リーグ団体戦・個人戦星取り表集計完全検証テスト', () {
    late MatchRule testRule;

    setUp(() {
      testRule = const MatchRule(
        winPoint: 3.0,
        drawPoint: 1.0,
        lossPoint: 0.0,
        matchTimeMinutes: 3.0,
      );
    });

    test('1. 団体リーグ戦（団体戦）において、コロンの前半（チーム名）で正しく集計されること', () {
      final matches = [
        // チームA : 選手A1 vs チームB : 選手B1 (A勝ち 2-0)
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: 'チームA : 選手A1',
          whiteName: 'チームB : 選手B1',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        // チームA : 選手A2 vs チームC : 選手C1 (A勝ち 1-0)
        const MatchModel(
          id: 'm2',
          matchType: '中堅',
          redName: 'チームA : 選手A2',
          whiteName: 'チームC : 選手C1',
          redScore: 1,
          whiteScore: 0,
          status: 'approved',
        ),
        // チームB : 選手B2 vs チームC : 選手C2 (引き分け 1-1)
        const MatchModel(
          id: 'm3',
          matchType: '大将',
          redName: 'チームB : 選手B2',
          whiteName: 'チームC : 選手C2',
          redScore: 1,
          whiteScore: 1,
          status: 'approved',
        ),
      ];

      final stats = KendoRuleEngine.calculateLeagueStandings(matches, testRule);

      // チームA, チームB, チームC の3チームが集計対象になること
      expect(stats.length, equals(3));
      final teamNames = stats.map((s) => s.name).toList();
      expect(teamNames, containsAll(['チームA', 'チームB', 'チームC']));

      // チームAの成績検証 (2勝0敗、合計本数 3本)
      final teamA = stats.firstWhere((s) => s.name == 'チームA');
      expect(teamA.matchWins, equals(2));
      expect(teamA.totalPointsScored, equals(3));
      expect(teamA.rank, equals(1));

      // チームBの成績検証 (0勝1敗1分、合計本数 1本)
      final teamB = stats.firstWhere((s) => s.name == 'チームB');
      expect(teamB.matchLosses, equals(1));
      expect(teamB.matchDraws, equals(1));
      expect(teamB.totalPointsScored, equals(1));

      // チームCの成績検証 (0勝1敗1分、合計本数 1本)
      final teamC = stats.firstWhere((s) => s.name == 'チームC');
      expect(teamC.matchLosses, equals(1));
      expect(teamC.matchDraws, equals(1));
      expect(teamC.totalPointsScored, equals(1));
    });

    test('2. 個人リーグ戦（個人戦）において、コロンの後半（個人名）で正しく集計されること', () {
      final matches = [
        // リーグ個人チーム:中村 一郎 vs 剣道道場:高橋 守 (中村勝ち 2-0)
        const MatchModel(
          id: 'm1',
          matchType: 'individual',
          redName: 'リーグ個人チーム:中村 一郎',
          whiteName: '剣道道場:高橋 守',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
        // リーグ個人チーム:中村 一郎 vs 剣友会:吉野 はるか (引き分け 1-1)
        const MatchModel(
          id: 'm2',
          matchType: '選手',
          redName: 'リーグ個人チーム:中村 一郎',
          whiteName: '剣友会:吉野 はるか',
          redScore: 1,
          whiteScore: 1,
          status: 'approved',
        ),
        // 剣道道場:高橋 守 vs 剣友会:吉野 はるか (高橋勝ち 2-0)
        const MatchModel(
          id: 'm3',
          matchType: '一般個人戦',
          redName: '剣道道場:高橋 守',
          whiteName: '剣友会:吉野 はるか',
          redScore: 2,
          whiteScore: 0,
          status: 'approved',
        ),
      ];

      final stats = KendoRuleEngine.calculateLeagueStandings(matches, testRule);

      // 個人名（中村 一郎、吉野 はるか、高橋 守）の3名で集計されていること
      expect(stats.length, equals(3));
      final names = stats.map((s) => s.name).toList();
      expect(names, containsAll(['中村 一郎', '吉野 はるか', '高橋 守']));

      // 中村 一郎の戦績検証 (1勝1分、本数3本)
      final nakamura = stats.firstWhere((s) => s.name == '中村 一郎');
      expect(nakamura.matchWins, equals(1));
      expect(nakamura.matchDraws, equals(1));
      expect(nakamura.totalPointsScored, equals(3));
      expect(nakamura.rank, equals(1));

      // 高橋 守の戦績検証 (1勝1敗、本数2本)
      final takahashi = stats.firstWhere((s) => s.name == '高橋 守');
      expect(takahashi.matchWins, equals(1));
      expect(takahashi.matchLosses, equals(1));
      expect(takahashi.totalPointsScored, equals(2));
      expect(takahashi.rank, equals(2));

      // 吉野 はるかの戦績検証 (0勝1敗1分、本数1本)
      final yoshino = stats.firstWhere((s) => s.name == '吉野 はるか');
      expect(yoshino.matchLosses, equals(1));
      expect(yoshino.matchDraws, equals(1));
      expect(yoshino.totalPointsScored, equals(1));
      expect(yoshino.rank, equals(3));
    });
  });
}
