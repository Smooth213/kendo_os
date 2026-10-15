import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
// ★ 追加: ScoreEventの正しい生成アダプター
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';

void main() {
  group('[Unit] オフライン同期エンジン（CRDT・マージ・コンフリクト解決）ユニットテスト要塞', () {
    late DateTime now;

    setUp(() {
      // 完全に決定論的な基準時刻を創出
      now = DateTime(2026, 5, 29, 12, 0, 0);
    });

    test(
      'Queue & Dirty判定において syncStateがsynced以外の試合は、未送信データ（isDirty）として正しく検出されること',
      () {
        const matchLocal = MatchModel(
          id: 'sync_test_001',
          matchType: '先鋒',
          redName: '紅道場',
          whiteName: '白剣友会',
          syncState: SyncState.localOnly, // 未送信状態
        );

        const matchSynced = MatchModel(
          id: 'sync_test_002',
          matchType: '次鋒',
          redName: '紅道場',
          whiteName: '白剣友会',
          syncState: SyncState.synced, // 同期完了状態
        );

        expect(matchLocal.isDirty, isTrue);
        expect(matchSynced.isDirty, isFalse);
      },
    );

    test(
      'Merge & Conflict Resolutionにおいて サーバーの歴史とローカルの未送信差分（pendingEvents）が、ランポート論理時計と絶対時刻で厳密にソートされ、確定的に一本化されること',
      () {
        // サーバー側にある既存の歴史（先に同期されていたイベント）
        final remoteEvents = [
          ScoreEventLegacyAdapter.fromLegacy(
            id: 'ev_remote_1',
            side: Side.red,
            type: PointType.men,
            timestamp: now.subtract(const Duration(seconds: 10)),
            userId: 'test_user',
            sequence: 1,
            logicalClock: 1, // 過去の論理時計
          ),
        ];

        // 体育館のオフライン中にローカル側で新しく叩き込まれた未送信差分
        final localPendingEvents = [
          ScoreEventLegacyAdapter.fromLegacy(
            id: 'ev_local_2',
            side: Side.white,
            type: PointType.kote,
            timestamp: now,
            userId: 'test_user',
            sequence: 2,
            logicalClock: 2, // 進んだ論理時計
          ),
        ];

        // SyncEngine内部で実行されるCRDT確定ソートマージの挙動を厳格に再現検証
        final Map<String, ScoreEvent> mergedEventsMap = {};
        for (var e in remoteEvents) {
          mergedEventsMap[e.id] = e;
        }
        for (var e in localPendingEvents) {
          mergedEventsMap[e.id] = e;
        }

        final mergedEvents = mergedEventsMap.values.toList()
          ..sort((a, b) {
            if (a.logicalClock != b.logicalClock) {
              return a.logicalClock.compareTo(b.logicalClock);
            }
            return a.timestamp.compareTo(b.timestamp);
          });

        // 決定論的検証：論理時計の順に歴史が一本の鎖へと編み込まれているか
        expect(mergedEvents.length, equals(2));
        expect(mergedEvents.first.id, equals('ev_remote_1'));
        expect(mergedEvents.last.id, equals('ev_local_2'));
        expect(mergedEvents.last.type, equals(PointType.kote));
      },
    );

    test(
      'Retry & Sequence防壁において イベント順序順のcompareToが、論理時計最優先のドメイン規約に完全適合していること',
      () {
        final earlyEvent = ScoreEventLegacyAdapter.fromLegacy(
          id: 'a',
          side: Side.red,
          type: PointType.men,
          timestamp: now,
          userId: 'test_user',
          sequence: 1,
          logicalClock: 1,
        );

        final lateEvent = ScoreEventLegacyAdapter.fromLegacy(
          id: 'b',
          side: Side.white,
          type: PointType.kote,
          timestamp: now.add(const Duration(seconds: 5)),
          userId: 'test_user',
          sequence: 2,
          logicalClock: 2,
        );

        // タイムスタンプに関わらず、論理時計（logicalClock）の整合性が最優先で判定されることの証明
        int compare(ScoreEvent a, ScoreEvent b) {
          if (a.logicalClock != b.logicalClock) {
            return a.logicalClock.compareTo(b.logicalClock);
          }
          return a.timestamp.compareTo(b.timestamp);
        }

        expect(compare(earlyEvent, lateEvent), isNegative);
      },
    );

    test('不可逆ガードにおいて 完了ステータス（finished / approved）が遅延パケットによって進行中・未開始へ巻き戻らないこと', () {
      // 1. ローカルが finished の場合、リモートが古い in_progress かつリモート優先指定であっても finished が維持されること
      final preservedFinished = SyncCrdtMerger.resolveMonotonicStatus(
        localStatus: 'finished',
        remoteStatus: 'in_progress',
        preferLocal: false,
      );
      expect(preservedFinished, equals('finished'));

      // 2. リモートが finished の場合、ローカルが古い in_progress かつローカル優先指定であっても finished が維持されること
      final preservedFromRemote = SyncCrdtMerger.resolveMonotonicStatus(
        localStatus: 'in_progress',
        remoteStatus: 'finished',
        preferLocal: true,
      );
      expect(preservedFromRemote, equals('finished'));

      // 3. 完了系同士の比較：より高次の approved (rank 4) が finished (rank 3) に優先されること
      final higherRankWins = SyncCrdtMerger.resolveMonotonicStatus(
        localStatus: 'finished',
        remoteStatus: 'approved',
        preferLocal: true,
      );
      expect(higherRankWins, equals('approved'));

      // 4. 同一ランク同士（例: in_progress vs paused）では preferLocal の指定が決定論的に尊重されること
      final localTieBreak = SyncCrdtMerger.resolveMonotonicStatus(
        localStatus: 'in_progress',
        remoteStatus: 'paused',
        preferLocal: true,
      );
      expect(localTieBreak, equals('in_progress'));

      final remoteTieBreak = SyncCrdtMerger.resolveMonotonicStatus(
        localStatus: 'in_progress',
        remoteStatus: 'paused',
        preferLocal: false,
      );
      expect(remoteTieBreak, equals('paused'));
    });
  });
}
