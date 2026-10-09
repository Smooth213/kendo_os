import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('[Unit] KendoRuleEngine 形・基本判定試合テスト', () {
    late KendoRuleEngine engine;
    final kataRule = const MatchRule(isKataMatch: true);

    setUp(() {
      engine = KendoRuleEngine();
    });

    MatchModel createMatch(List<ScoreEvent> events) {
      return MatchModel(
        id: 'test_kata_match',
        matchType: 'kata',
        redName: '山田・佐藤',
        whiteName: '鈴木・高橋',
        rule: kataRule,
        events: events,
      );
    }

    test('赤3対0の旗判定において、スコア・勝者・表示が正しく計算されること', () {
      final judgeEvent = ScoreEvent(
        id: 'evt_judge_3_0',
        side: Side.red,
        isHantei: true,
        redFlags: 3,
        whiteFlags: 0,
        timestamp: DateTime(2026, 10, 10, 10, 0, 0),
      );

      final match = createMatch([judgeEvent]);
      final analysis = engine.analyzeHistory(match.events, match, kataRule);

      // スコア検証
      expect(analysis.context.redIppon, 3);
      expect(analysis.context.whiteIppon, 0);

      // 勝者検証
      final result = engine.decideResult(analysis.context, kataRule, [
        judgeEvent,
      ]);
      expect(result, MatchResultStatus.redWin);

      // 表示検証
      final redDisplays = analysis.displays[Side.red]!;
      final whiteDisplays = analysis.displays[Side.white]!;
      expect(redDisplays.length, 1);
      expect(redDisplays.first.mark, '3');
      expect(whiteDisplays.length, 1);
      expect(whiteDisplays.first.mark, '0');
    });

    test('赤2対1の旗判定において、赤の判定勝ちとなること', () {
      final judgeEvent = ScoreEvent(
        id: 'evt_judge_2_1',
        side: Side.red,
        isHantei: true,
        redFlags: 2,
        whiteFlags: 1,
        timestamp: DateTime(2026, 10, 10, 10, 0, 0),
      );

      final match = createMatch([judgeEvent]);
      final analysis = engine.analyzeHistory(match.events, match, kataRule);

      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 1);

      final result = engine.decideResult(analysis.context, kataRule, [
        judgeEvent,
      ]);
      expect(result, MatchResultStatus.redWin);

      expect(analysis.displays[Side.red]!.first.mark, '2');
      expect(analysis.displays[Side.white]!.first.mark, '1');
    });

    test('赤1対2の旗判定において、白の判定勝ちとなること', () {
      final judgeEvent = ScoreEvent(
        id: 'evt_judge_1_2',
        side: Side.white,
        isHantei: true,
        redFlags: 1,
        whiteFlags: 2,
        timestamp: DateTime(2026, 10, 10, 10, 0, 0),
      );

      final match = createMatch([judgeEvent]);
      final analysis = engine.analyzeHistory(match.events, match, kataRule);

      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 2);

      final result = engine.decideResult(analysis.context, kataRule, [
        judgeEvent,
      ]);
      expect(result, MatchResultStatus.whiteWin);

      expect(analysis.displays[Side.red]!.first.mark, '1');
      expect(analysis.displays[Side.white]!.first.mark, '2');
    });

    test('赤不戦勝イベントにおいて、赤の勝利となること', () {
      final fusenEvent = ScoreEvent(
        id: 'evt_fusen_red',
        side: Side.red,
        isFusen: true,
        timestamp: DateTime(2026, 10, 10, 10, 0, 0),
      );

      final match = createMatch([fusenEvent]);
      final analysis = engine.analyzeHistory(match.events, match, kataRule);

      final result = engine.decideResult(analysis.context, kataRule, [
        fusenEvent,
      ]);
      expect(result, MatchResultStatus.redWin);

      expect(analysis.displays[Side.red]!.first.mark, '○');
      expect(analysis.displays[Side.white]!.first.mark, '×');
    });

    test('Undo相殺イベントが追加された場合において、初期状態に戻ること', () {
      final judgeEvent = ScoreEvent(
        id: 'evt_judge_2_1',
        side: Side.red,
        isHantei: true,
        redFlags: 2,
        whiteFlags: 1,
        timestamp: DateTime(2026, 10, 10, 10, 0, 0),
      );
      final undoEvent = ScoreEvent(
        id: 'evt_undo',
        side: Side.none,
        isUndo: true,
        targetId: 'evt_judge_2_1',
        timestamp: DateTime(2026, 10, 10, 10, 0, 10),
      );

      final match = createMatch([judgeEvent, undoEvent]);
      final analysis = engine.analyzeHistory(match.events, match, kataRule);

      expect(analysis.context.redIppon, 0);
      expect(analysis.context.whiteIppon, 0);

      final result = engine.decideResultFromMatch(match);
      expect(result, MatchResultStatus.inProgress);
      expect(analysis.displays[Side.red]!.isEmpty, isTrue);
      expect(analysis.displays[Side.white]!.isEmpty, isTrue);
    });
  });
}
