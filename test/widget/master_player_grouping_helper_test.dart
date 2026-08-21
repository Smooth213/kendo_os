import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_player_grouping_helper.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('MasterPlayerGroupingHelper Tests', () {
    test('getCategoryName returns correct category for each grade', () {
      expect(MasterPlayerGroupingHelper.getCategoryName(-1), '初心者の部');
      expect(MasterPlayerGroupingHelper.getCategoryName(0), '幼年の部');
      expect(MasterPlayerGroupingHelper.getCategoryName(3), '小学生低学年の部');
      expect(MasterPlayerGroupingHelper.getCategoryName(6), '小学生高学年の部');
      expect(MasterPlayerGroupingHelper.getCategoryName(8), '中学生の部');
      expect(MasterPlayerGroupingHelper.getCategoryName(11), '高校生の部');
      expect(MasterPlayerGroupingHelper.getCategoryName(13), '一般の部');
    });

    test('groupPlayers groups by gradeName when mode is 0', () {
      final players = [
        PlayerModel(
          id: 'p1',
          lastName: '山田',
          firstName: '太郎',
          lastNameKana: 'やまだ',
          firstNameKana: 'たろう',
          grade: 3,
        ),
        PlayerModel(
          id: 'p2',
          lastName: '佐藤',
          firstName: '次郎',
          lastNameKana: 'さとう',
          firstNameKana: 'じろう',
          grade: 3,
        ),
        PlayerModel(
          id: 'p3',
          lastName: '鈴木',
          firstName: '三郎',
          lastNameKana: 'すずき',
          firstNameKana: 'さぶろう',
          grade: 5,
        ),
      ];

      final grouped = MasterPlayerGroupingHelper.groupPlayers(
        players: players,
        groupingMode: 0,
      );

      expect(grouped['小学3年']!.length, 2);
      expect(grouped['小学5年']!.length, 1);
    });

    test('groupPlayers groups by category when mode is 1', () {
      final players = [
        PlayerModel(
          id: 'p1',
          lastName: '山田',
          firstName: '太郎',
          lastNameKana: 'やまだ',
          firstNameKana: 'たろう',
          grade: 1,
        ),
        PlayerModel(
          id: 'p2',
          lastName: '佐藤',
          firstName: '次郎',
          lastNameKana: 'さとう',
          firstNameKana: 'じろう',
          grade: 3,
        ),
        PlayerModel(
          id: 'p3',
          lastName: '鈴木',
          firstName: '三郎',
          lastNameKana: 'すずき',
          firstNameKana: 'さぶろう',
          grade: 5,
        ),
      ];

      final grouped = MasterPlayerGroupingHelper.groupPlayers(
        players: players,
        groupingMode: 1,
      );

      expect(grouped['小学生低学年の部']!.length, 2);
      expect(grouped['小学生高学年の部']!.length, 1);
    });
  });
}
