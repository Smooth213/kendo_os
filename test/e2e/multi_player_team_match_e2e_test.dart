import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';
import 'package:kendo_os/shared/utils/kendo_position_sorter.dart';

void main() {
  group('[E2E] 多人数団体戦（8人制・9人制）生成・整列・代表戦ライフサイクル完全検証', () {
    test('8人制団体戦（偶数・中堅なし）: 試合作成からソート・勝敗集計のライフサイクルこと', () {
      final redTeam = '東京道場A';
      final redMembers = [
        '先鋒 太郎',
        '次鋒 次郎',
        '六将 三郎',
        '五将 四郎',
        '四将 五郎',
        '三将 六郎',
        '副将 七郎',
        '大将 八郎',
      ];
      final whiteTeam = '大阪武道館B';
      final whiteMembers = [
        '白 選手1',
        '白 選手2',
        '白 選手3',
        '白 選手4',
        '白 選手5',
        '白 選手6',
        '白 選手7',
        '白 選手8',
      ];

      // 1. ポジション名生成
      final positions = MatchFormatSetupHelper.generatePositions(8);
      expect(positions, ['先鋒', '次鋒', '六将', '五将', '四将', '三将', '副将', '大将']);

      // 2. 試合群の生成シミュレーション（MatchGenerator と同等のロジック）
      final bouts = <MatchModel>[];
      final baseOrder = 1000.0;
      for (int i = 0; i < positions.length; i++) {
        bouts.add(
          MatchModel(
            id: 'm_8_$i',
            tournamentId: 'tour_e2e_multi',
            matchType: positions[i],
            groupName: '$redTeam vs $whiteTeam',
            redName: '$redTeam:${redMembers[i]}',
            whiteName: '$whiteTeam:${whiteMembers[i]}',
            matchOrder: i + 1,
            order: baseOrder + i,
            status: 'finished',
          ),
        );
      }

      expect(bouts.length, equals(8));
      expect(bouts.last.matchType, equals('大将'));

      // 3. 入力順やネットワーク乱れを想定したシャッフル
      final scrambled = bouts.reversed.toList();

      // 4. KendoPositionSorter による整列
      final sorted = KendoPositionSorter.sortMatches(scrambled);
      expect(sorted.map((m) => m.matchType).toList(), positions);
      expect(sorted.first.matchType, equals('先鋒'));
      expect(sorted.last.matchType, equals('大将'));

      // 5. 各試合スコアの集計（赤5勝、白2勝、1引分）
      final scoredBouts = sorted.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value;
        if (idx < 5) {
          // 先鋒〜四将: 赤勝ち (2-0)
          return m.copyWith(redScore: 2, whiteScore: 0);
        } else if (idx < 7) {
          // 三将〜副将: 白勝ち (0-2)
          return m.copyWith(redScore: 0, whiteScore: 2);
        } else {
          // 大将: 引き分け (1-1)
          return m.copyWith(redScore: 1, whiteScore: 1);
        }
      }).toList();

      int redWins = 0;
      int whiteWins = 0;
      int redPoints = 0;
      int whitePoints = 0;

      for (final m in scoredBouts) {
        redPoints += m.redScore;
        whitePoints += m.whiteScore;
        if (m.redScore > m.whiteScore) redWins++;
        if (m.whiteScore > m.redScore) whiteWins++;
      }

      expect(redWins, equals(5));
      expect(whiteWins, equals(2));
      expect(redPoints, equals(11)); // 5*2 + 1 = 11
      expect(whitePoints, equals(5)); // 2*2 + 1 = 5
      expect(redWins > whiteWins, isTrue, reason: '赤チームの勝利');
    });

    test('9人制団体戦（奇数・中央中堅あり）: 同点 代表戦発生時の整列と決着E2Eライフサイクルこと', () {
      final redTeam = '神奈川道場';
      final whiteTeam = '愛知武道館';

      // 1. 9人制のポジション生成
      final positions = MatchFormatSetupHelper.generatePositions(9);
      expect(positions, ['先鋒', '次鋒', '七将', '六将', '中堅', '四将', '三将', '副将', '大将']);
      expect(positions[4], equals('中堅'), reason: '5番目に中堅が位置すること');

      // 2. 9試合の生成
      final bouts = <MatchModel>[];
      for (int i = 0; i < positions.length; i++) {
        bouts.add(
          MatchModel(
            id: 'm_9_$i',
            tournamentId: 'tour_e2e_multi',
            matchType: positions[i],
            groupName: '$redTeam vs $whiteTeam',
            redName: '$redTeam: 選手$i',
            whiteName: '$whiteTeam: 選手$i',
            matchOrder: i + 1,
            order: 2000.0 + i,
            status: 'finished',
          ),
        );
      }

      // 3. 4勝4敗1分で完全同点となるスコアを設定
      // 先鋒〜六将(4名): 赤一本勝ち (1-0)
      // 中堅(1名): 引き分け (0-0)
      // 四将〜大将(4名): 白一本勝ち (0-1)
      final scoredBouts = bouts.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value;
        if (idx < 4) {
          return m.copyWith(redScore: 1, whiteScore: 0);
        } else if (idx == 4) {
          return m.copyWith(redScore: 0, whiteScore: 0);
        } else {
          return m.copyWith(redScore: 0, whiteScore: 1);
        }
      }).toList();

      int redWins = 0;
      int whiteWins = 0;
      int redPoints = 0;
      int whitePoints = 0;
      for (final m in scoredBouts) {
        redPoints += m.redScore;
        whitePoints += m.whiteScore;
        if (m.redScore > m.whiteScore) redWins++;
        if (m.whiteScore > m.redScore) whiteWins++;
      }

      expect(redWins, equals(4));
      expect(whiteWins, equals(4));
      expect(redPoints, equals(4));
      expect(whitePoints, equals(4));
      expect(
        redWins == whiteWins && redPoints == whitePoints,
        isTrue,
        reason: '完全同点により代表戦が発生する条件',
      );

      // 4. 代表戦の追加
      final daihyoMatch = MatchModel(
        id: 'm_9_daihyo',
        tournamentId: 'tour_e2e_multi',
        matchType: '代表戦',
        groupName: '$redTeam vs $whiteTeam',
        redName: '$redTeam: 代表 太郎',
        whiteName: '$whiteTeam: 代表 次郎',
        matchOrder: 10,
        order: 3000.0,
        status: 'finished',
        redScore: 1,
        whiteScore: 0,
      );

      final allBouts = [...scoredBouts, daihyoMatch];
      expect(allBouts.length, equals(10), reason: '9試合＋代表戦1試合で合計10試合');

      // 5. 意図的にシャッフルしてソート検証
      final scrambled = [
        daihyoMatch,
        scoredBouts[8], // 大将
        scoredBouts[0], // 先鋒
        scoredBouts[4], // 中堅
        scoredBouts[6], // 三将
        scoredBouts[2], // 七将
        scoredBouts[5], // 四将
        scoredBouts[1], // 次鋒
        scoredBouts[7], // 副将
        scoredBouts[3], // 六将
      ];

      final sorted = KendoPositionSorter.sortMatches(scrambled);
      final sortedTypes = sorted.map((m) => m.matchType).toList();

      expect(sortedTypes, [
        '先鋒',
        '次鋒',
        '七将',
        '六将',
        '中堅',
        '四将',
        '三将',
        '副将',
        '大将',
        '代表戦',
      ]);
      expect(sorted.last.matchType, equals('代表戦'), reason: '大将の後に代表戦が来ること');
      expect(sorted.last.redScore, equals(1), reason: '代表戦で赤が1本取得し勝利決定');
    });
  });
}
