import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/sync/pending_sync_queue.dart';

void main() {
  group('[Unit] 未同期オフラインキューおよびFIFO順序保存テスト', () {
    test('初期状態においてキューが空であり安全にnullを返すこと', () {
      final queue = PendingSyncQueue<Map<String, dynamic>>();

      expect(queue.isEmpty, isTrue);
      expect(queue.pendingCount, equals(0));
      expect(queue.peek, isNull);

      // 空キューに対するデキュー呼び出しで例外が発生しないこと
      expect(() => queue.dequeue(), returnsNormally);
      expect(queue.isEmpty, isTrue);
    });

    test('複数タスク登録時に先入れ先出しの順序が厳格に維持されること', () {
      final queue = PendingSyncQueue<String>();

      queue.enqueue('sync_task_alpha', 'payload_alpha');
      queue.enqueue('sync_task_beta', 'payload_beta');
      queue.enqueue('sync_task_gamma', 'payload_gamma');

      expect(queue.isEmpty, isFalse);
      expect(queue.pendingCount, equals(3));

      // 1件目の参照と取り出し
      final task1 = queue.peek;
      expect(task1, isNotNull);
      expect(task1!.taskId, equals('sync_task_alpha'));
      expect(task1.data, equals('payload_alpha'));
      queue.dequeue();
      expect(queue.pendingCount, equals(2));

      // 2件目の参照と取り出し
      final task2 = queue.peek;
      expect(task2, isNotNull);
      expect(task2!.taskId, equals('sync_task_beta'));
      expect(task2.data, equals('payload_beta'));
      queue.dequeue();
      expect(queue.pendingCount, equals(1));

      // 3件目の参照と取り出し
      final task3 = queue.peek;
      expect(task3, isNotNull);
      expect(task3!.taskId, equals('sync_task_gamma'));
      expect(task3.data, equals('payload_gamma'));
      queue.dequeue();
      expect(queue.pendingCount, equals(0));

      expect(queue.isEmpty, isTrue);
      expect(queue.peek, isNull);
    });

    test('キュー初期化メソッドにより全タスクが一括クリアされ原状復帰すること', () {
      final queue = PendingSyncQueue<int>();

      queue.enqueue('t1', 100);
      queue.enqueue('t2', 200);
      expect(queue.pendingCount, equals(2));

      queue.clear();
      expect(queue.isEmpty, isTrue);
      expect(queue.pendingCount, equals(0));
      expect(queue.peek, isNull);
    });
  });
}
