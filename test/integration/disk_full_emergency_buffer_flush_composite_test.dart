import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

/// 🥋 ディスク満杯・I/O障害時の緊急メモリ退避バッファおよびフラッシュ機構
class EmergencyPersistenceCoordinator {
  final Map<String, MatchModel> _persistedStorage = {};
  final Map<String, MatchModel> _emergencyBuffer = {};
  bool _isDiskFull = false;

  void simulateDiskFull() {
    _isDiskFull = true;
  }

  void recoverDiskSpace() {
    _isDiskFull = false;
  }

  bool get isDiskFull => _isDiskFull;
  int get bufferCount => _emergencyBuffer.length;
  int get persistedCount => _persistedStorage.length;

  Future<void> persistMatch(MatchModel match) async {
    if (_isDiskFull) {
      // ディスク満杯時は即座にインメモリ緊急バッファへ退避
      _emergencyBuffer[match.id] = match;
      return;
    }

    _persistedStorage[match.id] = match;
  }

  /// ディスク回復時の一括フラッシュ処理
  Future<int> flushEmergencyBuffer() async {
    if (_isDiskFull) {
      throw StateError('ディスク空き容量がまだ不足しています');
    }

    final count = _emergencyBuffer.length;
    for (final entry in _emergencyBuffer.entries) {
      _persistedStorage[entry.key] = entry.value;
    }
    _emergencyBuffer.clear();
    return count;
  }

  MatchModel? getMatch(String id) {
    return _emergencyBuffer[id] ?? _persistedStorage[id];
  }
}

void main() {
  group('[E2E] 打突入力中DiskFull退避および容量回復後フラッシュ複合テスト', () {
    test('試合進行中のディスク満杯障害時に緊急退避し容量回復後に完全フラッシュ同期されること', () async {
      final coordinator = EmergencyPersistenceCoordinator();

      MatchModel match = MatchModel(
        id: 'match_chaos_disk_full_01',
        organizationId: 'org_chaos',
        matchType: 'individual',
        redName: '佐々木 小次郎',
        whiteName: '宮本 武蔵',
        status: 'in_progress',
      );

      // 1. 通常状態での打突保存 (赤・面)
      final ev1 = ScoreEvent(
        id: 'ev1_men',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: DateTime.now(),
      );
      match = match.copyWith(events: [ev1], redScore: 1);
      await coordinator.persistMatch(match);

      expect(coordinator.isDiskFull, isFalse);
      expect(coordinator.persistedCount, 1);
      expect(coordinator.bufferCount, 0);
      expect(coordinator.getMatch(match.id)?.redScore, 1);

      // 2. ディスク満杯障害が発生
      coordinator.simulateDiskFull();

      // 3. 障害発生中に白が小手を決める (白・小手)
      final ev2 = ScoreEvent(
        id: 'ev2_kote',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: DateTime.now(),
      );
      match = match.copyWith(events: [...match.events, ev2], whiteScore: 1);
      await coordinator.persistMatch(match);

      // 4. さらに赤が胴を決める (赤・胴)
      final ev3 = ScoreEvent(
        id: 'ev3_dou',
        side: Side.red,
        strikeType: StrikeType.dou,
        isIppon: true,
        timestamp: DateTime.now(),
      );
      match = match.copyWith(
        events: [...match.events, ev3],
        redScore: 2,
        status: 'completed',
      );
      await coordinator.persistMatch(match);

      // 緊急バッファに安全退避されており、読み出しデータは最新であること
      expect(coordinator.isDiskFull, isTrue);
      expect(coordinator.bufferCount, 1);
      final bufferedMatch = coordinator.getMatch(match.id);
      expect(bufferedMatch, isNotNull);
      expect(bufferedMatch?.redScore, 2);
      expect(bufferedMatch?.whiteScore, 1);
      expect(bufferedMatch?.events.length, 3);
      expect(bufferedMatch?.status, 'completed');

      // 5. ディスク障害が解消（容量確保）
      coordinator.recoverDiskSpace();
      expect(coordinator.isDiskFull, isFalse);

      // 6. 緊急バッファから永続化ストレージへ一括フラッシュ
      final flushedCount = await coordinator.flushEmergencyBuffer();
      expect(flushedCount, 1);
      expect(coordinator.bufferCount, 0);

      // 永続化ストレージ上のデータが完全同期されていること
      final finalPersistedMatch = coordinator.getMatch(match.id);
      expect(finalPersistedMatch, isNotNull);
      expect(finalPersistedMatch?.redScore, 2);
      expect(finalPersistedMatch?.whiteScore, 1);
      expect(finalPersistedMatch?.events.length, 3);
      expect(finalPersistedMatch?.status, 'completed');
    });
  });
}
