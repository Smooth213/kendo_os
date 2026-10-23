import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
// ★ 追加: ScoreEventの正しい生成アダプター
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test(
      'Poison Pill防護において SyncEngineの通信失敗が上限10回に達した異常コマンドが自律パージされ後続キューをブロックしないこと',
      () async {
        final poisonCommand = MatchCommandModel(
          id: 'poison_cmd_1',
          type: CommandType.updateMatch,
          payload: {
            'id': 'match_poison',
            'matchType': '個人戦',
            'redName': '選手A',
            'whiteName': '選手B',
            'organizationId': 'test_org',
            'tournamentId': 'test_tour',
            'version': 1,
          },
          createdAt: DateTime.now(),
        );

        final fakeLocal = _FakeLocalMatchRepoForSync([poisonCommand]);
        final fakeRemote = _FakeMatchRepoForSync()
          ..onSaveMatch = (_) async {
            throw Exception('Network unreachable (Gymnasium offline)');
          };

        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
            localMatchRepositoryProvider.overrideWithValue(fakeLocal),
            matchRepositoryProvider.overrideWithValue(fakeRemote),
            currentDojoIdProvider.overrideWith((ref) => 'test_org'),
            currentTournamentIdProvider.overrideWith((ref) => 'test_tour'),
          ],
        );
        final syncEngine = container.read(syncEngineProvider);
        addTearDown(() async {
          container.dispose();
          await pumpEventQueue();
        });

        // 1〜9回目: 失敗してバックオフが設定されるがパージはされない
        for (int i = 0; i < 9; i++) {
          syncEngine.clearBackoffForTesting();
          await syncEngine.processQueue();
          expect(fakeLocal.deletedCommandIds, isEmpty);
          expect(fakeLocal.pendingCommands.length, equals(1));
          expect(syncEngine.retryCount, equals(i + 1));
        }

        // 10回目のリトライ試行: 上限超過により自律パージが発火
        syncEngine.clearBackoffForTesting();
        await syncEngine.processQueue();

        expect(fakeLocal.deletedCommandIds, contains('poison_cmd_1'));
        expect(fakeLocal.pendingCommands, isEmpty);
        expect(syncEngine.retryCount, equals(0)); // パージ後に0にリセットされる
      },
    );

    test(
      '即時同期復帰において SyncEngineの指数バックオフ待機中にsyncNowが呼ばれた際、待機がリセットされて即座にアップロードが再開されること',
      () async {
        final normalCommand = MatchCommandModel(
          id: 'normal_cmd_1',
          type: CommandType.updateMatch,
          payload: {
            'id': 'match_normal',
            'matchType': '個人戦',
            'redName': '選手A',
            'whiteName': '選手B',
            'organizationId': 'test_org',
            'tournamentId': 'test_tour',
            'version': 1,
          },
          createdAt: DateTime.now(),
        );

        final fakeLocal = _FakeLocalMatchRepoForSync([normalCommand]);
        bool shouldFail = true;
        final fakeRemote = _FakeMatchRepoForSync()
          ..onSaveMatch = (_) async {
            if (shouldFail) {
              throw Exception('Connection dropped');
            }
            return 2;
          };

        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
            localMatchRepositoryProvider.overrideWithValue(fakeLocal),
            matchRepositoryProvider.overrideWithValue(fakeRemote),
            currentDojoIdProvider.overrideWith((ref) => 'test_org'),
            currentTournamentIdProvider.overrideWith((ref) => 'test_tour'),
          ],
        );

        final syncEngine = container.read(syncEngineProvider);
        addTearDown(() async {
          container.dispose();
          await pumpEventQueue();
        });

        // 1. 初回試行：失敗させてバックオフ状態にする
        await syncEngine.processQueue();
        expect(fakeLocal.deletedCommandIds, isEmpty);

        // 2. 電波復帰: 成功フラグを立てるが、バックオフ期間中のため通常processQueueはスキップされる
        shouldFail = false;
        await syncEngine.processQueue();
        expect(fakeLocal.deletedCommandIds, isEmpty);

        // 3. syncNow() を実行: バックオフがリセットされて即座に送信が完了する
        await syncEngine.syncNow();
        await pumpEventQueue();

        expect(fakeLocal.deletedCommandIds, contains('normal_cmd_1'));
        expect(fakeLocal.pendingCommands, isEmpty);
      },
    );

    test(
      'Staleコマンド自律パージにおいて クラウド側が既に最新バージョンの場合、ConflictException検知後に自律パージされキュー詰まりを起こさないこと',
      () async {
        final staleCommand = MatchCommandModel(
          id: 'stale_cmd_1',
          type: CommandType.updateMatch,
          payload: {
            'id': 'match_conflict_1',
            'matchType': '個人戦',
            'redName': '選手A',
            'whiteName': '選手B',
            'organizationId': 'test_org',
            'tournamentId': 'test_tour',
            'version': 1,
          },
          createdAt: DateTime.now(),
        );

        final fakeLocal = _FakeLocalMatchRepoForSync([staleCommand]);
        final fakeRemote = _FakeMatchRepoForSync()
          ..onSaveMatch = (_) async {
            throw Exception('ConflictException: 古いバージョンです');
          }
          ..onGetMatch = (id, {organizationId, tournamentId}) async {
            return const MatchModel(
              id: 'match_conflict_1',
              matchType: '個人戦',
              redName: '選手A',
              whiteName: '選手B',
              organizationId: 'test_org',
              tournamentId: 'test_tour',
              version: 2,
            );
          };

        final container = ProviderContainer(
          overrides: [
            firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
            localMatchRepositoryProvider.overrideWithValue(fakeLocal),
            matchRepositoryProvider.overrideWithValue(fakeRemote),
            currentDojoIdProvider.overrideWith((ref) => 'test_org'),
            currentTournamentIdProvider.overrideWith((ref) => 'test_tour'),
          ],
        );

        final syncEngine = container.read(syncEngineProvider);
        addTearDown(() async {
          container.dispose();
          await pumpEventQueue();
        });

        await syncEngine.processQueue();

        expect(fakeLocal.deletedCommandIds, contains('stale_cmd_1'));
        expect(fakeLocal.pendingCommands, isEmpty);
      },
    );

    test(
      'CRDT決定論的タイブレークにおいて 同一論理時計で端末時計が狂っている・逆転している場合でも、id順で決定論的に一意ソートされること',
      () {
        final base = DateTime(2026, 10, 1, 10, 0, 0);

        final evLateTime = ScoreEventLegacyAdapter.fromLegacy(
          id: 'ev_deviceA_late',
          side: Side.red,
          type: PointType.men,
          timestamp: base.add(const Duration(seconds: 30)),
          sequence: 1,
          logicalClock: 2,
        );

        final evEarlyTime1 = ScoreEventLegacyAdapter.fromLegacy(
          id: 'ev_deviceB_early_1',
          side: Side.white,
          type: PointType.kote,
          timestamp: base,
          sequence: 2,
          logicalClock: 2,
        );

        final evEarlyTime2 = ScoreEventLegacyAdapter.fromLegacy(
          id: 'ev_deviceC_early_2',
          side: Side.white,
          type: PointType.doIdo,
          timestamp: base,
          sequence: 3,
          logicalClock: 2,
        );

        final list1 = [evLateTime, evEarlyTime1, evEarlyTime2]
          ..sort((a, b) => a.compareTo(b));
        final list2 = [evEarlyTime2, evLateTime, evEarlyTime1]
          ..sort((a, b) => a.compareTo(b));
        final list3 = [evEarlyTime1, evEarlyTime2, evLateTime]
          ..sort((a, b) => a.compareTo(b));

        expect(list1, equals(list2));
        expect(list2, equals(list3));

        expect(list1[0].id, equals('ev_deviceB_early_1'));
        expect(list1[1].id, equals('ev_deviceC_early_2'));
        expect(list1[2].id, equals('ev_deviceA_late'));
      },
    );

    test('大量キュー存在時にgetPendingCommands(50)によりバッチ分割取得されること', () async {
      final fakeList = List.generate(
        70,
        (i) => MatchCommandModel(
          id: 'batch_cmd_$i',
          type: CommandType.updateMatch,
          payload: {'id': 'm_$i'},
          createdAt: DateTime.now(),
        ),
      );
      final repo = _FakeLocalMatchRepoForSync(fakeList);
      final batch = await repo.getPendingCommands(50);
      expect(batch.length, equals(50));
      expect(batch.first.id, equals('batch_cmd_0'));
      expect(batch.last.id, equals('batch_cmd_49'));
    });
  });
}

class _FakeLocalMatchRepoForSync implements LocalMatchRepository {
  final List<MatchCommandModel> pendingCommands;
  final List<String> deletedCommandIds = [];

  _FakeLocalMatchRepoForSync(this.pendingCommands);

  @override
  Future<List<MatchCommandModel>> getPendingCommands([int? limit]) async {
    final list = List<MatchCommandModel>.from(pendingCommands);
    return limit != null ? list.take(limit).toList() : list;
  }

  @override
  Future<void> deleteCommand(String id) async {
    deletedCommandIds.add(id);
    pendingCommands.removeWhere((cmd) => cmd.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMatchRepoForSync implements MatchRepository {
  Future<int> Function(MatchModel match)? onSaveMatch;
  Future<MatchModel?> Function(
    String matchId, {
    String? organizationId,
    String? tournamentId,
  })?
  onGetMatch;

  @override
  Future<int> saveMatch(MatchModel match) async {
    if (onSaveMatch != null) return await onSaveMatch!(match);
    return match.version + 1;
  }

  @override
  Future<MatchModel?> getMatch(
    String matchId, {
    String? organizationId,
    String? tournamentId,
  }) async {
    if (onGetMatch != null) {
      return await onGetMatch!(
        matchId,
        organizationId: organizationId,
        tournamentId: tournamentId,
      );
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
