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

        expect(result.length, 1);
        final teamProgress = result.first;

        // 全体対戦カード数は2対戦（1回戦と2回戦）
        expect(teamProgress.totalCount, 2);
        // 完了対戦カード数は1（1回戦のみ完了）
        expect(teamProgress.completedCount, 1);
        // 進行中の試合があること
        expect(teamProgress.hasLiveMatch, isTrue);
        expect(teamProgress.inProgressMatch?.id, 'm2_jiho');
        expect(teamProgress.nextWaitingMatch?.id, 'm2_chuken');

        // 通算成績: 1回戦（道上勝利）= 1勝0敗
        expect(teamProgress.totalWins, 1);
        expect(teamProgress.totalLosses, 0);
        // 総取得本数: 1回戦(2+1+0+0+2=5本) + 2回戦(2+0+0=2本) = 7本
        expect(teamProgress.totalPoints, 7);

        // コート表示
        expect(teamProgress.currentCourtName, '第1試合場 (2回戦・第4試合)');
      });
    });
  });
}
