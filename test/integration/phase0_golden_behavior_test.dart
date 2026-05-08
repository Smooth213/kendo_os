import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
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
  });
}