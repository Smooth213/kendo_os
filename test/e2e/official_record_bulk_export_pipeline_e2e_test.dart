import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';

void main() {
  group('[E2E] 公式記録全カテゴリ一括出力パイプラインE2Eテスト', () {
    test('個人戦および団体戦混在の全カテゴリ公式記録が一括CSVおよびバイト列として整合出力されること', () async {
      final categories = ['幼年の部', '小学生の部', '中学生男子の部', '中学生女子の部', '一般団体の部'];

      final bulkCategoryData = categories.map((cat) {
        final isTeam = cat.contains('団体');
        final matches = List.generate(5, (index) {
          return MatchModel(
            id: 'bulk_m_${cat}_$index',
            tournamentId: 't_bulk_export',
            category: cat,
            matchType: isTeam ? '団体戦' : '個人戦',
            order: (index + 1).toDouble(),
            redName: '選手A_$index',
            whiteName: '選手B_$index',
            redScore: (index % 2 == 0) ? 2 : 1,
            whiteScore: (index % 2 == 0) ? 0 : 2,
            status: 'finished',
          );
        });

        return (
          categoryName: cat,
          groupDataList: [
            {'groupName': '本戦トーナメント', 'matches': matches},
          ],
        );
      }).toList();

      expect(bulkCategoryData.length, 5);

      // 全カテゴリ一括CSV生成パイプライン
      final csvContent = CsvService.generateMultiCategoryCsvString(
        bulkCategoryData,
      );

      // 1. Excel文字化け防止BOM（\uFEFF）が含まれていること
      expect(csvContent.startsWith('\uFEFF'), isTrue);

      // 2. 全5カテゴリ名がセクションヘッダーとして含まれていること
      for (final cat in categories) {
        expect(csvContent.contains(cat), isTrue);
      }

      // 3. UTF-8バイト列への変換と可逆デコードが成功すること
      final bytes = utf8.encode(csvContent);
      expect(bytes.isNotEmpty, isTrue);

      final decoded = utf8.decode(bytes);
      expect(decoded.contains(categories.first), isTrue);
      expect(decoded.contains(categories.last), isTrue);
    });
  });
}
