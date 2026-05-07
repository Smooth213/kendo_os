import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import '../helpers/test_match_factory.dart';

void main() {
  group('🌪️ Phase 3-2: シミュレーションテスト (同時操作・競合の検証)', () {
    late AddScoreUseCase addScoreUseCase;

    setUp(() {
      // ★ 修正: エラーの通り、2つの引数（KendoRuleEngine, PermissionService）を渡す
      addScoreUseCase = AddScoreUseCase(KendoRuleEngine(), PermissionService());
    });

    test('【競合シミュレーション】AさんとBさんが同時にスコアを追加しようとした場合、古いバージョンに基づく更新は弾かれること', () async {
      // 1. 試合の初期状態（Version 0）
      final rule = const MatchRule(ipponLimit: 2, matchTimeMinutes: 3.0);
      final initialMatch = TestMatchFactory.createIndividualMatch(id: 'sim-match-1');
      
      // 2. 実行主体
      final userA = const User(id: 'user_A', role: Role.scorer, organizationId: 'org1');
      final userB = const User(id: 'user_B', role: Role.scorer, organizationId: 'org1');

      // 3. Aさんが「初期状態 (Version 0)」を読み込んだと仮定
      final stateSeenByA = initialMatch.copyWith(); 
      // ★ 修正: 使われていない stateSeenByB 変数を削除

      // 4. Aさんが先に「赤のメン」を入力してサーバーへ送信した（成功する）
      final eventA = ScoreEventLegacyAdapter.fromLegacy(
        side: Side.red, type: PointType.men, userId: userA.id, sequence: 1,
      );
      
      // Aさんの状態が正常に更新される
      final updatedMatchByA = addScoreUseCase.execute(userA, stateSeenByA, eventA, rule);
      
      // サーバー上の最新状態が A さんのもの（Version 1）に更新されたと仮定する
      final serverLatestMatch = updatedMatchByA;

      // 5. わずかに遅れて、Bさんが「白のコテ」を入力して送信した（BさんはVersion 0を元に操作している）
      final eventB = ScoreEventLegacyAdapter.fromLegacy(
        side: Side.white, type: PointType.kote, userId: userB.id, sequence: 1, // Bさんも自分をsequence: 1だと思っている
      );

      // Bさんの送信内容は、サーバー上の最新状態（Version 1）に対して適用されようとする
      // ここで、Sequence（バージョン）の不整合により例外が飛ぶはず
      expect(
        () => addScoreUseCase.execute(userB, serverLatestMatch, eventB, rule),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('競合'))),
        reason: '他人が既に更新した状態に対して、古いバージョンを元にした書き込みは「競合」として弾かれなければならない',
      );
    });
  });
}