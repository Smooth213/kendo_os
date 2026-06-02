import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/infrastructure/persistence/models/match_projection_entity.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart'; // ★ 既存の isarProvider を流用するためインポート

class IsarProjectionStore {
  final Isar? _isar;
  IsarProjectionStore(this._isar);

  // =========================================================================
  // 🛡️ Phase 0 - STEP 0-2 要件：プロジェクションのIsar高速永続化（エラー修復版）
  // =========================================================================
  Future<void> saveMatchProjection(MatchModel match) async {
    if (_isar == null || kIsWeb) {
      return;
    }

    final entity = MatchProjectionEntity()
      ..matchId = match.id
      ..tournamentId = match.tournamentId ?? ''
      ..category = match.category
      ..groupName = match.groupName
      ..matchOrder = match.order
          .toInt() // 🌟 補正：doubleを明示的にintにキャスト
      ..redName = match.redName
      ..whiteName = match.whiteName
      ..redScore = match.redScore
      ..whiteScore = match.whiteScore
      ..status = match.status
      ..lastUpdatedAt =
          DateTime.now(); // 🌟 補正：ドメインaggregateに含まれないwinnerNameの直接代入を排除

    await _isar.writeTxn(() async {
      // 🌟 補正：スマートキャストが効いているため「!」を完全撤去
      final existing = await _isar.matchProjectionEntitys
          .filter()
          .matchIdEqualTo(match.id)
          .findFirst();
      if (existing != null) {
        entity.id = existing.id;
      }
      await _isar.matchProjectionEntitys.put(entity);
    });
    debugPrint('💾 [Isar Projection] 試合キャッシュをディスクに同期しました: ${match.id}');
  }

  // キャッシュから特定の大会の全プロジェクションを高速復元
  Future<List<MatchProjectionEntity>> getTournamentProjections(
    String tournamentId,
  ) async {
    if (_isar == null) return [];
    return await _isar
        .matchProjectionEntitys // 🌟 補正：「!」を完全撤去
        .filter()
        .tournamentIdEqualTo(tournamentId)
        .sortByMatchOrder()
        .findAll();
  }
}

final isarProjectionStoreProvider = Provider<IsarProjectionStore>((ref) {
  final isar = ref.watch(isarProvider); // 🌟 補正：単一の真実からIsarインスタンスを安全に購読
  return IsarProjectionStore(isar);
});
