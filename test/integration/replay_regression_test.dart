import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/domain/entities/match_context.dart'; // ★ 追加: MatchResultStatus のためにインポート
import '../helpers/test_match_factory.dart';

void main() {
  final engine = KendoRuleEngine();

  group('⏪ Phase 3-3: リプレイ回帰テスト (過去の試合の完全再現)', () {
    
    test('実データシナリオ1: 逆転勝利の歴史が正しく再現されること', () {
      // 1. 過去の試合の前提条件
      final rule = const MatchRule(ipponLimit: 2, matchTimeMinutes: 3.0);
      final match = TestMatchFactory.createIndividualMatch(id: 'historic-match-001');

      // 2. 過去の試合のイベント履歴（データベースに保存されていたJSONを想定）
      // 歴史: 赤メン先制 -> 白コテ取り返し -> 赤反則1回 -> 白メン で「白の勝利」
      final historicEvents = [
        ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men, sequence: 1, userId: 'ref_1'),
        ScoreEventLegacyAdapter.fromLegacy(side: Side.white, type: PointType.kote, sequence: 2, userId: 'ref_1'),
        ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.hansoku, sequence: 3, userId: 'ref_1'),
        ScoreEventLegacyAdapter.fromLegacy(side: Side.white, type: PointType.men, sequence: 4, userId: 'ref_1'),
      ];

      // 3. エンジンによる歴史の再構築
      final analysis = engine.analyzeHistory(historicEvents, match, rule);
      final ctx = analysis.context;

      // 4. 当時の結果（期待値）と完全に一致するかを検証
      expect(ctx.redIppon, 1, reason: '赤のスコアが歴史と一致しません');
      expect(ctx.whiteIppon, 2, reason: '白のスコアが歴史と一致しません');
      expect(ctx.redHansoku, 1, reason: '赤の反則数が歴史と一致しません');
      expect(ctx.whiteHansoku, 0, reason: '白の反則数が歴史と一致しません');

      // 勝敗の検証
      final result = engine.decideResult(ctx, rule);
      expect(result, MatchResultStatus.whiteWin, reason: '勝敗判定が歴史と一致しません');
    });

    test('実データシナリオ2: 誤審の取り消し（Undo）を含む歴史が正しく再現されること', () {
      final rule = const MatchRule(ipponLimit: 2, matchTimeMinutes: 3.0);
      final match = TestMatchFactory.createIndividualMatch(id: 'historic-match-002');

      // 歴史: 赤メン -> 間違えて白ドウを入力（後でUndoキャンセル） -> 赤コテ で「赤の2本勝ち」
      final historicEvents = [
        ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.men, sequence: 1, userId: 'ref_1'),
        ScoreEventLegacyAdapter.fromLegacy(side: Side.white, type: PointType.doIdo, sequence: 2, userId: 'ref_1', isCanceled: true), // キャンセル済み
        ScoreEventLegacyAdapter.fromLegacy(side: Side.red, type: PointType.kote, sequence: 3, userId: 'ref_1'),
      ];

      final analysis = engine.analyzeHistory(historicEvents, match, rule);
      final ctx = analysis.context;

      // キャンセルされた「白のドウ」がスコアに影響を与えていないことを証明
      expect(ctx.redIppon, 2);
      expect(ctx.whiteIppon, 0); 

      final result = engine.decideResult(ctx, rule);
      expect(result, MatchResultStatus.redWin);
    });
  });
}