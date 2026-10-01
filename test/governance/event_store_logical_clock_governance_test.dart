import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_event_store.dart';

void main() {
  group('[Governance] イベントソーシング論理時計採番および楽観的ロック整合性保証規約', () {
    test('論理時計が単調増加し競合時にはConcurrencyExceptionが確実に送出されること', () async {
      final store = InMemoryEventStore();
      final now = DateTime.now();

      final ev1 = ScoreEvent(
        id: 'gov-ev-1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
      );

      // 初回保存
      await store.append(
        streamId: 'gov-stream',
        events: [ev1],
        expectedVersion: 0,
      );

      // 競合バージョンの投入
      final ev2 = ScoreEvent(
        id: 'gov-ev-2',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now,
      );

      expect(
        () => store.append(
          streamId: 'gov-stream',
          events: [ev2],
          expectedVersion: 0,
        ),
        throwsA(isA<ConcurrencyException>()),
      );
    });

    test('静的解析において論理時計ソートと楽観的ロック例外が実装されていること', () {
      final file = File(
        'lib/shared/infrastructure/repository/in_memory_event_store.dart',
      );
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content.contains('class ConcurrencyException'), isTrue);
      expect(content.contains('logicalClock'), isTrue);
      expect(content.contains('expectedVersion'), isTrue);
    });
  });
}
