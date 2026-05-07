import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
// ★ 修正: 古いヘルパーの代わりに、正しいSequenceを付与できるアダプターを使用する
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';

void main() {
  group('AddScoreUseCase - Event Driven Update', () {
    late KendoRuleEngine engine;
    late AddScoreUseCase usecase;
    late User testUser; // ★ 追加

    setUp(() {
      engine = KendoRuleEngine();
      final permission = PermissionService(); // ★ 関所を追加
      usecase = AddScoreUseCase(engine, permission); // ★ 引数追加
      testUser = const User(id: 'test_user', role: Role.admin, organizationId: 'test_org'); 
    });

    test('イベントを追加するとMatchModelのeventsとscoreが更新されること', () {
      final initialMatch = MatchModel( 
        id: 'test', tournamentId: 't1', matchOrder: 1,
        redName: 'Red', whiteName: 'White',
        status: 'in_progress', matchType: '個人戦',
        remainingSeconds: 180,
      );

      // ★ 修正: 競合チェックを通過するため、期待される sequence (空の状態に対しては 1) を明示する
      final newEvent = ScoreEventLegacyAdapter.fromLegacy(
        side: Side.red,
        type: PointType.men,
        sequence: 1,
        userId: testUser.id,
      );
      final rule = const MatchRule();

      final updatedMatch = usecase.execute(testUser, initialMatch, newEvent, rule);

      expect(updatedMatch.events.length, 1);
      expect(updatedMatch.events.first.strikeType, StrikeType.men);
      expect(updatedMatch.redScore, 1);
    });
  });
}