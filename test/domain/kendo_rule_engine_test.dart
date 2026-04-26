import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/kendo_rule_engine.dart';
import 'package:kendo_os/models/score_event.dart';
import '../helpers/test_match_factory.dart';

void main() {
  late KendoRuleEngine engine;
  
  setUp(() {
    engine = KendoRuleEngine();
  });
  
  group('KendoRuleEngine - 基本スコアテスト', () {
    test('赤が面を打った時、赤のスコアが1本になること', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);
      final analysis = engine.analyzeHistory([event], match, rule);

      expect(analysis.context.redIppon, 1);
      expect(analysis.displays[Side.red]!.first.mark, 'メ');
    });
    
    test('白が小手を打った時、白のスコアが1本になること', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      
      final event = TestMatchFactory.createEvent(side: Side.white, type: PointType.kote);
      final analysis = engine.analyzeHistory([event], match, rule);

      expect(analysis.context.whiteIppon, 1);
      expect(analysis.displays[Side.white]!.first.mark, 'コ');
    });
  });

  group('KendoRuleEngine - 反則ロジックテスト', () {
    test('赤が反則1回の場合、スコアは動かないこと', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.hansoku);
      final analysis = engine.analyzeHistory([event], match, rule);

      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteIppon, 0);
    });

    test('赤が反則2回の場合、白に一本（反）が入ること', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      
      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.hansoku, sequence: 1);
      final e2 = TestMatchFactory.createEvent(side: Side.red, type: PointType.hansoku, sequence: 2);
      
      final analysis = engine.analyzeHistory([e1, e2], match, rule);

      expect(analysis.context.redHansoku, 2);
      expect(analysis.context.whiteIppon, 1);
      expect(analysis.displays[Side.white]!.first.mark, '反');
    });
  });

  group('KendoRuleEngine - 延長戦ロジックテスト', () {
    test('時間切れかつ同点の場合、延長戦に突入すべきと判定されること', () {
      final ctx = MatchContext(
        redIppon: 0,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: true, // 時間切れ
        targetIppon: 2,
        hasHantei: false,
      );
      
      final shouldExtend = engine.shouldEnterEncho(ctx, true); // 延長を許可する設定

      expect(shouldExtend, isTrue);
    });

    test('時間切れでもスコアに差がある場合、延長戦には入らないこと', () {
      final ctx = MatchContext(
        redIppon: 1,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: true,
        targetIppon: 2,
        hasHantei: false,
      );
      
      final shouldExtend = engine.shouldEnterEncho(ctx, true);

      expect(shouldExtend, isFalse);
    });
  });

  group('KendoRuleEngine - 勝敗判定ロジックテスト', () {
    test('赤が2本（規定本数）先取した場合、赤の勝利となること', () {
      final ctx = MatchContext(
        redIppon: 2,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: false,
        targetIppon: 2,
        hasHantei: false,
      );
      
      final result = engine.decideResult(ctx);

      expect(result, MatchResultStatus.redWin);
    });

    test('時間切れで赤が1本、白が0本の場合、赤の勝利となること', () {
      final ctx = MatchContext(
        redIppon: 1,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: true,
        targetIppon: 2,
        hasHantei: false,
      );
      
      final result = engine.decideResult(ctx);

      expect(result, MatchResultStatus.redWin);
    });

    test('時間切れで同点、かつ延長なしの設定なら引き分けとなること', () {
      final ctx = MatchContext(
        redIppon: 0,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: true,
        targetIppon: 2,
        hasHantei: false,
      );
      
      final result = engine.decideResult(ctx);

      expect(result, MatchResultStatus.draw);
    });

    test('規定本数に達しておらず、時間も残っている場合は進行中となること', () {
      final ctx = MatchContext(
        redIppon: 1,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: false,
        targetIppon: 2,
        hasHantei: false,
      );
      
      final result = engine.decideResult(ctx);

      expect(result, MatchResultStatus.inProgress);
    });
  });

  group('KendoRuleEngine - 異常系・バリデーションテスト', () {
    test('試合ステータスが「finished」の場合、新しいイベントは無効と判定されること', () {
      final match = TestMatchFactory.createIndividualMatch().copyWith(status: 'finished');
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);
      final ctx = MatchContext(redIppon: 0, whiteIppon: 0, redHansoku: 0, whiteHansoku: 0, isTimeUp: false, targetIppon: 2, hasHantei: false);
      
      final validation = engine.validateEvent(match, event, ctx);

      expect(validation.isValid, isFalse);
      expect(validation.reason, '試合は既に終了しています。');
    });

    test('既に規定本数（2本）に達している場合、追加の打突イベントは無効と判定されること', () {
      final match = TestMatchFactory.createIndividualMatch();
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);
      // 赤が既に2本取っている状況
      final ctx = MatchContext(redIppon: 2, whiteIppon: 0, redHansoku: 0, whiteHansoku: 0, isTimeUp: false, targetIppon: 2, hasHantei: false);
      
      final validation = engine.validateEvent(match, event, ctx);

      expect(validation.isValid, isFalse);
      expect(validation.reason, '既に規定本数に達しています。');
    });

    test('既に規定本数に達していても、Undo（取り消し）イベントは有効と判定されること', () {
      final match = TestMatchFactory.createIndividualMatch();
      final event = TestMatchFactory.createEvent(side: Side.none, type: PointType.undo);
      final ctx = MatchContext(redIppon: 2, whiteIppon: 0, redHansoku: 0, whiteHansoku: 0, isTimeUp: false, targetIppon: 2, hasHantei: false);
      
      final validation = engine.validateEvent(match, event, ctx);

      expect(validation.isValid, isTrue);
    });
  });

  group('KendoRuleEngine - 表示マーク(◯判, ◯, 反)網羅テスト', () {
    test('【判定】判定(Hantei)が入力された際、マークが「判定」かつ「◯囲み対象」になるか', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.hantei);
      
      final analysis = engine.analyzeHistory([event], match, rule);
      final display = analysis.displays[Side.red]!.first;

      expect(display.mark, '判定');
      expect(display.isFirstMatchPoint, isTrue, reason: '試合の1本目なので◯囲みが必要');
    });

    test('【不戦勝】不戦勝(Fusen)が入力された際、マーク「◯」が2つ生成されるか', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.fusen);
      
      final analysis = engine.analyzeHistory([event], match, rule);
      final displays = analysis.displays[Side.red]!;

      expect(displays.length, 2);
      expect(displays[0].mark, '◯');
      expect(displays[0].isFirstMatchPoint, isTrue, reason: '不戦勝の1本目は◯囲み');
      expect(displays[1].mark, '◯');
      expect(displays[1].isFirstMatchPoint, isFalse, reason: '不戦勝の2本目はそのまま');
    });

    test('【反則一本】反則2回で、相手側にマーク「反」が生成されるか', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.hansoku, sequence: 1);
      final e2 = TestMatchFactory.createEvent(side: Side.red, type: PointType.hansoku, sequence: 2);
      
      final analysis = engine.analyzeHistory([e1, e2], match, rule);
      
      // 赤の反則により、白（相手）に一本入る
      final whiteDisplay = analysis.displays[Side.white]!.first;

      expect(whiteDisplay.mark, '反');
      expect(whiteDisplay.isFirstMatchPoint, isTrue);
      expect(analysis.context.redHansoku, 2);
    });

    test('【1本目/2本目】1本目は◯囲みあり、2本目は◯囲みなしになるか', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.men, sequence: 1);
      final e2 = TestMatchFactory.createEvent(side: Side.red, type: PointType.kote, sequence: 2);
      
      final analysis = engine.analyzeHistory([e1, e2], match, rule);
      final displays = analysis.displays[Side.red]!;

      expect(displays[0].mark, 'メ');
      expect(displays[0].isFirstMatchPoint, isTrue);
      expect(displays[1].mark, 'コ');
      expect(displays[1].isFirstMatchPoint, isFalse);
    });
    
    test('【反則数】UI表示用の反則数(▲カウント)が正しく計算されるか', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.hansoku, sequence: 1);
      
      final analysis = engine.analyzeHistory([e1], match, rule);

      // UIで「▲」を出すためのカウントを検証
      expect(analysis.context.redHansoku, 1);
    });
  });
}