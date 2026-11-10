import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/organization_graduation_type.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// 一括進級の実行結果サマリー
class AnnualPromotionSummary {
  final int promotedCount;
  final int graduatedCount;
  final int unchangedCount;

  const AnnualPromotionSummary({
    required this.promotedCount,
    required this.graduatedCount,
    required this.unchangedCount,
  });

  int get totalProcessed => promotedCount + graduatedCount;
}

// アプリ全体からこの職人（リポジトリ）を呼べるようにするプロバイダー
final playerRepositoryProvider = Provider((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  return PlayerRepository(dojoId: dojoId);
});

class PlayerRepository {
  final FirebaseFirestore _firestore;
  final String dojoId;

  PlayerRepository({required String dojoId, FirebaseFirestore? firestore})
    : dojoId = dojoId.isNotEmpty ? dojoId : 'test201',
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _playersCollection {
    return _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('players');
  }

  CollectionReference<Map<String, dynamic>> get _customTeamsCollection {
    return _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('custom_team_names');
  }

  DocumentReference<Map<String, dynamic>> get _organizationDoc =>
      _firestore.collection('organizations').doc(dojoId);

  // ① 選手一覧を取得する
  Stream<List<PlayerModel>> getPlayers({String organization = ''}) {
    return _playersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PlayerModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// 組織の卒業区分・最終進級年度設定を監視する
  Stream<OrganizationPromotionConfig> watchOrganizationPromotionConfig() {
    return _organizationDoc.snapshots().map(
      (doc) =>
          OrganizationPromotionConfig.fromMap(doc.exists ? doc.data() : null),
    );
  }

  /// 組織の卒業区分を保存する
  Future<void> updateOrganizationGraduationType(
    OrganizationGraduationType type,
  ) async {
    await _organizationDoc.set({
      'graduationType': type.id,
    }, SetOptions(merge: true));
  }

  // ② 選手を新しく追加する
  Future<void> addPlayer(PlayerModel player) async {
    await _playersCollection.add(player.toMap());
  }

  // ③ 選手の情報を手動で更新する（手動で一般に変更する時など！）
  Future<void> updatePlayer(PlayerModel player) async {
    await _playersCollection.doc(player.id).update(player.toMap());
  }

  /// 卒業アーカイブ済みの選手を現役へ復帰させる
  Future<void> reactivatePlayer(String playerId, {int? nextGrade}) async {
    final updateData = <String, dynamic>{
      'status': PlayerModel.statusActive,
      'graduatedFiscalYear': FieldValue.delete(),
      'graduatedAt': FieldValue.delete(),
      'grade': ?nextGrade,
    };
    await _playersCollection.doc(playerId).update(updateData);
  }

  /// 選手を手動で卒業（OB/OG）アーカイブにする
  Future<void> archivePlayerAsGraduated(
    String playerId, {
    int? graduatedFiscalYear,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    await _playersCollection.doc(playerId).update({
      'status': PlayerModel.statusGraduated,
      'graduatedFiscalYear': ?graduatedFiscalYear,
      'graduatedAt': effectiveNow.toIso8601String(),
    });
  }

  // ④ 選手を削除する
  Future<void> deletePlayer(String playerId) async {
    await _playersCollection.doc(playerId).delete();
  }

  // ★⑤ 魔法のボタン用：新年度の一括進級・卒業アーカイブ処理（Firestore 500件バッチ制限安全分割）
  Future<AnnualPromotionSummary> promoteAllPlayers({
    String? organization = '',
    OrganizationGraduationType graduationType =
        OrganizationGraduationType.allAges,
    Set<String> retainPlayerIds = const {},
    int? graduationFiscalYear,
    int? promotionFiscalYear,
    DateTime? now,
    bool recordOrganizationHistory = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final effectiveGradYear =
        graduationFiscalYear ??
        FiscalYearHelper.defaultGraduationFiscalYear(effectiveNow);
    final effectivePromoYear =
        promotionFiscalYear ??
        FiscalYearHelper.targetPromotionFiscalYear(effectiveNow);

    final QuerySnapshot<Map<String, dynamic>> snapshot = organization != null
        ? await _playersCollection
              .where('organization', isEqualTo: organization)
              .get()
        : await _playersCollection.get();

    const int batchLimit = 450;
    WriteBatch batch = _firestore.batch();
    int opCount = 0;
    int promotedCount = 0;
    int graduatedCount = 0;
    int unchangedCount = 0;

    for (final doc in snapshot.docs) {
      final player = PlayerModel.fromMap(doc.data(), doc.id);
      final outcome = graduationType.evaluatePromotion(
        player,
        retainInActive: retainPlayerIds.contains(player.id),
        graduationFiscalYear: effectiveGradYear,
        now: effectiveNow,
      );

      switch (outcome.kind) {
        case PlayerPromotionKind.promoted:
          batch.update(doc.reference, {'grade': outcome.updatedPlayer.grade});
          opCount++;
          promotedCount++;
        case PlayerPromotionKind.graduated:
          batch.update(doc.reference, {
            'status': PlayerModel.statusGraduated,
            'graduatedFiscalYear': outcome.updatedPlayer.graduatedFiscalYear,
            'graduatedAt': outcome.updatedPlayer.graduatedAt?.toIso8601String(),
          });
          opCount++;
          graduatedCount++;
        case PlayerPromotionKind.unchanged:
          unchangedCount++;
      }

      if (opCount >= batchLimit) {
        await batch.commit();
        batch = _firestore.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }

    if (recordOrganizationHistory) {
      await _organizationDoc.set({
        'graduationType': graduationType.id,
        'lastPromotedFiscalYear': effectivePromoYear,
        'lastPromotedAt': effectiveNow.toIso8601String(),
      }, SetOptions(merge: true));
    }

    return AnnualPromotionSummary(
      promotedCount: promotedCount,
      graduatedCount: graduatedCount,
      unchangedCount: unchangedCount,
    );
  }

  // --- よく使う自チーム名（カスタムチーム名）の管理機能 ---

  /// 所属道場に関連付けられたカスタムチーム名の一覧を監視する
  Stream<List<String>> watchCustomTeamNames({String organization = ''}) {
    return _customTeamsCollection
        .where('organization', isEqualTo: organization)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()['name'] as String).toList()
                ..sort(),
        )
        .handleError((error, stackTrace) {
          // 権限エラーやネットワーク遮断時でも例外をスローせず安全に空リストへフォールバック
          return <String>[];
        });
  }

  /// 新しいカスタムチーム名を追加する
  Future<void> addCustomTeamName(
    String name, {
    String organization = '',
  }) async {
    final docId = '${organization}_$name'; // 重複防止のためのID
    await _customTeamsCollection.doc(docId).set({
      'organization': organization,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// カスタムチーム名を削除する
  Future<void> deleteCustomTeamName(
    String name, {
    String organization = '',
  }) async {
    final docId = '${organization}_$name';
    await _customTeamsCollection.doc(docId).delete();
  }
}
