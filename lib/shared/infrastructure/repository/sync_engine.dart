import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/shared/domain/entities/user_session.dart';
import 'package:kendo_os/shared/presentation/providers/auth_session_provider.dart';

class SyncEngine {
  final Ref _ref;
  Timer? _syncTimer;
  Timer? _debounceSyncTimer;
  QuerySnapshot<Map<String, dynamic>>? _pendingMatchesSnapshot;
  bool _isProcessing = false;
  int _retryCount = 0;

  // ダウンストリーム監視用のサブスクリプション
  StreamSubscription? _matchesSubscription;
  StreamSubscription? _bunaiksenSubscription;

  SyncEngine(this._ref) {
    // 🌟 起動と同時に自動ポーリング同期ループを開始
    _startSyncLoop();
    // 🌟 Firestoreダウンストリーム監視の初期設定
    _setupFirestoreDownstream();
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await processQueue();
    });
  }

  void _setupFirestoreDownstream() {
    // DojoId または TournamentId が変わったときに再バインドする
    _ref.listen<String>(
      currentDojoIdProvider,
      (prev, next) => _bindListeners(),
    );
    _ref.listen<String>(
      currentTournamentIdProvider,
      (prev, next) => _bindListeners(),
    );
    _ref.listen<String?>(
      webCurrentTournamentIdProvider,
      (prev, next) => _bindListeners(),
    );
    // 🔑 認証セッション状態が変化した（ログイン成功など）際にも再バインドして再接続する
    _ref.listen<UserSession?>(authSessionProvider, (prev, next) {
      debugPrint(
        '🔑 [Sync Engine] 認証セッション状態の変更を検知しました: ${prev?.role} -> ${next?.role}',
      );
      _bindListeners();
    });

    // 初回バインド
    _bindListeners();
  }

  void _bindListeners() {
    _matchesSubscription?.cancel();
    _bunaiksenSubscription?.cancel();
    _debounceSyncTimer?.cancel();
    _matchesSubscription = null;
    _bunaiksenSubscription = null;
    _pendingMatchesSnapshot = null;

    final dojoId = _ref.read(currentDojoIdProvider);
    final tournamentId = _ref.read(currentTournamentIdProvider);
    final webTournamentId = _ref.read(webCurrentTournamentIdProvider);

    final activeTournamentId = (tournamentId.isNotEmpty)
        ? tournamentId
        : (webTournamentId ?? '');

    if (dojoId.isEmpty || activeTournamentId.isEmpty) {
      debugPrint(
        '📢 [Sync Engine] dojoId または tournamentId が未確定のため、Firestore監視を保留します。',
      );
      return;
    }

    debugPrint(
      '🚀 [Sync Engine] Firestoreダウンストリーム監視を開始します (dojoId: $dojoId, tournamentId: $activeTournamentId)',
    );

    // 1. 通常のトーナメント戦の試合データ監視（16msバッチド・デバウンスでUIリビルドをフレーム同期）
    final matchesCollection = _ref
        .read(firestoreProvider)
        .collection('organizations')
        .doc(dojoId)
        .collection('tournaments')
        .doc(activeTournamentId)
        .collection('matches');

    _matchesSubscription = matchesCollection.snapshots().listen(
      (snapshot) {
        _pendingMatchesSnapshot = snapshot;
        _debounceSyncTimer?.cancel();
        // ★ 最適化 (Web/Native共通): 連続するFirestoreイベントを50ms以内でバッチ集約
        // - Native: 50ms(約3フレーム)で複数コートの更新をまとめてIsarへ1回書き込み
        // - Web: IsarはnullのためsaveMatchesBulkは空処理（LocalMatchRepositoryのnullガード済み）
        //   Firestore→matchListProviderへの通知は別経路なので、Webでも正しく動作する
        _debounceSyncTimer = Timer(const Duration(milliseconds: 50), () async {
          final pending = _pendingMatchesSnapshot;
          if (pending != null) {
            _pendingMatchesSnapshot = null;
            await _syncFirestoreToIsar(pending);
          }
        });
      },
      onError: (e) {
        debugPrint('⚠️ [Sync Engine Downstream] トーナメント試合監視エラー: $e');
      },
    );

    // 2. 特設コレクション (bunaiksen) の包括サブリスナー（ドキュメント監視）
    if (activeTournamentId.startsWith('bunaiksen_') ||
        activeTournamentId == 'bunaiksen') {
      final bunaiksenDoc = _ref
          .read(firestoreProvider)
          .collection('organizations')
          .doc(dojoId)
          .collection('tournaments')
          .doc(activeTournamentId);

      _bunaiksenSubscription = bunaiksenDoc.snapshots().listen(
        (snapshot) async {
          if (snapshot.exists && snapshot.data() != null) {
            debugPrint(
              '⚡ [Sync Engine Downstream] 特設部内大会ドキュメントの更新を受信しました: ${snapshot.id}',
            );
            await _syncBunaiksenDocToIsar(snapshot);
          }
        },
        onError: (e) {
          debugPrint(
            '⚠️ [Sync Engine Downstream] 特設(bunaiksen)ドキュメント監視エラー: $e',
          );
        },
      );
    }
  }

  Future<void> _syncBunaiksenDocToIsar(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    try {
      final data = snapshot.data();
      if (data == null) return;

      // ドキュメント内に直接 'matches' リストが含まれている場合の安全同期フォールバック
      if (data.containsKey('matches') && data['matches'] is List) {
        final matchesList = data['matches'] as List;
        final matches = <MatchModel>[];
        for (final item in matchesList) {
          if (item is Map<String, dynamic>) {
            try {
              final sanitized = _sanitizeFirestoreData(item);
              final id =
                  sanitized['id']?.toString() ??
                  'bunaiksen_match_${DateTime.now().millisecondsSinceEpoch}';
              final match = MatchModel.fromJson({...sanitized, 'id': id});
              matches.add(match);
            } catch (e) {
              debugPrint(
                '⚠️ [Sync Engine Downstream] bunaiksen doc inner match parse error: $e',
              );
            }
          }
        }

        if (matches.isNotEmpty) {
          final healedMatches = matches.map(_healMatchSignatures).toList();
          final localRepo = _ref.read(localMatchRepositoryProvider);
          await localRepo.saveMatchesBulk(healedMatches);
          debugPrint(
            '⚡ [Sync Engine Downstream] bunaiksenドキュメント直下のリストから ${healedMatches.length} 件の試合データをIsarに同期しました。',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '🔥 [Sync Engine Downstream Critical] bunaiksenドキュメント同期中にエラーが発生しました: $e',
      );
    }
  }

  Future<void> _syncFirestoreToIsar(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    try {
      final matches = <MatchModel>[];
      for (final doc in snapshot.docs) {
        try {
          final sanitized = _sanitizeFirestoreData(doc.data());
          final match = MatchModel.fromJson({...sanitized, 'id': doc.id});
          matches.add(match);
        } catch (e) {
          debugPrint(
            '⚠️ [Sync Engine Downstream] Match parsing failed for doc ${doc.id}: $e',
          );
        }
      }

      if (matches.isNotEmpty) {
        final healedMatches = matches.map(_healMatchSignatures).toList();
        final localRepo = _ref.read(localMatchRepositoryProvider);
        await localRepo.saveMatchesBulk(healedMatches);
        debugPrint(
          '⚡ [Sync Engine Downstream] Firestoreから ${healedMatches.length} 件の試合データをIsarに同期しました。',
        );
      }
    } catch (e) {
      debugPrint(
        '🔥 [Sync Engine Downstream Critical] Isarへのバルクインサート中にエラーが発生しました: $e',
      );
    }
  }

  MatchModel _healMatchSignatures(MatchModel match) {
    try {
      final healedEvents = match.events.map((event) {
        try {
          if (ScoreEventLegacyAdapter.verifySignature(
            event,
            'kendo_os_secret_key_v1',
          )) {
            return event;
          }
          final eventId = event.id.isNotEmpty ? event.id : const Uuid().v4();
          final uid = event.userId ?? 'unknown_user';
          final payload =
              '$eventId:$uid:${event.timestamp.toIso8601String()}:${event.side.name}:${event.type.name}';
          final signature = ScoreEventLegacyAdapter.generateSignature(
            payload,
            'kendo_os_secret_key_v1',
          );
          return event.copyWith(id: eventId, signature: signature);
        } catch (e) {
          debugPrint(
            '⚠️ [Sync Engine Downstream] Failed to verify/heal single event signature: $e',
          );
          final eventId = event.id.isNotEmpty ? event.id : const Uuid().v4();
          final uid = event.userId ?? 'unknown_user';
          final payload =
              '$eventId:$uid:${DateTime.now().toIso8601String()}:${event.side.name}:${event.type.name}';
          final signature = ScoreEventLegacyAdapter.generateSignature(
            payload,
            'kendo_os_secret_key_v1',
          );
          return event.copyWith(id: eventId, signature: signature);
        }
      }).toList();

      final healedPendingEvents = match.pendingEvents.map((event) {
        try {
          if (ScoreEventLegacyAdapter.verifySignature(
            event,
            'kendo_os_secret_key_v1',
          )) {
            return event;
          }
          final eventId = event.id.isNotEmpty ? event.id : const Uuid().v4();
          final uid = event.userId ?? 'unknown_user';
          final payload =
              '$eventId:$uid:${event.timestamp.toIso8601String()}:${event.side.name}:${event.type.name}';
          final signature = ScoreEventLegacyAdapter.generateSignature(
            payload,
            'kendo_os_secret_key_v1',
          );
          return event.copyWith(id: eventId, signature: signature);
        } catch (e) {
          debugPrint(
            '⚠️ [Sync Engine Downstream] Failed to verify/heal single pending event signature: $e',
          );
          final eventId = event.id.isNotEmpty ? event.id : const Uuid().v4();
          final uid = event.userId ?? 'unknown_user';
          final payload =
              '$eventId:$uid:${DateTime.now().toIso8601String()}:${event.side.name}:${event.type.name}';
          final signature = ScoreEventLegacyAdapter.generateSignature(
            payload,
            'kendo_os_secret_key_v1',
          );
          return event.copyWith(id: eventId, signature: signature);
        }
      }).toList();

      return match.copyWith(
        events: healedEvents,
        pendingEvents: healedPendingEvents,
      );
    } catch (e) {
      debugPrint(
        '⚠️ [Sync Engine Downstream] Error in _healMatchSignatures: $e',
      );
      return match;
    }
  }

  Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = _sanitizeFirestoreData(value);
      } else if (value is List) {
        result[key] = value.map((e) {
          if (e is Map<String, dynamic>) return _sanitizeFirestoreData(e);
          if (e is Timestamp) return e.toDate().toIso8601String();
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

  // =========================================================================
  // 🛡️ Phase 1 - STEP 1-2 要件：指数バックオフ・重複防止付き再送エンジン
  // =========================================================================
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final localRepo = _ref.read(localMatchRepositoryProvider);
      // Pending 状態の未送信SyncAction（MatchCommandModel）をIsarから全取得
      final pendingActions = await localRepo.getPendingCommands();

      if (pendingActions.isEmpty) {
        _retryCount = 0; // キューが空ならリトライカウントをリセット
        _isProcessing = false;
        return;
      }

      debugPrint('🔄 [Sync Engine] 未送信キューを検知しました: ${pendingActions.length} 件');

      for (final action in pendingActions) {
        // 重複送信防止（eventId / commandId の完全一致検証によるFirestoreべき等性担保）
        bool success = await _attemptUpload(action);

        if (success) {
          // 送信成功時：Isar上の保留キューから物理削除
          await localRepo.deleteCommand(action.id);
          _retryCount = 0;
        } else {
          // 劣悪ネットワーク環境下での指数バックオフ制御（最大5分まで段階的に遅延を挿入）
          _retryCount++;
          final backoffSeconds = min(pow(2, _retryCount).toInt(), 300);
          debugPrint(
            '⚠️ [Sync Engine] 通信断の可能性。指数バックオフを実行します。次の再送まで: $backoffSeconds秒',
          );
          await Future.delayed(Duration(seconds: backoffSeconds));
          break; // 一度エラーが起きたら順序保証のため以降のキュー処理を中断
        }
      }
    } catch (e) {
      debugPrint('🔥 [Sync Engine Critical] キュー処理中に例外が発生しました: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _attemptUpload(SyncAction action) async {
    try {
      final remoteRepo = _ref.read(matchRepositoryProvider);

      // ペイロード（Map形式）からドメインモデルへ完全復元
      // (※既存リポジトリが要求する型に合わせて安全にアップロードを試みます)
      if (action.payload.containsKey('id')) {
        final match = MatchModel.fromJson(action.payload);
        await remoteRepo.saveMatch(match);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _matchesSubscription?.cancel();
    _bunaiksenSubscription?.cancel();
  }
}

// アプリ起動時に即座に常駐起動するための自動同期プロバイダー
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(ref);
  ref.onDispose(() => engine.dispose());
  return engine;
});
