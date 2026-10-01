import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_player_roster_resolver.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';

void main() {
  group('[Unit] 現場選手交代および学年カテゴリ自動解決エンジン単体テスト', () {
    test('学年数値から剣道公式カテゴリ文字列が正確に決定されること', () {
      expect(MatchPlayerRosterResolver.getPlayerCategory(-1), '初心者の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(0), '幼年の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(1), '小学生低学年の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(4), '小学生低学年の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(5), '小学生高学年の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(6), '小学生高学年の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(7), '中学生の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(9), '中学生の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(10), '高校生の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(12), '高校生の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(13), '一般の部');
      expect(MatchPlayerRosterResolver.getPlayerCategory(20), '一般の部');
    });

    test('resolveにおいて出場中選手とポジションおよびチーム補欠リストが正しく分類されること', () {
      final match1 = MatchModel(
        id: 'm-1',
        tournamentId: 't-1',
        matchType: '先鋒',
        groupName: '1回戦',
        redName: '剣道クラブA:山田太郎',
        whiteName: '道場B:佐藤二朗',
      );
      final match2 = MatchModel(
        id: 'm-2',
        tournamentId: 't-1',
        matchType: '次鋒',
        groupName: '1回戦',
        redName: '剣道クラブA:田中三郎',
        whiteName: '道場B:鈴木四郎',
      );

      const registeredTeam = TeamModel(
        id: 'team-1',
        tournamentId: 't-1',
        category: '小学生高学年の部',
        teamName: '剣道クラブA',
        playerNames: ['山田 太郎', '田中 三郎', '補欠選手X'],
      );

      final players = [
        PlayerModel(
          id: 'p-1',
          lastName: '山田',
          firstName: '太郎',
          lastNameKana: 'やまだ',
          firstNameKana: 'たろう',
          organization: '剣道クラブA',
          grade: 6,
        ),
        PlayerModel(
          id: 'p-2',
          lastName: '田中',
          firstName: '三郎',
          lastNameKana: 'たなか',
          firstNameKana: 'さぶろう',
          organization: '剣道クラブA',
          grade: 6,
        ),
        PlayerModel(
          id: 'p-3',
          lastName: '補欠選手',
          firstName: 'X',
          lastNameKana: 'ほけつ',
          firstNameKana: 'えっくす',
          organization: '剣道クラブA',
          grade: 5,
        ),
        PlayerModel(
          id: 'p-4',
          lastName: '他カテゴリ選手',
          firstName: 'Y',
          lastNameKana: 'ほか',
          firstNameKana: 'わい',
          organization: '剣道クラブA',
          grade: 2,
        ),
      ];

      final roster = MatchPlayerRosterResolver.resolve(
        teamName: '剣道クラブA',
        match: match1,
        currentGroupMatches: [match1, match2],
        players: players,
        registeredTeams: [registeredTeam],
      );

      expect(roster.activePlayerNames.contains('山田太郎'), isTrue);
      expect(roster.activePlayerNames.contains('田中三郎'), isTrue);
      expect(roster.playerPositions['山田太郎'], '先鋒');
      expect(roster.playerPositions['田中三郎'], '次鋒');
    });
  });
}
