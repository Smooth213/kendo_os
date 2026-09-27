import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';

void main() {
  group('🥋 【Unit】CsvService 堅牢性・文字コード・RFC 4180適合テスト', () {
    test('1. UTF-8 BOM(\\uFEFF)が先頭に付与され、Excelでの文字化けが完全に防止されること', () {
      final csv = CsvService.generateCsvString('一般男子の部', []);
      expect(csv.startsWith('\uFEFF'), isTrue);

      final bytes = utf8.encode(csv);
      // UTF-8 BOM の 3バイト: 0xEF, 0xBB, 0xBF
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);
    });

    test('2. 外字（異体字・サロゲートペア文字: 髙、﨑、𠮷、德など）が破損せず正確に出力されること', () {
      final matches = [
        MatchModel(
          id: 'm_surrogate',
          tournamentId: 't1',
          matchType: '個人戦',
          order: 1,
          redName: '神武館: 𠮷田 德三郎',
          whiteName: '修道館: 髙橋 山﨑',
          redScore: 2,
          whiteScore: 0,
          note: '延長戦なし 𠮷野家旗',
        ),
      ];

      final groupDataList = [
        {'groupName': '決勝トーナメント', 'matches': matches},
      ];

      final csv = CsvService.generateCsvString('三段以下の部', groupDataList);

      // 外字が完全保持されていること
      expect(csv.contains('𠮷田'), isTrue);
      expect(csv.contains('髙橋'), isTrue);
      expect(csv.contains('𠮷野家旗'), isTrue);

      // バイト変換しても正常にデコードできること（Dartのutf8.decodeは先頭BOMをストリップするためBOM除去後と比較）
      final encodedBytes = utf8.encode(csv);
      final decoded = utf8.decode(encodedBytes);
      expect(decoded, equals(csv.substring(1)));
    });

    test('3. 改行やカンマを含む備考欄が改行置換＆ダブルクォーテーションで安全にエスケープされること', () {
      final matches = [
        MatchModel(
          id: 'm_escape',
          tournamentId: 't1',
          matchType: '個人戦',
          order: 1,
          redName: '選手A',
          whiteName: '選手B',
          redScore: 1,
          whiteScore: 1,
          note: '注意: 行動制限あり,\n審判合議あり, 警告2回',
        ),
      ];

      final groupDataList = [
        {'groupName': '第1コート', 'matches': matches},
      ];

      final csv = CsvService.generateCsvString('一般の部', groupDataList);

      // 改行がスペースに置換されていること
      expect(csv.contains('\n審判合議あり'), isFalse);
      expect(csv.contains('注意: 行動制限あり, 審判合議あり, 警告2回'), isTrue);

      // 各列がダブルクォートで囲まれていること
      final lines = csv.trim().split('\n');
      expect(lines.length, 2); // ヘッダー + データ1行
      final dataRow = lines[1];
      expect(dataRow.startsWith('"一般の部"'), isTrue);
      expect(dataRow.endsWith('"注意: 行動制限あり, 審判合議あり, 警告2回"'), isTrue);
    });

    test('4. 複数カテゴリ混在時のマルチカテゴリ一括CSV生成の整合性', () {
      final category1Matches = [
        MatchModel(
          id: 'm_cat1',
          tournamentId: 't1',
          matchType: '個人戦',
          order: 1,
          redName: '紅組: 佐藤',
          whiteName: '白組: 鈴木',
          redScore: 2,
          whiteScore: 1,
        ),
      ];
      final category2Matches = [
        MatchModel(
          id: 'm_cat2',
          tournamentId: 't1',
          matchType: '個人戦',
          order: 1,
          redName: '青組: 田中',
          whiteName: '緑組: 高橋',
          redScore: 0,
          whiteScore: 1,
        ),
      ];

      final multiCategoryData = [
        (
          categoryName: '小学生低学年の部',
          groupDataList: [
            {'groupName': 'Aリーグ', 'matches': category1Matches},
          ],
        ),
        (
          categoryName: '中学生女子の部',
          groupDataList: [
            {'groupName': 'Bトーナメント', 'matches': category2Matches},
          ],
        ),
      ];

      final csv = CsvService.generateMultiCategoryCsvString(multiCategoryData);
      expect(csv.contains('小学生低学年の部'), isTrue);
      expect(csv.contains('中学生女子の部'), isTrue);
      expect(csv.contains('Aリーグ'), isTrue);
      expect(csv.contains('Bトーナメント'), isTrue);
    });
  });
}
