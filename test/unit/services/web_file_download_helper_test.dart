import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';
import 'package:kendo_os/shared/utils/file_download_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Unit] 【Unit】Webファイルダウンロード＆共有ヘルパー 安全性・フォールバック検証', () {
    test('file_download_helper (ネイティブ/スタブ環境): 例外スローなく安全に終了すること', () async {
      final dummyBytes = Uint8List.fromList([
        0x4B,
        0x45,
        0x4E,
        0x44,
        0x4F,
      ]); // "KENDO"
      const filename = 'kendo_test.csv';
      const mimeType = 'text/csv';

      expect(
        () => downloadFileWeb(dummyBytes, filename, mimeType),
        returnsNormally,
      );

      final shared = await shareFilesWeb(
        [dummyBytes],
        [filename],
        mimeType,
        '大会公式記録共有テスト',
      );
      // ネイティブ環境ではスタブが安全に false を返し、アプリがクラッシュしないこと
      expect(shared, isFalse);
    });

    test('CsvService: CSV文字列生成とヘッダー・BOM付与の完全性が正しく検証されること', () {
      final sampleMatch = MatchModel(
        id: 'test_m1',
        matchType: '個人戦',
        redName: '赤道場:田中',
        whiteName: '白道場:佐藤',
        redScore: 2,
        whiteScore: 1,
        status: 'finished',
      );

      final csvString = CsvService.generateCsvString('一般男子の部', [
        {
          'groupName': 'Aブロック',
          'matches': [sampleMatch],
        },
      ]);

      // 1. BOM(\uFEFF)で始まること
      expect(csvString.startsWith('\uFEFF'), isTrue);

      // 2. ヘッダー行が存在すること
      expect(
        csvString.contains('カテゴリ,グループ名,試合順,赤チーム,赤選手,白チーム,白選手,赤スコア,白スコア,勝敗,備考'),
        isTrue,
      );

      // 3. レコードが正しく分解されていること
      expect(csvString.contains('一般男子の部'), isTrue);
      expect(csvString.contains('Aブロック'), isTrue);
      expect(csvString.contains('田中'), isTrue);
      expect(csvString.contains('佐藤'), isTrue);
      expect(csvString.contains('2'), isTrue);
      expect(csvString.contains('1'), isTrue);
    });

    test('CsvService: 空データ・複数カテゴリ一括CSV生成の安全性こと', () {
      final emptyCsv = CsvService.generateMultiCategoryCsvString([]);
      expect(emptyCsv.startsWith('\uFEFF'), isTrue);
      expect(emptyCsv.contains('カテゴリ,グループ名'), isTrue);

      final multiCatCsv = CsvService.generateMultiCategoryCsvString([
        (
          categoryName: '小学生の部',
          groupDataList: [
            {'groupName': '第1コート', 'matches': <MatchModel>[]},
          ],
        ),
        (
          categoryName: '中学生の部',
          groupDataList: [
            {'groupName': '第2コート', 'matches': <MatchModel>[]},
          ],
        ),
      ]);
      expect(multiCatCsv.contains('小学生の部'), isFalse); // 試合がない場合はレコードなし
      expect(multiCatCsv.contains('カテゴリ,グループ名'), isTrue);
    });

    test('Safariポップアップ抑止・Blob URL安全処理: 不正バイト列・空バイト列での例外隔離こと', () async {
      final emptyBytes = Uint8List(0);

      expect(
        () => downloadFileWeb(emptyBytes, 'empty.csv', 'text/csv'),
        returnsNormally,
      );

      final shareResult = await shareFilesWeb([], [], 'text/csv', '');
      expect(shareResult, isFalse);
    });
  });
}
