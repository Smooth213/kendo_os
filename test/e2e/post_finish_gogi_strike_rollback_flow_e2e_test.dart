import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/services/match_rewind_service.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[E2E] 試合確定後・審判団合議打突取消（Rollback）＆延長戦再開E2Eテスト', () {
    test('試合確定（Finished）後に審判団合議で直前打突が取り消され、試合が再開されること', () {
      final now = DateTime(2026, 10, 2, 10, 0);

      // 試合終了（赤が面を決めて勝敗確定）
      final finishedMatch = MatchModel(
        id: 'match_gogi_rollback_01',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: '剣道一郎',
        whiteName: '武道二郎',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'e1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now,
          ),
        ],
      );

      final addScoreUseCase = AddScoreUseCase(
        KendoRuleEngine(),
        PermissionService(),
        SystemTimeSource(),
      );

      // 合議により直前打突を取り消してロールバック（targetVersion: 0）
      final rollbackedMatch = MatchRewindService.executeRewind(
        initialMatch: finishedMatch,
        targetVersion: 0,
        currentUser: const User(
          id: 'admin_referee_1',
          role: Role.admin,
          organizationId: 'dojo_1',
        ),
        rule: const MatchRule(isEnchoUnlimited: true),
        addScore: addScoreUseCase,
      );

      // 検証: スコアが0になり、ステータスが進行中（再開）へロールバック
      expect(rollbackedMatch.redScore, 0);
      expect(rollbackedMatch.status, isNot('finished'));
      expect(rollbackedMatch.events.any((e) => e.isUndo), isTrue);
    });
  });
}
