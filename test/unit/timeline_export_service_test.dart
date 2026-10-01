import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/application/services/timeline_export_service.dart';

void main() {
  group('[Unit] タイムライン出力サービス単体テスト', () {
    final testTime = DateTime(2026, 10, 1, 14, 30, 0);

    test('CSV出力において先頭にUTF-8のBOMが付加されExcel文字化けが防止されること', () {
      final matches = [
        const MatchModel(
          id: 'csv_1',
          tournamentId: 't1',
          matchType: '個人戦',
          category: '一般の部',
          redName: '佐藤',
          whiteName: '鈴木',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          note: '好勝負',
        ),
      ];

      final csv = TimelineExportService.exportToCsv(matches);

      expect(csv.codeUnitAt(0), 0xFEFF);
      expect(csv.startsWith('\uFEFF試合順,カテゴリ,試合種別'), isTrue);
    });

    test('CSV出力においてダブルクォートや特殊記号を含む備考が安全に二重化エスケープされること', () {
      final matches = [
        const MatchModel(
          id: 'csv_quote',
          tournamentId: 't1',
          matchType: '団体戦',
          category: '高校男子',
          redName: '神武館',
          whiteName: '修道館',
          redScore: 0,
          whiteScore: 0,
          status: 'in_progress',
          note: '判定"合議"中, 時間注意',
        ),
      ];

      final csv = TimelineExportService.exportToCsv(matches);

      expect(csv.contains('判定""合議""中, 時間注意'), isTrue);
    });

    test('TXT出力において取消済イベントに取消タグが付加され見やすく整形されること', () {
      final matches = [
        MatchModel(
          id: 'txt_cancel',
          tournamentId: 't1',
          matchType: '個人戦',
          category: '中学生女子',
          redName: '田中',
          whiteName: '高橋',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          note: '白反則1回',
          events: [
            ScoreEvent(
              id: 'ev1',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: testTime,
              isCanceled: true,
            ),
            ScoreEvent(
              id: 'ev2',
              side: Side.red,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: testTime.add(const Duration(minutes: 1)),
              isCanceled: false,
            ),
          ],
        ),
      ];

      final txt = TimelineExportService.exportToTxt(matches, '秋季新人戦');

      expect(txt.contains('大会公式タイムライン記録: 秋季新人戦'), isTrue);
      expect(txt.contains('[⚠️取消済]'), isTrue);
      expect(txt.contains('第 1 試合 [中学生女子] (個人戦)'), isTrue);
      expect(txt.contains('メモ: 白反則1回'), isTrue);
    });

    test('打突イベントが存在しない試合でもTXT出力がクラッシュせず履歴なし表記となること', () {
      final matches = [
        const MatchModel(
          id: 'txt_empty',
          tournamentId: 't1',
          matchType: '個人戦',
          category: '少年部',
          redName: '小林',
          whiteName: '渡辺',
          redScore: 0,
          whiteScore: 0,
          status: 'ready',
          note: '',
          events: [],
        ),
      ];

      final txt = TimelineExportService.exportToTxt(matches, '少年錬成会');

      expect(txt.contains('(打突イベント履歴なし)'), isTrue);
      expect(txt.contains('対戦: 小林 [0] vs [0] 渡辺'), isTrue);
    });
  });
}
