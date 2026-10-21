import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/domain/entities/role_permission.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[Unit] 試合終了（Time-Up）＆有効打突（Strike）ミリ秒衝突 決定論的調停テスト', () {
    test('試合終了ブザーと打突入力が±50ms以内で衝突した際、論理タイムスタンプ順序に基づき決定論的に調停されること', () {
      final engine = KendoRuleEngine();
      final permission = PermissionService();
      final timeSource = SystemTimeSource();
      final addScoreUseCase = AddScoreUseCase(engine, permission, timeSource);
      final timeUpUseCase = TimeUpUseCase(engine, permission, timeSource);

      const scorerUser = User(
        id: 'scorer-1',
        role: Role.scorer,
        organizationId: 'org-1',
      );

      final now = DateTime(2026, 10, 2, 10, 3, 0);

      // 初期試合状態: 3分経過寸前（同点 0-0）
      final activeMatch = MatchModel(
        id: 'collision_match_01',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'in_progress',
        redScore: 0,
        whiteScore: 0,
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );

      // ケースA: ブザー直前（-20ms）に打突判定が成立していた場合 -> 打突が有効となり1-0で勝敗確定
      final strikeJustBefore = ScoreEvent(
        id: 'strike_ev_01',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now.subtract(const Duration(milliseconds: 20)),
        sequence: 1,
      );

      final matchWithStrike = activeMatch.copyWith(
        events: [strikeJustBefore],
        redScore: 1,
      );

      // その後タイムアップ処理を実行
      final resultAfterTimeUp = timeUpUseCase.execute(
        scorerUser,
        matchWithStrike,
        false, // 延長なし
        const MatchRule(),
      );

      expect(resultAfterTimeUp.redScore, 1);
      expect(resultAfterTimeUp.status, 'finished');

      // ケースB: ブザー確定後に打突判定が届いた場合 -> 既に終了状態であるためスコア加算が弾かれるか決定論的に調停される
      final lateStrike = ScoreEvent(
        id: 'late_strike_ev',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now.add(const Duration(milliseconds: 50)),
      );

      expect(
        () => addScoreUseCase.execute(
          scorerUser,
          resultAfterTimeUp,
          lateStrike,
          const MatchRule(),
        ),
        throwsA(isA<DomainException>()),
      );
    });
  });
}
