import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/application/services/line_summary_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  test('formats expedition summary correctly for LINE sharing', () {
    final matches = [
      MatchModel(
        id: 'm1',
        groupName: '第1試合',
        matchType: '先鋒',
        redName: '誠道館 : 山田',
        whiteName: 'ライバル道場 : 田中',
        redScore: 2,
        whiteScore: 0,
        order: 0,
        events: [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
          ScoreEvent(
            id: 'e2',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
        ],
      ),
      MatchModel(
        id: 'm2',
        groupName: '第1試合',
        matchType: '次鋒',
        redName: '誠道館 : 佐藤',
        whiteName: 'ライバル道場 : 鈴木',
        redScore: 1,
        whiteScore: 1,
        order: 1,
        events: [
          ScoreEvent(
            id: 'e3',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
          ScoreEvent(
            id: 'e4',
            side: Side.white,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
        ],
      ),
    ];

    final summary = LineSummaryFormatter.formatExpeditionSummary(
      title: '夏季錬成会',
      matches: matches,
      date: DateTime(2026, 8, 28),
    );

    expect(summary, contains('【夏季錬成会 結果速報】'));
    expect(summary, contains('2026/08/28'));
    expect(summary, contains('第1試合: ○ 誠道館 1(3) - 0(1) ライバル道場'));
    expect(summary, contains('🏆 通算成績: 1勝0敗0分 (勝率: 100.0%)'));
    expect(summary, contains('🔥 本日の最多取得本数: 山田 (2本)'));
  });
}
