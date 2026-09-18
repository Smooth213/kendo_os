import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/share_import/player_roster_matcher.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('PlayerRosterMatcher', () {
    final roster = [
      PlayerModel(
        id: 'p1',
        lastName: '皿田',
        firstName: '脩人',
        lastNameKana: 'さらだ',
        firstNameKana: 'しゅうと',
        grade: 3, // 小学3年
      ),
      PlayerModel(
        id: 'p2',
        lastName: '塚本',
        firstName: '大道',
        lastNameKana: 'つかもと',
        firstNameKana: 'ひろみち',
        grade: 6, // 小学6年
      ),
      PlayerModel(
        id: 'p3',
        lastName: '久安',
        firstName: '智也',
        lastNameKana: 'ひさやす',
        firstNameKana: 'ともや',
        grade: 5, // 小学5年
      ),
      PlayerModel(
        id: 'p4',
        lastName: '佐藤',
        firstName: '太郎',
        lastNameKana: 'さとう',
        firstNameKana: 'たろう',
        grade: 2, // 小学2年（低学年）
      ),
      PlayerModel(
        id: 'p5',
        lastName: '佐藤',
        firstName: '次郎',
        lastNameKana: 'さとう',
        firstNameKana: 'じろう',
        grade: 8, // 中学2年（中学生）
      ),
    ];

    test('スペース揺れがあっても完全一致する（皿田 脩人、皿田脩人、皿田　脩人）', () {
      final res1 = PlayerRosterMatcher.matchPlayer(
        rawName: '皿田脩人',
        roster: roster,
      );
      expect(res1.isMatched, isTrue);
      expect(res1.resolvedName, '皿田 脩人');
      expect(res1.gradeDisplay, '小学3年');

      final res2 = PlayerRosterMatcher.matchPlayer(
        rawName: '皿田　脩人',
        roster: roster,
      );
      expect(res2.isMatched, isTrue);
      expect(res2.resolvedName, '皿田 脩人');

      final res3 = PlayerRosterMatcher.matchPlayer(
        rawName: '  皿田   脩人  ',
        roster: roster,
      );
      expect(res3.isMatched, isTrue);
      expect(res3.resolvedName, '皿田 脩人');
    });

    test('苗字のみの場合、名簿で一意ならその選手を採用する（塚本、久安）', () {
      final res1 = PlayerRosterMatcher.matchPlayer(
        rawName: '塚本',
        roster: roster,
      );
      expect(res1.isMatched, isTrue);
      expect(res1.resolvedName, '塚本 大道');
      expect(res1.gradeDisplay, '小学6年');

      final res2 = PlayerRosterMatcher.matchPlayer(
        rawName: '久安',
        roster: roster,
      );
      expect(res2.isMatched, isTrue);
      expect(res2.resolvedName, '久安 智也');
    });

    test('同姓の選手が複数いる場合、カテゴリから学年を賢く推定する（佐藤）', () {
      // 低学年の部 → 佐藤 太郎（小2）
      final resLow = PlayerRosterMatcher.matchPlayer(
        rawName: '佐藤',
        teamCategory: '低学年の部',
        roster: roster,
      );
      expect(resLow.isMatched, isTrue);
      expect(resLow.resolvedName, '佐藤 太郎');
      expect(resLow.matchedPlayer?.id, 'p4');

      // 中学生の部 → 佐藤 次郎（中2）
      final resMiddle = PlayerRosterMatcher.matchPlayer(
        rawName: '佐藤',
        teamCategory: '中学生の部',
        roster: roster,
      );
      expect(resMiddle.isMatched, isTrue);
      expect(resMiddle.resolvedName, '佐藤 次郎');
      expect(resMiddle.matchedPlayer?.id, 'p5');
    });

    test('名簿未登録の選手は元の名前を保持し、isMatched = false になる', () {
      final res = PlayerRosterMatcher.matchPlayer(
        rawName: '外部 助っ人',
        roster: roster,
      );
      expect(res.isMatched, isFalse);
      expect(res.resolvedName, '外部 助っ人');
      expect(res.matchedPlayer, isNull);
      expect(res.badgeText, '外部 助っ人 (名簿未登録)');
    });

    test('チーム全員の照合', () {
      final members = [
        const ParsedTeamMember(position: '先鋒', name: '皿田 脩人'),
        const ParsedTeamMember(position: '中堅', name: '塚本'),
        const ParsedTeamMember(position: '大将', name: '名無し'),
      ];

      final matched = PlayerRosterMatcher.matchTeamMembers(
        members: members,
        teamCategory: '低学年',
        roster: roster,
      );

      expect(matched.length, 3);
      expect(matched[0].displayName, '皿田 脩人');
      expect(matched[0].isMatched, isTrue);

      expect(matched[1].displayName, '塚本 大道');
      expect(matched[1].isMatched, isTrue);

      expect(matched[2].displayName, '名無し');
      expect(matched[2].isMatched, isFalse);
    });

    test('buildAssignedPlayerMap: 登録済み選手（他チーム・他スロット）を正しくマッピングし、自身を除外すること', () {
      final teams = [
        const ParsedTeamOrder(
          teamName: '低学年',
          category: '小学生低学年の部',
          members: [
            ParsedTeamMember(position: '先鋒', name: '皿田 脩人'),
            ParsedTeamMember(position: '大将', name: '塚本 大道'),
          ],
        ),
        const ParsedTeamOrder(
          teamName: '中学生A',
          category: '中学生の部',
          members: [
            ParsedTeamMember(position: '先鋒', name: '恵木 春陽'), // 未登録
            ParsedTeamMember(position: '大将', name: '佐藤 次郎'),
          ],
        ),
      ];

      // 中学生Aの先鋒（恵木 春陽）を編集中
      final map = PlayerRosterMatcher.buildAssignedPlayerMap(
        allTeams: teams,
        roster: roster,
        currentEditingMember: const ParsedTeamMember(
          position: '先鋒',
          name: '恵木 春陽',
        ),
        currentTeamName: '中学生A',
      );

      // p1 (皿田 脩人) は 低学年・先鋒 に登録済
      expect(map['p1'], '低学年・先鋒');
      expect(map[PlayerRosterMatcher.normalize('皿田 脩人')], '低学年・先鋒');

      // p2 (塚本 大道) は 低学年・大将 に登録済
      expect(map['p2'], '低学年・大将');

      // p5 (佐藤 次郎) は 中学生A・大将 に登録済
      expect(map['p5'], '中学生A・大将');

      // 未登録の恵木 春陽 や 未配置の久安 智也(p3)・佐藤 太郎(p4) はマップに含まれない
      expect(map['p3'], isNull);
      expect(map['p4'], isNull);

      // 編集中の自分自身（低学年・先鋒の皿田 脩人）を編集中とした場合、p1は除外されること
      final mapSelf = PlayerRosterMatcher.buildAssignedPlayerMap(
        allTeams: teams,
        roster: roster,
        currentEditingMember: const ParsedTeamMember(
          position: '先鋒',
          name: '皿田 脩人',
        ),
        currentTeamName: '低学年',
      );
      expect(mapSelf['p1'], isNull);
      expect(mapSelf['p2'], '低学年・大将');
    });

    test('matchesCategory: 各カテゴリに対して学年・性別が正しく判定されること', () {
      final pLow = PlayerModel(
        id: '1',
        lastName: '低学年',
        firstName: '太郎',
        lastNameKana: 'ていがくねん',
        firstNameKana: 'たろう',
        grade: 3,
      );
      final pHigh = PlayerModel(
        id: '2',
        lastName: '高学年',
        firstName: '次郎',
        lastNameKana: 'こうがくねん',
        firstNameKana: 'じろう',
        grade: 6,
      );
      final pJunior = PlayerModel(
        id: '3',
        lastName: '中学',
        firstName: '三郎',
        lastNameKana: 'ちゅうがく',
        firstNameKana: 'さぶろう',
        grade: 8,
      );

      expect(PlayerRosterMatcher.matchesCategory(pLow, '小学生低学年の部'), isTrue);
      expect(PlayerRosterMatcher.matchesCategory(pLow, '中学生の部'), isFalse);

      expect(PlayerRosterMatcher.matchesCategory(pHigh, '小学生高学年の部'), isTrue);
      expect(PlayerRosterMatcher.matchesCategory(pHigh, '小学生低学年の部'), isFalse);

      expect(PlayerRosterMatcher.matchesCategory(pJunior, '中学生の部'), isTrue);
      expect(PlayerRosterMatcher.matchesCategory(pJunior, '小学生の部'), isFalse);
    });

    test('sortRosterForCategory: カテゴリ対応選手および未登録選手が優先して上位にソートされること', () {
      final p1 = PlayerModel(
        id: 'p1',
        lastName: '低学年',
        firstName: '未登録',
        lastNameKana: 'あ',
        firstNameKana: 'あ',
        grade: 2, // 低学年
      );
      final p2 = PlayerModel(
        id: 'p2',
        lastName: '低学年',
        firstName: '登録済',
        lastNameKana: 'い',
        firstNameKana: 'い',
        grade: 2, // 低学年 (登録済)
      );
      final p3 = PlayerModel(
        id: 'p3',
        lastName: '中学生',
        firstName: '未登録',
        lastNameKana: 'う',
        firstNameKana: 'う',
        grade: 8, // 中学生
      );

      final assignedMap = {'p2': '他チーム・先鋒'};

      // 「小学生低学年の部」でソート
      final sorted = PlayerRosterMatcher.sortRosterForCategory(
        roster: [p3, p2, p1],
        category: '小学生低学年の部',
        assignedPlayerMap: assignedMap,
      );

      // 1番目: 低学年かつ未登録 (p1)
      expect(sorted[0].id, 'p1');
      // 2番目: 低学年かつ登録済 (p2)
      expect(sorted[1].id, 'p2');
      // 3番目: 中学生（他部門） (p3)
      expect(sorted[2].id, 'p3');
    });
  });
}
