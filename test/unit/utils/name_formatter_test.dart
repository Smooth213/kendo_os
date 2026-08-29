import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/name_formatter.dart';

void main() {
  group('🛡️ NameFormatter Tests', () {
    test('1. parse extracts last and first names correctly', () {
      final res1 = NameFormatter.parse('佐藤 太郎');
      expect(res1['last'], '佐藤');
      expect(res1['first'], '太郎');

      final res2 = NameFormatter.parse('A道場 : 鈴木 一郎');
      expect(res2['last'], '鈴木');
      expect(res2['first'], '一郎');

      final res3 = NameFormatter.parse('(欠員)');
      expect(res3['last'], '');
      expect(res3['first'], '');
    });

    test(
      '2. formatScoreboardTitle removes UUIDs and raw group IDs correctly',
      () {
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
      },
    );
  });
}
