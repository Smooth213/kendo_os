import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_match_generator.dart';

void main() {
  group(
    '[Widget] OrderSetupMatchGenerator via OrderSetupExecutionHelper テスト',
    () {
      test('generateMatchesにおいて 個人戦の有効な試合一覧が正しく生成されること', () {
        final rule = MatchRule(category: '小学生低学年の部');

        final matches = OrderSetupMatchGenerator.generateMatches(
          tournamentId: 't1',
          rule: rule,
          positions: ['選手'],
          selectedPlayers: {0: '山田'},
          opponentPlayers: {0: '佐藤'},
          opponentTeamInput: 'B道場',
          isOwnTeamRed: true,
          leagueParticipants: [],
          leagueTeamOrders: {},
          matchType: '個人戦',
          isStartNow: true,
          baseOrder: 1000.0,
        );

        expect(matches.length, 1);
        expect(matches.first.redName, contains('山田'));
        expect(matches.first.whiteName, contains('佐藤'));
      });
    },
  );
}
