import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/application/services/timeline_export_service.dart';

void main() {
  group('[E2E] 複合ルール動的変更および既存試合不変性CSV出力結合テスト', () {
    test('大会途中でルールが変更されても完了済み過去試合のスコアとルール定義が保持され新旧混在CSVが安全に出力されること', () async {
      final now = DateTime(2026, 10, 1, 9, 30, 0);

      // 1. 第1試合は「3本勝負・4分」の標準ルールで実施・完了
      const rule1 = MatchRule(
        matchTimeMinutes: 4,
        ipponLimit: 2,
        isIpponShobu: false,
      );

      final match1 = MatchModel(
        id: 'm_dyn_1',
        tournamentId: 't_dynamic',
        matchType: '個人戦',
        category: '男子有段の部',
        redName: '佐藤 健一',
        whiteName: '田中 誠',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        rule: rule1,
        note: '標準ルールで決着',
        events: [
          ScoreEvent(
            id: 'ev1_men',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
            sequence: 1,
          ),
          ScoreEvent(
            id: 'ev1_kote',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: now.add(const Duration(minutes: 2)),
            sequence: 2,
          ),
        ],
      );

      // 2. 進行の都合により、運営側が大会ルールを「1本勝負・2分・判定あり」に変更
      const rule2 = MatchRule(
        matchTimeMinutes: 2,
        ipponLimit: 1,
        isIpponShobu: true,
        hasHantei: true,
      );

      // 3. 第2試合は変更後の「1本勝負」で実施・完了
      final match2 = MatchModel(
        id: 'm_dyn_2',
        tournamentId: 't_dynamic',
        matchType: '個人戦',
        category: '男子有段の部',
        redName: '高橋 涼介',
        whiteName: '伊藤 拓真',
        redScore: 0,
        whiteScore: 1,
        status: 'finished',
        rule: rule2,
        note: '時間短縮一本勝負',
        events: [
          ScoreEvent(
            id: 'ev2_do',
            side: Side.white,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: now.add(const Duration(minutes: 10)),
            sequence: 1,
          ),
        ],
      );

      // 4. 既存の第1試合のルール・スコアが破壊されていないこと（イミュータビリティ保証）
      expect(match1.rule?.ipponLimit, 2);
      expect(match1.rule?.isIpponShobu, isFalse);
      expect(match1.redScore, 2);
      expect(match1.whiteScore, 0);

      // 5. 新旧ルール混在の全試合データをCSVエクスポート
      final matches = [match1, match2];
      final csv = TimelineExportService.exportToCsv(matches);

      // BOMヘッダー検証
      expect(csv.startsWith('\uFEFF'), isTrue);

      final lines = csv.trim().split('\n');
      expect(lines.length, 3); // ヘッダー + 2試合

      // 各行の内容検証
      expect(lines[1], contains('"佐藤 健一",2,0,"田中 誠"'));
      expect(lines[1], contains('"標準ルールで決着",2'));

      expect(lines[2], contains('"高橋 涼介",0,1,"伊藤 拓真"'));
      expect(lines[2], contains('"時間短縮一本勝負",1'));

      // プレーンテキストレポート出力も正常に行われること
      final txt = TimelineExportService.exportToTxt(matches, 'ルール動的変更検証大会');
      expect(txt.contains('第 1 試合 [男子有段の部] (個人戦)'), isTrue);
      expect(txt.contains('第 2 試合 [男子有段の部] (個人戦)'), isTrue);
    });
  });
}
