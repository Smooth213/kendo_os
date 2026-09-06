import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_category_team_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/tournament_own_info_provider.dart';

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

    test('個人戦において合同チーム助っ人は自道場チームに吸い込まれず、正規選手のみが集約されること', () {
      // 合同チーム連合Aに所属していた「山田 太郎」（自道場）と「助っ人 花子」（他道場）
      // 助っ人 花子は ownInfo から除外されている
      const ownInfo = TournamentOwnInfo(
        ownTeamNames: {'連合A'},
        ownPlayerNames: {'山田 太郎'},
        playerToTeamMap: {'山田 太郎': '連合A'},
      );

      final matches = [
        const MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '個人戦',
          redName: '山田 太郎',
          whiteName: 'ライバル道場: 鈴木',
          status: 'waiting',
          order: 1,
        ),
        const MatchModel(
          id: 'm2',
          tournamentId: 't1',
          matchType: '個人戦',
          redName: '助っ人 花子',
          whiteName: 'ライバル道場: 佐藤',
          status: 'waiting',
          order: 2,
        ),
      ];

      final result = TimelineCategoryTeamResolver.resolveMatchesByTeam(
        catMatches: matches,
        ownTeams: ['連合A'],
        ownInfo: ownInfo,
      );

      // 自チーム「連合A」のグループを取得
      final ownTeamEntry = result.firstWhere((e) => e.key == '連合A');
      // 自道場の正規選手「山田 太郎」の試合のみが含まれる
      expect(ownTeamEntry.value.any((m) => m.id == 'm1'), isTrue);
      // 助っ人 花子の試合は「連合A」に含まれない！
      expect(ownTeamEntry.value.any((m) => m.id == 'm2'), isFalse);
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
