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
        final localRepository = ref.watch(localMatchRepositoryProvider);
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

                  try {
                    await localRepository.saveMatchesBulk(healedMatches);
                  } catch (e) {
                    debugPrint('⚠️ [Sync Exception] Isar一括保存エラー: $e');
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

final bunaiksenAvailableDatesProvider = StreamProvider.autoDispose<Set<String>>(
  (ref) {
    final dojoId = ref.watch(currentDojoIdProvider);
    final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';

    FirebaseFirestore? firestore;
    try {
      firestore = ref.watch(firestoreProvider);
    } catch (e) {
      debugPrint('⚠️ [日付同期] Firestore取得失敗: $e');
    }

    if (firestore == null) {
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
    }

    return firestore.collectionGroup('matches').snapshots().map((snap) {
      return snap.docs
          .where((doc) {
            final path = doc.reference.path;
            return path.contains('organizations/$safeDojoId/');
          })
          .map((doc) {
            try {
              return doc.data()['tournamentId'] as String?;
            } catch (_) {
              return null;
            }
          })
          .whereType<String>()
          .where((id) => id.startsWith('bunaiksen_'))
          .map((id) => id.replaceFirst('bunaiksen_', ''))
          .toSet();
    });
  },
);

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

        debugPrint('🔍🔍 [剣道OS ログ] Isarデータパイプラインリアルタイム監視 🔍🔍');
        debugPrint(' 1. 画面側から要求された日付ID = "$targetTournamentId"');
        debugPrint(' 2. 現在Isarローカルディスクに保存されている総試合数 = ${allMatches.length} 件');

        matches = allMatches
            .where((m) => m.tournamentId == targetTournamentId)
            .toList();
        debugPrint(' 3. 条件に合致して画面へ美しく表示する試合数 = ${matches.length} 件');
        debugPrint('🔍🔍 [剣道OS ログ] 監視終了 🔍🔍');
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
