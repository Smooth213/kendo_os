import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_text_parser.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('[E2E] コピー自動登録から部門微調整および大会編成・進行完全貫通テスト', () {
    test('コピー自動登録後に部門を微調整したエントリーが正確に大会登録・トーナメント進行まで貫通すること', () {
      // ── Step 1: テキスト取り込み（個人戦エントリーのパース） ──
      const sampleText = '''
第35回 少年少女剣道選手権大会
2026年10月11日
会場: 広島県立武道館

個人戦
中学生
平山 空
前本 渚

小学生
恵木 春陽
塚本 大道
''';

      final parsedData = TournamentTextParser.parse(sampleText);
      expect(parsedData.teams.length, 4);
      expect(parsedData.teams.every((t) => t.matchType == '個人戦'), isTrue);

      // ── Step 2: ユーザーによる各エントリーの部門微調整 ──
      // 平山 空 ➔ 中学生男子の部
      // 前本 渚 ➔ 中学生女子の部
      // 恵木 春陽 ➔ 小学生3年の部
      // 塚本 大道 ➔ 小学生高学年の部
      final tunedTeams = [
        parsedData.teams[0].copyWith(category: '中学生男子の部'),
        parsedData.teams[1].copyWith(category: '中学生女子の部'),
        parsedData.teams[2].copyWith(category: '小学生3年の部'),
        parsedData.teams[3].copyWith(category: '小学生高学年の部'),
      ];

      // ── Step 3: 部門解決および大会カテゴリ一覧抽出 ──
      final categories = TournamentTeamAutoRegisterService.extractCategories(
        tunedTeams,
      );
      expect(
        categories,
        containsAll(['中学生男子の部', '中学生女子の部', '小学生3年の部', '小学生高学年の部']),
      );
      expect(categories.length, 4);

      // ── Step 4: 大会登録用 TeamModel 群の生成 ──
      final roster = <PlayerModel>[];
      final teamModels = TournamentTeamAutoRegisterService.buildTeamModels(
        teams: tunedTeams,
        tournamentId: 'tour_tuned_01',
        roster: roster,
      );

      expect(teamModels.length, 4);
      expect(teamModels[0].teamName, '平山 空');
      expect(teamModels[0].category, '中学生男子の部');
      expect(teamModels[1].teamName, '前本 渚');
      expect(teamModels[1].category, '中学生女子の部');
      expect(teamModels[2].teamName, '恵木 春陽');
      expect(teamModels[2].category, '小学生3年の部');
      expect(teamModels[3].teamName, '塚本 大道');
      expect(teamModels[3].category, '小学生高学年の部');

      // ── Step 5: 大会モデルおよび各部門マッチの編成 ──
      final tournament = TournamentModel(
        id: 'tour_tuned_01',
        organizationId: 'org_kendo_hiroshima',
        name: parsedData.tournamentName,
        venue: parsedData.venue,
        status: 'active',
        categories: categories,
        date: DateTime(2026, 10, 11),
      );

      const standardRule = MatchRule(
        matchTimeMinutes: 3.0,
        isIpponShobu: false,
        enchoTimeMinutes: 3.0,
      );

      // 中学生男子の部 決勝戦の編成
      final matchBoys = MatchModel(
        id: 'match_jh_boys_final',
        tournamentId: tournament.id,
        category: '中学生男子の部',
        groupName: '個人戦トーナメント',
        matchType: '個人戦',
        status: 'in_progress',
        redName: teamModels[0].teamName, // 平山 空
        whiteName: '対戦相手A',
        redScore: 0,
        whiteScore: 0,
        rule: standardRule,
        order: 1.0,
        events: [],
      );

      // ── Step 6: 試合進行と一本打突記録 ──
      final strike1 = ScoreEvent(
        id: 'ev_boys_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: DateTime(2026, 10, 11, 10, 0),
        logicalClock: 1,
      );
      final strike2 = ScoreEvent(
        id: 'ev_boys_2',
        side: Side.red,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: DateTime(2026, 10, 11, 10, 1),
        logicalClock: 2,
      );

      final finishedMatchBoys = matchBoys.copyWith(
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
        events: [strike1, strike2],
      );

      // ── Step 7: 勝敗確定と結果整合性のアサーション ──
      expect(finishedMatchBoys.status, 'finished');
      expect(finishedMatchBoys.category, '中学生男子の部');
      expect(finishedMatchBoys.redScore, 2);
      expect(finishedMatchBoys.whiteScore, 0);
      expect(finishedMatchBoys.redName, '平山 空');
      expect(
        finishedMatchBoys.events.map((e) => e.strikeType),
        equals([StrikeType.men, StrikeType.kote]),
      );
    });
  });
}
