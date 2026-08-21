import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_backup_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'match_list_provider.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  final isTest =
      const bool.fromEnvironment('FLUTTER_TEST') ||
      RegExp(r'test').hasMatch(StackTrace.current.toString());
  if (isTest) {
    return Stream.value(true);
  }
  return _connectivityStream();
});

Stream<bool> _connectivityStream() async* {
  if (!kIsWeb) {
    yield true;
    await Future.delayed(const Duration(days: 999));
    return;
  }

  final initialResults = await Connectivity().checkConnectivity();
  debugPrint('📡 [Connectivity] Web環境 初期状態: $initialResults');
  yield !initialResults.contains(ConnectivityResult.none);

  await for (final results in Connectivity().onConnectivityChanged) {
    debugPrint('📡 [Connectivity] Web環境 状態変化: $results');
    yield !results.contains(ConnectivityResult.none);
  }
}

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});

final isSyncingStateProvider = StateProvider<bool>((ref) => false);

/// バックグラウンド同期エンジン
class SyncEngine {
  final Ref ref;
  bool _isSyncing = false;
  bool _needsSyncAgain = false;

  SyncEngine(this.ref) {
    if (kIsWeb) return;

    SyncBackupHelper.cleanupOldPendingData(
      ref.read(localMatchRepositoryProvider),
    );

    ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
      if (isOnline && (previous == false || previous == null)) {
        syncNow();
      }
    });

    ref.listen<AsyncValue<int>>(pendingMatchesCountProvider, (previous, next) {
      final count = next.value ?? 0;
      if (count > 0 && ref.read(isOnlineProvider)) {
        syncNow();
      }
    });

    final lifecycleListener = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) {
          SyncBackupHelper.autoBackupToJson(ref.read(matchListProvider));
          debugPrint('🌙 [Lifecycle] アプリがバックグラウンドに移行しました。未送信データの強制同期を試行します...');
          syncNow();
        }

        if (state == AppLifecycleState.resumed) {
          debugPrint(
            '☀️ [Lifecycle] アプリが復帰しました。Drift監視とReconnect Replayを開始します...',
          );
          _performReconnectReplay();
        }
      },
    );
    ref.onDispose(() => lifecycleListener.dispose());

    Future.delayed(const Duration(seconds: 2), () => syncNow());
  }

  Future<void> _performReconnectReplay() async {
    _isProcessing();
    try {
      final localRepo = ref.read(localMatchRepositoryProvider);
      final rule = ref.read(matchRuleProvider);
      final rebuilder = ref.read(rebuildMatchFromEventsUseCaseProvider);

      final matches = ref.read(matchListProvider);
      int driftCount = 0;

      for (final match in matches) {
        if (match.events.isEmpty) continue;

        MatchModel rebuiltMatch = rebuilder.execute(match, rule);
        rebuiltMatch = rebuiltMatch.copyWith(status: match.status);

        bool hasDrift = false;
        if (rebuiltMatch.redScore != match.redScore) hasDrift = true;
        if (rebuiltMatch.whiteScore != match.whiteScore) hasDrift = true;

        if (hasDrift) {
          driftCount++;
          debugPrint(
            '⚠️ [Drift Monitor] 試合 ${match.id} に状態の矛盾(Drift)を検知しました。歴史を正として修復します。',
          );
          await localRepo.saveMatch(rebuiltMatch);
        }
      }

      if (driftCount > 0) {
        debugPrint('🛠️ [Self-Healing] $driftCount 件の試合を自動修復しました。');
      } else {
        debugPrint('✅ [Drift Monitor] すべての試合状態は歴史(Events)と完全に一致しています。');
      }
    } catch (e) {
      debugPrint('🔥 [Reconnect Replay] 復旧・監査プロセス中にエラーが発生しました: $e');
    } finally {
      _isDone();
      syncNow();
    }
  }

  Future<void> forceSync() async {
    debugPrint('🔄 [Sync Engine] 手動同期(forceSync)を強制的に開始します...');
    await _syncWithRetry(1);
  }

  Future<void> syncNow() async {
    if (_isSyncing) {
      _needsSyncAgain = true;
      return;
    }
    _isProcessing();

    try {
      final localRepo = ref.read(localMatchRepositoryProvider);
      final firestore = ref.read(firestoreProvider);
      final dojoId = ref.read(currentDojoIdProvider);
      if (dojoId.isEmpty) {
        debugPrint('⚠️ [Sync Engine] 道場IDが空のため同期をスキップします');
        _isDone();
        return;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final lastDojoId = prefs.getString('global_last_dojo_id_v4');
        if (lastDojoId != null &&
            lastDojoId.isNotEmpty &&
            lastDojoId != dojoId) {
          await prefs.setString('global_last_dojo_id_v4', dojoId);
          debugPrint('⚠️ [Sync Engine] 道場ID切り替え検知 ($lastDojoId -> $dojoId)');
          if (!kIsWeb) {
            try {
              final isar = Isar.getInstance();
              if (isar != null) {
                await isar.writeTxn(() async {});
              }
            } catch (_) {}

            try {
              final allMatches = ref.read(matchListProvider);
              for (var m in allMatches) {
                await localRepo.deleteMatch(m.id);
              }
            } catch (_) {}
          }
          _isDone();
          return;
        } else if (lastDojoId == null || lastDojoId.isEmpty) {
          await prefs.setString('global_last_dojo_id_v4', dojoId);
        }
      } catch (_) {}

      final pendingMatches = await localRepo.getPendingMatches();
      if (pendingMatches.isEmpty) return;

      debugPrint('🔄 [Sync Engine] ${pendingMatches.length}件を同期開始...');

      for (final pendingMatch in pendingMatches) {
        final match = await localRepo.getMatch(pendingMatch.id);
        if (match == null) continue;

        final targetTournamentId =
            (match.tournamentId != null && match.tournamentId!.isNotEmpty)
            ? match.tournamentId!
            : 'default_tournament';

        final docRef = firestore
            .collection('organizations')
            .doc(dojoId)
            .collection('tournaments')
            .doc(targetTournamentId)
            .collection('matches')
            .doc(match.id);

        final snapshot = await docRef.get();
        int targetVersion = match.version;

        if (snapshot.exists) {
          final remoteData = snapshot.data()!;
          final remoteVersion = (remoteData['version'] as num?)?.toInt() ?? 1;

          if (match.version < remoteVersion) {
            debugPrint(
              '⚠️ [Sync Engine] 競合検知 ID:${match.id} -> 🛡️ CRDT自動マージを実行します',
            );

            MatchModel remoteMatch;
            try {
              remoteData['id'] = docRef.id;
              final sanitizedRemoteData = SyncCrdtMerger.sanitizeForSync(
                remoteData,
              );
              remoteMatch = MatchModel.fromJson(sanitizedRemoteData);
            } catch (e) {
              debugPrint('🔥 [Sync Engine] リモートデータの解析エラー: $e');
              targetVersion = remoteVersion + 1;
              final uploadData = match
                  .copyWith(
                    syncState: SyncState.synced,
                    pendingEvents: [],
                    version: targetVersion,
                  )
                  .toJson();
              await docRef.set(uploadData);
              await localRepo.markAsSynced(match.id);
              continue;
            }

            final rebuiltMatch = SyncCrdtMerger.mergeAndRebuild(
              remoteMatch: remoteMatch,
              localMatch: match,
              rule: ref.read(matchRuleProvider),
              rebuilder: ref.read(rebuildMatchFromEventsUseCaseProvider),
            );

            targetVersion = remoteVersion + 1;
            final uploadData = rebuiltMatch
                .copyWith(
                  syncState: SyncState.synced,
                  pendingEvents: [],
                  version: targetVersion,
                )
                .toJson();

            await docRef.set(uploadData);

            final currentLocal = await localRepo.getMatch(match.id);
            if (currentLocal != null &&
                (currentLocal.events.length > match.events.length ||
                    currentLocal.lastUpdatedAt != match.lastUpdatedAt)) {
              _needsSyncAgain = true;
            } else {
              await localRepo.saveMatch(
                rebuiltMatch.copyWith(
                  syncState: SyncState.synced,
                  pendingEvents: [],
                  version: targetVersion,
                ),
              );
            }

            debugPrint('✅ [Sync Engine] CRDTマージ完了＆保存 ID:${match.id}');
            continue;
          }
          targetVersion = remoteVersion + 1;
        } else {
          targetVersion = 1;
        }

        final uploadData = match
            .copyWith(
              syncState: SyncState.synced,
              pendingEvents: [],
              version: targetVersion,
            )
            .toJson();

        try {
          await docRef.set(uploadData);
        } catch (e, stack) {
          debugPrint(
            '🔥 [Sync Engine] 試合ID: ${match.id} のFirestoreアップロードに失敗しました: $e\n$stack',
          );
          _needsSyncAgain = true;
          continue;
        }

        final currentLocal = await localRepo.getMatch(match.id);
        if (currentLocal != null &&
            (currentLocal.events.length > match.events.length ||
                currentLocal.lastUpdatedAt != match.lastUpdatedAt)) {
          _needsSyncAgain = true;
        } else {
          final syncedMatch = match.copyWith(
            syncState: SyncState.synced,
            pendingEvents: const [],
            version: targetVersion,
          );
          await localRepo.saveMatch(syncedMatch);
        }
      }
    } catch (e) {
      debugPrint('🔥 [Sync Engine] 同期失敗: $e');
    } finally {
      _isDone();
      if (_needsSyncAgain) {
        _needsSyncAgain = false;
        syncNow();
      }
    }
  }

  void _isProcessing() {
    _isSyncing = true;
    ref.read(isSyncingStateProvider.notifier).state = true;
  }

  void _isDone() {
    _isSyncing = false;
    ref.read(isSyncingStateProvider.notifier).state = false;
  }

  Future<void> resolveConflictByKeepingServer() async {
    try {
      final localRepo = ref.read(localMatchRepositoryProvider);
      final pendingMatches = await localRepo.getPendingMatches();
      for (final match in pendingMatches) {
        await localRepo.markAsSynced(match.id);
      }
      debugPrint('✅ [Sync Engine] 競合状態をクリアしました（サーバー優先）');
    } catch (e) {
      debugPrint('🔥 [Sync Engine] 競合クリアエラー: $e');
    }
  }

  Future<void> _syncWithRetry(int attempt) async {
    try {
      await syncNow();
    } catch (e) {
      if (attempt < 3) {
        final delay = Duration(seconds: (2 * attempt));
        await Future.delayed(delay);
        await _syncWithRetry(attempt + 1);
      }
    }
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(ref);
});

final pendingMatchesCountProvider = StreamProvider<int>((ref) {
  return ref.watch(localMatchRepositoryProvider).watchPendingMatchesCount();
});

enum SyncStatus { synced, syncing, pending }

final syncStatusProvider = Provider<SyncStatus>((ref) {
  final isSyncing = ref.watch(isSyncingStateProvider);
  final hasDirty = ref.watch(
    matchListProvider.select((list) => list.any((m) => m.isDirty)),
  );

  if (isSyncing) return SyncStatus.syncing;
  if (hasDirty) return SyncStatus.pending;
  return SyncStatus.synced;
});
