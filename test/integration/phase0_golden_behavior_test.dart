// ============================================================================
// 【GOVERNANCE BASELINE FREEZE】
// 本ファイルは Phase 0 にて「Golden Replay Baseline」として凍結されました。
// 現在のイベント評価ロジックの「正しい基準線」を証明する絶対的な防波堤です。
// ============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import '../helpers/test_match_factory.dart';
import '../helpers/event_factory.dart';

void main() {
  group('🔒 Phase 0-2: Golden Behavior Snapshot (現状挙動の凍結)', () {
    late AddScoreUseCase addScoreUseCase;
    late UndoScoreUseCase undoScoreUseCase;
    late TimeUpUseCase timeUpUseCase;
    final testUser = const User(id: 'golden_user', role: Role.admin, organizationId: 'test_org');

    setUp(() {
      final engine = KendoRuleEngine();
      final permission = PermissionService();
      addScoreUseCase = AddScoreUseCase(engine, permission);
      undoScoreUseCase = UndoScoreUseCase(engine, permission);
      timeUpUseCase = TimeUpUseCase(engine, permission);
    });

    test('1. 二本勝ちのGolden Snapshot', () {
      var match = TestMatchFactory.createIndividualMatch(id: 'golden-1');
      final rule = const MatchRule();

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule);
      match = addScoreUseCase.execute(testUser, match, kote(Side.red), rule);

      expect(match.redScore, 2);
      expect(match.whiteScore, 0);
      expect(match.status, 'finished');
    });

    test('2. 引き分けのGolden Snapshot', () {
      var match = TestMatchFactory.createIndividualMatch(id: 'golden-2');
      final rule = const MatchRule(isEnchoUnlimited: false, enchoCount: 0);

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule);
      match = addScoreUseCase.execute(testUser, match, men(Side.white), rule);
      match = timeUpUseCase.execute(testUser, match, false, rule);

      expect(match.redScore, 1);
      expect(match.whiteScore, 1);
      expect(match.status, 'finished'); // 延長なしなら終了
    });

    test('3. 延長戦突入のGolden Snapshot', () {
      var match = TestMatchFactory.createIndividualMatch(id: 'golden-3');
      final rule = const MatchRule(isEnchoUnlimited: true);

      match = timeUpUseCase.execute(testUser, match, true, rule);

      expect(match.matchType, '延長戦');
      expect(match.status, 'in_progress');
    });

    test('4. 反則勝ち(累積4回)のGolden Snapshot', () {
      var match = TestMatchFactory.createIndividualMatch(id: 'golden-4');
      final rule = const MatchRule();

      for (int i = 0; i < 4; i++) {
        match = addScoreUseCase.execute(testUser, match, hansoku(Side.white), rule);
      }

      expect(match.redScore, 2);
      expect(match.status, 'finished');
    });

    test('5. UndoのGolden Snapshot', () {
      var match = TestMatchFactory.createIndividualMatch(id: 'golden-5');
      final rule = const MatchRule();

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule);
      match = undoScoreUseCase.execute(testUser, match, rule);

      expect(match.redScore, 0);
      // ★ Phase 2: isCanceled(上書き)を廃止したため、最新のイベントが「Undoイベント」として追記されていることを確認する
      expect(match.events.last.isUndo, isTrue);
      expect(match.events.length, 2, reason: 'メン(1) + Undo(1) で履歴が2つになっているべき');
      expect(match.status, 'in_progress');
    });

    test('6. 一本勝負のGolden Snapshot', () {
      var match = TestMatchFactory.createIndividualMatch(id: 'golden-6');
      final rule = const MatchRule(isIpponShobu: true);

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule);

      expect(match.redScore, 1);
      expect(match.status, 'finished', reason: '一本勝負なので1本で終了するはず');
    });

    test('7. 判定(Hantei)のGolden Snapshot', () {
      var match = TestMatchFactory.createIndividualMatch(id: 'golden-7');
      final rule = const MatchRule(hasHantei: true);

      match = timeUpUseCase.execute(testUser, match, false, rule);
      
      final hanteiEvent = ScoreEventLegacyAdapter.fromLegacy(
        side: Side.red, type: PointType.hantei, sequence: 0, userId: testUser.id,
      );
      match = addScoreUseCase.execute(testUser, match, hanteiEvent, rule);

      expect(match.events.where((e) => e.type == PointType.hantei).length, 1);
    });

    test('8. 不戦勝(Fusen)のGolden Snapshot', () {
      var match = TestMatchFactory.createIndividualMatch(id: 'golden-8');
      final rule = const MatchRule(); // 規定2本

      final fusenEvent = ScoreEventLegacyAdapter.fromLegacy(
        side: Side.red, type: PointType.fusen, sequence: 0, userId: testUser.id,
      );
      match = addScoreUseCase.execute(testUser, match, fusenEvent, rule);

      expect(match.redScore, 2, reason: '不戦勝イベント1つで規定本数(2)が入るはず');
      expect(match.status, 'finished');
    });

    test('9. 団体戦(Team)引分のGolden Snapshot', () {
      final rule = const MatchRule();
      var match1 = TestMatchFactory.createIndividualMatch(id: 'team-1').copyWith(status: 'finished');
      var match2 = TestMatchFactory.createIndividualMatch(id: 'team-2').copyWith(status: 'finished');
      
      final engine = KendoRuleEngine();
      final status = engine.analyzeGroupStatus(
        currentMatch: match2,
        groupMatches: [match1, match2],
        rule: rule,
      );

      expect(status.isAllDone, isTrue);
      expect(status.isTie, isTrue, reason: '両試合スコア0-0なので代表戦なしなら完全引き分け');
    });

    test('10. 勝ち抜き戦(Kachinuki)大将戦のGolden Snapshot', () {
      final rule = const MatchRule(isKachinuki: true, kachinukiUnlimitedType: '大将引き分け延長');
      var match = TestMatchFactory.createIndividualMatch(id: 'kachinuki-1').copyWith(
        matchType: '個人戦', // 代表戦や延長戦ではない状態
        redRemaining: [],   // 大将
        whiteRemaining: [], // 大将
        redScore: 0,
        whiteScore: 0,
        status: 'in_progress',
        note: '',
      );
      
      final engine = KendoRuleEngine();
      final status = engine.analyzeGroupStatus(
        currentMatch: match,
        groupMatches: [match],
        rule: rule,
        lastSettings: {'extensionCount': -1}, // 無制限
      );

      expect(status.isTie, isFalse, reason: '大将引き分け延長が設定されているので、まだ終わらないはず');
      expect(status.isAllDone, isFalse);
    });
  });
}