import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// 観客席画面用 大会情報取得プロバイダ
final viewerTournamentProvider = StreamProvider.family
    .autoDispose<TournamentModel?, String>((ref, id) async* {
      final firestore = FirebaseFirestore.instance;
      final currentDojoId = ref.watch(currentDojoIdProvider);

      debugPrint(
        '[viewerTournamentProvider] start - id: $id, currentDojoId: $currentDojoId',
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
              '[viewerTournamentProvider] found in organizations/$currentDojoId/tournaments',
            );
            yield* firestore
                .collection('organizations')
                .doc(currentDojoId)
                .collection('tournaments')
                .doc(id)
                .snapshots()
                .map((doc) {
                  if (!doc.exists) return null;
                  return TournamentModel.fromJson({
                    ...doc.data()!,
                    'id': doc.id,
                  });
                });
            return;
          }

          debugPrint(
            '[WARN] [viewerTournamentProvider] currentDojoId($currentDojoId) の大会が見つかりませんでした。フォールバック検索を継続します。',
          );
        }

        yield null;
      } catch (e, st) {
        debugPrint('[ERROR] [viewerTournamentProvider] エラー: $e\n$st');
        yield null;
      }
    });
