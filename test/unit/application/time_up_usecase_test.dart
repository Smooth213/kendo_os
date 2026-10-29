import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';
import 'package:kendo_os/shared/time/time_source.dart';

void main() {
  late KendoRuleEngine engine;
  late PermissionService permission;
  late TimeSource timeSource;
  late TimeUpUseCase useCase;

  setUp(() {
    engine = KendoRuleEngine();
    permission = PermissionService();
    timeSource = SystemTimeSource();
    useCase = TimeUpUseCase(engine, permission, timeSource);
  });

  group('[Unit] TimeUpUseCase 単体テスト', () {
    test('閲覧者ロールのユーザーが時間切れ操作を実行した際にUnauthorizedExceptionが送出されること', () {
      const viewerUser = User(
        id: 'viewer-1',
        role: Role.viewer,
        organizationId: 'org-1',
      );

      const match = MatchModel(
        id: 'match-1',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
      );

      expect(
        () => useCase.execute(viewerUser, match, true, const MatchRule()),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('同点かつ延長有効の場合に延長戦へ突入しnoteに延長が記録されること', () {
      const scorerUser = User(
        id: 'scorer-1',
        role: Role.scorer,
        organizationId: 'org-1',
      );

      const match = MatchModel(
        id: 'match-2',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 1,
        whiteScore: 1,
        status: 'in_progress',
      );

      const rule = MatchRule(enchoTimeMinutes: 3.0);

      final result = useCase.execute(scorerUser, match, true, rule);
      expect(result.matchType, '延長戦');
      expect(result.note, contains('延長'));
      expect(result.status, 'in_progress');
      expect(result.timerStartedAt, isNull);
    });

    test('延長無効の場合に時間切れ終了状態へ遷移すること', () {
      const scorerUser = User(
        id: 'scorer-1',
        role: Role.scorer,
        organizationId: 'org-1',
      );

      const match = MatchModel(
        id: 'match-3',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
        redScore: 1,
        whiteScore: 1,
        status: 'in_progress',
      );

      const rule = MatchRule();

      final result = useCase.execute(scorerUser, match, false, rule);
      expect(result.status, 'finished');
    });
  });
}
