import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_group_helper.dart';

void main() {
  group('OfficialRecordGroupHelper Tests', () {
    test('groupMatchesByCategory correctly groups matches', () {
      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          redName: 'A',
          whiteName: 'B',
          matchType: '団体戦',
          groupName: '1回戦',
          category: '小学生の部',
        ),
        MatchModel(
          id: 'm2',
          tournamentId: 't1',
          redName: 'C',
          whiteName: 'D',
          matchType: '団体戦',
          groupName: '1回戦',
          category: '小学生の部',
        ),
      ];

      final grouped = OfficialRecordGroupHelper.groupMatchesByCategory(matches);
      expect(grouped.containsKey('小学生の部'), isTrue);
      expect(grouped['小学生の部']!['1回戦']!.length, 2);
    });

    test(
      'mergeIndividualGroups: 「第1試合場, 17試合目」など独立した個人戦グループが単一の __merged_individual__ に統合されること',
      () {
        final groupsMap = {
          '第1試合場, 17試合目': [
            const MatchModel(
              id: 'm1',
              tournamentId: 't1',
              redName: '道上剣友会: 橋本 璃久',
              whiteName: '湯田剣道教室: 村上 颯',
              matchType: '個人戦',
              groupName: '第1試合場, 17試合目',
              category: '中学生の部',
              order: 17,
            ),
          ],
          '第1試合場, 33試合目': [
            const MatchModel(
              id: 'm2',
              tournamentId: 't1',
              redName: '小畠剣道教室: 小林 奨',
              whiteName: '道上剣友会: 皿田 唯人',
              matchType: '個人戦',
              groupName: '第1試合場, 33試合目',
              category: '中学生の部',
              order: 33,
            ),
          ],
          '第1試合場, 34試合目': [
            const MatchModel(
              id: 'm3',
              tournamentId: 't1',
              redName: '道上剣友会: 橋本 璃久',
              whiteName: '小畠剣道教室: 田村 聰典',
              matchType: '個人戦',
              groupName: '第1試合場, 34試合目',
              category: '中学生の部',
              order: 34,
            ),
          ],
        };

        final merged = OfficialRecordGroupHelper.mergeIndividualGroups(
          groupsMap,
        );

        // 個別の3グループではなく、単一の __merged_individual__ に統合されていること！
        expect(merged.length, 1);
        expect(merged.containsKey('__merged_individual__'), isTrue);
        expect(merged['__merged_individual__']!.length, 3);
        expect(merged.containsKey('第1試合場, 17試合目'), isFalse);
        expect(merged.containsKey('第1試合場, 33試合目'), isFalse);
        expect(merged.containsKey('第1試合場, 34試合目'), isFalse);

        // 試合順に並んでいること
        expect(merged['__merged_individual__']![0].id, 'm1');
        expect(merged['__merged_individual__']![1].id, 'm2');
        expect(merged['__merged_individual__']![2].id, 'm3');
      },
    );

    test('mergeIndividualGroups: 団体戦グループやリーグ戦はマージされずに独立グループとして維持されること', () {
      final groupsMap = {
        '決勝トーナメント1回戦': [
          const MatchModel(
            id: 'team_m1',
            tournamentId: 't1',
            redName: '小畠剣道教室',
            whiteName: '道上剣友会',
            matchType: '先鋒',
            groupName: '決勝トーナメント1回戦',
          ),
        ],
        '予選Aリーグ': [
          const MatchModel(
            id: 'league_m1',
            tournamentId: 't1',
            redName: '小畠: 山田',
            whiteName: '道上: 佐藤',
            matchType: '個人戦',
            groupName: '予選Aリーグ',
            note: '[リーグ戦]',
          ),
        ],
      };

      final merged = OfficialRecordGroupHelper.mergeIndividualGroups(groupsMap);
      expect(merged.containsKey('決勝トーナメント1回戦'), isTrue);
      expect(merged.containsKey('予選Aリーグ'), isTrue);
      expect(merged.containsKey('__merged_individual__'), isFalse);
    });
  });
}
