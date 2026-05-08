import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import '../helpers/test_match_factory.dart';

void main() {
  group('📼 Phase 0-3: Event Replay Snapshot (履歴の完全再生比較)', () {
    test('100試合のランダムイベントを処理し、最終状態のチェックサムが一致すること', () {
      final engine = KendoRuleEngine();
      final permission = PermissionService();
      final addScoreUseCase = AddScoreUseCase(engine, permission);
      final undoScoreUseCase = UndoScoreUseCase(engine, permission);
      final testUser = const User(id: 'snapshot_user', role: Role.admin, organizationId: 'test_org');
      final rule = const MatchRule();

      // 固定シード(42)を使用することで、何度実行しても「全く同じ100試合の歴史」が生成される
      final random = Random(42); 
      
      int totalRedScoreChecksum = 0;
      int totalWhiteScoreChecksum = 0;
      int totalFinishedMatches = 0;

      for (int i = 0; i < 100; i++) {
        var match = TestMatchFactory.createIndividualMatch(id: 'replay-match-$i');
        final eventCount = random.nextInt(15) + 1; // 1〜15件のイベント

        for (int j = 0; j < eventCount; j++) {
          if (match.status == 'finished') break; // 終了していたら打ち切り

          final isUndo = random.nextDouble() < 0.1; // 10%でUndo
          if (isUndo && match.events.isNotEmpty) {
            match = undoScoreUseCase.execute(testUser, match, rule);
            continue;
          }

          final side = random.nextBool() ? Side.red : Side.white;
          final type = _randomPointType(random);
          
          final event = ScoreEventLegacyAdapter.fromLegacy(
            side: side, type: type, sequence: 0, userId: testUser.id,
          );

          match = addScoreUseCase.execute(testUser, match, event, rule);
        }

        totalRedScoreChecksum += match.redScore;
        totalWhiteScoreChecksum += match.whiteScore;
        if (match.status == 'finished') totalFinishedMatches++;
      }

      // ★ すべての真実のチェックサムを出力して確認する
      debugPrint('★★★ 真実のチェックサム ★★★');
      debugPrint('Red: $totalRedScoreChecksum');
      debugPrint('White: $totalWhiteScoreChecksum');
      debugPrint('Finished: $totalFinishedMatches');

      // ★ 判明した真実のチェックサムを完全固定（FSM化後も絶対にこの数値にならなければならない）
      expect(totalRedScoreChecksum, 95, reason: '赤の総スコア合計(Checksum)が壊れています。リファクタリングによるデグレが発生しました。');
      expect(totalWhiteScoreChecksum, 132, reason: '白の総スコア合計(Checksum)が壊れています。リファクタリングによるデグレが発生しました。');
      expect(totalFinishedMatches, 88, reason: '終了した試合数(Checksum)が壊れています。リファクタリングによるデグレが発生しました。');
    });
  });
}

PointType _randomPointType(Random r) {
  final types = [PointType.men, PointType.kote, PointType.doIdo, PointType.tsuki, PointType.hansoku];
  return types[r.nextInt(types.length)];
}