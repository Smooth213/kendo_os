import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/entities/role_permission.dart'; // ★ 追加
import '../helpers/event_factory.dart';

void main() {
  group('Event Driven Match Flow Integration', () {
    late KendoRuleEngine engine;
    late AddScoreUseCase addScoreUsecase;
    late UndoScoreUseCase undoUsecase;
    late User testUser; // ★ 追加

    setUp(() {
      engine = KendoRuleEngine();
      final permission = PermissionService(); // ★ 関所を追加
      addScoreUsecase = AddScoreUseCase(engine, permission); // ★ 引数追加
      undoUsecase = UndoScoreUseCase(engine, permission); // ★ 引数追加
      testUser = const User(id: 'test_user', role: Role.admin, organizationId: 'test_org'); 
    });

    test('赤が2本先取して試合が終了するまでのフロー', () {
      var match = MatchModel( 
        id: 'test', tournamentId: 't1', matchOrder: 1,
        redName: 'Red', whiteName: 'White',
        status: 'in_progress', matchType: '個人戦',
        remainingSeconds: 180,
      );
      final rule = MatchRule();

      // 赤が面を打つ
      match = addScoreUsecase.execute(testUser, match, men(Side.red), rule); // ★ 変更
      expect(match.redScore, 1);

      // 白が小手を打つ
      match = addScoreUsecase.execute(testUser, match, kote(Side.white), rule); // ★ 変更
      expect(match.redScore, 1);
      expect(match.whiteScore, 1);

      // 白の小手を取り消す(Undo)
      match = undoUsecase.execute(testUser, match, rule);
      // 履歴: 赤メン + 白コテ + Undo = 3件
      expect(match.events.length, 3, reason: 'Undoイベントが追記され、履歴は3件になるべき'); 
      expect(match.events.last.isUndo, true);
      expect(match.whiteScore, 0);

      // 赤が胴を打って決着
      match = addScoreUsecase.execute(testUser, match, dou(Side.red), rule); // ★ 変更
      expect(match.redScore, 2);
      
      // ステータスが終了になること
      expect(match.status, 'finished');
    });
  });
}