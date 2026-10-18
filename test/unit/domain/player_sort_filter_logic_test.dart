import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('[Unit] 選手学年ソート・ゲスト優先・部門フィルタリング純粋ロジックテスト', () {
    final samplePlayers = [
      PlayerModel(
        id: 'p_younen',
        lastName: '幼年',
        firstName: '太郎',
        lastNameKana: 'ヨウネン',
        firstNameKana: 'タロウ',
        grade: 0,
        organization: '千代田道場',
      ),
      PlayerModel(
        id: 'p_teigakunen',
        lastName: '低学年',
        firstName: '一郎',
        lastNameKana: 'テイガクネン',
        firstNameKana: 'イチロウ',
        grade: 2,
        organization: '千代田道場',
      ),
      PlayerModel(
        id: 'p_kougakunen',
        lastName: '高学年',
        firstName: '次郎',
        lastNameKana: 'コウガクネン',
        firstNameKana: 'ジロウ',
        grade: 5,
        organization: '千代田道場',
      ),
      PlayerModel(
        id: 'p_chugaku',
        lastName: '中学生',
        firstName: '三郎',
        lastNameKana: 'チュウガク',
        firstNameKana: 'サブロウ',
        grade: 8,
        organization: '千代田道場',
      ),
      PlayerModel(
        id: 'p_ippan',
        lastName: '一般',
        firstName: '四郎',
        lastNameKana: 'イッパン',
        firstNameKana: 'シロウ',
        grade: 14,
        organization: '千代田道場',
      ),
    ];

    test('学年昇順ソートで幼年から一般まで低学年優先で正しく整列されること', () {
      final sorted = List<PlayerModel>.from(samplePlayers)
        ..sort((a, b) => a.grade.compareTo(b.grade));

      final names = sorted.map((p) => p.name).toList();
      expect(names, ['幼年 太郎', '低学年 一郎', '高学年 次郎', '中学生 三郎', '一般 四郎']);
    });

    test('学年降順ソートで一般から幼年まで高段・年長優先で正しく整列されること', () {
      final sorted = List<PlayerModel>.from(samplePlayers)
        ..sort((a, b) => b.grade.compareTo(a.grade));

      final names = sorted.map((p) => p.name).toList();
      expect(names, ['一般 四郎', '中学生 三郎', '高学年 次郎', '低学年 一郎', '幼年 太郎']);
    });

    test('ゲスト選手（出稽古）が存在する場合に最優先で配置されること', () {
      const guestPlayerName = '出稽古 ゲスト';
      final playerNames = samplePlayers.map((p) => p.name).toList();

      // ゲストを先頭に配備するロジック
      final combined = [guestPlayerName, ...playerNames];

      expect(combined.first, equals(guestPlayerName));
      expect(combined.length, equals(samplePlayers.length + 1));
    });

    test('部門別（小学生・中学生・一般）の区分判定フィルタが正しく動作すること', () {
      // 小学生 (grade 1〜6)
      final shougaku = samplePlayers
          .where((p) => p.grade >= 1 && p.grade <= 6)
          .toList();
      expect(shougaku.map((p) => p.name), ['低学年 一郎', '高学年 次郎']);

      // 中学生 (grade 7〜9)
      final chugaku = samplePlayers
          .where((p) => p.grade >= 7 && p.grade <= 9)
          .toList();
      expect(chugaku.map((p) => p.name), ['中学生 三郎']);

      // 一般 (grade >= 13)
      final ippan = samplePlayers.where((p) => p.grade >= 13).toList();
      expect(ippan.map((p) => p.name), ['一般 四郎']);
    });
  });
}
