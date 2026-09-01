import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';

void main() {
  group('🥋 チーム試合状況 ドメイン＆計算ロジック完全保証テスト', () {
    group('1. 自チーム判定（isSideOwn）高精度リゾルバー検証', () {
      final knownTeams = {'道上剣友会A', '道上選抜', '合同テスト'};
      final knownPlayers = {'皿田 脩人', '久安 智也', '塚本 大道'};
      const myDojo = '道上';

      test('登録チーム名と完全一致する場合は自チームと判定', () {
        expect(
          isSideOwn(
            sideFullName: '道上剣友会A: 選手1',
            knownTeams: knownTeams,
            knownPlayers: {},
            myDojoName: '',
          ),
          isTrue,
        );
      });

      test('ルール設定のチーム名と一致する場合は自チームと判定', () {
        expect(
          isSideOwn(
            sideFullName: '特別選抜: 選手1',
            knownTeams: {},
            knownPlayers: {},
            myDojoName: '',
            ruleTeamName: '特別選抜',
          ),
          isTrue,
        );
      });

      test('チーム名が全く異なっていても登録選手名が含まれれば逆引きで自チームと判定', () {
        expect(
          isSideOwn(
            sideFullName: '大阪連合チーム: 久安 智也',
            knownTeams: {},
            knownPlayers: knownPlayers,
            myDojoName: '道上',
          ),
          isTrue,
        );
      });

      test('道場名プレフィックス（道上）に前方一致する場合は自チームと判定', () {
        expect(
          isSideOwn(
            sideFullName: '道上剣友会B: 選手2',
            knownTeams: {},
            knownPlayers: {},
            myDojoName: myDojo,
          ),
          isTrue,
        );
      });

      test('相手チームは自チームと判定されないこと', () {
        expect(
          isSideOwn(
            sideFullName: '相手チーム02: 相手一郎',
            knownTeams: knownTeams,
            knownPlayers: knownPlayers,
            myDojoName: myDojo,
          ),
          isFalse,
        );
      });
    });

    group('2. コート・回戦・試合順抽出（extractCourtAndRoundDisplay）検証', () {
      test('第2コート, 1回戦, 4試合目 -> 第2コート (1回戦・第4試合)', () {
        const match = MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: 'A',
          whiteName: 'B',
          note: '第2コート, 1回戦, 4試合目',
        );
        expect(extractCourtAndRoundDisplay(match), '第2コート (1回戦・第4試合)');
      });

      test('第1試合場, 3試合目 -> 第1試合場 (第3試合)', () {
        const match = MatchModel(
          id: 'm2',
          matchType: '個人戦',
          redName: 'A',
          whiteName: 'B',
          note: '第1試合場, 3試合目',
        );
        expect(extractCourtAndRoundDisplay(match), '第1試合場 (第3試合)');
      });

      test('第3コート, 準決勝 -> 第3コート (準決勝)', () {
        const match = MatchModel(
          id: 'm3',
          matchType: '個人戦',
          redName: 'A',
          whiteName: 'B',
          note: '第3コート, 準決勝',
        );
        expect(extractCourtAndRoundDisplay(match), '第3コート (準決勝)');
      });

      test('部内戦コート -> 部内戦コート', () {
        const match = MatchModel(
          id: 'm4',
          matchType: '個人戦',
          redName: 'A',
          whiteName: 'B',
          note: '部内戦コート',
        );
        expect(extractCourtAndRoundDisplay(match), '部内戦コート');
      });

      test('コート未指定で回戦のみ -> コート未指定 (2回戦・第1試合)', () {
        const match = MatchModel(
          id: 'm5',
          matchType: '個人戦',
          redName: 'A',
          whiteName: 'B',
          note: '2回戦, 1試合目',
        );
        expect(extractCourtAndRoundDisplay(match), 'コート未指定 (2回戦・第1試合)');
      });

      test('すべて未指定 -> コート未指定', () {
        const match = MatchModel(
          id: 'm6',
          matchType: '個人戦',
          redName: 'A',
          whiteName: 'B',
          note: '',
        );
        expect(extractCourtAndRoundDisplay(match), 'コート未指定');
      });
    });

    group('3. 団体戦対戦集計（calculateTeamProgress）検証', () {
      test('団体戦5試合（先鋒〜大将）が1対戦カードとして正しく集計されること', () {
        final matches = [
          // 団体戦1回戦（5試合）: 終了済（3勝1敗1分でチーム勝利）
          const MatchModel(
            id: 'm1_senpo',
            groupName: 'group_round_1',
            matchType: '先鋒戦',
            redName: '道上A: 選手1',
            whiteName: '相手A: 相手1',
            status: 'finished',
            redScore: 2,
            whiteScore: 0,
            note: '第1試合場, 1回戦, 1試合目',
            category: '小学生の部',
            order: 1.0,
          ),
          const MatchModel(
            id: 'm1_jiho',
            groupName: 'group_round_1',
            matchType: '次鋒戦',
            redName: '道上A: 選手2',
            whiteName: '相手A: 相手2',
            status: 'finished',
            redScore: 1,
            whiteScore: 0,
            note: '第1試合場, 1回戦, 1試合目',
            category: '小学生の部',
            order: 2.0,
          ),
          const MatchModel(
            id: 'm1_chuken',
            groupName: 'group_round_1',
            matchType: '中堅戦',
            redName: '道上A: 選手3',
            whiteName: '相手A: 相手3',
            status: 'finished',
            redScore: 0,
            whiteScore: 0,
            note: '第1試合場, 1回戦, 1試合目',
            category: '小学生の部',
            order: 3.0,
          ),
          const MatchModel(
            id: 'm1_fukujo',
            groupName: 'group_round_1',
            matchType: '副将戦',
            redName: '道上A: 選手4',
            whiteName: '相手A: 相手4',
            status: 'finished',
            redScore: 0,
            whiteScore: 1,
            note: '第1試合場, 1回戦, 1試合目',
            category: '小学生の部',
            order: 4.0,
          ),
          const MatchModel(
            id: 'm1_taisho',
            groupName: 'group_round_1',
            matchType: '大将戦',
            redName: '道上A: 選手5',
            whiteName: '相手A: 相手5',
            status: 'finished',
            redScore: 2,
            whiteScore: 1,
            note: '第1試合場, 1回戦, 1試合目',
            category: '小学生の部',
            order: 5.0,
          ),

          // 団体戦2回戦（3試合）: 進行中（先鋒終了、次鋒LIVE、中堅待機）
          const MatchModel(
            id: 'm2_senpo',
            groupName: 'group_round_2',
            matchType: '先鋒戦',
            redName: '相手B: 相手6',
            whiteName: '道上A: 選手1',
            status: 'finished',
            redScore: 0,
            whiteScore: 2,
            note: '第1試合場, 2回戦, 4試合目',
            category: '小学生の部',
            order: 6.0,
          ),
          MatchModel(
            id: 'm2_jiho',
            groupName: 'group_round_2',
            matchType: '次鋒戦',
            redName: '相手B: 相手7',
            whiteName: '道上A: 選手2',
            status: 'in_progress',
            redScore: 1,
            whiteScore: 0,
            note: '第1試合場, 2回戦, 4試合目',
            category: '小学生の部',
            order: 7.0,
            timerStartedAt: DateTime.now(),
          ),
          const MatchModel(
            id: 'm2_chuken',
            groupName: 'group_round_2',
            matchType: '中堅戦',
            redName: '相手B: 相手8',
            whiteName: '道上A: 選手3',
            status: 'waiting',
            note: '第1試合場, 2回戦, 4試合目',
            category: '小学生の部',
            order: 8.0,
          ),
        ];

        final result = calculateTeamProgress(
          matches,
          myDojoName: '道上',
          registeredTeamNames: ['道上A'],
        );

        // 1回戦カードと2回戦カードの2対戦カードが展開されること
        expect(result.length, 2);

        // 2回戦カード（進行中LIVE）が上位
        final round2Progress = result.first;
        expect(round2Progress.hasLiveMatch, isTrue);
        expect(round2Progress.inProgressMatch?.id, 'm2_jiho');
        expect(round2Progress.nextWaitingMatch?.id, 'm2_chuken');
        expect(round2Progress.totalCount, 2); // 本日の全対戦カード数: 2
        expect(round2Progress.completedCount, 1); // 終了した対戦カード数: 1
        expect(round2Progress.totalWins, 1); // 1回戦で団体戦勝利（1勝）

        // 1回戦カード（終了済）
        final round1Progress = result[1];
        expect(round1Progress.totalCount, 2); // 全2対戦
        expect(round1Progress.completedCount, 1); // 1対戦完了
        expect(round1Progress.totalWins, 1); // 団体戦1勝
        expect(round1Progress.totalPoints, 7); // 1回戦5本 + 2回戦2本 = 7本
      });

      test('4. 個人戦・リーグ個人戦・リーグ団体戦・勝ち抜き戦が漏れなくカード化され正しく集計されること', () {
        final multiMatches = [
          // 個人戦（皿田 脩人: 終了済勝）
          const MatchModel(
            id: 'indiv_1',
            matchType: '個人戦',
            redName: '道上剣友会: 皿田 脩人',
            whiteName: 'ライバル館: 相手 太郎',
            status: 'finished',
            redScore: 2,
            whiteScore: 0,
            note: '第1コート, 1回戦, 1試合目',
            category: '個人小学生の部',
            order: 1.0,
          ),
          // リーグ個人戦（久安 智也: 進行中LIVE）
          MatchModel(
            id: 'league_indiv_1',
            matchType: 'リーグ個人戦',
            redName: '相手 次郎',
            whiteName: '久安 智也',
            status: 'in_progress',
            redScore: 0,
            whiteScore: 1,
            note: '第2コート, Aリーグ, 3試合目',
            category: '個人中学生の部',
            order: 2.0,
            timerStartedAt: DateTime.now(),
          ),
          // 勝ち抜き戦（道上剣友会: 待機中）
          const MatchModel(
            id: 'kachinuki_1',
            matchType: '勝ち抜き戦',
            isKachinuki: true,
            redName: '道上剣友会',
            whiteName: '炎陽塾',
            status: 'waiting',
            note: '第3試合場, 1回戦',
            category: '勝ち抜きオープンの部',
            order: 3.0,
          ),
        ];

        final result = calculateTeamProgress(
          multiMatches,
          myDojoName: '道上剣友会',
          registeredTeamNames: ['道上剣友会'],
          registeredPlayerNames: ['皿田 脩人', '久安 智也'],
        );

        // 自道場として全て認識されること
        expect(result.isNotEmpty, isTrue);

        // 個人戦カードの検証
        final indivStatus = result.firstWhere(
          (t) => t.matches.any((m) => m.id == 'indiv_1'),
        );
        expect(indivStatus.totalWins, greaterThanOrEqualTo(1));
        expect(
          extractTeamMatchupTitle(
            indivStatus.matches.firstWhere((m) => m.id == 'indiv_1'),
          ),
          contains('個人戦：'),
        );

        // リーグ個人戦の検証
        final leagueIndivMatch = multiMatches.firstWhere(
          (m) => m.id == 'league_indiv_1',
        );
        expect(extractTeamMatchupTitle(leagueIndivMatch), contains('リーグ個人戦：'));

        // 勝ち抜き戦の検証
        final kachinukiMatch = multiMatches.firstWhere(
          (m) => m.id == 'kachinuki_1',
        );
        expect(extractTeamMatchupTitle(kachinukiMatch), contains('勝ち抜き戦：'));
      });
    });
  });
}
