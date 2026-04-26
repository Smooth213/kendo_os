// ignore_for_file: experimental_member_use
import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../models/local/match_entity.dart';
import '../models/score_event.dart';
import 'dart:convert'; // ★ 追加: Ruleを文字列に圧縮・解凍するための道具
import '../models/match_rule.dart'; // ★ 追加: MatchRuleの型を認識させるため
import '../providers/match_command_provider.dart'; // ★ 追加: MatchCommandModel等の型を認識させるため

// アプリ起動時に main.dart で初期化された Isar を受け取る Provider
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('main.dartでIsarを初期化してoverrideしてください');
});

final localMatchRepositoryProvider = Provider<LocalMatchRepository>((ref) {
  return LocalMatchRepository(ref.read(isarProvider));
});

class LocalMatchRepository {
  final Isar _isar;
  LocalMatchRepository(this._isar);

  // 1. 試合一覧をローカルからリアルタイム取得
  Stream<List<MatchModel>> watchMatches() {
    return _isar.matchEntitys.where().watch(fireImmediately: true).map((entities) {
      return entities.map((e) => _toModel(e)).toList();
    });
  }

  // 2. 特定の1試合をローカルからリアルタイム監視
  Stream<MatchModel?> watchSingleMatch(String matchId) {
    return _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).watch(fireImmediately: true).map((entities) {
      if (entities.isEmpty) return null;
      return _toModel(entities.first);
    });
  }

  // ★ 追加: DBから直接最新の試合データを1件取得（RiverpodのStream遅延を回避するため）
  Future<MatchModel?> getMatch(String matchId) async {
    final entity = await _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).findFirst();
    if (entity == null) return null;
    return _toModel(entity);
  }

  // 3. 試合をローカルに保存（ここが単一真実への書き込み）
  Future<void> saveMatch(MatchModel match) async {
    final entity = _toEntity(match);
    await _isar.writeTxn(() async {
      // 既存データを検索し、Isar内部のID(autoIncrement)を引き継いで上書き更新する
      final existing = await _isar.matchEntitys.filter().firestoreIdEqualTo(match.id).findFirst();
      if (existing != null) {
        entity.id = existing.id;
      }
      await _isar.matchEntitys.put(entity);
    });
  }

  // 4. 複数試合を一括保存（バッチ処理の代替）
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {
    await _isar.writeTxn(() async {
      for (var match in matches) {
        final entity = _toEntity(match);
        final existing = await _isar.matchEntitys.filter().firestoreIdEqualTo(match.id).findFirst();
        if (existing != null) entity.id = existing.id;
        await _isar.matchEntitys.put(entity);
      }
    });
  }

  // 5. 試合の削除
  Future<void> deleteMatch(String matchId) async {
    await _isar.writeTxn(() async {
      await _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).deleteAll();
    });
  }

  // ★ Phase 3 復旧: 同期キュー（未送信データ）の取得
  Future<List<MatchModel>> getPendingMatches() async {
    final entities = await _isar.matchEntitys.filter().isDirtyEqualTo(true).findAll();
    return entities.map((e) => _toModel(e)).toList();
  }

  // ★ Phase 3 復旧: 同期完了処理（isDirtyをfalseにする）
  Future<void> markAsSynced(String matchId) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.matchEntitys.filter().firestoreIdEqualTo(matchId).findFirst();
      if (entity != null) {
        entity.isDirty = false;
        await _isar.matchEntitys.put(entity);
      }
    });
  }

  // ★ Phase 6: UI表示用 - 未送信データの「件数」をリアルタイム監視するストリーム
  Stream<int> watchPendingMatchesCount() {
    return _isar.matchEntitys.filter().isDirtyEqualTo(true).watch(fireImmediately: true).map((events) => events.length);
  }

  // --- 翻訳機（マッパー関数） ---
  MatchEntity _toEntity(MatchModel model) {
    return MatchEntity()
      ..firestoreId = model.id
      ..matchType = model.matchType
      ..redName = model.redName
      ..whiteName = model.whiteName
      ..redScore = model.redScore
      ..whiteScore = model.whiteScore
      ..status = model.status
      ..events = model.events.map((e) => ScoreEventEntity()
        ..id = e.id
        ..side = e.side
        ..type = e.type
        ..timestamp = e.timestamp
        ..userId = e.userId
        ..sequence = e.sequence
        ..isCanceled = e.isCanceled
      ).toList()
      // ★ Phase 1: スナップショットのエンティティ変換を追加（Isarへの保存）
      ..snapshots = model.snapshots.map((s) => MatchSnapshotEntity()
        ..id = s.id
        ..createdAt = s.createdAt
        ..reason = s.reason
        ..events = s.events.map((e) => ScoreEventEntity()
          ..id = e.id
          ..side = e.side
          ..type = e.type
          ..timestamp = e.timestamp
          ..userId = e.userId
          ..sequence = e.sequence
          ..isCanceled = e.isCanceled
        ).toList()
      ).toList()
      ..isDirty = model.isDirty
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

  MatchModel _toModel(MatchEntity entity) {
    return MatchModel(
      id: entity.firestoreId,
      matchType: entity.matchType,
      redName: entity.redName,
      whiteName: entity.whiteName,
      redScore: entity.redScore,
      whiteScore: entity.whiteScore,
      status: entity.status,
      events: entity.events.map((e) => ScoreEvent(
        id: e.id ?? '',
        side: e.side,
        type: e.type,
        timestamp: e.timestamp ?? DateTime.now(),
        userId: e.userId,
        sequence: e.sequence,
        isCanceled: e.isCanceled,
      )).toList(),
      // ★ Phase 1: スナップショットのモデル変換を追加（Isarからの読み込み）
      snapshots: entity.snapshots.map((s) => MatchSnapshot(
        id: s.id ?? '',
        createdAt: s.createdAt ?? DateTime.now(),
        reason: s.reason ?? '',
        events: s.events.map((e) => ScoreEvent(
          id: e.id ?? '',
          side: e.side,
          type: e.type,
          timestamp: e.timestamp ?? DateTime.now(),
          userId: e.userId,
          sequence: e.sequence,
          isCanceled: e.isCanceled,
        )).toList(),
      )).toList(),
      isDirty: entity.isDirty,
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
      remainingSeconds: entity.remainingSeconds,
      timerIsRunning: entity.timerIsRunning,
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
    final entity = MatchCommandEntity()
      ..id = cmd.id
      ..type = cmd.type.name
      ..payloadJson = jsonEncode(cmd.payload)
      ..createdAt = cmd.createdAt
      ..status = cmd.status.name;

    await _isar.writeTxn(() async {
      await _isar.matchCommandEntitys.put(entity);
    });
  }

  Future<void> deleteCommand(String id) async {
    await _isar.writeTxn(() async {
      await _isar.matchCommandEntitys.filter().idEqualTo(id).deleteAll();
    });
  }

  Future<List<MatchCommandModel>> getPendingCommands() async {
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