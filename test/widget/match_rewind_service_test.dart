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
  group('🛡️ MatchRewindService Unit Tests', () {
    test(
      '1. executeRewind returns initialMatch if targetVersion >= validEvents.length',
      () {
        final match = MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '山田',
          whiteName: '佐藤',
          events: const [],
        );

        final result = MatchRewindService.executeRewind(
          initialMatch: match,
          targetVersion: 0,
          currentUser: const User(
            id: 'u1',
            role: Role.admin,
            organizationId: 'o1',
          ),
          rule: const MatchRule(),
          addScore: AddScoreUseCase(
            KendoRuleEngine(),
            PermissionService(),
            SystemTimeSource(),
          ),
        );

        expect(result.id, 'm1');
      },
    );

    test(
      '2. executeRewind appends undo events to roll back to targetVersion',
      () {
        final now = DateTime.now();
        final match = MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '山田',
          whiteName: '佐藤',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'e1',
              timestamp: now,
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
            ),
          ],
        );

        final result = MatchRewindService.executeRewind(
          initialMatch: match,
          targetVersion: 0,
          currentUser: const User(
            id: 'u1',
            role: Role.admin,
            organizationId: 'o1',
          ),
          rule: const MatchRule(),
          addScore: AddScoreUseCase(
            KendoRuleEngine(),
            PermissionService(),
            SystemTimeSource(),
          ),
        );

        expect(result.status, 'in_progress');
        expect(result.events.length, 2);
        expect(result.redScore, 0);
      },
    );
  });
}
