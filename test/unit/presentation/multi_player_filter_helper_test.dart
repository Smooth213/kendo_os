import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/widgets/multi_player_filter_helper.dart';

void main() {
  group('MultiPlayerFilterHelper テスト', () {
    final pBeginner = PlayerModel(
      id: 'p1',
      lastName: '山田',
      firstName: '太郎',
      lastNameKana: 'ヤマダ',
      firstNameKana: 'タロウ',
      grade: 2,
      isBeginner: true,
    );
    final pYoune = PlayerModel(
      id: 'p2',
      lastName: '鈴木',
      firstName: '次郎',
      lastNameKana: 'スズキ',
      firstNameKana: 'ジロウ',
      grade: 0,
    );
    final pTei = PlayerModel(
      id: 'p3',
      lastName: '佐藤',
      firstName: '花子',
      lastNameKana: 'サトウ',
      firstNameKana: 'ハナコ',
      grade: 3,
    );
    final pKou = PlayerModel(
      id: 'p4',
      lastName: '田中',
      firstName: '三郎',
      lastNameKana: 'タナカ',
      firstNameKana: 'サブロウ',
      grade: 6,
    );
    final pChu = PlayerModel(
      id: 'p5',
      lastName: '高橋',
      firstName: '四郎',
      lastNameKana: 'タカハシ',
      firstNameKana: 'シロウ',
      grade: 8,
    );
    final pKoukou = PlayerModel(
      id: 'p6',
      lastName: '伊藤',
      firstName: '五郎',
      lastNameKana: 'イトウ',
      firstNameKana: 'ゴロウ',
      grade: 11,
    );
    final pIppan = PlayerModel(
      id: 'p7',
      lastName: '渡辺',
      firstName: '六郎',
      lastNameKana: 'ワタナベ',
      firstNameKana: 'ロクロウ',
      grade: 14,
    );

    final allMaster = [pBeginner, pYoune, pTei, pKou, pChu, pKoukou, pIppan];

    test('フィルター「すべて」で全件取得できること', () {
      final res = MultiPlayerFilterHelper.filterAndSortMaster(
        masterPlayers: allMaster,
        searchText: '',
        selectedFilter: 'すべて',
        isAscending: true,
      );
      expect(res.length, 7);
    });

    test('フィルター「初心者」で初心者のみ絞り込めること', () {
      final res = MultiPlayerFilterHelper.filterAndSortMaster(
        masterPlayers: allMaster,
        searchText: '',
        selectedFilter: '初心者',
        isAscending: true,
      );
      expect(res.length, 1);
      expect(res.first.name, '山田 太郎');
    });

    test('フィルター「低学年」で1〜4年生のみ絞り込めること', () {
      final res = MultiPlayerFilterHelper.filterAndSortMaster(
        masterPlayers: allMaster,
        searchText: '',
        selectedFilter: '低学年',
        isAscending: true,
      );
      expect(res.length, 1);
      expect(res.first.name, '佐藤 花子');
    });

    test('検索テキストで名前部分一致絞り込みができること', () {
      final res = MultiPlayerFilterHelper.filterAndSortMaster(
        masterPlayers: allMaster,
        searchText: '花子',
        selectedFilter: 'すべて',
        isAscending: true,
      );
      expect(res.length, 1);
      expect(res.first.name, '佐藤 花子');
    });

    test('isAscending: false で学年降順ソートされること', () {
      final res = MultiPlayerFilterHelper.filterAndSortMaster(
        masterPlayers: allMaster,
        searchText: '',
        selectedFilter: 'すべて',
        isAscending: false,
      );
      expect(res.first.name, '渡辺 六郎'); // grade 14
    });

    test('filterGuests でゲスト選手が検索絞り込みされること', () {
      final guests = ['ゲストA', 'ゲストB', '武道太郎'];
      final res = MultiPlayerFilterHelper.filterGuests(
        guestPlayers: guests,
        searchText: 'ゲスト',
        selectedFilter: 'すべて',
      );
      expect(res, ['ゲストA', 'ゲストB']);

      // ゲスト以外のフィルター選択時は空
      final resFilter = MultiPlayerFilterHelper.filterGuests(
        guestPlayers: guests,
        searchText: '',
        selectedFilter: '低学年',
      );
      expect(resFilter, isEmpty);
    });

    test('isNewName で新規名前か判定できること', () {
      expect(
        MultiPlayerFilterHelper.isNewName(
          searchText: '未知の剣士',
          masterPlayers: allMaster,
          guestPlayers: ['ゲストA'],
        ),
        isTrue,
      );

      expect(
        MultiPlayerFilterHelper.isNewName(
          searchText: '山田 太郎',
          masterPlayers: allMaster,
          guestPlayers: ['ゲストA'],
        ),
        isFalse,
      );

      expect(
        MultiPlayerFilterHelper.isNewName(
          searchText: '  ',
          masterPlayers: allMaster,
          guestPlayers: ['ゲストA'],
        ),
        isFalse,
      );
    });
  });
}
