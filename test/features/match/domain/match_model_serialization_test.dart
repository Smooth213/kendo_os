import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🛡️ MatchModel Serialization (JS Interop Crash Prevention) Test', () {
    test('✅ 1. ScoreEventListConverter が Dart オブジェクトではなく純粋な Map を返すこと', () {
      const converter = ScoreEventListConverter();
      final events = [
        ScoreEvent(
          id: 'event_1',
          side: Side.red,
          strikeType: StrikeType.men,
          timestamp: DateTime(2026, 1, 1),
          userId: 'user_1',
          sequence: 1,
          logicalClock: 1,
        ),
      ];

      final jsonList = converter.toJson(events);

      expect(jsonList, isA<List<dynamic>>());
      // 最も重要なチェック：リストの中身が `ScoreEvent` ではなく純粋な `Map` になっているか
      // (JS Interop で converted Future エラーが起きる原因はここにある)
      for (final item in jsonList) {
        expect(item, isNot(isA<ScoreEvent>()));
        expect(item, isA<Map<String, dynamic>>());
      }
    });

    test('✅ 2. MatchSnapshotListConverter が深いネストを含めて純粋な Map を返すこと', () {
      const converter = MatchSnapshotListConverter();
      final snapshots = [
        MatchSnapshot(
          id: 'snap_1',
          matchId: 'match_1',
          version: 1,
          state: const MatchModel(
            id: 'm1',
            matchType: 'test',
            redName: '赤',
            whiteName: '白',
          ),
          createdAt: DateTime(2026, 1, 1),
          reason: 'test',
          events: [],
        ),
      ];

      final jsonList = converter.toJson(snapshots);

      expect(jsonList, isA<List<dynamic>>());
      for (final item in jsonList) {
        expect(item, isNot(isA<MatchSnapshot>()));
        expect(item, isA<Map<String, dynamic>>());

        // ネストされた state も純粋な Map になっているか確認
        final stateMap = item['state'];
        expect(stateMap, isA<Map<String, dynamic>>());
        expect(stateMap, isNot(isA<MatchModel>()));
      }
    });

    test('✅ 3. MatchModel.toJson() 全体でネストされたクラスインスタンスが一切残存しないこと', () {
      final match = MatchModel(
        id: 'match_1',
        matchType: 'test',
        redName: '赤',
        whiteName: '白',
        events: [
          ScoreEvent(
            id: 'event_1',
            side: Side.red,
            strikeType: StrikeType.men,
            timestamp: DateTime(2026, 1, 1),
            userId: 'user_1',
            sequence: 1,
            logicalClock: 1,
          ),
        ],
        snapshots: [
          MatchSnapshot(
            id: 'snap_1',
            matchId: 'match_1',
            version: 1,
            state: const MatchModel(
              id: 'm1',
              matchType: 'test',
              redName: '赤',
              whiteName: '白',
            ),
            createdAt: DateTime(2026, 1, 1),
            reason: 'test',
            events: [],
          ),
        ],
      );

      final json = match.toJson();

      // JS Interop / Firestore がクラッシュする原因は、Map/List のツリーの中に
      // カスタムクラス (ScoreEvent, MatchSnapshot, MatchModel) が混ざっていること。

      // イベントリストの確認
      expect(json['events'], isA<List<dynamic>>());
      expect(json['events'].first, isA<Map<String, dynamic>>());

      // スナップショットリストの確認
      expect(json['snapshots'], isA<List<dynamic>>());
      expect(json['snapshots'].first, isA<Map<String, dynamic>>());

      // スナップショット内の state (MatchModel) の確認
      expect(json['snapshots'].first['state'], isA<Map<String, dynamic>>());
    });

    test('✅ 4. pendingEvents も明示的に純粋な Map にシリアライズされること', () {
      // Arrange: 保存時にエラーとなった「pendingEvents にイベントが含まれている状態」を再現
      final event = ScoreEvent(
        id: 'test-event-1',
        side: Side.red,
        strikeType: StrikeType.men,
        timestamp: DateTime(2026, 1, 1),
        sequence: 1,
        logicalClock: 1,
        userId: 'test_user',
      );

      final match = MatchModel(
        id: 'test_match_1',
        tournamentId: 'test_tournament_1',
        matchType: '団体戦',
        category: '一般',
        groupName: '団体戦A',
        redName: '赤チーム',
        whiteName: '白チーム',
        events: [event],
        pendingEvents: [event], // ★ 以前 Web(PWA) 環境で保存クラッシュを引き起こした箇所
        status: 'in_progress',
        order: 1.0,
        rule: const MatchRule(),
      );

      // Act: JSONへのシリアライズを実行
      final json = match.toJson();

      // Assert: pendingEvents が純粋な Map になっていることを確認
      final pendingEventsJson = json['pendingEvents'] as List;
      expect(pendingEventsJson.isNotEmpty, isTrue);
      expect(pendingEventsJson.first, isA<Map<String, dynamic>>());
    });
  });
}
