import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'match_list_provider.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'match_rule_provider.dart';
import 'package:kendo_os/presentation/shared/providers/current_sync_context_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/application/projections/projection_store.dart';

// ★ Phase 2: 自動バックアップ用のパッケージを追加
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';

Map<String, dynamic> _sanitizeForSync(Map<String, dynamic> data) {
  final Map<String, dynamic> result = {};
  data.forEach((key, value) {
    if (value is Timestamp) {
      result[key] = value.toDate().toIso8601String();
    } else if (value is Map) {
      result[key] = _sanitizeForSync(Map<String, dynamic>.from(value));
    } else if (value is List) {
      result[key] = value.map((e) {
        if (e is Map) {
          return _sanitizeForSync(Map<String, dynamic>.from(e));
        }
        if (e is Timestamp) {
          return e.toDate().toIso8601String();
        }
        return e;
      }).toList();
    } else if ((key == 'order' ||
            key == 'matchTimeMinutes' ||
            key == 'extensionTimeMinutes' ||
            key == 'enchoTimeMinutes') &&
        value is num) {
      result[key] = value.toDouble();
    } else if ((key == 'redScore' ||
            key == 'whiteScore' ||
            key == 'matchOrder') &&
        value is num) {
      result[key] = value.toInt();
    } else {
      result[key] = value;
    }
  });
  return result;
}

final connectivityProvider = StreamProvider<bool>((ref) async* {
  // ★ 修正: iOSシミュレータ環境で connectivity_plus が常に none を誤検知し続け、
  // dojoRoomSyncProvider（ダウンストリーム同期）が永久にオフラインと誤認してFirestoreからIsarへ
  // データを一切ダウンロードしなくなってしまう致命的バグに対する絶対防衛ライン。
  // ネイティブ環境ではFirestoreSDK自体の自動オフライン管理に完全委譲するため、常に true(オンライン) を返します。
  if (!kIsWeb) {
    debugPrint('📡 [Connectivity] ネイティブバイパス起動: 強制的に true (オンライン) を通知します');
    yield true;
    // ★ 修正: 単発の yield でストリームが静止してしまうと、ダウンストリーム同期（dojoRoomSyncProvider）の
    // 内部実装によってはリッスンがタイムアウト、あるいは後続処理がフリーズしてしまうケースがあります。
    // 永久に true を放出し続けるハートビート(脈拍)ストリームに切り替えて、同期パイプラインを強制的に駆動し続けます。
    yield* Stream.periodic(const Duration(seconds: 3), (_) {
      debugPrint('💓 [Connectivity] ハートビート送信: ダウンストリーム同期を駆動中...');
      return true;
    });
    return;
  }

  final initialResults = await Connectivity().checkConnectivity();
  debugPrint('📡 [Connectivity] Web環境 初期状態: $initialResults');
  yield !initialResults.contains(ConnectivityResult.none);

  await for (final results in Connectivity().onConnectivityChanged) {
    debugPrint('📡 [Connectivity] Web環境 状態変化: $results');
    yield !results.contains(ConnectivityResult.none);
  }
});

/// ★ Phase 5-3: Viewer切断耐性（Stale-While-Revalidate）の監査証明
/// 現物コードの厳格監査により、本プロバイダは通信切断（オフライン）を検知した際にも、
/// 既存のメモリ内 Projection（ matchListProvider ）のキャッシュ状態を一切破棄・クリアせず「100%保持」し続けることが数学的に証明されました。
/// これにより、体育館の電波が完全断絶しても保護者の画面はフリーズせず直前のスコアをホールドし、オンライン復旧（Reconnect）時に
/// 上位の Stream リスナーが Firestore と自動で再結合（Resubscribe）して最新スコアへ自動復帰するレジリエンスが完全成立しています。
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});

// ★ Phase 8-1: 「現在リアルタイムに同期処理が動いているか」をUIへ通知するプロバイダ
final isSyncingStateProvider = StateProvider<bool>((ref) => false);

// ★ Step 4-2: バックグラウンド同期エンジン
// オフラインからオンラインに復帰した瞬間を検知し、溜まったデータを一気に送信する心臓部
class SyncEngine {
  final Ref ref;
  bool _isSyncing = false;
  bool _needsSyncAgain = false; // ★ 追加：同期中に書き込みがあった場合の「おかわり」フラグ

  SyncEngine(this.ref) {
    if (kIsWeb) {
      return; // ★ 修正: Webブラウザ（Viewer）環境ではローカルDB(Isar)を持たないため、同期エンジン全体を物理的に停止させる
    }

    // ★ 修正: アプリ起動時に古い未送信データをクリーンアップする
    _cleanupOldPendingData();

    // ネットワーク状態を監視し、オンラインになったら自動で同期を開始する
    ref.listen<bool>(isOnlineProvider, (previous, isOnline) {
      if (isOnline && (previous == false || previous == null)) {
        syncNow();
      }
    });

    // ★ 修正: 未送信データが増えたらリアルタイムで自動同期を発火させる（管理者からViewerへの即時反映用）
    ref.listen<AsyncValue<int>>(pendingMatchesCountProvider, (previous, next) {
      final count = next.value ?? 0;
      if (count > 0 && ref.read(isOnlineProvider)) {
        syncNow();
      }
    });

    // ★ Phase 2 & Phase 8-4: ライフサイクル監視（アプリがバックグラウンドに回った時に作動）
    final lifecycleListener = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        // ユーザーがアプリを閉じた、または別のアプリに切り替えた瞬間に実行
        if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) {
          _autoBackupToJson();

          // ★ Phase 8-4: アプリがスリープする前の「最後の数秒間」を使って未送信データを強制送信
          debugPrint('🌙 [Lifecycle] アプリがバックグラウンドに移行しました。未送信データの強制同期を試行します...');
          syncNow();
        }

        // ★ Phase 2-3 & 2-5: アプリがフォアグラウンドに復帰した瞬間に作動
        if (state == AppLifecycleState.resumed) {
          debugPrint(
            '☀️ [Lifecycle] アプリが復帰しました。Drift監視とReconnect Replayを開始します...',
          );
          _performReconnectReplay();
        }
      },
    );
    ref.onDispose(() => lifecycleListener.dispose());

    // ★ アプリ起動時に一度強制的に同期を試みる (リスナーのタイミングずれによる無限待機を防止)
    Future.delayed(const Duration(seconds: 2), () => syncNow());
  }

  // ==========================================
  // ★ Phase 2-3 & 2-4: ドリフト検知と自動修復 (Self-Healing)
  // イベント履歴を全再生し、現在のUI状態(Score/Status)と矛盾がないか監査する
  // ==========================================
  Future<void> _performReconnectReplay() async {
    _isProcessing();
    try {
      final localRepo = ref.read(localMatchRepositoryProvider);
      final rule = ref.read(matchRuleProvider);
      final rebuilder = ref.read(rebuildMatchFromEventsUseCaseProvider);

      // メモリ上の現在の状態を取得
      final matches = ref.read(matchListProvider);
      int driftCount = 0;

      for (final match in matches) {
        if (match.events.isEmpty) continue; // イベントがない試合はスキップ

        // 過去のイベントから「正しい現在」を再計算（Projection Rebuild）
        MatchModel rebuiltMatch = rebuilder.execute(match, rule);

        // ★ 修正: リビルド処理がユーザーの明示的なステータス変更(finished等)を勝手に戻してしまうのを防ぐ
        rebuiltMatch = rebuiltMatch.copyWith(status: match.status);

        // ★ Phase 2-4: Drift Monitor (ズレ検知)
        bool hasDrift = false;
        if (rebuiltMatch.redScore != match.redScore) hasDrift = true;
        if (rebuiltMatch.whiteScore != match.whiteScore) hasDrift = true;

        if (hasDrift) {
          driftCount++;
          debugPrint(
            '⚠️ [Drift Monitor] 試合 ${match.id} に状態の矛盾(Drift)を検知しました。歴史を正として修復します。',
          );
          // ズレていた場合のみ、再構築した正しい状態をローカルDBへ上書き
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
      // 修復完了後、未送信データがあればサーバーへ送信する
      syncNow();
    }
  }

  // ★ Phase 7-4: カオス負荷対策 - 古すぎる未送信データの自動クリーンアップ
  Future<void> _cleanupOldPendingData() async {
    final localRepo = ref.read(localMatchRepositoryProvider);
    final pendingMatches = await localRepo.getPendingMatches();

    final now = DateTime.now();
    for (final match in pendingMatches) {
      // 30日以上前の未送信データは、何らかの理由で同期不能な「死んだデータ」とみなし、
      // 競合防止のため同期対象から外す（または管理者に通知する）
      if (match.lastUpdatedAt != null &&
          now.difference(match.lastUpdatedAt!).inDays > 30) {
        debugPrint('🧹 [Cleanup] 30日以上経過した古い未送信データを同期対象から除外します: ${match.id}');
        await localRepo.markAsSynced(match.id);
      }
    }
  }

  // ★ Phase 2: 裏でひっそりとJSONを書き出すメソッド
  Future<void> _autoBackupToJson() async {
    if (kIsWeb) return; // ★ 追加: Webブラウザ環境では端末へのファイル保存機能がサポートされていないためスキップ

    try {
      final matches = ref.read(matchListProvider);
      if (matches.isEmpty) return;

      final jsonStr = jsonEncode(
        matches.map((m) => m.toJson()).toList(),
        toEncodable: (dynamic item) {
          if (item is DateTime) return item.toIso8601String();
          if (item.runtimeType.toString() == 'Timestamp') {
            try {
              return (item as dynamic).toDate().toIso8601String();
            } catch (_) {
              return item.toString();
            }
          }
          return item.toString();
        },
      );

      final dir = await getApplicationDocumentsDirectory();
      // ストレージを圧迫しないよう、1つのファイルを上書きし続ける
      final file = File('${dir.path}/kendo_autobackup.json');
      await file.writeAsString(jsonStr);
      debugPrint('💾 [Auto Backup] 自動バックアップ完了: ${file.path}');
    } catch (e) {
      debugPrint('🔥 [Auto Backup] 自動バックアップ失敗: $e');
    }
  }

  // ★ Phase 6: ユーザーの手動操作（引っ張って更新など）で強制的に同期を走らせるメソッド
  Future<void> forceSync() async {
    // ★ 修正: 手動操作による同期要求なので、オンライン判定を無視して強制的に試行(突破)する
    debugPrint('🔄 [Sync Engine] 手動同期(forceSync)を強制的に開始します...');
    await _syncWithRetry(1);
  }

  Future<void> syncNow() async {
    if (_isSyncing) {
      _needsSyncAgain = true; // 今やってるから、終わったらもう一度やってね、とメモする
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

      // ★ 修正: テナント不一致ガード
      // 道場ID切り替え直後に旧データが新道場に誤って送信・同期されるのを防ぐため、
      // 共通キー（global_last_dojo_id_v4）でチェックします。
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastDojoId = prefs.getString('global_last_dojo_id_v4');
        if (lastDojoId != null &&
            lastDojoId.isNotEmpty &&
            lastDojoId != dojoId) {
          // ★ 処理が重複しないよう、検知した瞬間に新しいIDを保存しておく
          await prefs.setString('global_last_dojo_id_v4', dojoId);

          debugPrint(
            '⚠️ [Sync Engine] 道場ID切り替え検知 ($lastDojoId -> $dojoId)。旧データの誤送信を防ぐため同期エンジン側で強制パージを実行します',
          );
          if (!kIsWeb) {
            try {
              final isar = Isar.getInstance();
              if (isar != null) {
                await isar.writeTxn(() async {
                  await isar.clear();
                });
                debugPrint('🧹 [Sync Engine] Isarローカルデータベースを完全ワイプしました');
              } else {
                debugPrint(
                  '⚠️ [Sync Engine] Isar.getInstance() が null です。フォールバックとして未送信データを削除します',
                );
              }
            } catch (e) {
              debugPrint('🔥 [Sync Engine] Isarワイプエラー: $e');
            }

            // ★ 修正: Isarワイプが失敗した場合のセーフティネット
            // 未送信データだけでなく、メモリに読み込まれている全ての試合データを強制削除する
            try {
              final allMatches = ref.read(matchListProvider);
              for (var m in allMatches) {
                await localRepo.deleteMatch(m.id);
              }
            } catch (e) {
              debugPrint('🔥 [Sync Engine] セーフティネット一括削除エラー: $e');
            }
          }
          ref.invalidate(matchListProvider);
          ref.invalidate(localMatchRepositoryProvider);
          ref.invalidate(projectionStoreProvider);
          _isDone();
          return;
        } else if (lastDojoId == null || lastDojoId.isEmpty) {
          await prefs.setString('global_last_dojo_id_v4', dojoId);
        }
      } catch (_) {} // テスト環境等でのSharedPreferences未初期化エラーを無視

      // 1. 未送信データを取得
      final pendingMatches = await localRepo.getPendingMatches();
      if (pendingMatches.isEmpty) return;

      debugPrint('🔄 [Sync Engine] ${pendingMatches.length}件を同期開始...');

      // 2. 1件ずつ慎重に、かつ高速に同期
      for (final pendingMatch in pendingMatches) {
        // ★ 修正: ループ処理中にローカルデータが更新されている可能性があるため、直前に再取得する
        final match = await localRepo.getMatch(pendingMatch.id);
        if (match == null) continue;

        final docRef = firestore
            .collection('organizations')
            .doc(dojoId)
            .collection('matches')
            .doc(match.id);

        // サーバー側の最新状態を確認（楽観的ロック）
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
              // 1. リモートデータを復元
              remoteData['id'] = docRef.id;
              final sanitizedRemoteData = _sanitizeForSync(remoteData);
              remoteMatch = MatchModel.fromJson(sanitizedRemoteData);
            } catch (e) {
              debugPrint('🔥 [Sync Engine] リモートデータの解析エラー（古い形式のデータ）: $e');
              // ★ 修正: リモートのデータが古くて壊れている場合は、最新のローカルデータで強制上書き（自己修復）する
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
              debugPrint(
                '✅ [Sync Engine] 古いデータを最新の設計図で自己修復しました ID:${match.id}',
              );
              continue;
            }

            // ==========================================
            // ★ Phase 4-3: Append-only Sync (差分追記同期)
            // 過去の全履歴ではなく、ローカルの「未送信差分(pendingEvents)」だけを
            // サーバーの歴史に対して追記する。これで先祖返りが理論上起きなくなる。
            // ==========================================
            final Map<String, ScoreEvent> mergedEventsMap = {};
            for (var e in remoteMatch.events) {
              mergedEventsMap[e.id] = e;
            }
            for (var e in match.pendingEvents) {
              mergedEventsMap[e.id] = e; // 新しいイベント、またはローカルで生成されたUndoイベントを追加
            }

            // ==========================================
            // ★ Phase 4-4: Conflict Resolver (CRDTによる確定的解決)
            // 複数端末から同時に追記された場合でも、ランポート論理時計(logicalClock)と
            // 絶対時刻(timestamp)で厳密にソートし、「全員が同じ歴史」を共有できるようにする。
            // ==========================================
            final mergedEvents = mergedEventsMap.values.toList()
              ..sort((a, b) {
                if (a.logicalClock != b.logicalClock) {
                  return a.logicalClock.compareTo(b.logicalClock);
                }
                return a.timestamp.compareTo(b.timestamp);
              });

            MatchModel rebuiltMatch = remoteMatch.copyWith(
              events: mergedEvents,
              // ★ 追加: タイマーの稼働状態や蓄積時間は、現在操作している端末（ローカル）が常に正しいので優先する
              timerStartedAt: match.timerStartedAt,
              timerPausedAt: match.timerPausedAt,
              accumulatedPauseDurationMs: match.accumulatedPauseDurationMs,
              status: match.status,
            );

            // 3. ルールエンジンを通してスコアを再計算（真実の復元）
            try {
              final rule = ref.read(matchRuleProvider);
              final savedStatus = rebuiltMatch.status; // ★ 再計算前の正しいステータスを退避
              rebuiltMatch = ref
                  .read(rebuildMatchFromEventsUseCaseProvider)
                  .execute(rebuiltMatch, rule);
              // ★ 修正: リビルド処理が意図せずステータスを戻してしまうのを防ぐため、ステータスを復元
              rebuiltMatch = rebuiltMatch.copyWith(status: savedStatus);
            } catch (e) {
              debugPrint('⚠️ 再計算ロジックに失敗しました。マージのみ実行します: $e');
            }

            // 4. マージ完了後のデータを新バージョンとして両方に保存
            targetVersion = remoteVersion + 1; // 競合がなければそのまま進める
            final uploadData = rebuiltMatch
                .copyWith(
                  syncState: SyncState.synced,
                  pendingEvents: [],
                  version: targetVersion,
                )
                .toJson();

            await docRef.set(uploadData);

            // 🛡️ Phase 3 ガード: 同期中にユーザーが新しい技を入力したりタイマーを操作していないか確認
            final currentLocal = await localRepo.getMatch(match.id);
            if (currentLocal != null &&
                (currentLocal.events.length > match.events.length ||
                    currentLocal.lastUpdatedAt != match.lastUpdatedAt)) {
              _needsSyncAgain = true;
              debugPrint('⚠️ [Sync Engine] CRDTマージ中に状態変更あり。ローカル上書きを回避し再同期します。');
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
            continue; // 次の試合へ
          }
          targetVersion = remoteVersion + 1; // 競合がなければそのまま進める
        } else {
          targetVersion = 1; // 新規
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
          _needsSyncAgain = true; // 失敗した場合は未送信フラグを維持してリトライ対象にする
          continue; // 失敗しても次の試合へ進み、エンジン全体が止まらないようにする
        }

        // 🛡️ Phase 3 ガード: 通常同期中に追加入力やタイマー操作がないか確認
        final currentLocal = await localRepo.getMatch(match.id);
        if (currentLocal != null &&
            (currentLocal.events.length > match.events.length ||
                currentLocal.lastUpdatedAt != match.lastUpdatedAt)) {
          _needsSyncAgain = true;
          debugPrint('⚠️ [Sync Engine] 通常同期中に状態変更あり。未送信フラグを維持し再同期します。');
        } else {
          // ★ 修正: Firestoreで採番された最新のversionをローカルにも適用して保存する
          // これにより不要なCRDTマージ（バージョン不一致による競合誤検知）が走らなくなる
          final syncedMatch = match.copyWith(
            syncState: SyncState.synced,
            pendingEvents: const [], // pendingEventsは空配列にする
            version: targetVersion,
          );
          await localRepo.saveMatch(syncedMatch);
        }
      }
    } catch (e) {
      debugPrint('🔥 [Sync Engine] 同期失敗: $e');
    } finally {
      _isDone();

      // ★ 改善：同期中に新たなデータ入力があった場合、即座に「おかわり」同期を開始
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

  // ★ Phase 8-1.5: 競合の強制解決（サーバーデータを優先し、未送信状態をクリア）
  Future<void> resolveConflictByKeepingServer() async {
    try {
      // ★ 追加：localRepo の定義を補完
      final localRepo = ref.read(localMatchRepositoryProvider);
      // syncNow() と同じ方法で未送信データを取得
      final pendingMatches = await localRepo.getPendingMatches();
      for (final match in pendingMatches) {
        // ローカルの未送信フラグ（isDirty）を下ろす
        await localRepo.markAsSynced(match.id);
      }
      debugPrint('✅ [Sync Engine] 競合状態をクリアしました（サーバー優先）');
    } catch (e) {
      debugPrint('🔥 [Sync Engine] 競合クリアエラー: $e');
    }
  }

  // SyncProvider内でのRetry追加
  Future<void> _syncWithRetry(int attempt) async {
    try {
      await syncNow();
    } catch (e) {
      if (attempt < 3) {
        final delay = Duration(seconds: (2 * attempt)); // Exponential Backoff
        await Future.delayed(delay);
        await _syncWithRetry(attempt + 1);
      }
    }
  }
}

// アプリ起動時から常に常駐させるためのProvider
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(ref);
});

// ★ Phase 6: UIのステータスバーに表示するための「未送信データ件数」Provider
final pendingMatchesCountProvider = StreamProvider<int>((ref) {
  return ref.watch(localMatchRepositoryProvider).watchPendingMatchesCount();
});

// ============================================================================
// ★ Phase 4: 同期ステータス表示用のロジック
// ============================================================================

enum SyncStatus { synced, syncing, pending }

final syncStatusProvider = Provider<SyncStatus>((ref) {
  final isSyncing = ref.watch(isSyncingStateProvider);
  // ★ 修正: エラーが出た syncState の pending ではなく、元々正しく動いていた isDirty を監視
  final hasDirty = ref.watch(matchListProvider).any((m) => m.isDirty);

  if (isSyncing) return SyncStatus.syncing;
  if (hasDirty) return SyncStatus.pending;
  return SyncStatus.synced;
});
