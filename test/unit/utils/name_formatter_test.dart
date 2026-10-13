import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/name_formatter.dart';

void main() {
  group('[Unit] NameFormatter テスト', () {
    test('parseにおいて 姓と名が正しく抽出されること', () {
      final res1 = NameFormatter.parse('佐藤 太郎');
      expect(res1['last'], '佐藤');
      expect(res1['first'], '太郎');

      final res2 = NameFormatter.parse('A道場 : 鈴木 一郎');
      expect(res2['last'], '鈴木');
      expect(res2['first'], '一郎');

      final res3 = NameFormatter.parse('(欠員)');
      expect(res3['last'], '');
      expect(res3['first'], '');

      // 形競技のペア選手
      final resPair1 = NameFormatter.parse('道上剣友会:皿田 脩人・塚本 大道');
      expect(resPair1['last'], '皿田・塚本');

      final resPair2 = NameFormatter.parse('対戦相手:選手・選手');
      expect(resPair2['last'], '選手・選手');

      final resPair3 = NameFormatter.parse('打太刀 皿田・仕太刀 塚本');
      expect(resPair3['last'], '皿田・塚本');
    });

    test('parseKataPair で同姓選手がいる場合に名前の頭文字（イニシャル）が抽出されること', () {
      // チーム内に同姓（別の「皿田 健太」）がいる場合
      final teamPlayers = ['道上剣友会:皿田 健太', '道上剣友会:佐藤 一郎'];
      final pair = NameFormatter.parseKataPair(
        '道上剣友会:皿田 脩人・塚本 大道',
        teamPlayerNames: teamPlayers,
      );

      expect(pair.length, 2);
      expect(pair[0].lastName, '皿田');
      expect(pair[0].initial, '脩'); // 同姓がいるため頭文字
      expect(pair[1].lastName, '塚本');
      expect(pair[1].initial, ''); // 同姓がいないため空文字

      // ペア内に同姓（佐藤 太郎・佐藤 次郎）がいる場合
      final sameLastPair = NameFormatter.parseKataPair('佐藤 太郎・佐藤 次郎');
      expect(sameLastPair.length, 2);
      expect(sameLastPair[0].lastName, '佐藤');
      expect(sameLastPair[0].initial, '太');
      expect(sameLastPair[1].lastName, '佐藤');
      expect(sameLastPair[1].initial, '次');
    });

    test('formatScoreboardTitleがUUIDおよび生グループIDを正しく除去すること', () {
      // UUID単体ケース
      expect(
        NameFormatter.formatScoreboardTitle(
          'group_64641bf4-b565-4218-bd25-f8a123456789',
        ),
        '団体戦スコアボード',
      );
      expect(
        NameFormatter.formatScoreboardTitle(
          '64641bf4-b565-4218-bd25-f8a123456789',
        ),
        '団体戦スコアボード',
      );

      // ハイフン以降にIDが付いているケース
      expect(
        NameFormatter.formatScoreboardTitle(
          '練習試合 - 5a6a33e1-db5a-4b61-bd25-f8a123456789',
        ),
        '練習試合',
      );
      expect(
        NameFormatter.formatScoreboardTitle(
          '男子団体戦 - group_64641bf4-b565-4218-bd25-f8a123456789',
        ),
        '男子団体戦',
      );

      // 日本語の正常なグループ名
      expect(NameFormatter.formatScoreboardTitle('小学生の部_リーグ戦'), '小学生の部_リーグ戦');
      expect(NameFormatter.formatScoreboardTitle('決勝トーナメント'), '決勝トーナメント');

      // 空白・nullケース
      expect(NameFormatter.formatScoreboardTitle(null), '団体戦スコアボード');
      expect(NameFormatter.formatScoreboardTitle('   '), '団体戦スコアボード');
    });
  });
}
