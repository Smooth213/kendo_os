import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';

void main() {
  group('[E2E] 多人数団体戦 不戦勝多発・代表戦決着・一括帳票エクスポート複合テスト', () {
    test('多人数団体戦で不戦勝が多発し代表戦へもつれ込んだ記録がCSV帳票へ完全出力されること', () async {
      // 7人制団体戦（先鋒〜大将 ＋ 代表戦）
      final positions = ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
      final matches = <MatchModel>[];

      // 1. 先鋒: 赤の不戦勝（◯◯: 2-0）
      matches.add(
        MatchModel(
          id: 'm_fusen_1',
          tournamentId: 't_multi_fusen',
          category: '7人制団体戦',
          groupName: '1回戦',
          order: 1.0,
          redName: '赤隊: 先鋒',
          whiteName: '白隊: 欠員',
          redScore: 2,
          whiteScore: 0,
          matchType: '選手',
          status: 'finished',
          note: '不戦勝',
          events: [
            ScoreEvent(
              id: 'e1',
              side: Side.red,
              isFusen: true,
              isIppon: true,
              timestamp: DateTime(2026, 10, 1),
            ),
            ScoreEvent(
              id: 'e2',
              side: Side.red,
              isFusen: true,
              isIppon: true,
              timestamp: DateTime(2026, 10, 1),
            ),
          ],
        ),
      );

      // 2. 次鋒: 白の不戦勝（▲▲: 0-2）
      matches.add(
        MatchModel(
          id: 'm_fusen_2',
          tournamentId: 't_multi_fusen',
          category: '7人制団体戦',
          groupName: '1回戦',
          order: 2.0,
          redName: '赤隊: 欠員',
          whiteName: '白隊: 次鋒',
          redScore: 0,
          whiteScore: 2,
          matchType: '選手',
          status: 'finished',
          note: '不戦勝',
          events: [
            ScoreEvent(
              id: 'e3',
              side: Side.white,
              isFusen: true,
              isIppon: true,
              timestamp: DateTime(2026, 10, 1),
            ),
            ScoreEvent(
              id: 'e4',
              side: Side.white,
              isFusen: true,
              isIppon: true,
              timestamp: DateTime(2026, 10, 1),
            ),
          ],
        ),
      );

      // 3〜6. 五将・中堅・三将・副将: すべて 0-0 の引き分け
      for (int i = 2; i < 6; i++) {
        matches.add(
          MatchModel(
            id: 'm_draw_$i',
            tournamentId: 't_multi_fusen',
            category: '7人制団体戦',
            groupName: '1回戦',
            order: (i + 1).toDouble(),
            redName: '赤隊: ${positions[i]}',
            whiteName: '白隊: ${positions[i]}',
            redScore: 0,
            whiteScore: 0,
            matchType: '選手',
            status: 'finished',
            note: '引分',
          ),
        );
      }

      // 7. 大将戦: 1-1 の引き分け
      matches.add(
        MatchModel(
          id: 'm_taisho_draw',
          tournamentId: 't_multi_fusen',
          category: '7人制団体戦',
          groupName: '1回戦',
          order: 7.0,
          redName: '赤隊: 大将',
          whiteName: '白隊: 大将',
          redScore: 1,
          whiteScore: 1,
          matchType: '選手',
          status: 'finished',
          note: 'メ - コ',
        ),
      );

      // 8. 勝者数（1勝1敗5分）・総取得本数（3本対3本）で同率のため代表戦
      matches.add(
        MatchModel(
          id: 'm_daihyo',
          tournamentId: 't_multi_fusen',
          category: '7人制団体戦',
          groupName: '1回戦',
          order: 8.0,
          redName: '赤隊: 代表（大将）',
          whiteName: '白隊: 代表（大将）',
          redScore: 1,
          whiteScore: 0,
          matchType: '代表戦',
          status: 'finished',
          note: '延長戦 メ一本勝負',
          events: [
            ScoreEvent(
              id: 'e_daihyo',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: DateTime(2026, 10, 1),
            ),
          ],
        ),
      );

      // CSV生成を実行
      final csvString = CsvService.generateCsvString('7人制団体戦', [
        {'groupName': '1回戦', 'matches': matches},
      ]);

      expect(csvString.isNotEmpty, isTrue);
      expect(csvString.contains('不戦勝'), isTrue);
      expect(csvString.contains('赤隊'), isTrue);
      expect(csvString.contains('代表'), isTrue);

      // Isolate 非同期一括CSV生成での整合性
      final multiCategoryData = [
        (
          categoryName: '7人制団体戦',
          groupDataList: [
            {'groupName': '1回戦', 'matches': matches},
          ],
        ),
      ];

      final csvBytes = await CsvService.generateMultiCategoryCsvBytesAsync(
        multiCategoryData,
      );

      expect(csvBytes.isNotEmpty, isTrue);
      // UTF-8 BOMヘッダーの存在
      expect(csvBytes[0], 0xEF);
      expect(csvBytes[1], 0xBB);
      expect(csvBytes[2], 0xBF);
    });
  });
}
