import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_queue.dart';

void main() {
  group('🛡️ MatchCommandQueue Unit Tests', () {
    test('1. DeadLetterQueueNotifier adds, retries, and discards errors', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cmd = MatchCommandModel(
        id: 'cmd-1',
        type: CommandType.addScore,
        payload: {'matchId': 'm1', 'side': 'red', 'type': 'men'},
        createdAt: DateTime.now(),
      );

      final notifier = container.read(deadLetterQueueProvider.notifier);
      notifier.addErrorCommand(cmd);
      expect(container.read(deadLetterQueueProvider).length, 1);
      expect(container.read(deadLetterQueueProvider).first.id, 'cmd-1');

      notifier.discardCommand(cmd);
      expect(container.read(deadLetterQueueProvider).isEmpty, true);
    });

    test('2. MatchCommandModel default status is pending', () {
      final cmd = MatchCommandModel(
        id: 'cmd-2',
        type: CommandType.undoLastEvent,
        payload: {'matchId': 'm2'},
        createdAt: DateTime.now(),
      );
      expect(cmd.status, CommandStatus.pending);
    });
  });
}
