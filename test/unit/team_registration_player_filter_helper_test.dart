import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_player_filter_helper.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('[Unit] チーム登録選手フィルタリングおよび50音順ソートエンジン単体テスト', () {
    test('isSameCategoryにおいて大カテゴリおよび小カテゴリの学年判定が正確に行われること', () {
      final pBeginner = PlayerModel(
        id: 'p-1',
        lastName: '初心者',
        firstName: 'A',
        lastNameKana: 'しょしんしゃ',
        firstNameKana: 'えー',
        organization: '道場',
        isBeginner: true,
        grade: 1,
      );
      final pInfant = PlayerModel(
        id: 'p-2',
        lastName: '幼年',
        firstName: 'B',
        lastNameKana: 'ようねん',
        firstNameKana: 'びー',
        organization: '道場',
        grade: 0,
      );
      final pLowerElem = PlayerModel(
        id: 'p-3',
        lastName: '低学年',
        firstName: 'C',
        lastNameKana: 'ていがくねん',
        firstNameKana: 'しー',
        organization: '道場',
        grade: 3,
      );
      final pHigherElem = PlayerModel(
        id: 'p-4',
        lastName: '高学年',
        firstName: 'D',
        lastNameKana: 'こうがくねん',
        firstNameKana: 'でぃー',
        organization: '道場',
        grade: 6,
      );
      final pJuniorHigh = PlayerModel(
        id: 'p-5',
        lastName: '中学生',
        firstName: 'E',
        lastNameKana: 'ちゅうがくせい',
        firstNameKana: 'いー',
        organization: '道場',
        grade: 8,
      );
      final pHighSchool = PlayerModel(
        id: 'p-6',
        lastName: '高校生',
        firstName: 'F',
        lastNameKana: 'こうこうせい',
        firstNameKana: 'えふ',
        organization: '道場',
        grade: 11,
      );
      final pAdult = PlayerModel(
        id: 'p-7',
        lastName: '一般',
        firstName: 'G',
        lastNameKana: 'いっぱん',
        firstNameKana: 'じー',
        organization: '道場',
        grade: 14,
      );

      expect(
        TeamRegistrationPlayerFilterHelper.isSameCategory(
          player: pBeginner,
          majorCategory: '初心者',
          minorCategory: '',
        ),
        isTrue,
      );

      expect(
        TeamRegistrationPlayerFilterHelper.isSameCategory(
          player: pInfant,
          majorCategory: '幼年',
          minorCategory: '',
        ),
        isTrue,
      );

      expect(
        TeamRegistrationPlayerFilterHelper.isSameCategory(
          player: pLowerElem,
          majorCategory: '小学生',
          minorCategory: '低学年',
        ),
        isTrue,
      );

      expect(
        TeamRegistrationPlayerFilterHelper.isSameCategory(
          player: pHigherElem,
          majorCategory: '小学生',
          minorCategory: '高学年',
        ),
        isTrue,
      );

      expect(
        TeamRegistrationPlayerFilterHelper.isSameCategory(
          player: pJuniorHigh,
          majorCategory: '中学生',
          minorCategory: '',
        ),
        isTrue,
      );

      expect(
        TeamRegistrationPlayerFilterHelper.isSameCategory(
          player: pHighSchool,
          majorCategory: '高校生',
          minorCategory: '',
        ),
        isTrue,
      );

      expect(
        TeamRegistrationPlayerFilterHelper.isSameCategory(
          player: pAdult,
          majorCategory: '大学・一般',
          minorCategory: '',
        ),
        isTrue,
      );
    });

    test('getRecommendedPlayersにおいて同カテゴリ選手が抽出されふりがな順にソートされること', () {
      final players = [
        PlayerModel(
          id: '1',
          lastName: '渡辺',
          firstName: '',
          lastNameKana: 'わたなべ',
          firstNameKana: '',
          organization: '道場',
          grade: 2,
        ),
        PlayerModel(
          id: '2',
          lastName: '青木',
          firstName: '',
          lastNameKana: 'あおき',
          firstNameKana: '',
          organization: '道場',
          grade: 1,
        ),
        PlayerModel(
          id: '3',
          lastName: '佐藤',
          firstName: '',
          lastNameKana: 'さとう',
          firstNameKana: '',
          organization: '道場',
          grade: 3,
        ),
        PlayerModel(
          id: '4',
          lastName: '高校生',
          firstName: '',
          lastNameKana: 'こうこうせい',
          firstNameKana: '',
          organization: '道場',
          grade: 10,
        ),
      ];

      final result = TeamRegistrationPlayerFilterHelper.getRecommendedPlayers(
        players: players,
        majorCategory: '小学生',
        minorCategory: '低学年',
        query: '',
      );

      // 高校生は除外され、あいうえお順（青木 -> 佐藤 -> 渡辺）になること
      expect(result.length, 3);
      expect(result[0].name, '青木');
      expect(result[1].name, '佐藤');
      expect(result[2].name, '渡辺');
    });

    test('matchesQueryにおいて漢字氏名およびふりがなで部分一致検索が行われること', () {
      final p = PlayerModel(
        id: '1',
        lastName: '山田',
        firstName: '太郎',
        lastNameKana: 'やまだ',
        firstNameKana: 'たろう',
        organization: '道場',
        grade: 1,
      );

      expect(
        TeamRegistrationPlayerFilterHelper.matchesQuery(player: p, query: ''),
        isTrue,
      );
      expect(
        TeamRegistrationPlayerFilterHelper.matchesQuery(player: p, query: '山田'),
        isTrue,
      );
      expect(
        TeamRegistrationPlayerFilterHelper.matchesQuery(
          player: p,
          query: 'やまだ',
        ),
        isTrue,
      );
      expect(
        TeamRegistrationPlayerFilterHelper.matchesQuery(
          player: p,
          query: 'たろう',
        ),
        isTrue,
      );
      expect(
        TeamRegistrationPlayerFilterHelper.matchesQuery(player: p, query: '鈴木'),
        isFalse,
      );
    });
  });
}
