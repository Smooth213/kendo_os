import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';
import 'package:kendo_os/shared/utils/kendo_compute_helper.dart';

// テスト用重計算関数
int _heavyFibonacci(int n) {
  if (n <= 1) return n;
  int a = 0, b = 1;
  for (int i = 2; i <= n; i++) {
    int next = a + b;
    a = b;
    b = next;
  }
  return b;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🧵 [Phase 4 Performance Governance] 重計算Isolate分離テスト', () {
    test('1. KendoComputeHelper.run が重計算を正しく実行し結果を返却すること', () async {
      final result = await KendoComputeHelper.run(_heavyFibonacci, 30);
      expect(result, 832040);
    });

    test(
      '2. CsvService.generateCsvBytesAsync が大量試合データを別スレッドでCSVバイナリ化できること',
      () async {
        // 100試合分のモックデータを生成
        final matches = List.generate(
          100,
          (i) => MatchModel(
            id: 'match_$i',
            tournamentId: 't1',
            category: '一般の部',
            order: i + 1,
            redName: '青龍道場: 選手_$i',
            whiteName: '白虎剣友会: 選手_${i + 100}',
            matchType: '個人戦',
            status: 'finished',
            redScore: (i % 2 == 0) ? 2 : 1,
            whiteScore: (i % 2 == 0) ? 0 : 2,
            note: '第$i試合メモ',
          ),
        );

        final groupDataList = [
          {'groupName': '第1コート', 'matches': matches},
        ];

        final bytes = await CsvService.generateCsvBytesAsync(
          '一般の部',
          groupDataList,
        );

        // UTF-8 デコードして検証
        final csvString = utf8.decode(bytes);

        // BOM検証 (UTF-8 BOM: 0xEF, 0xBB, 0xBF)
        expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
        // ヘッダー検証
        expect(csvString.contains('カテゴリ,グループ名,試合順'), isTrue);
        // 100試合分の行が含まれること
        expect(csvString.contains('青龍道場'), isTrue);
        expect(csvString.contains('白虎剣友会'), isTrue);
        expect(csvString.contains('match_99'), isFalse); // IDではなくチーム・選手情報
        expect(csvString.contains('第99試合メモ'), isTrue);
      },
    );

    test('3. KendoComputeHelper による大量JSONシリアライズがデータ欠損なく完了すること', () async {
      final rawList = List.generate(
        200,
        (i) => {
          'id': 'm_$i',
          'order': i,
          'title': '試合_$i',
          'timestamp': DateTime.now().toIso8601String(),
          'events': [
            {'type': 'men', 'point': 1},
            {'type': 'kote', 'point': 1},
          ],
        },
      );

      final jsonStr = await KendoComputeHelper.run(
        (List<Map<String, dynamic>> list) => jsonEncode(list),
        rawList,
      );

      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      expect(decoded.length, 200);
      expect(decoded[199]['id'], 'm_199');
    });
  });
}
