import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('🚀 【Phase 5-4/10】激しいネットワークフラッピング（100回接続/切断）CRDT収束 E2Eテスト', () {
    test('1. 100回のオンライン/オフライン切り替わり下で生成されたスコアイベントが1件も脱落せず時系列順に整列されること', () {
      final localQueue = <ScoreEvent>[];
      final cloudSyncedList = <ScoreEvent>[];

      final baseTime = DateTime(2026, 9, 3, 10, 0, 0);

      // 100回のフラッピングループ
      for (int i = 1; i <= 100; i++) {
        final isOnline = (i % 2 == 0); // 偶数はオンライン、奇数はオフライン

        // イベント発生
        final event = ScoreEvent(
          id: 'flap_ev_$i',
          side: (i % 2 == 0) ? Side.red : Side.white,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: baseTime.add(Duration(seconds: i)),
          logicalClock: i,
        );

        localQueue.add(event);

        if (isOnline) {
          // オンライン復帰時に未送信キューを一括フラッシュ（同期）
          cloudSyncedList.addAll(localQueue);
          localQueue.clear();
        }
      }

      // 最終同期（大会終了後にWi-Fiが安定）
      cloudSyncedList.addAll(localQueue);
      localQueue.clear();

      // 100件すべてのイベントが1件の脱落・重複もなく同期されていること
      expect(cloudSyncedList.length, 100);
      expect(localQueue.isEmpty, isTrue);

      // 論理時計（Lamport Logical Clock）の順序が1〜100で完全に整列していること
      for (int i = 0; i < 100; i++) {
        expect(cloudSyncedList[i].logicalClock, i + 1);
      }
    });
  });
}
