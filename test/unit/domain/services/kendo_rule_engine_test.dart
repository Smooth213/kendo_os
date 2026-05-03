import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/match_context.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import '../../../helpers/event_factory.dart';

void main() {
  group('KendoRuleEngine - 全面改修版テスト', () {
    late KendoRuleEngine engine;
    late MatchModel dummyMatch;
    late MatchRule dummyRule;

    setUp(() {
      engine = KendoRuleEngine();
      dummyMatch = MatchModel( // ★ constを外し、コンパイラクラッシュを回避
        id: 'test', tournamentId: 't1', matchOrder: 1,
        redName: 'Red', whiteName: 'White',
        status: 'in_progress', matchType: '個人戦'
      );
      dummyRule = MatchRule();
    });

    test('赤が面を打った時、赤のスコアが1本になること', () {
      final events = [men(Side.red)];
      final analysis = engine.analyzeHistory(events, dummyMatch, dummyRule);

      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 0);
      expect(analysis.displays[Side.red]!.first.mark, 'メ');
    });
    
    test('白が小手を打った時、白のスコアが1本になること', () {
      final events = [kote(Side.white)];
      final analysis = engine.analyzeHistory(events, dummyMatch, dummyRule);

      expect(analysis.context.whiteIppon, 1);
      expect(analysis.displays[Side.white]!.first.mark, 'コ');
    });

    test('赤が反則1回の場合、スコアは動かないこと', () {
      final events = [hansoku(Side.red)];
      final analysis = engine.analyzeHistory(events, dummyMatch, dummyRule);

      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteIppon, 0);
    });

    test('赤が反則2回の場合、白に一本（反）が入ること', () {
      final events = [hansoku(Side.red), hansoku(Side.red)];
      final analysis = engine.analyzeHistory(events, dummyMatch, dummyRule);

      expect(analysis.context.redHansoku, 2);
      expect(analysis.context.whiteIppon, 1);
      expect(analysis.displays[Side.white]!.first.mark, '反');
    });

    test('時間切れかつ同点の場合、延長戦に突入すべきと判定されること', () {
      final ctx = MatchContext(
        redIppon: 0,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: true,
        targetIppon: 2,
        hasHantei: false,
      );
      
      final shouldExtend = engine.shouldEnterEncho(ctx, true);

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
      
      final result = engine.decideResult(ctx, dummyRule);

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
      
      final result = engine.decideResult(ctx, dummyRule);

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
      
      final result = engine.decideResult(ctx, dummyRule);

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
      
      final result = engine.decideResult(ctx, dummyRule);

      expect(result, MatchResultStatus.inProgress);
    });

    test('試合ステータスが「finished」の場合、新しいイベントは無効と判定されること', () {
      final match = dummyMatch.copyWith(status: 'finished');
      final event = men(Side.red);
      final ctx = MatchContext(redIppon: 0, whiteIppon: 0, redHansoku: 0, whiteHansoku: 0, isTimeUp: false, targetIppon: 2, hasHantei: false);
      
      final validation = engine.validateEvent(match, event, ctx);

      expect(validation.isValid, isFalse);
      expect(validation.reason, '試合は既に終了しています。');
    });

    test('既に規定本数（2本）に達している場合、追加の打突イベントは無効と判定されること', () {
      final match = dummyMatch;
      final event = men(Side.red);
      final ctx = MatchContext(redIppon: 2, whiteIppon: 0, redHansoku: 0, whiteHansoku: 0, isTimeUp: false, targetIppon: 2, hasHantei: false);
      
      final validation = engine.validateEvent(match, event, ctx);

      expect(validation.isValid, isFalse);
      expect(validation.reason, '既に規定本数に達しています。');
    });

    test('既に規定本数に達していても、Undo（取り消し）イベントは有効と判定されること', () {
      final match = dummyMatch;
      final event = cancel(Side.none).copyWith(isUndo: true);
      final ctx = MatchContext(redIppon: 2, whiteIppon: 0, redHansoku: 0, whiteHansoku: 0, isTimeUp: false, targetIppon: 2, hasHantei: false);
      
      final validation = engine.validateEvent(match, event, ctx);

      expect(validation.isValid, isTrue);
    });

    test('【判定】判定(Hantei)が入力された際、マークが「判定」かつ「◯囲み対象」になるか', () {
      final event = ScoreEvent(id: 'e', side: Side.red, strikeType: StrikeType.none, isHantei: true, timestamp: DateTime.now());
      
      final analysis = engine.analyzeHistory([event], dummyMatch, dummyRule);
      final display = analysis.displays[Side.red]!.first;

      expect(display.mark, '判定');
      expect(display.isFirstMatchPoint, isTrue, reason: '試合の1本目なので◯囲みが必要');
    });

    test('【不戦勝】不戦勝(Fusen)が入力された際、マーク「◯」が2つ生成されるか', () {
      final event = ScoreEvent(id: 'e', side: Side.red, strikeType: StrikeType.none, isFusen: true, timestamp: DateTime.now());
      
      final analysis = engine.analyzeHistory([event], dummyMatch, dummyRule);
      final displays = analysis.displays[Side.red]!;

      expect(displays.length, 2);
      expect(displays[0].mark, '◯');
      expect(displays[0].isFirstMatchPoint, isTrue, reason: '不戦勝の1本目は◯囲み');
      expect(displays[1].mark, '◯');
      expect(displays[1].isFirstMatchPoint, isFalse, reason: '不戦勝の2本目はそのまま');
    });

    test('【反則一本】反則2回で、相手側にマーク「反」が生成されるか', () {
      final events = [hansoku(Side.red), hansoku(Side.red)];
      
      final analysis = engine.analyzeHistory(events, dummyMatch, dummyRule);
      
      final whiteDisplay = analysis.displays[Side.white]!.first;

      expect(whiteDisplay.mark, '反');
      expect(whiteDisplay.isFirstMatchPoint, isTrue);
      expect(analysis.context.redHansoku, 2);
    });

    test('【1本目/2本目】1本目は◯囲みあり、2本目は◯囲みなしになるか', () {
      final events = [men(Side.red), kote(Side.red)];
      
      final analysis = engine.analyzeHistory(events, dummyMatch, dummyRule);
      final displays = analysis.displays[Side.red]!;

      expect(displays[0].mark, 'メ');
      expect(displays[0].isFirstMatchPoint, isTrue);
      expect(displays[1].mark, 'コ');
      expect(displays[1].isFirstMatchPoint, isFalse);
    });
    
    test('【反則数】UI表示用の反則数(▲カウント)が正しく計算されるか', () {
      final analysis = engine.analyzeHistory([hansoku(Side.red)], dummyMatch, dummyRule);

      expect(analysis.context.redHansoku, 1);
    });
  });
}