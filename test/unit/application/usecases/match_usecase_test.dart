import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/entities/role_permission.dart'; // ★ 追加
import '../../../helpers/event_factory.dart';

void main() {
  group('MatchUseCase - イベント駆動版テスト', () {
    late KendoRuleEngine engine;
    late AddScoreUseCase addScoreUseCase;
    late UndoScoreUseCase undoScoreUseCase;
    late RebuildMatchFromEventsUseCase rebuildUseCase;
    late MatchModel dummyMatch;
    late User testUser; // ★ 追加

    setUp(() {
      engine = KendoRuleEngine();
      final permission = PermissionService(); // ★ 関所を追加
      addScoreUseCase = AddScoreUseCase(engine, permission); // ★ 引数追加
      undoScoreUseCase = UndoScoreUseCase(engine, permission); // ★ 引数追加
      rebuildUseCase = RebuildMatchFromEventsUseCase(engine);
      dummyMatch = MatchModel( 
        id: 'test_m1', tournamentId: 't1', matchOrder: 1,
        redName: 'Red', whiteName: 'White',
        status: 'in_progress', matchType: '個人戦',
        remainingSeconds: 180,
      );
      testUser = const User(id: 'test_user', role: Role.admin, organizationId: 'test_org'); // ★ 追加
    });

    test('ポイント追加によって MatchModel のスコアとイベント履歴が更新されること', () {
      // Arrange
      final initialMatch = dummyMatch.copyWith(events: <ScoreEvent>[]);
      final event = men(Side.red);
      final rule = MatchRule();

      // Act
      final updatedMatch = addScoreUseCase.execute(testUser, initialMatch, event, rule); // ★ 変更

      // Assert
      expect(updatedMatch.events.length, 1);
      expect(updatedMatch.redScore, 1);
      expect(updatedMatch.isDirty, true);
    });

    test('Undoによって最新のイベントがキャンセル扱いになり、スコアが戻ること', () {
      // Arrange
      final matchWithScore = dummyMatch.copyWith(
        events: [men(Side.red)],
        redScore: 1,
      );
      final rule = MatchRule();

      // Act
      final undoneMatch = undoScoreUseCase.execute(testUser, matchWithScore, rule); // ★ 変更

      // Assert
      expect(undoneMatch.events.last.isCanceled, true); 
      expect(undoneMatch.redScore, 0); 
    });

    test('イベント履歴からの再構築 UseCase が正しく機能すること', () {
      // Arrange
      final baseMatch = dummyMatch.copyWith(
        events: [men(Side.red), kote(Side.white)],
        redScore: 0, 
        whiteScore: 0,
      );
      final rule = MatchRule();

      // Act
      final rebuiltMatch = rebuildUseCase.execute(baseMatch, rule); // ★ 再構築は読み取りなのでUser不要のまま

      // Assert
      expect(rebuiltMatch.redScore, 1);
      expect(rebuiltMatch.whiteScore, 1);
      expect(rebuiltMatch.status, 'in_progress');
    });
  });
}