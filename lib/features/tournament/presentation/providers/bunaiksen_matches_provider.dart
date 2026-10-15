import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

final bunaiksenMatchesStreamProvider = StreamProvider.family
    .autoDispose<List<MatchModel>, String>((ref, tournamentId) {
      final targetTournamentId = tournamentId.isNotEmpty
          ? tournamentId
          : 'bunaiksen_default';

      final firestore = ref.watch(firestoreProvider);
      final dojoId = ref.watch(currentDojoIdProvider);
      final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';

      // ignore: invalid_use_of_visible_for_testing_member
      if (kIsWeb || debugIsWebOverride) {
        return firestore
            .collection('organizations')
            .doc(safeDojoId)
            .collection('tournaments')
            .doc(targetTournamentId)
            .collection('matches')
            .snapshots()
            .map((snap) {
              return snap.docs
                  .map((doc) {
                    try {
                      final data = MatchDataSanitizer.sanitizeFirestoreData(
                        doc.data(),
                      );
                      final match = MatchModel.fromJson({
                        ...data,
                        'id': doc.id,
                        'tournamentId': targetTournamentId,
                      });
                      return MatchDataSanitizer.healRepresentativeMatch(match);
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<MatchModel>()
                  .toList();
            });
      } else {
        final controller = StreamController<List<MatchModel>>();
        StreamSubscription? sub;

        controller.onListen = () {
          sub = firestore
              .collection('organizations')
              .doc(safeDojoId)
              .collection('tournaments')
              .doc(targetTournamentId)
              .collection('matches')
              .snapshots()
              .listen(
                (snap) async {
                  if (controller.isClosed) return;
                  final matches = snap.docs
                      .map((doc) {
                        try {
                          final data = MatchDataSanitizer.sanitizeFirestoreData(
                            doc.data(),
                          );
                          final match = MatchModel.fromJson({
                            ...data,
                            'id': doc.id,
                            'tournamentId': targetTournamentId,
                          });
                          return MatchDataSanitizer.healRepresentativeMatch(
                            match,
                          );
                        } catch (_) {
                          return null;
                        }
                      })
                      .whereType<MatchModel>()
                      .toList();

                  final healedMatches = matches
                      .map(MatchDataSanitizer.healMatchSignatures)
                      .toList();

                  // 🗄️ ネイティブ環境: FirestoreデータをIsarにキャッシュして双方向同期を保証
                  if (healedMatches.isNotEmpty) {
                    try {
                      final localRepo = ref.read(localMatchRepositoryProvider);
                      await localRepo.saveMatchesBulk(healedMatches);
                    } catch (e) {
                      debugPrint(
                        '[WARN] [bunaiksenMatchesStreamProvider] Isarキャッシュ書き込み失敗: $e',
                      );
                    }
                  }

                  if (!controller.isClosed) {
                    controller.add(healedMatches);
                  }
                },
                onError: (e) {
                  if (!controller.isClosed) controller.add([]);
                },
              );
        };

        ref.onDispose(() {
          sub?.cancel();
          if (!controller.isClosed) controller.close();
        });

        return controller.stream;
      }
    });

final bunaiksenAvailableDatesProvider = StreamProvider.autoDispose<Set<String>>((
  ref,
) {
  final dojoId = ref.watch(currentDojoIdProvider);
  final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';

  FirebaseFirestore? firestore;
  try {
    firestore = ref.watch(firestoreProvider);
  } catch (e) {
    debugPrint('[WARN] [日付同期] Firestore取得失敗: $e');
  }

  if (firestore == null) {
    try {
      final localRepository = ref.watch(localMatchRepositoryProvider);
      return localRepository.watchAllLocalMatches().map((allMatches) {
        return allMatches
            .where(
              (m) =>
                  m.tournamentId != null &&
                  m.tournamentId!.startsWith('bunaiksen_'),
            )
            .map((m) => m.tournamentId!.replaceFirst('bunaiksen_', ''))
            .toSet();
      });
    } catch (e) {
      debugPrint('[WARN] [日付同期] LocalRepository取得失敗: $e');
      return Stream.value(const <String>{});
    }
  }

  // ✅ 【Plan 2 最適化】matches collectionGroupに対して部内戦('bunaiksen_')プレフィックスでFirestore絞り込み。
  // 通常大会（何千試合）の無差別受信・課金・CPU過大消費を完全遮断し、自テナントのパスから安全に抽出する。
  return firestore
      .collectionGroup('matches')
      .where('tournamentId', isGreaterThanOrEqualTo: 'bunaiksen_')
      .where('tournamentId', isLessThan: 'bunaiksen_\uf8ff')
      .snapshots()
      .map((snap) {
        final prefix = 'organizations/$safeDojoId/tournaments/';
        return snap.docs
            .where((doc) => doc.reference.path.startsWith(prefix))
            .map((doc) {
              // path: organizations/{dojoId}/tournaments/{tournamentId}/matches/{matchId}
              final segments = doc.reference.path.split('/');
              if (segments.length != 6 ||
                  segments[0] != 'organizations' ||
                  segments[2] != 'tournaments' ||
                  segments[4] != 'matches') {
                return null;
              }
              return segments[3];
            })
            .whereType<String>()
            .where((id) => id.startsWith('bunaiksen_'))
            .map((id) => id.replaceFirst('bunaiksen_', ''))
            .toSet();
      });
});

final bunaiksenMatchesProvider = Provider.family
    .autoDispose<List<MatchModel>, String>((ref, tournamentId) {
      final targetTournamentId = tournamentId.isNotEmpty
          ? tournamentId
          : 'bunaiksen_default';

      final asyncVal = ref.watch(
        bunaiksenMatchesStreamProvider(targetTournamentId),
      );

      List<MatchModel> matches;
      // ignore: invalid_use_of_visible_for_testing_member
      if (kIsWeb || debugIsWebOverride) {
        matches = asyncVal.value ?? const [];
      } else {
        final allMatches = ref.watch(matchListProvider);
        matches = allMatches
            .where((m) => m.tournamentId == targetTournamentId)
            .toList();
      }

      final sorted = List<MatchModel>.from(matches);
      sorted.sort((a, b) {
        final aFinished = a.status == 'finished' || a.status == 'approved';
        final bFinished = b.status == 'finished' || b.status == 'approved';
        final aInProgress = a.status == 'in_progress';
        final bInProgress = b.status == 'in_progress';
        if (aFinished && !bFinished) return 1;
        if (!aFinished && bFinished) return -1;
        if (aInProgress && !bInProgress) return -1;
        if (!aInProgress && bInProgress) return 1;
        return a.order.compareTo(b.order);
      });
      return sorted;
    });
