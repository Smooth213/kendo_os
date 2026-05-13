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
      final undoneMatch = undoScoreUseCase.execute(testUser, matchWithScore, rule);

      // Assert
      // ★ 仕様変更: 書き換えではなく、Undoイベントが「追記」されていることを確認
      expect(undoneMatch.events.length, 2, reason: '元イベント1件 + Undoイベント1件 で計2件になるべき');
      expect(undoneMatch.events.last.isUndo, true, reason: '最新のイベントはUndoフラグが立っているべき');
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

    test('【完全性証明】2本先取で終了(finished)した試合でUndoを実行した場合、ステータスが進行中(in_progress)に復元されること', () {
      // 1. 初期状態（0対0、進行中）
      final initialMatch = dummyMatch.copyWith(events: <ScoreEvent>[], redScore: 0, whiteScore: 0, status: 'in_progress');
      final rule = MatchRule();

      // 2. 赤が1本目を取得
      final match1 = addScoreUseCase.execute(testUser, initialMatch, men(Side.red), rule);
      expect(match1.redScore, 1);
      expect(match1.status, 'in_progress');

      // 3. 赤が2本目を取得（2本先取で試合終了状態へ遷移）
      final match2 = addScoreUseCase.execute(testUser, match1, kote(Side.red), rule);
      expect(match2.redScore, 2);
      expect(match2.status, 'finished', reason: '2本取得した時点で試合は終了(finished)にならなければならない');

      // 4. 直前の2本目を取り消し（Undo）
      final undoneMatch = undoScoreUseCase.execute(testUser, match2, rule);

      // 5. 不変条件の検証（時系列の巻き戻し）
      expect(undoneMatch.redScore, 1, reason: 'スコアが正しく1本に減算されていること');
      expect(undoneMatch.status, 'in_progress', reason: '終了状態が解除され、再び進行中(in_progress)に戻っていること');
    });

    test('【完全性証明】反則2回による1本付与と、そのUndo（反則の取り消し）が正しく計算されること', () {
      final initialMatch = dummyMatch.copyWith(events: <ScoreEvent>[], redScore: 0, whiteScore: 0, status: 'in_progress');
      final rule = MatchRule();

      // 1. 赤が1回目の反則（スコアは動かない）
      final match1 = addScoreUseCase.execute(testUser, initialMatch, hansoku(Side.red), rule);
      expect(match1.whiteScore, 0, reason: '反則1回では相手に点数は入らない');

      // 2. 赤が2回目の反則（白に1本入る）
      final match2 = addScoreUseCase.execute(testUser, match1, hansoku(Side.red), rule);
      expect(match2.whiteScore, 1, reason: '反則2回目で相手(白)に1本入る');

      // 3. 2回目の反則をUndo
      final undoneMatch = undoScoreUseCase.execute(testUser, match2, rule);
      expect(undoneMatch.whiteScore, 0, reason: '2回目の反則が取り消され、白のスコアが0に戻ること');
    });
  });
}