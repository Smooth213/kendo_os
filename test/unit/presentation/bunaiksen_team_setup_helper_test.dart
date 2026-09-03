import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_team_setup_helper.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('BunaiksenTeamSetupHelper テスト', () {
    final p1 = PlayerModel(
      id: 'p1',
      lastName: 'A',
      firstName: '1',
      lastNameKana: 'エー',
      firstNameKana: 'ワン',
      grade: 1,
    );
    final p2 = PlayerModel(
      id: 'p2',
      lastName: 'B',
      firstName: '2',
      lastNameKana: 'ビー',
      firstNameKana: 'ツー',
      grade: 2,
    );
    final p3 = PlayerModel(
      id: 'p3',
      lastName: 'C',
      firstName: '3',
      lastNameKana: 'シー',
      firstNameKana: 'スリー',
      grade: 3,
    );
    final p4 = PlayerModel(
      id: 'p4',
      lastName: 'D',
      firstName: '4',
      lastNameKana: 'ディー',
      firstNameKana: 'フォー',
      grade: 4,
    );

    final master = [p1, p2, p3, p4];

    test('autoAssignByGrade でスネークドラフト方式で均等に振り分けられること', () {
      final pool = ['A 1', 'B 2', 'C 3', 'D 4'];
      final result = BunaiksenTeamSetupHelper.autoAssignByGrade(
        poolPlayers: pool,
        masterPlayers: master,
        teamSize: 2,
      );

      // 0番目: A 1 (grade 1) -> red[0]
      // 1番目: B 2 (grade 2) -> white[0]
      // 2番目: C 3 (grade 3) -> white[1]
      // 3番目: D 4 (grade 4) -> red[1]
      expect(result.redTeam[0], 'A 1');
      expect(result.whiteTeam[0], 'B 2');
      expect(result.whiteTeam[1], 'C 3');
      expect(result.redTeam[1], 'D 4');
    });

    test('generateTeamMatches で団体戦の試合リストが正確に生成されること', () {
      final now = DateTime(2026, 9, 3, 12, 0);
      final rule = MatchRule(matchTimeMinutes: 3.0);
      final positions = ['先鋒', '大将'];
      final matches = BunaiksenTeamSetupHelper.generateTeamMatches(
        teamSize: 2,
        currentPositions: positions,
        redTeam: ['選手A', '選手B'],
        whiteTeam: ['選手C', '選手D'],
        rule: rule,
        now: now,
      );

      expect(matches.length, 2);
      expect(matches[0].tournamentId, 'bunaiksen_20260903');
      expect(matches[0].matchType, '先鋒');
      expect(matches[0].redName, '選手A');
      expect(matches[0].whiteName, '選手C');
      expect(matches[0].status, 'waiting');

      expect(matches[1].matchType, '大将');
      expect(matches[1].redName, '選手B');
      expect(matches[1].whiteName, '選手D');
      expect(matches[0].groupName, equals(matches[1].groupName));
    });
  });
}
