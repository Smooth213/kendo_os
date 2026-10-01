import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/services/timeline_export_service.dart';

void main() {
  group('[Governance] データ入力サニタイズおよびインジェクション防護規約', () {
    test('CSVエクスポートにおいて備考欄のダブルクォートやカンマが安全にエスケープされること', () {
      final matches = [
        const MatchModel(
          id: 'm_sanitize_1',
          tournamentId: 't1',
          matchType: '個人戦',
          category: '高校生男子,個人',
          redName: '選手"A"',
          whiteName: '選手,B',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          note: '注意: "反則1回" あり, 延長',
        ),
      ];

      final csv = TimelineExportService.exportToCsv(matches);

      // UTF-8 BOM が先頭に存在すること
      expect(csv.startsWith('\uFEFF'), isTrue);

      // ノート内のダブルクォートが "" にエスケープされていること
      expect(csv.contains('注意: ""反則1回"" あり, 延長'), isTrue);

      // カンマを含むフィールドがダブルクォートで囲まれていること
      expect(csv.contains('"高校生男子,個人"'), isTrue);
      expect(csv.contains('"選手,B"'), isTrue);
    });

    test('TXTエクスポートにおいて制御文字やスクリプトタグが含まれても例外なく安全に出力されること', () {
      final matches = [
        const MatchModel(
          id: 'm_sanitize_2',
          tournamentId: 't1',
          matchType: '個人戦',
          category: '一般',
          redName: '<script>alert("xss")</script>',
          whiteName: '通常選手\x00\x1F',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          note: '改行入り\nメモ',
        ),
      ];

      final txt = TimelineExportService.exportToTxt(
        matches,
        'テスト大会<img src=x onerror=alert(1)>',
      );

      expect(txt, contains('テスト大会<img src=x onerror=alert(1)>'));
      expect(txt, contains('<script>alert("xss")</script>'));
      expect(txt, contains('改行入り\nメモ'));
    });

    test('空文字や極端な特殊文字入力に対してもCSVエクスポートが決定論的に崩れず出力されること', () {
      final matches = [
        const MatchModel(
          id: 'm_sanitize_3',
          tournamentId: 't1',
          matchType: '',
          category: null,
          redName: '',
          whiteName: '',
          redScore: 0,
          whiteScore: 0,
          status: '',
          note: '',
        ),
      ];

      final csv = TimelineExportService.exportToCsv(matches);
      final lines = csv.trim().split('\n');

      // ヘッダー行 + 1行 = 2行
      expect(lines.length, 2);
      expect(lines[1].startsWith('1,"","",""'), isTrue);
    });
  });
}
