import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';

void main() {
  group('🛡️ Bunaiksen Infinite Queue Notifier Verification Tests', () {
    late ProviderContainer container;
    late BunaiksenInfiniteQueueNotifier queueNotifier;

    setUp(() {
      container = ProviderContainer();
      queueNotifier = container.read(bunaiksenInfiniteQueueProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Initial queue state is empty', () {
      final state = container.read(bunaiksenInfiniteQueueProvider);
      expect(state, isEmpty);
    });

    test(
      '2. Adding players appends them to the end and prevents duplicates',
      () {
        queueNotifier.addPlayer('山田 太郎');
        expect(container.read(bunaiksenInfiniteQueueProvider), ['山田 太郎']);

        queueNotifier.addPlayer('佐藤 次郎');
        expect(container.read(bunaiksenInfiniteQueueProvider), [
          '山田 太郎',
          '佐藤 次郎',
        ]);

        // Attempt duplicate addition
        queueNotifier.addPlayer('山田 太郎');
        expect(container.read(bunaiksenInfiniteQueueProvider), [
          '山田 太郎',
          '佐藤 次郎',
        ]);
      },
    );

    test(
      '3. Removing players (leaving) removes them without disturbing other players\' order',
      () {
        queueNotifier.setPlayers(['山田', '佐藤', '田中', '鈴木']);

        // '田中' leaves the queue
        queueNotifier.removePlayer('田中');
        expect(container.read(bunaiksenInfiniteQueueProvider), [
          '山田',
          '佐藤',
          '鈴木',
        ]);

        // '山田' (front) leaves the queue
        queueNotifier.removePlayer('山田');
        expect(container.read(bunaiksenInfiniteQueueProvider), ['佐藤', '鈴木']);
      },
    );

    test('4. Moving a player to the last position preserves other orders', () {
      queueNotifier.setPlayers(['山田', '佐藤', '田中', '鈴木']);

      queueNotifier.moveToLast('佐藤');
      expect(container.read(bunaiksenInfiniteQueueProvider), [
        '山田',
        '田中',
        '鈴木',
        '佐藤',
      ]);
    });

    test('5. Shuffling the queue preserves all elements and count', () {
      final originalList = ['山田', '佐藤', '田中', '鈴木', '高橋'];
      queueNotifier.setPlayers(originalList);

      queueNotifier.shuffle();
      final shuffledList = container.read(bunaiksenInfiniteQueueProvider);

      expect(shuffledList.length, originalList.length);
      expect(shuffledList, containsAll(originalList));
    });

    test('6. Reordering via Drag and Drop works correctly for both directions', () {
      // Yamada (0), Sato (1), Tanaka (2), Suzuki (3)
      queueNotifier.setPlayers(['山田', '佐藤', '田中', '鈴木']);

      // Drag downwards: Yamada (index 0) to after Tanaka (index 2) -> should insert Yamada at index 2
      queueNotifier.reorder(
        0,
        3,
      ); // Flutter ReorderableListView signature: newIndex is after target slot
      expect(container.read(bunaiksenInfiniteQueueProvider), [
        '佐藤',
        '田中',
        '山田',
        '鈴木',
      ]);

      // Drag upwards: Suzuki (index 3) to before Sato (index 0) -> should insert Suzuki at index 0
      queueNotifier.reorder(3, 0);
      expect(container.read(bunaiksenInfiniteQueueProvider), [
        '鈴木',
        '佐藤',
        '田中',
        '山田',
      ]);
    });

    test('7. PopFirst retrieves and removes the front player', () {
      queueNotifier.setPlayers(['山田', '佐藤', '田中']);

      final first = queueNotifier.popFirst();
      expect(first, '山田');
      expect(container.read(bunaiksenInfiniteQueueProvider), ['佐藤', '田中']);

      final second = queueNotifier.popFirst();
      expect(second, '佐藤');
      expect(container.read(bunaiksenInfiniteQueueProvider), ['田中']);

      final third = queueNotifier.popFirst();
      expect(third, '田中');
      expect(container.read(bunaiksenInfiniteQueueProvider), isEmpty);

      final fourth = queueNotifier.popFirst();
      expect(fourth, isNull);
    });
  });
}
