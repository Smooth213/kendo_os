import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  group('[Unit] マルチテナント・道場切り替え時データ完全隔離テスト', () {
    test('道場ID（Tenant）変更時に前道場のゲスト選手一覧やキューがパージされ新道場データへクリーンに切り替わること', () async {
      final container = ProviderContainer(
        overrides: [currentDojoIdProvider.overrideWith((ref) => 'dojo_A')],
      );
      addTearDown(container.dispose);

      // 道場Aでのキュー状態
      final queueNotifier = container.read(
        bunaiksenInfiniteQueueProvider.notifier,
      );
      queueNotifier.setPlayers(['道場A_選手1', '道場A_選手2']);
      expect(container.read(bunaiksenInfiniteQueueProvider), [
        '道場A_選手1',
        '道場A_選手2',
      ]);

      // 連勝カウンター状態
      final streakNotifier = container.read(
        bunaiksenInfiniteStreakProvider.notifier,
      );
      streakNotifier.incrementStreak('道場A_選手1');
      expect(container.read(bunaiksenInfiniteStreakProvider)['道場A_選手1'], 1);

      // 道場Bへテナント切り替えシミュレーション
      final containerB = ProviderContainer(
        overrides: [currentDojoIdProvider.overrideWith((ref) => 'dojo_B')],
      );
      addTearDown(containerB.dispose);

      // 道場Bでは道場Aの選手・連勝キャッシュが一切存在しないこと
      final queueB = containerB.read(bunaiksenInfiniteQueueProvider);
      final streakB = containerB.read(bunaiksenInfiniteStreakProvider);

      expect(queueB.contains('道場A_選手1'), isFalse);
      expect(streakB.containsKey('道場A_選手1'), isFalse);
      expect(queueB, isEmpty);
      expect(streakB, isEmpty);
    });
  });
}
