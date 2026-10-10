import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_event_processor.dart';

void main() {
  group('[Governance] 未フィルタイベント直接集計禁止およびルールエンジンSSOT保証規約', () {
    test('集計プロセッサが未フィルタの生イベント直接ループを行わずKendoRuleEngine経由で確定スコアを算出すること', () {
      // 1. ソースコード静的解析: expedition_event_processor.dart 内で
      //    生の `for (final ev in m.events)` による直接走査が存在しないこと
      final file = File(
        'lib/features/tournament/presentation/components/official_record/expedition_event_processor.dart',
      );
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();

      // 生の未フィルタループが存在しないこと
      expect(
        content.contains('for (final ev in m.events)'),
        isFalse,
        reason: 'm.events の生走査はUndo取り消しイベントの残存リスクがあるため禁止されています',
      );

      // KendoRuleEngine または getEffectiveScores を経由していること
      expect(
        content.contains('KendoRuleEngine') ||
            content.contains('getEffectiveScores'),
        isTrue,
        reason:
            'スコア・有効打突の集計はKendoRuleEngine（SSOT）またはgetEffectiveScoresを経由する必要があります',
      );
    });

    test('Undo相殺イベントを含む試合データにおいて未取り消しの打突が選手サマリーに漏洩計上されないこと', () {
      final now = DateTime.now();

      // 面1本、小手1本を取得後、小手を取り消し（Undo）した試合
      final evMen = ScoreEvent(
        id: 'gov-men-1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
      );
      final evKote = ScoreEvent(
        id: 'gov-kote-1',
        side: Side.red,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 5)),
      );
      final evUndo = ScoreEvent(
        id: 'gov-undo-1',
        side: Side.none,
        isUndo: true,
        targetId: 'gov-kote-1',
        timestamp: now.add(const Duration(seconds: 10)),
      );

      final match = MatchModel(
        id: 'gov-undo-match',
        tournamentId: 't-gov-1',
        matchType: '先鋒',
        category: '一般',
        redName: '自チーム:選手X',
        whiteName: '相手チーム:選手Y',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        events: [evMen, evKote, evUndo],
      );

      final stats = ExpeditionEventProcessor.processEvents(
        matches: [match],
        selectedSummaryTeam: '自チーム',
        isMyTeam: (t) => t == '自チーム',
        isMyPlayer: (p, t) => t == '自チーム',
        isMatchPlayed: (m) => true,
        playerStatsMap: {},
      );

      // 有効な面のみが計上され、Undoされた小手は厳格に0件であること
      expect(stats.teamMen, 1);
      expect(stats.teamKote, 0);
      expect(stats.teamTotalScored, 1);
    });
  });
}
