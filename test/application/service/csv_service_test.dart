import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/service/csv_service.dart';
import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/domain/match/match_rule.dart';

void main() {
  group('CsvService ユニットテスト', () {
    test('生成されたCSV文字列が期待通りのフォーマットであること', () {
      // 1. テストデータの作成
      final mockMatch = MatchModel(
        id: '1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: '赤チーム : 皿田',
        whiteName: '白チーム : 山田',
        redScore: 2,
        whiteScore: 0,
        order: 1.0,
        note: 'メメ',
        status: 'finished',
        rule: MatchRule(positions: ['先鋒']),
      );

      final groupDataList = [
        {'groupName': '第1試合', 'matches': [mockMatch]}
      ];

      // 2. 実行
      final result = CsvService.generateCsvString('小学生の部', groupDataList);

      // 3. 検証（ヘッダーとデータ行が含まれているか）
      expect(result, contains('\uFEFF')); // BOMチェック
      expect(result, contains('"小学生の部","第1試合","1.0","赤チーム","皿田","白チーム","山田","2","0","赤勝ち","メメ"'));
    });
  });
}