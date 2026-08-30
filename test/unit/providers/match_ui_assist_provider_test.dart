import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_ui_assist_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MatchUIAssistProvider Tests', () {
    test('isMatchViewFlippedProvider のトグル動作が正常であること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const matchId = 'test_match_1';

      // 初期値は false (正面視点: 赤が左、白が右)
      expect(container.read(isMatchViewFlippedProvider(matchId)), false);

      // トグル -> true (逆サイド視点: 白が左、赤が右)
      container.read(isMatchViewFlippedProvider(matchId).notifier).state = true;
      expect(container.read(isMatchViewFlippedProvider(matchId)), true);

      // 再度トグル -> false
      container.read(isMatchViewFlippedProvider(matchId).notifier).state =
          false;
      expect(container.read(isMatchViewFlippedProvider(matchId)), false);
    });

    test('pendingSmartUndoProvider へのイベント登録と手動クリアが正常に動作すること', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const matchId = 'test_match_2';
      final notifier = container.read(
        pendingSmartUndoProvider(matchId).notifier,
      );

      // 初期値は null
      expect(container.read(pendingSmartUndoProvider(matchId)), isNull);

      final event = ScoreEvent(
        id: 'ev_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: DateTime.now(),
      );

      // イベント登録
      notifier.registerEvent(event);
      final state = container.read(pendingSmartUndoProvider(matchId));
      expect(state, isNotNull);
      expect(state!.event.side, Side.red);
      expect(state.event.type, PointType.men);

      // 手動クリア
      notifier.clear();
      expect(container.read(pendingSmartUndoProvider(matchId)), isNull);
    });
  });
}
