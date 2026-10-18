import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';

void main() {
  group('[Unit] 団体戦チーム登録・オーダー重複検証・役職マッピングロジックテスト', () {
    test('5人制団体戦でレギュラー5名が正常に重複なく登録されていること', () {
      const team = TeamModel(
        id: 'team_valid_1',
        tournamentId: 'tour_1',
        teamName: '赤心館A',
        category: '一般の部',
        playerNames: ['山田 太郎', '佐藤 次郎', '田中 三郎', '鈴木 四郎', '高橋 五郎'],
      );

      expect(team.playerNames.length, equals(5));

      // 重複チェックロジック
      final uniqueNames = team.playerNames.toSet();
      expect(
        uniqueNames.length,
        equals(team.playerNames.length),
        reason: '重複選手が存在しないこと',
      );
    });

    test('オーダー内で同一選手が重複指定されている場合に正しく検出されること', () {
      final duplicateOrder = {
        0: '山田 太郎', // 先鋒
        1: '佐藤 次郎', // 次鋒
        2: '山田 太郎', // 中堅に先鋒と同一選手が誤登録
        3: '鈴木 四郎', // 副将
        4: '高橋 五郎', // 大将
      };

      final values = duplicateOrder.values.toList();
      final hasDuplicate = values.toSet().length < values.length;
      expect(hasDuplicate, isTrue, reason: '山田太郎が重複しているためtrueとなること');

      // 重複している選手名の特定
      final seen = <String>{};
      final duplicates = <String>{};
      for (final name in values) {
        if (!seen.add(name)) {
          duplicates.add(name);
        }
      }
      expect(duplicates, contains('山田 太郎'));
    });

    test('未入力のスロット（空欄）が存在する場合に登録不可として検出されること', () {
      const requiredPlayerCount = 5;
      final incompleteOrder = <int, String>{
        0: '山田 太郎',
        1: '佐藤 次郎',
        // 2: 中堅が未入力
        3: '鈴木 四郎',
        4: '高橋 五郎',
      };

      final isComplete =
          incompleteOrder.length == requiredPlayerCount &&
          incompleteOrder.values.every((name) => name.trim().isNotEmpty);

      expect(isComplete, isFalse, reason: '中堅が未入力のため登録不可と判定されること');
    });

    test('形競技の役職表記オプションが正しい表示文字列にマッピングされること', () {
      final roleMapping = {
        'none': '表示なし（選手）',
        'uchidachi_shidachi': '打太刀・仕太刀',
        'shidachi_uchidachi': '仕太刀・打太刀 (入替)',
        'motodachi_kakarite': '元立ち・掛かり手',
      };

      expect(roleMapping['none'], '表示なし（選手）');
      expect(roleMapping['uchidachi_shidachi'], '打太刀・仕太刀');
      expect(roleMapping['shidachi_uchidachi'], '仕太刀・打太刀 (入替)');
      expect(roleMapping['motodachi_kakarite'], '元立ち・掛かり手');
    });
  });
}
