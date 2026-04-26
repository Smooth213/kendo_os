import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/kendo_rule_engine.dart';
import 'package:kendo_os/domain/match/match_context.dart';
import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/domain/match/match_rule.dart';
import 'package:kendo_os/domain/match/score_event.dart';

void main() {
  late KendoRuleEngine engine;

  setUp(() {
    engine = KendoRuleEngine();
  });

  group('Match Rule Integration - ルール整合性テスト', () {
    
    test('【判定設定】判定あり(hasHantei: true)の時、時間切れ同点で「判定入力待ち」になるか', () {
      const rule = MatchRule(hasHantei: true);
      
      final ctx = MatchContext(
        redIppon: 0, whiteIppon: 0, redHansoku: 0, whiteHansoku: 0,
        isTimeUp: true, targetIppon: 2, hasHantei: rule.hasHantei,
      );

      final result = engine.decideResult(ctx);
      expect(result, MatchResultStatus.inProgress);
    });

    test('【判定設定】判定なしの時、時間切れ同点で「引き分け」になるか', () {
      const rule = MatchRule(hasHantei: false);
      
      final ctx = MatchContext(
        redIppon: 0, whiteIppon: 0, redHansoku: 0, whiteHansoku: 0,
        isTimeUp: true, targetIppon: 2, hasHantei: rule.hasHantei,
      );

      final result = engine.decideResult(ctx);
      expect(result, MatchResultStatus.draw);
    });

    test('【延長回数制限】延長1回制限設定で、エンジンが正しく挙動するか', () {
      final ctx = MatchContext(
        redIppon: 1, whiteIppon: 1, redHansoku: 0, whiteHansoku: 0,
        isTimeUp: true, targetIppon: 2, hasHantei: false,
      );

      // UI側から「延長可能」と判断されている場合
      expect(engine.shouldEnterEncho(ctx, true), isTrue);
      // UI側から「延長不可（回数制限到達）」と判断されている場合
      expect(engine.shouldEnterEncho(ctx, false), isFalse);
    });

    test('【勝ち抜き戦】「大将対大将」以外での引き分け判定', () {
      // 必須項目をすべて含めてインスタンス化
      final current = MatchModel(
        id: 'kachinuki_sub', 
        matchType: '副将', // 必須
        redName: '赤チーム : 副将', // 必須
        whiteName: '白チーム : 副将', // 必須
        order: 4.0, 
        isKachinuki: true,
        redScore: 0, 
        whiteScore: 0, 
        status: 'finished',
        redRemaining: const ['大将'],
        whiteRemaining: const ['大将'],
      );

      final status = engine.analyzeGroupStatus(
        currentMatch: current,
        groupMatches: [current],
        rule: const MatchRule(isKachinuki: true, kachinukiUnlimitedType: '大将対大将'),
      );

      expect(status.isAllDone, isFalse);
    });

    test('【リーグ戦勝ち点】勝3点/分1点設定の計算', () {
      const rule = MatchRule(isLeague: true, winPoint: 3.0, drawPoint: 1.0, lossPoint: 0.0);
      
      final m1 = MatchModel(
        id: 'l1', matchType: '個人', redName: 'A : 選手', whiteName: 'B : 選手', 
        redScore: 2, whiteScore: 0, status: 'approved'
      );
      final m2 = MatchModel(
        id: 'l2', matchType: '個人', redName: 'A : 選手', whiteName: 'C : 選手', 
        redScore: 1, whiteScore: 1, status: 'approved'
      );

      final standings = KendoRuleEngine.calculateLeagueStandings([m1, m2], rule);
      final aTeam = standings.firstWhere((s) => s.name == 'A');

      expect(aTeam.customPoints, 4.0);
    });

    test('【不戦勝】不戦勝イベントによるスコア生成', () {
      final match = MatchModel(id: 'f_test', matchType: '個人', redName: 'A', whiteName: 'B');
      final event = ScoreEvent(
        side: Side.red, type: PointType.fusen, timestamp: DateTime.now()
      );

      final analysis = engine.analyzeHistory([event], match, const MatchRule());
      
      expect(analysis.context.redIppon, 2);
      expect(analysis.displays[Side.red]!.length, 2);
      expect(analysis.displays[Side.red]![0].mark, '◯');
    });
  });
}