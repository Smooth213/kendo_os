import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_entity_mapper.dart';

void main() {
  group('[Unit] LocalMatchEntityMapper テスト', () {
    test('eventToEntity & entityToEvent correctly converts ScoreEventこと', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);
      final event = ScoreEvent(
        id: 'ev-1',
        side: Side.red,
        strikeType: StrikeType.men,
        timestamp: now,
        userId: 'user-1',
        sequence: 1,
        isUndo: false,
        isRestore: false,
        deviceId: 'device-1',
        logicalClock: 42,
        signature: 'sig-abc',
      );

      final entity = LocalMatchEntityMapper.eventToEntity(event);
      expect(entity.id, 'ev-1');
      expect(entity.side, Side.red);
      expect(entity.type, PointType.men);
      expect(entity.timestamp, now);
      expect(entity.userId, 'user-1');
      expect(entity.sequence, 1);
      expect(entity.logicalClock, 42);
      expect(entity.signature, 'sig-abc');

      final restoredEvent = LocalMatchEntityMapper.entityToEvent(entity);
      expect(restoredEvent.id, event.id);
      expect(restoredEvent.side, Side.red);
      expect(restoredEvent.strikeType, StrikeType.men);
      expect(restoredEvent.sequence, event.sequence);
      expect(restoredEvent.logicalClock, event.logicalClock);
      expect(restoredEvent.signature, event.signature);
    });

    test(
      '双方向変換において toEntityおよびtoModelによりsnapshots and events付きのMatchModelが正しく変換されること',
      () {
        final now = DateTime(2026, 9, 3, 11, 0, 0);
        final model = MatchModel(
          id: 'match-100',
          matchType: 'individual',
          redName: '選手赤',
          whiteName: '選手白',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          events: [
            ScoreEvent(
              id: 'ev-1',
              side: Side.red,
              strikeType: StrikeType.men,
              timestamp: now,
              userId: 'user-1',
            ),
          ],
          tournamentId: 'tour-1',
          category: '一般男子',
          groupName: 'A',
          matchOrder: 1,
          matchTimeMinutes: 4,
        );

        final entity = LocalMatchEntityMapper.toEntity(model);
        expect(entity.firestoreId, 'match-100');
        expect(entity.redName, '選手赤');
        expect(entity.whiteName, '選手白');
        expect(entity.redScore, 2);
        expect(entity.whiteScore, 1);
        expect(entity.events.length, 1);

        final restoredModel = LocalMatchEntityMapper.toModel(entity);
        expect(restoredModel.id, 'match-100');
        expect(restoredModel.redName, '選手赤');
        expect(restoredModel.whiteName, '選手白');
        expect(restoredModel.redScore, 2);
        expect(restoredModel.whiteScore, 1);
        expect(restoredModel.events.length, 1);
        expect(restoredModel.events.first.strikeType, StrikeType.men);
      },
    );

    test('勝ち抜き戦プロパティおよびMatchRuleのJSONシリアライズ双方向変換が完全一致すること', () {
      final rule = MatchRule(
        matchTimeMinutes: 5.0,
        hasHantei: true,
        enchoTimeMinutes: 3.0,
        enchoCount: 2,
        isKachinuki: true,
      );

      final model = MatchModel(
        id: 'kachinuki-1',
        matchType: 'team',
        redName: '東軍',
        whiteName: '西軍',
        isKachinuki: true,
        redRemaining: ['選手A', '選手B'],
        whiteRemaining: <String>[],
        status: 'finished',
        rule: rule,
      );

      final entity = LocalMatchEntityMapper.toEntity(model);
      expect(entity.isKachinuki, isTrue);
      expect(entity.redRemaining, ['選手A', '選手B']);
      expect(entity.whiteRemaining, isEmpty);
      expect(entity.ruleJson, isNotNull);

      final restored = LocalMatchEntityMapper.toModel(entity);
      expect(restored.id, 'kachinuki-1');
      expect(restored.isKachinuki, isTrue);
      expect(restored.redRemaining, ['選手A', '選手B']);
      expect(restored.whiteRemaining, isEmpty);
      expect(restored.rule, isNotNull);
      expect(restored.rule!.matchTimeMinutes, 5.0);
      expect(restored.rule!.hasHantei, isTrue);
      expect(restored.rule!.enchoTimeMinutes, 3.0);
      expect(restored.rule!.enchoCount, 2);
    });
  });
}
