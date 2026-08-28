import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';

void main() {
  group('🥋 途中棄権（全日本剣道連盟 試合審判規則 第39条準拠）テスト要塞', () {
    late KendoRuleEngine ruleEngine;
    const rule = MatchRule(matchTimeMinutes: 3, ipponLimit: 2);

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('1. 0-0の状態で赤が途中棄権 ➔ 白に不戦勝2本が付与され、スコア白2-赤0で白の勝ち', () {
      final events = [
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'fusen1',
          side: Side.white,
          type: PointType.fusen,
          isRetirement: true,
        ),
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'fusen2',
          side: Side.white,
          type: PointType.fusen,
          isRetirement: true,
        ),
      ];

      final match = MatchModel(
        id: 'm1',
        matchType: '先鋒',
        redName: '赤選手',
        whiteName: '白選手',
        events: events,
        rule: rule,
      );

      final analysis = ruleEngine.analyzeHistory(events, match, rule);
      expect(analysis.context.redIppon, 0);
      expect(analysis.context.whiteIppon, 2);

      final result = ruleEngine.decideResult(analysis.context, rule, events);
      expect(result, MatchResultStatus.whiteWin);

      // 表示マークの検証 (白に◯が2つ)
      expect(analysis.displays[Side.white]!.length, 2);
      expect(analysis.displays[Side.white]![0].mark, '◯');
      expect(analysis.displays[Side.white]![1].mark, '◯');
      expect(analysis.displays[Side.red]!.isEmpty, isTrue);
    });

    test('2. 赤がメン1本先取後、赤が途中棄権 ➔ 白に2本付与され白2-赤1で白の勝ち（赤の先取点は維持）', () {
      final events = [
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'e1',
          side: Side.red,
          type: PointType.men,
        ),
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'fusen1',
          side: Side.white,
          type: PointType.fusen,
          isRetirement: true,
        ),
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'fusen2',
          side: Side.white,
          type: PointType.fusen,
          isRetirement: true,
        ),
      ];

      final match = MatchModel(
        id: 'm2',
        matchType: '先鋒',
        redName: '赤選手',
        whiteName: '白選手',
        events: events,
        rule: rule,
      );

      final analysis = ruleEngine.analyzeHistory(events, match, rule);
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 2);

      final result = ruleEngine.decideResult(analysis.context, rule, events);
      expect(result, MatchResultStatus.whiteWin);

      // 表示マークの検証 (赤にメ、白に◯2つ)
      expect(analysis.displays[Side.red]!.length, 1);
      expect(analysis.displays[Side.red]![0].mark, 'メ');
      expect(analysis.displays[Side.white]!.length, 2);
      expect(analysis.displays[Side.white]![0].mark, '◯');
      expect(analysis.displays[Side.white]![1].mark, '◯');
    });

    test('3. 白がコテ1本先取後、赤が途中棄権 ➔ 白に不足分の1本のみ追加付与され白2-赤0で白の勝ち', () {
      final events = [
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'e1',
          side: Side.white,
          type: PointType.kote,
        ),
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'fusen1',
          side: Side.white,
          type: PointType.fusen,
          isRetirement: true,
        ),
      ];

      final match = MatchModel(
        id: 'm3',
        matchType: '先鋒',
        redName: '赤選手',
        whiteName: '白選手',
        events: events,
        rule: rule,
      );

      final analysis = ruleEngine.analyzeHistory(events, match, rule);
      expect(analysis.context.redIppon, 0);
      expect(analysis.context.whiteIppon, 2);

      final result = ruleEngine.decideResult(analysis.context, rule, events);
      expect(result, MatchResultStatus.whiteWin);

      // 表示マークの検証 (白にコ、◯)
      expect(analysis.displays[Side.white]!.length, 2);
      expect(analysis.displays[Side.white]![0].mark, 'コ');
      expect(analysis.displays[Side.white]![1].mark, '◯');
    });

    test('4. 途中棄権イベントをUndo（取り消し）した場合、棄権前のスコア状態に戻ること', () {
      final events = [
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'e1',
          side: Side.red,
          type: PointType.men,
        ),
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'fusen1',
          side: Side.white,
          type: PointType.fusen,
          isRetirement: true,
        ),
        ScoreEventLegacyAdapter.fromLegacy(
          id: 'fusen2',
          side: Side.white,
          type: PointType.fusen,
          isRetirement: true,
        ),
        // fusen2を取り消し
        ScoreEvent(
          id: 'undo1',
          side: Side.none,
          isUndo: true,
          targetId: 'fusen2',
          timestamp: DateTime.now(),
        ),
        // fusen1を取り消し
        ScoreEvent(
          id: 'undo2',
          side: Side.none,
          isUndo: true,
          targetId: 'fusen1',
          timestamp: DateTime.now(),
        ),
      ];

      final match = MatchModel(
        id: 'm4',
        matchType: '先鋒',
        redName: '赤選手',
        whiteName: '白選手',
        events: events,
        rule: rule,
      );

      final analysis = ruleEngine.analyzeHistory(events, match, rule);
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 0);

      final result = ruleEngine.decideResult(analysis.context, rule, events);
      expect(result, MatchResultStatus.inProgress);
    });
  });
}
