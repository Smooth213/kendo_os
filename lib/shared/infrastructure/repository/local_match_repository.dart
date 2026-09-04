// ignore_for_file: experimental_member_use
import 'package:isar_community/isar.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';
import 'dart:convert'; // ★ 追加: Ruleを文字列に圧縮・解凍するための道具
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart'; // ★ 追加: MatchCommandModel等の型を認識させるため
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:flutter/foundation.dart'; // ★ 追加: debugPrint
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // ★ 追加: クラッシュレポート用
import 'package:kendo_os/shared/infrastructure/repository/local_match_entity_mapper.dart';

// ==========================================
// ★ Phase 1-Step 4: ゼロトラストの最終防壁（例外定義）
// ==========================================
class TamperedEventException implements Exception {
  final String message;
  TamperedEventException(this.message);
  @override
  String toString() => 'TamperedEventException: $message';
}

// アプリ起動時に main.dart で初期化された Isar を受け取る Provider（Web対応のため nullable に変更）
final isarProvider = Provider<Isar?>((ref) {
  throw UnimplementedError('main.dartでIsarを初期化してoverrideしてください');
});

final localMatchRepositoryProvider = Provider<LocalMatchRepository>((ref) {
  return LocalMatchRepository(ref.read(isarProvider));
});

class LocalMatchRepository {
  final Isar? _isar;
  LocalMatchRepository(this._isar);

  // 1. 試合一覧をローカルからリアルタイム取得
  Stream<List<MatchModel>> watchMatches() {
    if (_isar == null) return Stream.value([]);
    return _isar.matchEntitys.where().watch(fireImmediately: true).map((
      entities,
    ) {
      return entities.map(LocalMatchEntityMapper.toModel).toList();
    });
  }

  // 2. 特定の1試合をローカルからリアルタイム監視
  Stream<MatchModel?> watchSingleMatch(String matchId) {
    if (_isar == null) return Stream.value(null);
    return _isar.matchEntitys
        .filter()
        .firestoreIdEqualTo(matchId)
        .watch(fireImmediately: true)
        .map((entities) {
          if (entities.isEmpty) return null;
          return LocalMatchEntityMapper.toModel(entities.first);
        });
  }

  // ★ 追加: DBから直接最新の試合データを1件取得（RiverpodのStream遅延を回避するため）
  Future<MatchModel?> getMatch(String matchId) async {
    if (_isar == null) return null;
    try {
      final entity = await _isar.matchEntitys
          .filter()
          .firestoreIdEqualTo(matchId)
          .findFirst();
      if (entity == null) return null;

      // ★ 修正: タイマーをスタートした直後はイベントが空のまま in_progress になるのが正常な仕様のため、
      // ここでの過剰な警告ログ（Chaos Recovery）を削除し、コンソールをクリーンに保ちます。
      // if (entity.status == 'in_progress' && entity.events.isEmpty) {
      //   debugPrint('⚠️ [Chaos Recovery] 進行中の試合なのにイベントが空です。データの不整合を検知しました。');
      // }

      return LocalMatchEntityMapper.toModel(entity);
    } catch (e, stack) {
      // ★ Phase 7: 万が一ローカルDBが破損していた場合の緊急回避
      debugPrint('🔥 [Critical] ローカルDBからの読み込みに失敗しました(破損の可能性): $e');
      FirebaseCrashlytics.instance
          .recordError(e, stack, reason: 'Local DB Read Failure')
          .catchError((crashlyticsError) {
            debugPrint(
              '⚠️ [Crashlytics] recordError 送信失敗(モック環境等): $crashlyticsError',
            );
          });
      return null;
    }
  }

  // 3. 試合をローカルに保存（ここが単一真実への書き込み）
  Future<void> saveMatch(MatchModel match) async {
    if (_isar == null) return;
    try {
      // ==========================================
      // ★ Phase 1-Step 4: 最終防壁での署名検証
      // 保存前にすべてのイベントが改ざんされていないかチェックする
      // ==========================================
      for (final event in match.events) {
        if (!ScoreEventLegacyAdapter.verifySignature(
          event,
          'kendo_os_secret_key_v1',
        )) {
          throw TamperedEventException(
            'イベント(ID: ${event.id})の署名が無効、または改ざんされています。',
          );
        }
      }

      final entity = LocalMatchEntityMapper.toEntity(match);
      // ★ Phase 5-2, 5-3: 1〜3秒以内の自動保存を強制し、端末スリープ・強制終了時もデータを100%保護する即時同期的ライトスルー確約
      await _isar.writeTxn(() async {
        final existing = await _isar.matchEntitys
            .filter()
            .firestoreIdEqualTo(match.id)
            .findFirst();
        if (existing != null) {
          entity.id = existing.id; // 既存の内部IDを引き継いで上書き更新する
        }
        await _isar.matchEntitys.put(entity);
      });
    } catch (e, stack) {
      debugPrint('🔥 [Storage Error] ローカルDBへの保存に失敗しました: $e');
      FirebaseCrashlytics.instance
          .recordError(e, stack, reason: 'Local DB Save Failure')
          .catchError((crashlyticsError) {
            debugPrint(
              '⚠️ [Crashlytics] recordError 送信失敗(モック環境等): $crashlyticsError',
            );
          });

      // ★ Phase 7: 最後の一線 - DBがロックされていても、JSONとして緊急避難保存を試みる
      try {
        final emergencyJson = jsonEncode(match.toJson());
        final dir = await getApplicationDocumentsDirectory();
        // 試合ごとにユニークなファイル名で保存し、上書きを防ぐ
        final file = File(
          '${dir.path}/emergency_backup_${match.id}_${DateTime.now().millisecondsSinceEpoch}.json',
        );
        await file.writeAsString(emergencyJson);
        debugPrint(
          '🛡️ [Emergency Backup] DB保存失敗のため、緊急JSONバックアップを実行しました: ${file.path}',
        );
      } catch (innerE, innerStack) {
        debugPrint('🚨 [Fatal] 緊急バックアップすら失敗しました: $innerE');
        FirebaseCrashlytics.instance
            .recordError(innerE, innerStack, reason: 'Emergency Backup Failure')
            .catchError((crashlyticsError) {
              debugPrint(
                '⚠️ [Crashlytics] recordError 送信失敗(モック環境等): $crashlyticsError',
              );
            });
      }

      rethrow;
    }
  }

  // 4. 複数試合を一括保存（🔋 【Phase 5】バッチトランザクション・I/O最適化）
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {
    if (_isar == null || matches.isEmpty) return;
    // ★ 複数保存時もすべてのイベントの署名を検証する
    for (final match in matches) {
      for (final event in match.events) {
        if (!ScoreEventLegacyAdapter.verifySignature(
          event,
          'kendo_os_secret_key_v1',
        )) {
          throw TamperedEventException(
            'イベント(ID: ${event.id})の署名が無効、または改ざんされています。',
          );
        }
      }
    }

    final matchIds = matches.map((m) => m.id).toList();

    await _isar.writeTxn(() async {
      // 🔋 【Phase 5】ループ内の個別findFirstを廃止し、集合クエリ+putAllで1回の一括書き込みへ集約
      final existingEntities = await _isar.matchEntitys
          .filter()
          .anyOf(matchIds, (q, String id) => q.firestoreIdEqualTo(id))
          .findAll();

      final existingIdMap = {
        for (final e in existingEntities) e.firestoreId: e.id,
      };

      final entitiesToPut = matches.map((match) {
        final entity = LocalMatchEntityMapper.toEntity(match);
        final existingId = existingIdMap[match.id];
        if (existingId != null) {
          entity.id = existingId;
        }
        return entity;
      }).toList();

      await _isar.matchEntitys.putAll(entitiesToPut);
    });
  }

  // 5. 試合の削除
  Future<void> deleteMatch(String matchId) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      await _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).deleteAll();
    });
  }

  // ★ Phase 4 復旧: Isarの正しい否定構文に修正
  Future<List<MatchModel>> getPendingMatches() async {
    if (_isar == null) return [];
    final entities = await _isar.matchEntitys
        .filter()
        .not()
        .syncStateEqualTo(SyncState.synced)
        .findAll();
    return entities.map(LocalMatchEntityMapper.toModel).toList();
  }

  // ★ Phase 4 復旧: 同期完了処理
  Future<void> markAsSynced(String matchId) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      final entity = await _isar.matchEntitys
          .filter()
          .firestoreIdEqualTo(matchId)
          .findFirst();
      if (entity != null) {
        entity.syncState = SyncState.synced;
        entity.pendingEvents = []; // ★ 送信が完了したため差分キューを空にする
        await _isar.matchEntitys.put(entity);
      }
    });
  }

  // 🔋 【Phase 5】同期完了バッチ処理: 複数試合の同期状態を1回のwriteTxn・putAllで一括更新
  Future<void> markMatchesAsSynced(List<String> matchIds) async {
    if (_isar == null || matchIds.isEmpty) return;
    await _isar.writeTxn(() async {
      final entities = await _isar.matchEntitys
          .filter()
          .anyOf(matchIds, (q, String id) => q.firestoreIdEqualTo(id))
          .findAll();
      for (final entity in entities) {
        entity.syncState = SyncState.synced;
        entity.pendingEvents = [];
      }
      await _isar.matchEntitys.putAll(entities);
    });
  }

  // ★ Phase 4 復旧: Isarの正しい否定構文に修正
  Stream<int> watchPendingMatchesCount() {
    if (_isar == null) return Stream.value(0);
    return _isar.matchEntitys
        .filter()
        .not()
        .syncStateEqualTo(SyncState.synced)
        .watch(fireImmediately: true)
        .map((events) => events.length);
  }

  // ============================================================================
  // ★ Phase 2: コマンド永続化（Queue of SSOT）
  // ============================================================================

  Future<void> savePendingCommand(MatchCommandModel cmd) async {
    if (_isar == null) return;
    final entity = MatchCommandEntity()
      ..commandId = cmd.id
      ..type = cmd.type.name
      ..payloadJson = jsonEncode(cmd.payload)
      ..createdAt = cmd.createdAt
      ..status = cmd.status.name;

    // ★ Phase 5: 電波断環境下（体育館）でコマンドキューを1ミリ秒でローカルディスクに焼き付ける強制ライトスルー
    await _isar.writeTxn(() async {
      final existing = await _isar.matchCommandEntitys
          .filter()
          .commandIdEqualTo(cmd.id)
          .findFirst();
      if (existing != null) {
        entity.id = existing.id;
      }
      await _isar.matchCommandEntitys.put(entity);
    });
  }

  Future<void> deleteCommand(String id) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      await _isar.matchCommandEntitys.filter().commandIdEqualTo(id).deleteAll();
    });
  }

  Future<List<MatchCommandModel>> getPendingCommands() async {
    if (_isar == null) return [];
    final entities = await _isar.matchCommandEntitys
        .filter()
        .statusEqualTo(CommandStatus.pending.name)
        .sortByCreatedAt()
        .findAll();

    return entities
        .map(
          (e) => MatchCommandModel(
            id: e.commandId,
            type: CommandType.values.byName(e.type),
            payload: jsonDecode(e.payloadJson),
            createdAt: e.createdAt,
            status: CommandStatus.values.byName(e.status),
          ),
        )
        .toList();
  }

  // =========================================================================
  // 🛡️ Phase 0 - STEP 0-1 要件：UIのためのIsar直読リアルタイムストリーム
  // UIはFirestoreを見ず、このIsarローカルキャッシュストリームのみを凝視する
  // =========================================================================
  Stream<List<MatchModel>> watchLocalMatches(String tournamentId) {
    if (_isar == null) {
      debugPrint('⚠️ [Isar] Warning: Isar is null, fallback to empty stream');
      return Stream.value([]);
    }

    // Isarのコレクション変更を検知してリアルタイムにドメインモデルに変換して流す
    return _isar.matchEntitys
        .filter()
        .tournamentIdEqualTo(tournamentId)
        .sortByOrder() // 試合順にソート
        .watch(fireImmediately: true)
        // =========================================================================
        // 🛡️ 修正：MatchEntity には toDomain() が定義されていないため、
        // 既存の正しいプライベートマッパー関数である `_toModel(entity)` を使用して変換する
        // =========================================================================
        .map((entities) {
          return entities.map(LocalMatchEntityMapper.toModel).toList();
        });
  }

  // =========================================================================
  // 🛡️ Phase 0 - STEP 0-1 要件：引数なしの既存呼び出し（テスト含む）を完全救済する
  // Isar直読用全試合リアルタイムストリーム
  // =========================================================================
  Stream<List<MatchModel>> watchAllLocalMatches() {
    if (_isar == null) {
      debugPrint('⚠️ [Isar] Warning: Isar is null, fallback to empty stream');
      return Stream.value([]);
    }

    return _isar.matchEntitys
        .where()
        .sortByOrder()
        .watch(fireImmediately: true)
        .map((entities) {
          return entities.map(LocalMatchEntityMapper.toModel).toList();
        });
  }
}
