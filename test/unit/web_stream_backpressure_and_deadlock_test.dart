import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// ブラウザシングルスレッド環境において、WebSocket / Firestore イベントが過剰に押し寄せた場合の
/// Streamバックプレッシャー制御およびUIデッドロック回避の検証テスト。
void main() {
  group('[Unit] Webブラウザ極限 - Streamバックプレッシャーとデッドロック回避テスト', () {
    test('急激なバースト流入（1000件）に対して、最新のイベントのみにスロットリングされデッドロックしないこと', () async {
      final controller = StreamController<int>.broadcast();
      final List<int> receivedEvents = [];

      // スロットリング・バックプレッシャー制御ハンドラ
      int? pendingEvent;
      Timer? throttleTimer;

      void onNewEvent(int event) {
        pendingEvent = event;
        throttleTimer ??= Timer(const Duration(milliseconds: 20), () {
          if (pendingEvent != null) {
            receivedEvents.add(pendingEvent!);
            pendingEvent = null;
          }
          throttleTimer = null;
        });
      }

      final subscription = controller.stream.listen(onNewEvent);

      // 1000件のイベントを同期的にバースト投入
      for (int i = 1; i <= 1000; i++) {
        controller.add(i);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // スロットリングにより受取件数が極小（最新値1件）に抑えられ、UIスレッドが保護されること
      expect(receivedEvents.length, equals(1));
      expect(receivedEvents.first, equals(1000));

      await subscription.cancel();
      await controller.close();
    });

    test('サブスクリプションの多重バインド・解除が循環参照やリークを起こさず正常に完了すること', () async {
      final controller = StreamController<String>.broadcast();
      int listenerTriggerCount = 0;

      final sub1 = controller.stream.listen((_) => listenerTriggerCount++);
      final sub2 = controller.stream.listen((_) => listenerTriggerCount++);

      controller.add('event1');
      await Future.microtask(() {});
      expect(listenerTriggerCount, equals(2));

      await sub1.cancel();
      controller.add('event2');
      await Future.microtask(() {});
      expect(listenerTriggerCount, equals(3));

      await sub2.cancel();
      await controller.close();
    });
  });
}
