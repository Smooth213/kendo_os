import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('TournamentTeamAutoRegisterService', () {
    final roster = [
      PlayerModel(
        id: 'p1',
        lastName: '皿田',
        firstName: '脩人',
        lastNameKana: 'さらだ',
        firstNameKana: 'しゅうと',
        grade: 3,
      ),
      PlayerModel(
        id: 'p2',
        lastName: '塚本',
        firstName: '大道',
        lastNameKana: 'つかもと',
        firstNameKana: 'ひろみち',
        grade: 6,
      ),
      PlayerModel(
        id: 'p3',
        lastName: '久安',
        firstName: '智也',
        lastNameKana: 'ひさやす',
        firstNameKana: 'ともや',
        grade: 5,
      ),
    ];

    test('3人制チームの試合形式・カテゴリ・スロット割り当てテスト', () {
      final team = const ParsedTeamOrder(
        teamName: '低学年',
        members: [
          ParsedTeamMember(position: '先鋒', name: '皿田脩人'),
          ParsedTeamMember(position: '中堅', name: '塚本'),
          ParsedTeamMember(position: '大将', name: '久安'),
        ],
      );

      final matchType = TournamentTeamAutoRegisterService.determineMatchType(
        team,
      );
      expect(matchType, '団体戦（3人制）');

      final category = TournamentTeamAutoRegisterService.determineCategory(
        team.teamName,
      );
      expect(category, '小学生低学年の部');

      final playerNames = TournamentTeamAutoRegisterService.buildPlayerNames(
        team: team,
        matchType: matchType,
        roster: roster,
      );
      // 先鋒・中堅・大将 の3スロットに名簿照合済みの正式名称が配置される
      expect(playerNames, ['皿田 脩人', '塚本 大道', '久安 智也']);
    });

    test('5人制チームで補欠が存在する場合の割り当てテスト', () {
      final team = const ParsedTeamOrder(
        teamName: '高学年A',
        members: [
          ParsedTeamMember(position: '先鋒', name: '選手1'),
          ParsedTeamMember(position: '次鋒', name: '選手2'),
          ParsedTeamMember(position: '中堅', name: '選手3'),
          ParsedTeamMember(position: '副将', name: '選手4'),
          ParsedTeamMember(position: '大将', name: '選手5'),
          ParsedTeamMember(position: '補欠', name: '補欠選手'),
        ],
      );

      final matchType = TournamentTeamAutoRegisterService.determineMatchType(
        team,
      );
      expect(matchType, '団体戦（5人制）');

      final category = TournamentTeamAutoRegisterService.determineCategory(
        team.teamName,
      );
      expect(category, '小学生高学年の部');

      final playerNames = TournamentTeamAutoRegisterService.buildPlayerNames(
        team: team,
        matchType: matchType,
        roster: roster,
      );
      expect(playerNames.length, 6);
      expect(playerNames[0], '選手1');
      expect(playerNames[1], '選手2');
      expect(playerNames[2], '選手3');
      expect(playerNames[3], '選手4');
      expect(playerNames[4], '選手5');
      expect(playerNames[5], '補欠選手');
    });

    test('チーム一覧から TeamModel リストへの変換テスト', () {
      final teams = [
        const ParsedTeamOrder(
          teamName: '低学年',
          members: [
            ParsedTeamMember(position: '先鋒', name: '皿田 脩人'),
            ParsedTeamMember(position: '中堅', name: '塚本 大道'),
            ParsedTeamMember(position: '大将', name: '久安 智也'),
          ],
        ),
        const ParsedTeamOrder(
          teamName: '中学生',
          members: [
            ParsedTeamMember(position: '先鋒', name: '中学生1'),
            ParsedTeamMember(position: '次鋒', name: '中学生2'),
            ParsedTeamMember(position: '中堅', name: '中学生3'),
            ParsedTeamMember(position: '副将', name: '中学生4'),
            ParsedTeamMember(position: '大将', name: '中学生5'),
          ],
        ),
      ];

      final teamModels = TournamentTeamAutoRegisterService.buildTeamModels(
        teams: teams,
        tournamentId: 'tournament_123',
        roster: roster,
      );

      expect(teamModels.length, 2);
      expect(teamModels[0].tournamentId, 'tournament_123');
      expect(teamModels[0].category, '小学生低学年の部');
      expect(teamModels[0].matchType, '団体戦（3人制）');
      expect(teamModels[0].playerNames.length, 3);

      expect(teamModels[1].tournamentId, 'tournament_123');
      expect(teamModels[1].category, '中学生の部');
      expect(teamModels[1].matchType, '団体戦（5人制）');
      expect(teamModels[1].playerNames.length, 5);

      final categories = TournamentTeamAutoRegisterService.extractCategories(
        teams,
      );
      expect(categories, ['小学生低学年の部', '中学生の部']);
    });

    test('道場名のみでチーム名に学年キーワードがない場合、名簿選手からカテゴリを正しく推定すること', () {
      final team = const ParsedTeamOrder(
        teamName: '道上剣友会',
        members: [
          ParsedTeamMember(position: '先鋒', name: '皿田 脩人'), // 小3
          ParsedTeamMember(position: '中堅', name: '塚本 大道'), // 小6
          ParsedTeamMember(position: '大将', name: '久安 智也'), // 小5
        ],
      );

      // チーム名「道上剣友会」そのものはカテゴリにならず、名簿の学年（小3, 小6, 小5）から「小学生の部」となる
      final category = TournamentTeamAutoRegisterService.determineCategory(
        team.teamName,
        members: team.members,
        roster: roster,
      );
      expect(category, '小学生の部');
    });

    test('勝ち抜き戦・リーグ戦の自動判定および明示指定テスト', () {
      // 1. チーム名に「勝ち抜き」が含まれる場合 -> 勝ち抜き戦
      final kachinukiTeam = const ParsedTeamOrder(
        teamName: '小学生勝ち抜き選抜',
        members: [
          ParsedTeamMember(position: '先鋒', name: '選手1'),
          ParsedTeamMember(position: '次鋒', name: '選手2'),
          ParsedTeamMember(position: '中堅', name: '選手3'),
          ParsedTeamMember(position: '副将', name: '選手4'),
          ParsedTeamMember(position: '大将', name: '選手5'),
        ],
      );
      expect(
        TournamentTeamAutoRegisterService.determineMatchType(kachinukiTeam),
        '勝ち抜き戦',
      );
      expect(TournamentTeamAutoRegisterService.getBaseSlots('勝ち抜き戦'), [
        '先鋒',
        '次鋒',
        '中堅',
        '副将',
        '大将',
      ]);

      // 2. チーム名に「リーグ」が含まれ、複数人の場合 -> リーグ団体戦
      final leagueTeam = const ParsedTeamOrder(
        teamName: 'Aブロックリーグ',
        members: [
          ParsedTeamMember(position: '先鋒', name: '選手1'),
          ParsedTeamMember(position: '次鋒', name: '選手2'),
          ParsedTeamMember(position: '中堅', name: '選手3'),
          ParsedTeamMember(position: '副将', name: '選手4'),
          ParsedTeamMember(position: '大将', name: '選手5'),
        ],
      );
      expect(
        TournamentTeamAutoRegisterService.determineMatchType(leagueTeam),
        'リーグ団体戦',
      );
      expect(TournamentTeamAutoRegisterService.getBaseSlots('リーグ団体戦'), [
        '先鋒',
        '次鋒',
        '中堅',
        '副将',
        '大将',
      ]);

      // 3. チーム名に「リーグ」が含まれ、1人の場合 -> リーグ個人戦
      final leagueIndividualTeam = const ParsedTeamOrder(
        teamName: '予選リーグ',
        members: [ParsedTeamMember(position: '選手', name: '個人選手A')],
      );
      expect(
        TournamentTeamAutoRegisterService.determineMatchType(
          leagueIndividualTeam,
        ),
        'リーグ個人戦',
      );
      expect(TournamentTeamAutoRegisterService.getBaseSlots('リーグ個人戦'), ['選手']);

      // 4. 明示的に matchType が指定されている場合はそれを最優先
      final manualTeam = const ParsedTeamOrder(
        teamName: '低学年チーム',
        matchType: '勝ち抜き戦',
        members: [
          ParsedTeamMember(position: '先鋒', name: '選手1'),
          ParsedTeamMember(position: '中堅', name: '選手2'),
          ParsedTeamMember(position: '大将', name: '選手3'),
        ],
      );
      expect(
        TournamentTeamAutoRegisterService.determineMatchType(manualTeam),
        '勝ち抜き戦',
      );
    });
  });
}
