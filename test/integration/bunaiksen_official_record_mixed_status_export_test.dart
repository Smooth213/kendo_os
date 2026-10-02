import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';

void main() {
  group('[E2E] 部内戦進行中および完了混在公式記録エクスポート複合テスト', () {
    test('部内戦で未開始・進行中・完了済試合が混在する場合でも公式記録CSVが一括かつ破綻なくエクスポートされること', () async {
      // 1. 部内戦総当たりリーグの試合群（未開始・進行中・完了済が混在）
      final matches = <MatchModel>[
        // 試合1: 完了済 (赤勝ち 2-1)
        MatchModel(
          id: 'bunaiksen_m1',
          tournamentId: 't_bunaiksen_mixed',
          category: '一般部内戦',
          groupName: 'Aブロック',
          matchType: '部内戦個人',
          order: 1.0,
          redName: '神崎 (三段)',
          whiteName: '一条 (二段)',
          redScore: 2,
          whiteScore: 1,
          status: 'completed',
          note: '面・小手による一本勝ち',
        ),
        // 試合2: 進行中 (現在 1-0 で試合中)
        MatchModel(
          id: 'bunaiksen_m2',
          tournamentId: 't_bunaiksen_mixed',
          category: '一般部内戦',
          groupName: 'Aブロック',
          matchType: '部内戦個人',
          order: 2.0,
          redName: '一条 (二段)',
          whiteName: '藤原 (四段)',
          redScore: 1,
          whiteScore: 0,
          status: 'in_progress',
          note: '第1ピリオド終了時点',
        ),
        // 試合3: 未開始 (0-0 待機中)
        MatchModel(
          id: 'bunaiksen_m3',
          tournamentId: 't_bunaiksen_mixed',
          category: '一般部内戦',
          groupName: 'Aブロック',
          matchType: '部内戦個人',
          order: 3.0,
          redName: '藤原 (四段)',
          whiteName: '神崎 (三段)',
          redScore: 0,
          whiteScore: 0,
          status: 'waiting',
          note: '',
        ),
      ];

      final groupDataList = [
        {'groupName': 'Aブロック', 'matches': matches},
      ];

      // 2. CSVエクスポートを実行
      final csvString = CsvService.generateCsvString('一般部内戦', groupDataList);

      // 3. 検証
      // Excel用BOMが存在すること
      expect(csvString.startsWith('\uFEFF'), isTrue);

      // 各選手情報・試合順・備考が含まれていること
      expect(csvString.contains('一般部内戦'), isTrue);
      expect(csvString.contains('Aブロック'), isTrue);
      expect(csvString.contains('神崎'), isTrue);
      expect(csvString.contains('一条'), isTrue);
      expect(csvString.contains('藤原'), isTrue);
      expect(csvString.contains('面・小手による一本勝ち'), isTrue);
      expect(csvString.contains('第1ピリオド終了時点'), isTrue);

      // 完了試合の勝敗判定
      expect(csvString.contains('赤勝ち'), isTrue);

      // 4. バイト列変換の安全性
      final bytes = utf8.encode(csvString);
      expect(bytes.length, greaterThan(100));

      final decoded = utf8.decode(bytes);
      expect(decoded.contains('一般部内戦'), isTrue);
      expect(decoded.contains('Aブロック'), isTrue);
    });
  });
}
