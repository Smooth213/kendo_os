import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_category_team_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';

void main() {
  group('TimelineCategoryTeamResolver Tests', () {
    test('チームおよびグループごとに正しく試合を振り分けられること', () {
      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '先鋒',
          redName: 'A高校: 選手1',
          whiteName: 'B高校: 選手2',
          redScore: 0,
          whiteScore: 0,
          status: 'waiting',
          order: 1,
          groupName: 'グループA',
        ),
        MatchModel(
          id: 'm2',
          tournamentId: 't1',
          matchType: '次鋒',
          redName: 'A高校: 選手3',
          whiteName: 'B高校: 選手4',
          redScore: 0,
          whiteScore: 0,
          status: 'waiting',
          order: 2,
          groupName: 'グループA',
        ),
      ];

      final result = TimelineCategoryTeamResolver.resolveMatchesByTeam(
        catMatches: matches,
        ownTeams: ['A高校'],
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.first.key, 'A高校');
      expect(result.first.value.length, 2);
    });
  });

  group('TimelinePlayerMatchClassifier Tests', () {
    test('団体戦グループと個人戦を正しく分類できること', () {
      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '先鋒',
          redName: 'A高校: 山田',
          whiteName: 'B高校: 佐藤',
          redScore: 0,
          whiteScore: 0,
          status: 'waiting',
          order: 1,
          groupName: '第1試合',
        ),
        MatchModel(
          id: 'm2',
          tournamentId: 't1',
          matchType: '次鋒',
          redName: 'A高校: 田中',
          whiteName: 'B高校: 鈴木',
          redScore: 0,
          whiteScore: 0,
          status: 'waiting',
          order: 2,
          groupName: '第1試合',
        ),
        MatchModel(
          id: 'm3',
          tournamentId: 't1',
          matchType: 'individual',
          redName: 'A高校: 高橋',
          whiteName: 'C高校: 伊藤',
          redScore: 0,
          whiteScore: 0,
          status: 'waiting',
          order: 3,
        ),
      ];

      final classified = TimelinePlayerMatchClassifier.classifyTeamMatches(
        teamMatchesList: matches,
        teamName: 'A高校',
        sanitizedQuery: '',
        matchedMatchIds: {},
        matchedGroupNames: {},
        ownTeams: ['A高校'],
      );

      expect(classified.sortedGroups.length, 1);
      expect(classified.sortedGroups.first.key, '第1試合');
      expect(classified.sortedGroups.first.value.length, 2);
      expect(classified.sortedPlayers.length, 1);
      expect(classified.sortedPlayers.first.key, '高橋');
    });
  });
}
