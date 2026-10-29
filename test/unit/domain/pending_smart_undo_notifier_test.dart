import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_ui_assist_provider.dart';

void main() {
  group('[Unit] PendingSmartUndoNotifier 単体テスト', () {
    testWidgets('registerEventによりイベントがセットされ5秒後に自動消滅すること', (tester) async {
      final notifier = PendingSmartUndoNotifier();
      final event = ScoreEvent(
        id: 'undo-event-1',
        side: Side.red,
        strikeType: StrikeType.men,
        timestamp: DateTime.now(),
      );

      notifier.registerEvent(event);
      expect(notifier.state, isNotNull);
      expect(notifier.state!.event.id, 'undo-event-1');

      // 4秒経過時点では維持
      await tester.pump(const Duration(seconds: 4));
      expect(notifier.state, isNotNull);

      // 5秒経過時点で自動消滅
      await tester.pump(const Duration(seconds: 1));
      expect(notifier.state, isNull);

      notifier.dispose();
    });

    testWidgets('5秒未満で新しいイベントが登録された際にタイマーが再設定されること', (tester) async {
      final notifier = PendingSmartUndoNotifier();
      final event1 = ScoreEvent(
        id: 'undo-event-1',
        side: Side.red,
        strikeType: StrikeType.men,
        timestamp: DateTime.now(),
      );
      final event2 = ScoreEvent(
        id: 'undo-event-2',
        side: Side.white,
        strikeType: StrikeType.kote,
        timestamp: DateTime.now(),
      );

      notifier.registerEvent(event1);
      await tester.pump(const Duration(seconds: 3));

      // 3秒後にevent2登録
      notifier.registerEvent(event2);
      expect(notifier.state!.event.id, 'undo-event-2');

      // さらに3秒経過（event1から6秒、event2から3秒）
      await tester.pump(const Duration(seconds: 3));
      expect(notifier.state, isNotNull);
      expect(notifier.state!.event.id, 'undo-event-2');

      // さらに2秒経過（event2から5秒で消滅）
      await tester.pump(const Duration(seconds: 2));
      expect(notifier.state, isNull);

      notifier.dispose();
    });

    testWidgets('clearにより即座に状態がnullになること', (tester) async {
      final notifier = PendingSmartUndoNotifier();
      final event = ScoreEvent(
        id: 'undo-event-clear',
        side: Side.white,
        strikeType: StrikeType.tsuki,
        timestamp: DateTime.now(),
      );

      notifier.registerEvent(event);
      expect(notifier.state, isNotNull);

      notifier.clear();
      expect(notifier.state, isNull);

      notifier.dispose();
    });
  });
}
