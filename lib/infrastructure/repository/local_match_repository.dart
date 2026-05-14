// ignore_for_file: experimental_member_use
import 'package:isar_community/isar.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/infrastructure/persistence/models/match_entity.dart';
import 'package:kendo_os/domain/entities/score_event.dart'; // ★ ScoreEventの型認識のため追加
import 'dart:convert'; // ★ 追加: Ruleを文字列に圧縮・解凍するための道具
import 'package:kendo_os/domain/rules/match_rule.dart'; // ★ 追加: MatchRuleの型を認識させるため
import 'package:kendo_os/presentation/operate/providers/match_command_provider.dart'; // ★ 追加: MatchCommandModel等の型を認識させるため
import 'package:kendo_os/domain/entities/match_aggregate.dart'; // ★ 追加
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import 'package:flutter/foundation.dart'; // ★ 追加: debugPrint
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // ★ 追加: クラッシュレポート用

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
    return _isar.matchEntitys.where().watch(fireImmediately: true).map((entities) {
      return entities.map((e) => _toModel(e)).toList();
    });
  }

  // 2. 特定の1試合をローカルからリアルタイム監視
  Stream<MatchModel?> watchSingleMatch(String matchId) {
    if (_isar == null) return Stream.value(null);
    return _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).watch(fireImmediately: true).map((entities) {
      if (entities.isEmpty) return null;
      return _toModel(entities.first);
    });
  }

  // ★ 追加: DBから直接最新の試合データを1件取得（RiverpodのStream遅延を回避するため）
  Future<MatchModel?> getMatch(String matchId) async {
    if (_isar == null) return null;
    try {
      final entity = await _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).findFirst();
      if (entity == null) return null;

      // ★ Phase 7: カオス耐性 - データの整合性チェック
      if (entity.status == 'in_progress' && entity.events.isEmpty) {
        debugPrint('⚠️ [Chaos Recovery] 進行中の試合なのにイベントが空です。データの不整合を検知しました。');
        // ここで必要に応じてサーバーからの再取得フラグを立てる等の処置が可能
      }

      return _toModel(entity);
    } catch (e, stack) {
      // ★ Phase 7: 万が一ローカルDBが破損していた場合の緊急回避
      debugPrint('🔥 [Critical] ローカルDBからの読み込みに失敗しました(破損の可能性): $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Local DB Read Failure');
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
        if (!ScoreEventLegacyAdapter.verifySignature(event, 'kendo_os_secret_key_v1')) {
          throw TamperedEventException('イベント(ID: ${event.id})の署名が無効、または改ざんされています。');
        }
      }

      final entity = _toEntity(match);
      await _isar.writeTxn(() async {
        // ★ 修正: putByFirestoreIdがEmbeddedリストの更新でクラッシュし、
        // トランザクション全体がロールバックして「試合が追加されないバグ」を防ぐため、
        // findFirstで既存IDを引き継いでから通常のputを行う「最も安全なUpsert」に切り替えます。
        final existing = await _isar.matchEntitys.filter().firestoreIdEqualTo(match.id).findFirst();
        if (existing != null) {
          entity.id = existing.id; // 既存の内部IDを引き継いで上書き更新する
        }
        await _isar.matchEntitys.put(entity);
      });
    } catch (e, stack) {
      debugPrint('🔥 [Storage Error] ローカルDBへの保存に失敗しました: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Local DB Save Failure');
      
      // ★ Phase 7: 最後の一線 - DBがロックされていても、JSONとして緊急避難保存を試みる
      try {
        final emergencyJson = jsonEncode(match.toJson());
        final dir = await getApplicationDocumentsDirectory();
        // 試合ごとにユニークなファイル名で保存し、上書きを防ぐ
        final file = File('${dir.path}/emergency_backup_${match.id}_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(emergencyJson);
        debugPrint('🛡️ [Emergency Backup] DB保存失敗のため、緊急JSONバックアップを実行しました: ${file.path}');
      } catch (innerE, innerStack) {
        debugPrint('🚨 [Fatal] 緊急バックアップすら失敗しました: $innerE');
        FirebaseCrashlytics.instance.recordError(innerE, innerStack, reason: 'Emergency Backup Failure');
      }
      
      rethrow;
    }
  }

  // 4. 複数試合を一括保存（バッチ処理の代替）
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {
    if (_isar == null) return;
    // ★ 複数保存時もすべてのイベントの署名を検証する
    for (final match in matches) {
      for (final event in match.events) {
        if (!ScoreEventLegacyAdapter.verifySignature(event, 'kendo_os_secret_key_v1')) {
          throw TamperedEventException('イベント(ID: ${event.id})の署名が無効、または改ざんされています。');
        }
      }
    }

    await _isar.writeTxn(() async {
      for (var match in matches) {
        final entity = _toEntity(match);
        final existing = await _isar.matchEntitys.filter().firestoreIdEqualTo(match.id).findFirst();
        if (existing != null) {
          entity.id = existing.id; // ここでも既存IDを引き継ぐ
        }
        await _isar.matchEntitys.put(entity);
      }
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
    final entities = await _isar.matchEntitys.filter().not().syncStateEqualTo(SyncState.synced).findAll();
    return entities.map((e) => _toModel(e)).toList();
  }

  // ★ Phase 4 復旧: 同期完了処理
  Future<void> markAsSynced(String matchId) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      final entity = await _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).findFirst();
      if (entity != null) {
        entity.syncState = SyncState.synced;
        entity.pendingEvents = []; // ★ 送信が完了したため差分キューを空にする
        await _isar.matchEntitys.put(entity);
      }
    });
  }

  // ★ Phase 4 復旧: Isarの正しい否定構文に修正
  Stream<int> watchPendingMatchesCount() {
    if (_isar == null) return Stream.value(0);
    return _isar.matchEntitys.filter().not().syncStateEqualTo(SyncState.synced).watch(fireImmediately: true).map((events) => events.length);
  }

  ScoreEventEntity _eventToEntity(ScoreEvent e) {
    return ScoreEventEntity()
      ..id = e.id
      ..side = e.side
      ..type = e.type
      ..timestamp = e.timestamp
      ..userId = e.userId
      ..sequence = e.sequence
      ..isCanceled = e.isCanceled
      ..isUndo = e.isUndo
      ..isRestore = e.isRestore
      ..deviceId = e.deviceId
      ..logicalClock = e.logicalClock
      ..signature = e.signature;
  }

  // --- 翻訳機（マッパー関数） ---
  MatchEntity _toEntity(MatchModel model) {
    return MatchEntity()
      ..id = Isar.autoIncrement // ★ ハッシュ関数を捨て、Isarの自動採番に完全に任せる
      ..firestoreId = model.id
      ..matchType = model.matchType
      ..redName = model.redName
      ..whiteName = model.whiteName
      ..redScore = model.redScore
      ..whiteScore = model.whiteScore
      ..status = model.status
      ..events = model.events.map<ScoreEventEntity>((e) => _eventToEntity(e)).toList() // ★ 型を明示的に指定して変換エラーを回避
      ..snapshots = model.snapshots.map((s) => MatchSnapshotEntity()
        ..id = s.id
        ..createdAt = s.createdAt
        ..reason = s.reason
        ..events = s.events.map<ScoreEventEntity>((e) => _eventToEntity(e)).toList()
      ).toList()
      ..syncState = model.syncState
      ..pendingEvents = model.pendingEvents.map<ScoreEventEntity>((e) => _eventToEntity(e)).toList()
      ..lastUpdatedAt = model.lastUpdatedAt
      ..refereeNames = model.refereeNames
      ..countForStandings = model.countForStandings
      ..scorerId = model.scorerId
      ..version = model.version
      ..isAutoAssigned = model.isAutoAssigned
      ..order = model.order
      ..source = model.source
      ..tournamentId = model.tournamentId
      ..category = model.category
      ..groupName = model.groupName
      ..matchOrder = model.matchOrder
      ..matchTimeMinutes = model.matchTimeMinutes
      ..isRunningTime = model.isRunningTime
      ..hasExtension = model.hasExtension
      ..extensionTimeMinutes = model.extensionTimeMinutes
      ..extensionCount = model.extensionCount
      ..hasHantei = model.hasHantei
      ..remainingSeconds = model.remainingSeconds
      ..timerIsRunning = model.timerIsRunning
      ..note = model.note
      ..isKachinuki = model.isKachinuki
      // ★ 追加：複雑なルール箱を文字列(JSON)に圧縮してローカルDBにねじ込む！
      ..ruleJson = model.rule != null ? jsonEncode(model.rule!.toJson()) : null
      ..redRemaining = model.redRemaining
      ..whiteRemaining = model.whiteRemaining;
  }

  ScoreEvent _entityToEvent(ScoreEventEntity e) {
    return ScoreEventLegacyAdapter.fromLegacy(
      id: e.id ?? '',
      side: e.side,
      type: e.type,
      timestamp: e.timestamp ?? DateTime.now(),
      userId: e.userId,
      sequence: e.sequence,
      isCanceled: e.isCanceled,
    ).copyWith(
      isUndo: e.isUndo,
      isRestore: e.isRestore,
      deviceId: e.deviceId,
      logicalClock: e.logicalClock,
      signature: e.signature,
    );
  }

  MatchModel _toModel(MatchEntity entity) {
    return MatchModel(
      id: entity.firestoreId,
      matchType: entity.matchType,
      redName: entity.redName,
      whiteName: entity.whiteName,
      redScore: entity.redScore,
      whiteScore: entity.whiteScore,
      status: entity.status,
      syncState: entity.syncState,
      pendingEvents: entity.pendingEvents.map(_entityToEvent).toList(),
      events: entity.events.map(_entityToEvent).toList(),
      // ★ Phase 1: スナップショットのモデル変換を追加（Isarからの読み込み）
      snapshots: entity.snapshots.map((s) => MatchSnapshot(
        id: s.id ?? '',
        matchId: entity.firestoreId,
        version: s.events.length,
        state: MatchModel(
          id: entity.firestoreId,
          matchType: entity.matchType,
          redName: entity.redName,
          whiteName: entity.whiteName,
        ),
        createdAt: s.createdAt ?? DateTime.now(),
        reason: s.reason ?? '',
        events: s.events.map(_entityToEvent).toList(),
      )).toList(),
      lastUpdatedAt: entity.lastUpdatedAt,
      refereeNames: entity.refereeNames,
      countForStandings: entity.countForStandings,
      scorerId: entity.scorerId,
      version: entity.version,
      isAutoAssigned: entity.isAutoAssigned,
      order: entity.order,
      source: entity.source,
      tournamentId: entity.tournamentId,
      category: entity.category,
      groupName: entity.groupName,
      matchOrder: entity.matchOrder,
      matchTimeMinutes: entity.matchTimeMinutes,
      isRunningTime: entity.isRunningTime,
      hasExtension: entity.hasExtension,
      extensionTimeMinutes: entity.extensionTimeMinutes,
      extensionCount: entity.extensionCount,
      hasHantei: entity.hasHantei,
      note: entity.note,
      isKachinuki: entity.isKachinuki,
      // ★ 追加：文字列(JSON)から元のルール箱に解凍して復元する！
      rule: entity.ruleJson != null ? MatchRule.fromJson(jsonDecode(entity.ruleJson!) as Map<String, dynamic>) : null,
      redRemaining: entity.redRemaining,
      whiteRemaining: entity.whiteRemaining,
    );
  }

  // ============================================================================
  // ★ Phase 2: コマンド永続化（Queue of SSOT）
  // ============================================================================

  Future<void> savePendingCommand(MatchCommandModel cmd) async {
    if (_isar == null) return;
    final entity = MatchCommandEntity()
      ..id = cmd.id
      ..type = cmd.type.name
      ..payloadJson = jsonEncode(cmd.payload)
      ..createdAt = cmd.createdAt
      ..status = cmd.status.name;

    await _isar.writeTxn(() async {
      // ★ 修正: リトライ機能が同じコマンドを何度も保存しようとした際に
      // Unique index violated（一意制約エラー）を出さないよう、既存のIDを引き継いで安全に上書きする
      final existing = await _isar.matchCommandEntitys.filter().idEqualTo(cmd.id).findFirst();
      if (existing != null) {
        entity.isarId = existing.isarId;
      }
      await _isar.matchCommandEntitys.put(entity);
    });
  }

  Future<void> deleteCommand(String id) async {
    if (_isar == null) return;
    await _isar.writeTxn(() async {
      await _isar.matchCommandEntitys.filter().idEqualTo(id).deleteAll();
    });
  }

  Future<List<MatchCommandModel>> getPendingCommands() async {
    if (_isar == null) return [];
    final entities = await _isar.matchCommandEntitys
        .filter()
        .statusEqualTo(CommandStatus.pending.name)
        .sortByCreatedAt()
        .findAll();

    return entities.map((e) => MatchCommandModel(
      id: e.id,
      type: CommandType.values.byName(e.type),
      payload: jsonDecode(e.payloadJson),
      createdAt: e.createdAt,
      status: CommandStatus.values.byName(e.status),
    )).toList();
  }
}