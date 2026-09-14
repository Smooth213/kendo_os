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
    final allMatches = ref.watch(webCurrentTournamentMatchesProvider);
    // ★ Plan 3-④: 大会IDが一致する試合のみを厳格にフィルタリングし、異大会データのゴースト混入を物理的に遮断
    return allMatches
        .where((m) => m.tournamentId == currentTournamentId)
        .toList();
  }
  return ref.watch(matchStreamProvider).value ?? const [];
});

final matchListByTournamentProvider = StreamProvider.family
    .autoDispose<List<MatchModel>, String>((ref, tournamentId) {
      // 🔋 5分間のキャッシュ保持: 画面遷移時の瞬間的な切断・再接続チラつきを防ぎつつ、
      // 誰も見ていない大会のFirestoreリスナーを確実にクリーンアップして通信リークを根絶
      final link = ref.keepAlive();
      Timer? keepAliveTimer;
      ref.onDispose(() => keepAliveTimer?.cancel());
      ref.onCancel(() {
        keepAliveTimer = Timer(const Duration(minutes: 5), () {
          link.close();
        });
      });
      ref.onResume(() {
        keepAliveTimer?.cancel();
      });
      if (kIsWeb || debugIsWebOverride) {
        final firestore = ref.watch(firestoreProvider);
        final dojoId = ref.watch(currentDojoIdProvider);

        final safeDojoId = dojoId.isNotEmpty ? dojoId : 'default_org';
        final safeTournamentId = tournamentId.isNotEmpty
            ? tournamentId
            : 'default_tournament';

        // ★ Plan 3-④: 大会切り替え時に前大会の試合データが画面に残留するのを即時リセット
        final activeWebTournamentId = ref.read(webCurrentTournamentIdProvider);
        if (activeWebTournamentId != safeTournamentId) {
          Future.microtask(() {
            ref.read(webCurrentTournamentMatchesProvider.notifier).state =
                const [];
            ref.read(webCurrentTournamentIdProvider.notifier).state =
                safeTournamentId;
          });
        }

        debugPrint(
          '🌐 [matchListByTournamentProvider] Webモード単方向直列監視開始 - dojoId: "$safeDojoId", tournamentId: "$safeTournamentId"',
        );

        final controller = StreamController<List<MatchModel>>();
        StreamSubscription? sub;

        MatchModel? parseMatch(DocumentSnapshot<Map<String, dynamic>> doc) {
          try {
            final data = MatchDataSanitizer.sanitizeFirestoreData(
              doc.data() ?? {},
            );
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
                      ref
                              .read(
                                webCurrentTournamentMatchesProvider.notifier,
                              )
                              .state =
                          matches;
                      ref.read(webCurrentTournamentIdProvider.notifier).state =
                          safeTournamentId;
                      ref.read(currentTournamentIdProvider.notifier).state =
                          safeTournamentId;
                      ref.read(currentDojoIdProvider.notifier).state =
                          safeDojoId;
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
      final currentTournamentId = ref.watch(currentTournamentIdProvider);
      if (tournamentId.isNotEmpty && currentTournamentId != tournamentId) {
        Future.microtask(() {
          try {
            ref.read(currentTournamentIdProvider.notifier).state = tournamentId;
          } catch (_) {}
        });
      }

      // 🔋 【Plan 2 最適化】二重リスナーおよび二重saveMatchesBulkを撤廃
      // ネイティブ環境におけるFirestoreダウンストリーム同期は SyncEngine に完全一本化し、
      // ここではIsarのリアクティブストリームのみを安全・低負荷に返却する
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

/// ⚡ 最適化: 単一試合（matchId）専用のセレクタープロバイダ
/// 他の試合や別コートの更新による画面全体のリビルド連鎖を完全に遮断します
final singleMatchProvider = Provider.family<MatchModel?, String>((
  ref,
  matchId,
) {
  return ref.watch(
    matchListProvider.select(
      (list) => list.where((m) => m.id == matchId).firstOrNull,
    ),
  );
});

/// ⚡ リストの中身（要素順・内容）が同一であれば同一とみなすラッパー（不要なWidgetリビルド連鎖を根絶）
@immutable
class ListEqualityWrapper<T> {
  final List<T> list;
  const ListEqualityWrapper(this.list);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListEqualityWrapper<T> && listEquals(list, other.list);

  @override
  int get hashCode => Object.hashAll(list);
}

/// ⚡ 最適化: 団体戦グループ（groupName）専用の試合リストセレクター
/// ListEqualityWrapperにより、要素の中身が変化しない限りリスナーへの再通知を100%遮断する
final teamMatchesByGroupProvider = Provider.family<List<MatchModel>, String>((
  ref,
  groupName,
) {
  if (groupName.isEmpty) return const [];
  return ref
      .watch(
        matchListProvider.select(
          (list) => ListEqualityWrapper(
            list.where((m) => m.groupName == groupName).toList(),
          ),
        ),
      )
      .list;
});
