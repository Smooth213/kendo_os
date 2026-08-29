import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';

void main() {
  group('🥋 【完全保証】チーム試合状況 全試合形式判定＆対戦カード展開テスト要塞', () {
    group('1. 試合形式判定・対戦見出しの精密性保証（誤判定ゼロ保証）', () {
      test('トーナメント団体戦（先鋒〜大将）が絶対に「リーグ団体戦」と誤判定されず「団体戦：」となること', () {
        const matchSenpo = MatchModel(
          id: 'senpo_1',
          groupName: 'group_dantai_r1',
          matchType: '先鋒戦',
          redName: '道上剣友会A: 皿田 脩人',
          whiteName: '相手チーム02: 相手 一郎',
          status: 'in_progress',
          category: '小学生低学年の部',
          order: 1.0,
        );

        const matchDantai = MatchModel(
          id: 'dantai_1',
          groupName: 'group_dantai_r2',
          matchType: '団体戦',
          redName: '道上剣友会A',
          whiteName: '相手チーム03',
          status: 'waiting',
          category: '小学生低学年の部',
          order: 2.0,
        );

        // 判定ヘルパーの検証
        expect(TeamProgressHelper.isIndividualMatch(matchSenpo), isFalse);
        expect(TeamProgressHelper.isLeagueMatch(matchSenpo), isFalse);
        expect(TeamProgressHelper.isKachinukiMatch(matchSenpo), isFalse);

        // 見出しの検証（「リーグ団体戦」が含まれず、確実に「団体戦：」であること）
        final titleSenpo = TeamProgressHelper.extractTeamMatchupTitle(
          matchSenpo,
        );
        expect(titleSenpo, isNot(contains('リーグ')));
        expect(titleSenpo, '団体戦：道上剣友会A vs 相手チーム02');

        final titleDantai = TeamProgressHelper.extractTeamMatchupTitle(
          matchDantai,
        );
        expect(titleDantai, isNot(contains('リーグ')));
        expect(titleDantai, '団体戦：道上剣友会A vs 相手チーム03');
      });

      test('リーグ団体戦が「リーグ団体戦：」と正しく判定されること', () {
        const matchLeagueTeam = MatchModel(
          id: 'league_team_1',
          groupName: 'group_league_1',
          matchType: 'リーグ団体戦',
          redName: '道上選抜',
          whiteName: '強豪館B',
          status: 'finished',
          category: '中学生団体の部',
          order: 1.0,
        );

        expect(TeamProgressHelper.isLeagueMatch(matchLeagueTeam), isTrue);
        expect(TeamProgressHelper.isIndividualMatch(matchLeagueTeam), isFalse);

        final title = TeamProgressHelper.extractTeamMatchupTitle(
          matchLeagueTeam,
        );
        expect(title, 'リーグ団体戦：道上選抜 vs 強豪館B');
      });

      test('リーグ個人戦が「リーグ個人戦：」と正しく判定されること', () {
        const matchLeagueIndiv = MatchModel(
          id: 'league_indiv_1',
          matchType: 'リーグ個人戦',
          redName: '相手 四郎',
          whiteName: '皿田 脩人',
          status: 'waiting',
          category: '小学生個人の部',
          order: 1.0,
        );

        expect(TeamProgressHelper.isLeagueMatch(matchLeagueIndiv), isTrue);
        expect(TeamProgressHelper.isIndividualMatch(matchLeagueIndiv), isTrue);

        final title = TeamProgressHelper.extractTeamMatchupTitle(
          matchLeagueIndiv,
        );
        expect(title, 'リーグ個人戦：相手 四郎 vs 皿田 脩人');
      });

      test('トーナメント個人戦が「個人戦：」と正しく判定されること', () {
        const matchIndiv = MatchModel(
          id: 'indiv_1',
          matchType: '個人戦',
          redName: '道上剣友会: 久安 智也',
          whiteName: 'ライバル館: 相手 三郎',
          status: 'finished',
          category: '中学生個人の部',
          order: 1.0,
        );

        expect(TeamProgressHelper.isIndividualMatch(matchIndiv), isTrue);
        expect(TeamProgressHelper.isLeagueMatch(matchIndiv), isFalse);

        final title = TeamProgressHelper.extractTeamMatchupTitle(matchIndiv);
        expect(title, '個人戦：久安 智也（道上剣友会） vs 相手 三郎（ライバル館）');
      });

      test('勝ち抜き戦が「勝ち抜き戦：」と正しく判定されること', () {
        const matchKachinuki = MatchModel(
          id: 'kachinuki_1',
          matchType: '勝ち抜き戦',
          isKachinuki: true,
          redName: '道上勝抜隊',
          whiteName: '炎陽塾',
          status: 'waiting',
          category: '勝ち抜きオープンの部',
          order: 1.0,
        );

        expect(TeamProgressHelper.isKachinukiMatch(matchKachinuki), isTrue);

        final title = TeamProgressHelper.extractTeamMatchupTitle(
          matchKachinuki,
        );
        expect(title, '勝ち抜き戦：道上勝抜隊 vs 炎陽塾');
      });

      test('錬成会・申合せモードやおかわりの追加試合（matchScene/rule）で正しく【錬成】・【申合せ】が付与されること', () {
        // ① 錬成会モードから追加されたおかわり試合（noteに明示文字列がなくてもmatchSceneで判定）
        const matchRenseiScene = MatchModel(
          id: 'rensei_extra_1',
          groupName: 'group_rensei_extra',
          matchType: '先鋒戦',
          redName: '道上剣友会',
          whiteName: '相手チームA',
          status: 'waiting',
          matchScene: 'renseikai',
          category: '小学生の部',
          order: 1.0,
        );

        final titleRensei = TeamProgressHelper.extractTeamMatchupTitle(
          matchRenseiScene,
        );
        expect(titleRensei, '【錬成】団体戦：道上剣友会 vs 相手チームA');

        // ② 申合せモードから追加されたおかわり試合
        const matchMoushiawaseScene = MatchModel(
          id: 'moushiawase_extra_1',
          matchType: '個人戦',
          redName: '道上: 皿田 脩人',
          whiteName: 'ライバル道場: 相手 B',
          status: 'in_progress',
          matchScene: 'moushiawase',
          category: '小学生個人の部',
          order: 2.0,
        );

        final titleMoushiawase = TeamProgressHelper.extractTeamMatchupTitle(
          matchMoushiawaseScene,
        );
        expect(titleMoushiawase, '【申合せ】個人戦：皿田 脩人（道上） vs 相手 B（ライバル道場）');

        // ③ note に「錬成会」「申合せ」が含まれる場合も確実に付与
        const matchRenseiNote = MatchModel(
          id: 'rensei_note_1',
          matchType: '団体戦',
          redName: '道上剣友会',
          whiteName: '相手チームC',
          status: 'finished',
          note: '【錬成会】第2試合場',
          category: '小学生の部',
          order: 3.0,
        );

        final titleNote = TeamProgressHelper.extractTeamMatchupTitle(
          matchRenseiNote,
        );
        expect(titleNote, '【錬成】団体戦：道上剣友会 vs 相手チームC');
      });
    });

    group('2. 対戦カード完全展開（全試合漏れゼロ保証）', () {
      test('同一チームの1回戦・2回戦および個人戦がそれぞれ独立したカードとして完全展開されること', () {
        final matches = [
          // 道上剣友会Aの1回戦（5人制・終了済）
          const MatchModel(
            id: 'm1_1',
            groupName: 'group_dohjo_a_r1',
            matchType: '先鋒戦',
            redName: '道上剣友会A: 選手1',
            whiteName: '相手01: 相手1',
            status: 'finished',
            redScore: 2,
            whiteScore: 0,
            note: '第1コート, 1回戦',
            category: '小学生低学年の部',
            order: 1.0,
          ),
          const MatchModel(
            id: 'm1_2',
            groupName: 'group_dohjo_a_r1',
            matchType: '次鋒戦',
            redName: '道上剣友会A: 選手2',
            whiteName: '相手01: 相手2',
            status: 'finished',
            redScore: 1,
            whiteScore: 0,
            note: '第1コート, 1回戦',
            category: '小学生低学年の部',
            order: 2.0,
          ),

          // 道上剣友会Aの2回戦（5人制・進行中LIVE）
          MatchModel(
            id: 'm2_1',
            groupName: 'group_dohjo_a_r2',
            matchType: '先鋒戦',
            redName: '道上剣友会A: 皿田 脩人',
            whiteName: '相手02: 相手3',
            status: 'in_progress',
            redScore: 1,
            whiteScore: 0,
            note: '第3試合場, 2回戦',
            category: '小学生低学年の部',
            order: 3.0,
            timerStartedAt: DateTime.now(),
          ),

          // 久安 智也の個人戦1回戦（終了済）
          const MatchModel(
            id: 'indiv_hisayasu',
            matchType: '個人戦',
            redName: '道上剣友会A: 久安 智也',
            whiteName: '強豪塾: 相手4',
            status: 'finished',
            redScore: 2,
            whiteScore: 0,
            note: '第2コート, 1回戦',
            category: '小学生個人の部',
            order: 4.0,
          ),

          // 皿田 脩人のリーグ個人戦（待機中）
          const MatchModel(
            id: 'league_sarada',
            matchType: 'リーグ個人戦',
            redName: '相手5',
            whiteName: '皿田 脩人',
            status: 'waiting',
            note: '第4コート, Aリーグ',
            category: '小学生個人の部',
            order: 5.0,
          ),
        ];

        final results = calculateTeamProgress(
          matches,
          myDojoName: '道上',
          registeredTeamNames: ['道上剣友会A'],
          registeredPlayerNames: ['皿田 脩人', '久安 智也', '選手1', '選手2'],
        );

        // 1回戦、2回戦、個人戦(久安)、リーグ個人戦(皿田) の4対戦カードが漏れなく全て展開されること！
        expect(results.length, 4);

        // ① 2回戦（LIVE）が最上位
        final r2 = results[0];
        expect(r2.hasLiveMatch, isTrue);
        expect(r2.matchupTitle, '団体戦：道上剣友会A vs 相手02');
        expect(r2.currentCourtName, '第3試合場 (2回戦)');

        // ② 待機中のリーグ個人戦（皿田）
        final leagueIndiv = results.firstWhere(
          (r) => r.matches.any((m) => m.id == 'league_sarada'),
        );
        expect(leagueIndiv.matchupTitle, 'リーグ個人戦：相手5 vs 皿田 脩人');

        // ③ 終了済みの1回戦団体戦
        final r1 = results.firstWhere(
          (r) => r.matches.any((m) => m.id == 'm1_1'),
        );
        expect(r1.isAllFinished, isTrue);
        expect(r1.matchupTitle, '団体戦：道上剣友会A vs 相手01');

        // ④ 終了済みの個人戦（久安）
        final indiv = results.firstWhere(
          (r) => r.matches.any((m) => m.id == 'indiv_hisayasu'),
        );
        expect(indiv.isAllFinished, isTrue);
        expect(indiv.matchupTitle, '個人戦：久安 智也（道上剣友会A） vs 相手4（強豪塾）');
      });
    });
  });
}
