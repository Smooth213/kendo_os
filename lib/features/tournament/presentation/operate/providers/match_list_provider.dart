import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_data_sanitizer.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';

import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

export 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_matches_provider.dart';
export 'match_data_sanitizer.dart';

@visibleForTesting
bool debugIsWebOverride = false;

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final webCurrentTournamentMatchesProvider = StateProvider<List<MatchModel>>(
  (ref) => [],
);
final webCurrentTournamentIdProvider = StateProvider<String?>((ref) => null);

final matchStreamProvider = StreamProvider<List<MatchModel>>((ref) {
  if (kIsWeb || debugIsWebOverride) {
    debugPrint('🌐 [Web Environment Detected] Isarの代わりにメモリ/クラウド監視ラインを確立します');
    return Stream.value([]);
  }

  final localRepository = ref.watch(localMatchRepositoryProvider);
  return localRepository.watchAllLocalMatches().map((matches) {
    if (matches.isEmpty) {
      debugPrint(
        '⏳ [Startup Restore] Isar内にローカルキャッシュがありません。クラウド同期をバックグラウンドで待機します。',
      );
    } else {
      debugPrint(
        '⚡ [Startup Restore] Isarローカルディスクから ${matches.length} 件の試合状態を一瞬で完全復元しました（電波ゼロOK）',
      );
    }
    return matches;
  });
});

final matchListProvider = Provider<List<MatchModel>>((ref) {
  if (kIsWeb || debugIsWebOverride) {
    final currentTournamentId = ref.watch(webCurrentTournamentIdProvider);
    if (currentTournamentId == null || currentTournamentId.isEmpty) {
      return const [];
    }
    return ref.watch(webCurrentTournamentMatchesProvider);
  }
  return ref.watch(matchStreamProvider).value ?? const [];
});

final matchListByTournamentProvider = StreamProvider.family<List<MatchModel>, String>((
  ref,
  tournamentId,
) {
  if (kIsWeb || debugIsWebOverride) {
    final firestore = ref.watch(firestoreProvider);
    final dojoId = ref.watch(currentDojoIdProvider);

    final safeDojoId = dojoId.isNotEmpty ? dojoId : 'default_org';
    final safeTournamentId = tournamentId.isNotEmpty
        ? tournamentId
        : 'default_tournament';

    debugPrint(
      '🌐 [matchListByTournamentProvider] Webモード単方向直列監視開始 - dojoId: "$safeDojoId", tournamentId: "$safeTournamentId"',
    );

    final controller = StreamController<List<MatchModel>>();
    StreamSubscription? sub;

    MatchModel? parseMatch(DocumentSnapshot<Map<String, dynamic>> doc) {
      try {
        final data = MatchDataSanitizer.sanitizeFirestoreData(doc.data() ?? {});
        final match = MatchModel.fromJson({
          ...data,
          'id': doc.id,
          'tournamentId': safeTournamentId,
        });
        return MatchDataSanitizer.healRepresentativeMatch(match);
      } catch (e) {
        debugPrint('🚨 [Parse Error] ID:${doc.id} -> $e');
        return null;
      }
    }

    controller.onListen = () {
      sub = firestore
          .collection('organizations')
          .doc(safeDojoId)
          .collection('tournaments')
          .doc(safeTournamentId)
          .collection('matches')
          .snapshots()
          .listen(
            (snap) {
              if (controller.isClosed) return;
              final matches = snap.docs
                  .map(parseMatch)
                  .whereType<MatchModel>()
                  .toList();

              controller.add(matches);

              Future.microtask(() {
                try {
                  ref.read(webCurrentTournamentMatchesProvider.notifier).state =
                      matches;
                  ref.read(webCurrentTournamentIdProvider.notifier).state =
                      safeTournamentId;
                  ref.read(currentTournamentIdProvider.notifier).state =
                      safeTournamentId;
                  ref.read(currentDojoIdProvider.notifier).state = safeDojoId;
                } catch (_) {}
              });
            },
            onError: (e) {
              debugPrint('🚨 [Match Query Error] Web: $e');
              if (!controller.isClosed) {
                controller.add([]);
              }
            },
          );
    };

    ref.onDispose(() {
      sub?.cancel();
      if (!controller.isClosed) {
        controller.close();
      }
    });

    return controller.stream;
  }

  final localRepository = ref.watch(localMatchRepositoryProvider);
  final dojoId = ref.watch(currentDojoIdProvider);

  if (dojoId.isNotEmpty && tournamentId.isNotEmpty) {
    final firestore = ref.watch(firestoreProvider);
    final safeDojoId = dojoId;
    final safeTournamentId = tournamentId;

    final isBunaiksen =
        safeTournamentId.startsWith('bunaiksen_') ||
        safeTournamentId == 'bunaiksen';
    debugPrint(
      '📱 [matchListByTournamentProvider] Native mode background listener start - dojoId: "$safeDojoId", tournamentId: "$safeTournamentId" (isBunaiksen: $isBunaiksen)',
    );

    final matchesCollection = firestore
        .collection('organizations')
        .doc(safeDojoId)
        .collection('tournaments')
        .doc(safeTournamentId)
        .collection('matches');

    final sub = matchesCollection.snapshots().listen(
      (snap) async {
        try {
          final matches = <MatchModel>[];
          for (final doc in snap.docs) {
            try {
              final sanitized = MatchDataSanitizer.sanitizeFirestoreData(
                doc.data(),
              );
              final match = MatchDataSanitizer.healRepresentativeMatch(
                MatchModel.fromJson({...sanitized, 'id': doc.id}),
              );
              matches.add(match);
            } catch (e) {
              debugPrint(
                '⚠️ [Native Downstream Sync] Match parsing failed for doc ${doc.id}: $e',
              );
            }
          }

          if (matches.isNotEmpty) {
            final healedMatches = matches
                .map(MatchDataSanitizer.healMatchSignatures)
                .toList();
            await localRepository.saveMatchesBulk(healedMatches);
            debugPrint(
              '⚡ [Native Downstream Sync] Firestoreから ${healedMatches.length} 件の試合データをIsarに同期しました。',
            );
          }
        } catch (e) {
          debugPrint(
            '🔥 [Native Downstream Sync Critical] Isarへのバルクインサート中にエラーが発生しました: $e',
          );
        }
      },
      onError: (e) {
        debugPrint('🚨 [Native Downstream Sync] Firestore listen error: $e');
      },
    );

    ref.onDispose(() {
      debugPrint(
        '📱 [matchListByTournamentProvider] Native mode background listener disposed for tournamentId: $safeTournamentId',
      );
      sub.cancel();
    });
  }

  return localRepository.watchLocalMatches(tournamentId);
});

final currentDojoNameProvider = StreamProvider.autoDispose<String>((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  final safeDojoId = dojoId.isNotEmpty ? dojoId : 'test201';
  FirebaseFirestore? firestore;
  try {
    firestore = ref.watch(firestoreProvider);
  } catch (_) {}
  if (firestore == null) return Stream.value('');
  return firestore
      .collection('organizations')
      .doc(safeDojoId)
      .snapshots()
      .map((doc) => doc.exists ? (doc.data()?['name'] as String? ?? '') : '');
});
