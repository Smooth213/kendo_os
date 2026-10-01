import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Unit] CsvService 単体テスト', () {
    final sampleMatch1 = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      category: '小学生の部',
      groupName: '予選A',
      order: 1.0,
      redName: '道場A: 田中',
      whiteName: '道場B: 佐藤',
      redScore: 2,
      whiteScore: 0,
      matchType: '選手',
      status: 'finished',
      note: 'メ メ',
      events: [],
    );

    final sampleMatch2 = MatchModel(
      id: 'm2',
      tournamentId: 't1',
      category: '中学生の部',
      groupName: '決勝トーナメント',
      order: 1.0,
      redName: '中A: 高橋',
      whiteName: '中B: 渡辺',
      redScore: 1,
      whiteScore: 2,
      matchType: '選手',
      status: 'finished',
      note: 'コ - メ ド',
      events: [],
    );

    test('generateCsvString produces single category CSV with BOMであること', () {
      final csv = CsvService.generateCsvString('小学生の部', [
        {
          'groupName': '予選A',
          'matches': [sampleMatch1],
        },
      ]);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(
        csv.contains('カテゴリ,グループ名,試合順,赤チーム,赤選手,白チーム,白選手,赤スコア,白スコア,勝敗,備考'),
        isTrue,
      );
      expect(
        csv.contains(
          '"小学生の部","予選A","1.0","道場A","田中","道場B","佐藤","2","0","赤勝ち","メ メ"',
        ),
        isTrue,
      );
    });

    test(
      'generateMultiCategoryCsvString produces multi-category CSV in orderであること',
      () {
        final csv = CsvService.generateMultiCategoryCsvString([
          (
            categoryName: '小学生の部',
            groupDataList: [
              {
                'groupName': '予選A',
                'matches': [sampleMatch1],
              },
            ],
          ),
          (
            categoryName: '中学生の部',
            groupDataList: [
              {
                'groupName': '決勝トーナメント',
                'matches': [sampleMatch2],
              },
            ],
          ),
        ]);

        expect(csv.startsWith('\uFEFF'), isTrue);
        // ヘッダーは1行のみ
        final headerMatches = 'カテゴリ,グループ名'.allMatches(csv).length;
        expect(headerMatches, 1);

        // 小学生の部が先に出現
        final posSho = csv.indexOf('小学生の部');
        final posChu = csv.indexOf('中学生の部');
        expect(posSho < posChu, isTrue);

        expect(
          csv.contains(
            '"小学生の部","予選A","1.0","道場A","田中","道場B","佐藤","2","0","赤勝ち","メ メ"',
          ),
          isTrue,
        );
        expect(
          csv.contains(
            '"中学生の部","決勝トーナメント","1.0","中A","高橋","中B","渡辺","1","2","白勝ち","コ - メ ド"',
          ),
          isTrue,
        );
      },
    );

    test(
      'generateMultiCategoryCsvBytesAsync returns valid UTF-8 bytes with BOMであること',
      () async {
        final bytes = await CsvService.generateMultiCategoryCsvBytesAsync([
          (
            categoryName: '小学生の部',
            groupDataList: [
              {
                'groupName': '予選A',
                'matches': [sampleMatch1],
              },
            ],
          ),
        ]);

        // BOM [0xEF, 0xBB, 0xBF]
        expect(bytes.length >= 3, isTrue);
        expect(bytes[0], 0xEF);
        expect(bytes[1], 0xBB);
        expect(bytes[2], 0xBF);

        final decoded = utf8.decode(bytes);
        expect(decoded.contains('小学生の部'), isTrue);
      },
    );
  });
}
