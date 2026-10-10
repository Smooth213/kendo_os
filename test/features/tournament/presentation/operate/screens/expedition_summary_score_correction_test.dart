import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_calculator.dart';

void main() {
  group('[Unit] 選手サマリー スコア修正・Undo反映テスト', () {
    final now = DateTime(2026, 10, 10, 10, 0);

    test('Undo（取り消し）によりスコア修正された試合で、選手サマリーの勝敗・本数・技内訳に修正が100%反映されること', () {
      // 山田（赤）が面を取り、その後取り消し（Undo）して0-0の引き分けになった試合
      final evMen = ScoreEvent(
        id: 'ev_men_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
      );
      final evUndo = ScoreEvent(
        id: 'ev_undo_1',
        side: Side.none,
        isUndo: true,
        targetId: 'ev_men_1',
        timestamp: now.add(const Duration(seconds: 10)),
      );

      final matchWithUndo = MatchModel(
        id: 'm_undo_test',
        tournamentId: 't1',
        matchType: '先鋒',
        category: '一般',
        groupName: '1回戦 (東京道場 vs 京都道場)',
        redName: '東京道場 : 山田',
        whiteName: '京都道場 : 田中',
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
        events: [evMen, evUndo],
      );

      final summary = ExpeditionStatsCalculator.calculate(
        matches: [matchWithUndo],
        registeredTeamNames: {'東京道場'},
        registeredPlayerNames: {'山田'},
        selectedSummaryTeam: '全体',
      );

      final yamadaStats = summary.playerStatsMap['山田'];
      expect(yamadaStats, isNotNull);

      // 勝敗: 0勝 0敗 1分 (引き分け) であること
      expect(yamadaStats!.win, 0);
      expect(yamadaStats.loss, 0);
      expect(yamadaStats.draw, 1);

      // 本数: 0本 であること (取り消された面が加算されていないこと)
      expect(yamadaStats.totalPoints, 0);
      expect(yamadaStats.teamPoints, 0);

      // 技内訳: 面が0であること
      expect(yamadaStats.men, 0);

      // チーム全体の総得点も0であること
      expect(summary.teamTotalScored, 0);
      expect(summary.teamMen, 0);
    });

    test('2本勝ちから1本取り消されて1本勝ちにスコア修正された場合、選手サマリーが1勝1本（面1、小手0）になること', () {
      final evMen = ScoreEvent(
        id: 'ev_men_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
      );
      final evKote = ScoreEvent(
        id: 'ev_kote_1',
        side: Side.red,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 5)),
      );
      // 小手を取り消し
      final evUndo = ScoreEvent(
        id: 'ev_undo_kote',
        side: Side.none,
        isUndo: true,
        targetId: 'ev_kote_1',
        timestamp: now.add(const Duration(seconds: 10)),
      );

      final match = MatchModel(
        id: 'm_correct_test',
        tournamentId: 't1',
        matchType: '次鋒',
        category: '一般',
        groupName: '1回戦 (東京道場 vs 京都道場)',
        redName: '東京道場 : 佐藤',
        whiteName: '京都道場 : 鈴木',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        events: [evMen, evKote, evUndo],
      );

      final summary = ExpeditionStatsCalculator.calculate(
        matches: [match],
        registeredTeamNames: {'東京道場'},
        registeredPlayerNames: {'佐藤'},
        selectedSummaryTeam: '全体',
      );

      final satoStats = summary.playerStatsMap['佐藤'];
      expect(satoStats, isNotNull);

      // 勝敗: 1勝 0敗 0分
      expect(satoStats!.win, 1);
      expect(satoStats.loss, 0);
      expect(satoStats.draw, 0);

      // 本数: 1本
      expect(satoStats.totalPoints, 1);
      expect(satoStats.teamPoints, 1);

      // 技内訳: 面1、小手0
      expect(satoStats.men, 1);
      expect(satoStats.kote, 0);

      expect(summary.teamTotalScored, 1);
      expect(summary.teamMen, 1);
      expect(summary.teamKote, 0);
    });

    test(
      'イベント詳細のない試合（簡易入力や外部インポート）でも、redScore/whiteScoreが選手サマリーに正しく反映されること',
      () {
        final matchSummary = const MatchModel(
          id: 'm_summary_import',
          tournamentId: 't1',
          matchType: '中堅',
          category: '一般',
          groupName: '1回戦 (東京道場 vs 京都道場)',
          redName: '東京道場 : 高橋',
          whiteName: '京都道場 : 伊藤',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          events: [],
        );

        final summary = ExpeditionStatsCalculator.calculate(
          matches: [matchSummary],
          registeredTeamNames: {'東京道場'},
          registeredPlayerNames: {'高橋'},
          selectedSummaryTeam: '全体',
        );

        final takahashiStats = summary.playerStatsMap['高橋'];
        expect(takahashiStats, isNotNull);

        // 勝敗: 1勝 0敗
        expect(takahashiStats!.win, 1);
        expect(takahashiStats.loss, 0);

        // 取得本数: 2本、失本数: 1本
        expect(takahashiStats.totalPoints, 2);
        expect(takahashiStats.concededPoints, 1);

        // チーム総得点・失点も正しく集計されること
        expect(summary.teamTotalScored, 2);
        expect(summary.teamTotalConceded, 1);
      },
    );
  });
}
