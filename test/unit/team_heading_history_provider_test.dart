import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_heading_history_provider.dart';

void main() {
  group('[Unit] TeamHeadingHistoryProvider Tests', () {
    test('チームごとの履歴が独立して保持されること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(teamHeadingHistoryProvider.notifier);

      // 初期状態は空
      expect(notifier.getHistory('team_a'), isNull);

      // Team A の設定を記録: 第1試合場, 1試合目
      notifier.recordHeading(teamId: 'team_a', courtNumber: 1, matchOrder: 1);

      // Team B の設定を記録: 第2試合場, 3試合目
      notifier.recordHeading(teamId: 'team_b', courtNumber: 2, matchOrder: 3);

      // それぞれ正しく分離されて取得できること
      final historyA = notifier.getHistory('team_a');
      expect(historyA?.courtNumber, 1);
      expect(historyA?.lastMatchOrder, 1);

      final historyB = notifier.getHistory('team_b');
      expect(historyB?.courtNumber, 2);
      expect(historyB?.lastMatchOrder, 3);

      // 未知のチームの場合はグローバルデフォルト（直近の記録: Team Bの内容）が返ること
      final historyUnknown = notifier.getHistory('team_c');
      expect(historyUnknown?.courtNumber, 2);
      expect(historyUnknown?.lastMatchOrder, 3);
    });
  });
}
