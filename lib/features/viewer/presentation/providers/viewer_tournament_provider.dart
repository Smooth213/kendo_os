import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// 観客席画面用 大会情報取得プロバイダ
final viewerTournamentProvider = StreamProvider.family.autoDispose<TournamentModel?, String>((
  ref,
  id,
) async* {
  final firestore = FirebaseFirestore.instance;
  final currentDojoId = ref.watch(currentDojoIdProvider);

  debugPrint(
    '🔎 [viewerTournamentProvider] start - id: $id, currentDojoId: $currentDojoId',
  );

  try {
    if (currentDojoId.isNotEmpty) {
      final orgTournamentDoc = await firestore
          .collection('organizations')
          .doc(currentDojoId)
          .collection('tournaments')
          .doc(id)
          .get();

      if (orgTournamentDoc.exists) {
        debugPrint(
          '🔎 [viewerTournamentProvider] found in organizations/$currentDojoId/tournaments',
        );
        yield* firestore
            .collection('organizations')
            .doc(currentDojoId)
            .collection('tournaments')
            .doc(id)
            .snapshots()
            .map((doc) {
              if (!doc.exists) return null;
              return TournamentModel.fromJson({...doc.data()!, 'id': doc.id});
            });
        return;
      }

      debugPrint(
        '⚠️ [viewerTournamentProvider] currentDojoId($currentDojoId) の大会が見つかりませんでした。フォールバック検索を継続します。',
      );
    }

    final rootTournamentDoc = await firestore
        .collection('tournaments')
        .doc(id)
        .get();
    debugPrint(
      '🔎 [viewerTournamentProvider] root doc exists: ${rootTournamentDoc.exists}',
    );
    if (rootTournamentDoc.exists) {
      debugPrint('🔎 [viewerTournamentProvider] found in tournaments/$id');
      yield* firestore.collection('tournaments').doc(id).snapshots().map((doc) {
        if (!doc.exists) return null;
        return TournamentModel.fromJson({...doc.data()!, 'id': doc.id});
      });
      return;
    }

    final groupTournamentQuery = await firestore
        .collectionGroup('tournaments')
        .where(FieldPath.documentId, isEqualTo: id)
        .limit(1)
        .get();

    debugPrint(
      '🔎 [viewerTournamentProvider] collectionGroup tournaments found: ${groupTournamentQuery.docs.length}',
    );

    if (groupTournamentQuery.docs.isNotEmpty) {
      final docRef = groupTournamentQuery.docs.first.reference;
      debugPrint(
        '🔎 [viewerTournamentProvider] found in collectionGroup at path: ${docRef.path}',
      );
      yield* docRef.snapshots().map((doc) {
        if (!doc.exists) return null;
        return TournamentModel.fromJson({...doc.data()!, 'id': doc.id});
      });
      return;
    }

    final matchQuery = await firestore
        .collectionGroup('matches')
        .where('tournamentId', isEqualTo: id)
        .limit(1)
        .get();

    if (matchQuery.docs.isNotEmpty) {
      final matchRef = matchQuery.docs.first.reference;
      final pathSegments = matchRef.path.split('/');
      final orgIndex = pathSegments.indexOf('organizations');

      if (orgIndex != -1 && pathSegments.length > orgIndex + 1) {
        final orgId = pathSegments[orgIndex + 1];
        yield* firestore
            .collection('organizations')
            .doc(orgId)
            .collection('tournaments')
            .doc(id)
            .snapshots()
            .map((doc) {
              if (!doc.exists) return null;
              return TournamentModel.fromJson({...doc.data()!, 'id': doc.id});
            });
        return;
      }
    }

    yield null;
  } catch (e, st) {
    debugPrint('🚨 [viewerTournamentProvider] エラー: $e\n$st');
    yield null;
  }
});
