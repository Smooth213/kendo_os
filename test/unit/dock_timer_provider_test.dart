import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/providers/dock_timer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('⏱️ DockTimerNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態は3分(180秒)のカウントダウンで停止中であること', () {
      final state = container.read(dockTimerProvider);
      expect(state.mode, DockTimerMode.countdown);
      expect(state.initialSeconds, 180);
      expect(state.remainingSeconds, 180);
      expect(state.isRunning, isFalse);
      expect(state.isFinished, isFalse);
      expect(state.formattedDisplay, '03:00');
      expect(state.progress, 1.0);
    });

    test('プリセット設定（5分=300秒）が正しく反映されること', () {
      final notifier = container.read(dockTimerProvider.notifier);
      notifier.setPreset(300);

      final state = container.read(dockTimerProvider);
      expect(state.initialSeconds, 300);
      expect(state.remainingSeconds, 300);
      expect(state.formattedDisplay, '05:00');
    });

    test('モード切替（ストップウォッチ ⇄ カウントダウン）が正しく動作すること', () {
      final notifier = container.read(dockTimerProvider.notifier);
      notifier.toggleMode();

      var state = container.read(dockTimerProvider);
      expect(state.mode, DockTimerMode.stopwatch);
      expect(state.elapsedSeconds, 0);
      expect(state.formattedDisplay, '00:00');

      notifier.toggleMode();
      state = container.read(dockTimerProvider);
      expect(state.mode, DockTimerMode.countdown);
    });

    test('秒数追加（+30秒）がカウントダウンに加算されること', () {
      final notifier = container.read(dockTimerProvider.notifier);
      notifier.addSeconds(30);

      final state = container.read(dockTimerProvider);
      expect(state.remainingSeconds, 210);
      expect(state.initialSeconds, 210);
      expect(state.formattedDisplay, '03:30');
    });

    test('スタート・一時停止・リセットが正しくステートを更新すること', () {
      final notifier = container.read(dockTimerProvider.notifier);
      notifier.start();

      var state = container.read(dockTimerProvider);
      expect(state.isRunning, isTrue);

      notifier.pause();
      state = container.read(dockTimerProvider);
      expect(state.isRunning, isFalse);

      notifier.reset();
      state = container.read(dockTimerProvider);
      expect(state.remainingSeconds, 180);
      expect(state.isRunning, isFalse);
    });
  });
}
