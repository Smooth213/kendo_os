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
      WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
      RegExp(r'test').hasMatch(StackTrace.current.toString());
  if (isTest) return Stream.value(true);
  return _connectivityStream();
});

Stream<bool> _connectivityStream() async* {
  try {
    final initialResults = await Connectivity().checkConnectivity();
    debugPrint('📡 [Connectivity] 初期状態: $initialResults');
    yield !initialResults.contains(ConnectivityResult.none);

    await for (final results in Connectivity().onConnectivityChanged) {
      debugPrint('📡 [Connectivity] 状態変化: $results');
      yield !results.contains(ConnectivityResult.none);
    }
  } catch (e) {
    debugPrint('⚠️ [Connectivity] ストリーム監視エラー (fallback to true): $e');
    yield true;
  }
}

final isOnlineProvider = Provider<bool>(
  (ref) => ref.watch(connectivityProvider).value ?? true,
);

final isSyncingStateProvider = StateProvider<bool>((ref) => false);

/// バックグラウンド同期エンジン
class SyncEngine {
  final Ref ref;
  bool _isSyncing = false;
  bool _needsSyncAgain = false;
  int _consecutiveFailures = 0;
  static const int maxConsecutiveFailures = 5;
  Timer? _retryTimer;

  int get consecutiveFailures => _consecutiveFailures;

  SyncEngine(this.ref) {
    if (kIsWeb) return;

    SyncBackupHelper.cleanupOldPendingData(
      ref.read(localMatchRepositoryProvider),
    );

    ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
      if (isOnline && (previous == false || previous == null)) {
        _consecutiveFailures = 0;
        _retryTimer?.cancel();
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
          debugPrint('🌙 [Lifecycle] アプリがバックグラウンドに移行しました。強制同期を試行...');
          syncNow();
        }
        if (state == AppLifecycleState.resumed) {
          debugPrint('☀️ [Lifecycle] アプリ復帰。Drift監視とReconnect Replayを開始...');
          _performReconnectReplay();
        }
      },
    );
    ref.onDispose(() {
      _retryTimer?.cancel();
      lifecycleListener.dispose();
    });

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
        MatchModel rebuiltMatch = rebuilder
            .execute(match, rule)
            .copyWith(status: match.status);
        final hasDrift =
            rebuiltMatch.redScore != match.redScore ||
            rebuiltMatch.whiteScore != match.whiteScore;
        if (hasDrift) {
          driftCount++;
          debugPrint('⚠️ [Drift Monitor] 試合 ${match.id} に矛盾検知。修復します。');
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
    bool hasError = false;

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
              if (isar != null) await isar.writeTxn(() async {});
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
      final matchesToSync = <MatchModel>[];
      for (final pendingMatch in pendingMatches) {
        final match = await localRepo.getMatch(pendingMatch.id);
        if (match != null) matchesToSync.add(match);
      }
      if (matchesToSync.isEmpty) return;

      // 2. ⚡【Plan 1 最適化】並列で Firestore 取得 & アップロードを実行
      final syncedMatchesToSave = <MatchModel>[];

      await Future.wait(
        matchesToSync.map((match) async {
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

          try {
            final snapshot = await docRef.get();
            int targetVersion = match.version;

            if (snapshot.exists) {
              final remoteData = snapshot.data()!;
              final remoteVersion =
                  (remoteData['version'] as num?)?.toInt() ?? 1;

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
                  return;
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
                  syncedMatchesToSave.add(
                    rebuiltMatch.copyWith(
                      syncState: SyncState.synced,
                      pendingEvents: [],
                      version: targetVersion,
                    ),
                  );
                }
                debugPrint('✅ [Sync Engine] CRDTマージ完了＆保存待機 ID:${match.id}');
                return;
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
            await docRef.set(uploadData);

            final currentLocal = await localRepo.getMatch(match.id);
            if (currentLocal != null &&
                (currentLocal.events.length > match.events.length ||
                    currentLocal.lastUpdatedAt != match.lastUpdatedAt)) {
              _needsSyncAgain = true;
            } else {
              syncedMatchesToSave.add(
                match.copyWith(
                  syncState: SyncState.synced,
                  pendingEvents: const [],
                  version: targetVersion,
                ),
              );
            }
          } catch (e, stack) {
            debugPrint(
              '🔥 [Sync Engine] 試合ID: ${match.id} のFirestoreアップロードに失敗しました: $e\n$stack',
            );
            hasError = true;
          }
        }),
      );

      // 3. ⚡【Plan 1 最適化】全試合を単一トランザクションでIsarに一括反映
      if (syncedMatchesToSave.isNotEmpty) {
        await localRepo.saveMatchesBulk(syncedMatchesToSave);
        debugPrint(
          '⚡ [Sync Engine] ${syncedMatchesToSave.length}件の同期完了試合を単一トランザクションでIsarに一括反映しました',
        );
      }
    } catch (e) {
      debugPrint('🔥 [Sync Engine] 同期失敗: $e');
      hasError = true;
    } finally {
      _isDone();
      if (hasError) {
        _consecutiveFailures++;
        debugPrint(
          '⚠️ [Sync Engine] 同期失敗回数: $_consecutiveFailures / $maxConsecutiveFailures',
        );
        if (_consecutiveFailures >= maxConsecutiveFailures) {
          debugPrint(
            '🚨 [Sync Engine] 連続失敗上限($maxConsecutiveFailures回)に達したためサーキットブレーカーが発動しました。30秒間クールダウンします。',
          );
          _retryTimer?.cancel();
          _retryTimer = Timer(const Duration(seconds: 30), () {
            _consecutiveFailures = 0;
            syncNow();
          });
        } else {
          // 指数バックオフ (1s, 2s, 4s, 8s, 16s... 最大30s)
          final delaySeconds = (1 << (_consecutiveFailures - 1)).clamp(1, 30);
          debugPrint('⏳ [Sync Engine] 指数バックオフ待機: $delaySeconds秒後に再試行します');
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: delaySeconds), () => syncNow());
        }
      } else {
        _consecutiveFailures = 0;
        if (_needsSyncAgain) {
          _needsSyncAgain = false;
          _retryTimer?.cancel();
          _retryTimer = Timer(
            const Duration(milliseconds: 200),
            () => syncNow(),
          );
        }
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
        await Future.delayed(Duration(seconds: 2 * attempt));
        await _syncWithRetry(attempt + 1);
      }
    }
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) => SyncEngine(ref));

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
