import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/role_permission.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import 'package:replay_engine/replay/replay_hash_calculator.dart';
import 'package:kendo_os/core/time/system_time_source.dart';
import '../helpers/test_match_factory.dart';

void main() {
  group('Phase 2: Replay Deterministic 完全化', () {
    late KendoRuleEngine engine;
    late PermissionService permission;
    late SystemTimeSource timeSource;
    late AddScoreUseCase addScoreUseCase;
    late UndoScoreUseCase undoScoreUseCase;
    final testUser = const User(id: 'test_user', role: Role.admin, organizationId: 'test_org');
    final rule = const MatchRule();

    setUp(() {
      engine = KendoRuleEngine();
      permission = PermissionService();
      timeSource = SystemTimeSource();
      addScoreUseCase = AddScoreUseCase(engine, permission, timeSource);
      undoScoreUseCase = UndoScoreUseCase(engine, permission, timeSource);
    });

    ScoreEvent createEvent(String id, Side side, PointType type, int clock, DateTime time) {
      return ScoreEventLegacyAdapter.fromLegacy(
        id: id,
        side: side,
        type: type,
        sequence: clock,
        userId: 'test_user',
      ).copyWith(logicalClock: clock, timestamp: time);
    }

    test('Step 2-3: Replay fuzz test - ランダム順序でのリプレイ（イベントソートの決定的確認）', () {
      final baseTime = DateTime(2025, 1, 1, 10, 0, 0).toUtc();
      final events = [
        createEvent('e1', Side.red, PointType.men, 1, baseTime.add(const Duration(seconds: 1))),
        createEvent('e2', Side.white, PointType.kote, 2, baseTime.add(const Duration(seconds: 2))),
        createEvent('e3', Side.red, PointType.doIdo, 3, baseTime.add(const Duration(seconds: 3))),
        createEvent('e4', Side.white, PointType.tsuki, 4, baseTime.add(const Duration(seconds: 4))),
        createEvent('e5', Side.red, PointType.men, 5, baseTime.add(const Duration(seconds: 5))), // 赤の勝ち
      ];

      // 真実の順序での投影を生成
      var matchTruth = TestMatchFactory.createIndividualMatch(id: 'match-fuzz');
      final sortedEvents = List<ScoreEvent>.from(events)..sort((a, b) => a.compareTo(b));
      matchTruth = matchTruth.copyWith(events: sortedEvents);
      final analysisTruth = engine.analyzeHistory(sortedEvents, matchTruth, rule);
      final projTruth = MatchProjectionMapper.toProjection(matchTruth, analysisTruth);
      final hashTruth = ReplayHashCalculator.calculate(projTruth);

      final random = Random(42);
      
      // 1000回シャッフルしてリプレイ
      for (int i = 0; i < 1000; i++) {
        final shuffledEvents = List<ScoreEvent>.from(events)..shuffle(random);
        
        // システム側でソートされることをシミュレート
        final resolvedEvents = List<ScoreEvent>.from(shuffledEvents)..sort((a, b) => a.compareTo(b));
        var matchReplay = matchTruth.copyWith(events: resolvedEvents);
        
        final analysisReplay = engine.analyzeHistory(resolvedEvents, matchReplay, rule);
        final projReplay = MatchProjectionMapper.toProjection(matchReplay, analysisReplay);
        final hashReplay = ReplayHashCalculator.calculate(projReplay);

        expect(hashReplay, hashTruth, reason: 'Iteration $i failed: hash mismatch');
      }
    });

    test('Step 2-4: Undo deterministic test - Undoが混ざった状態での決定性', () {
      final baseTime = DateTime(2025, 1, 1, 10, 0, 0).toUtc();
      var matchTruth = TestMatchFactory.createIndividualMatch(id: 'match-undo');
      
      // イベント生成とUndo
      final e1 = createEvent('e1', Side.red, PointType.men, 1, baseTime.add(const Duration(seconds: 1)));
      matchTruth = addScoreUseCase.execute(testUser, matchTruth, e1, rule);
      
      final e2 = createEvent('e2', Side.white, PointType.kote, 2, baseTime.add(const Duration(seconds: 2)));
      matchTruth = addScoreUseCase.execute(testUser, matchTruth, e2, rule);
      
      matchTruth = undoScoreUseCase.execute(testUser, matchTruth, rule); // e2を取り消す

      final e3 = createEvent('e3', Side.red, PointType.men, 4, baseTime.add(const Duration(seconds: 4)));
      matchTruth = addScoreUseCase.execute(testUser, matchTruth, e3, rule); // 赤の勝ち

      final analysisTruth = engine.analyzeHistory(matchTruth.events, matchTruth, rule);
      final projTruth = MatchProjectionMapper.toProjection(matchTruth, analysisTruth);
      final hashTruth = ReplayHashCalculator.calculate(projTruth);

      final random = Random(123);
      final allEvents = List<ScoreEvent>.from(matchTruth.events);

      for (int i = 0; i < 1000; i++) {
        final shuffledEvents = List<ScoreEvent>.from(allEvents)..shuffle(random);
        
        final resolvedEvents = List<ScoreEvent>.from(shuffledEvents)..sort((a, b) => a.compareTo(b));
        var matchReplay = matchTruth.copyWith(events: resolvedEvents);
        
        final analysisReplay = engine.analyzeHistory(resolvedEvents, matchReplay, rule);
        final projReplay = MatchProjectionMapper.toProjection(matchReplay, analysisReplay);
        final hashReplay = ReplayHashCalculator.calculate(projReplay);

        expect(hashReplay, hashTruth, reason: 'Undo Iteration $i failed: hash mismatch');
      }
    });
  });
}