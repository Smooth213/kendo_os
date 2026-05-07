import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import '../../../helpers/test_match_factory.dart'; // ★ 修正: ファイルを移動したため、階層を深く(../../..)戻るように修正

void main() {
  final engine = KendoRuleEngine();
  final random = Random();

  group('🧪 Phase 3-1: Property-based testing (不変条件の自動検証)', () {
    
    test('10,000回のランダムな試合展開（技・反則・Undo）でも不変条件が絶対に壊れないこと', () {
      for (int i = 0; i < 10000; i++) {
        // 1. ランダムなルールの生成
        final ipponLimit = random.nextBool() ? 1 : 2; // 1本勝負 or 通常(2本先取)
        final rule = MatchRule(
          ipponLimit: ipponLimit,
          matchTimeMinutes: 3.0,
        );
        final match = TestMatchFactory.createIndividualMatch(id: 'random-match-$i');

        // 2. ランダムなイベント列（0〜30件）の生成
        final eventCount = random.nextInt(31);
        final List<ScoreEvent> events = [];
        
        for (int j = 0; j < eventCount; j++) {
          // 現在の状況を分析し、試合が終了しているか確認
          final currentAnalysis = engine.analyzeHistory(events, match, rule);
          final isFinished = currentAnalysis.context.redIppon >= rule.ipponLimit || currentAnalysis.context.whiteIppon >= rule.ipponLimit;

          // 低確率(10%)で「過去のイベントの取り消し(Undo)」が発生するシナリオも混ぜる
          bool isUndo = random.nextDouble() < 0.10 && events.isNotEmpty;
          
          if (isFinished && !isUndo) {
            // 試合決着後はシステム的に新しい技や反則が追加されないためスキップ
            // (Undoによって進行中に戻った場合のみ追加可能になる)
            continue;
          }

          final side = random.nextBool() ? Side.red : Side.white;
          final type = _randomPointType(random);
          
          if (isUndo) {
            // ランダムに選んだ過去の有効なイベントをキャンセル状態にする
            final targetIndex = random.nextInt(events.length);
            events[targetIndex] = events[targetIndex].copyWith(isCanceled: true);
          } else {
            // 通常のイベント追加
            events.add(ScoreEventLegacyAdapter.fromLegacy(
              side: side,
              type: type,
              sequence: j + 1,
              userId: 'prop-test-user',
            ));
          }
        }

        // 3. 計算実行
        final analysis = engine.analyzeHistory(events, match, rule);
        final context = analysis.context;

        // --------------------------------------------------
        // 不変条件 (Invariants) の検証：いかなる展開でもこれらは真でなければならない
        // --------------------------------------------------
        
        // 検証1: スコアは絶対に負（マイナス）にならない
        expect(context.redIppon, greaterThanOrEqualTo(0), 
          reason: '赤のスコアが負になりました (Iteration: $i, Events: ${events.length})');
        expect(context.whiteIppon, greaterThanOrEqualTo(0), 
          reason: '白のスコアが負になりました (Iteration: $i, Events: ${events.length})');

        // 検証2: 反則規則の整合性（累計反則数から相手に与えられるべき最低得点が確実に加算されているか）
        final expectedWhiteIpponFromHansoku = context.redHansoku ~/ rule.hansokuLimit;
        final expectedRedIpponFromHansoku = context.whiteHansoku ~/ rule.hansokuLimit;
        
        expect(context.whiteIppon, greaterThanOrEqualTo(expectedWhiteIpponFromHansoku), 
          reason: '赤の反則(${context.redHansoku}回)による白への得点加算が不足しています (Iteration: $i)');
        expect(context.redIppon, greaterThanOrEqualTo(expectedRedIpponFromHansoku), 
          reason: '白の反則(${context.whiteHansoku}回)による赤への得点加算が不足しています (Iteration: $i)');

        // 検証3: 勝敗の排他性と上限（規定本数を超えて同時に両者が勝利することはあり得ない）
        final isRedWinner = context.redIppon >= rule.ipponLimit;
        final isWhiteWinner = context.whiteIppon >= rule.ipponLimit;
        expect(isRedWinner && isWhiteWinner, isFalse, 
          reason: '赤白同時に勝利条件を満たしています。判定ロジックに矛盾があります (Iteration: $i)');
          
        // 検証4: イベントの整合性（履歴再構築後、スコアは規定本数＋1本を超えることはない）
        // ※反則による付与を含め、勝利確定後の過剰な加算がないか
        expect(context.redIppon, lessThanOrEqualTo(rule.ipponLimit + 1));
        expect(context.whiteIppon, lessThanOrEqualTo(rule.ipponLimit + 1));
      }
    });
  });
}

/// ランダムな打突部位または反則を返す
PointType _randomPointType(Random r) {
  final types = [
    PointType.men, 
    PointType.kote, 
    PointType.doIdo, 
    PointType.tsuki,
    PointType.hansoku,
  ];
  return types[r.nextInt(types.length)];
}