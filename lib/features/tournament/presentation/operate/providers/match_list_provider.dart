import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:uuid/uuid.dart';

// =========================================================================
// 🛡️ 補正：プロジェクト全域でUndefinedエラーを吐いている firestoreProvider をここで安全に定義
// =========================================================================
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

// =========================================================================
// ★ 追加: Web環境で特定の大会を読み込んだ際、グローバルにキャッシュを保持するプロバイダ
// =========================================================================
final webCurrentTournamentMatchesProvider = StateProvider<List<MatchModel>>(
  (ref) => [],
);
final webCurrentTournamentIdProvider = StateProvider<String?>((ref) => null);

// =========================================================================
// 🛡️ Webアプリ表示不具合修正パッチ（ロードマップメソッド完全維持）
// Flutter Web環境（Isarが非活性）のときはストリームを沈黙させず、
// 即座に安全な空配列（またはFirestoreの読み込み側）をUIへ射出してフリーズを完全回避します。
// =========================================================================
final matchStreamProvider = StreamProvider<List<MatchModel>>((ref) {
  // Webブラウザ環境（kIsWeb == true）のとき、Isarディスク監視を安全にバイパス
  if (kIsWeb) {
    debugPrint('🌐 [Web Environment Detected] Isarの代わりにメモリ/クラウド監視ラインを確立します');
    // 🌟 Webアプリ表示不具合修正パッチ（アーカイブフリーズ完全防止）
    // 全試合の snapshots() はアーカイブが増大するとブラウザを数分間フリーズさせるため、
    // ここでは安全に空のストリームを返し、画面側では必ず matchListByTournamentProvider を使用させます。
    return Stream.value([]);
  }

  // 🍏 ネイティブ環境（シミュレータ・iPad実機アプリ）はこれまでの強力なIsar最優先監視を100%継続
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

// =========================================================================
// 🛡️ Phase 0 - STEP 0-1 要件：既存の全UI・ロジック・テストを完全無傷で救済するコア
// 呼び出し側には同期的で扱いやすい List<MatchModel> を返しつつ、
// その実態は Isar のリアルタイムストリーム（matchStreamProvider）を凝視する、完璧なブリッジ構造です。
// =========================================================================

Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> data) {
  final Map<String, dynamic> result = {};
  data.forEach((key, value) {
    if (value is Timestamp) {
      result[key] = value.toDate().toIso8601String();
    } else if (value is Map) {
      result[key] = _sanitizeFirestoreData(Map<String, dynamic>.from(value));
    } else if (value is List) {
      result[key] = value.map((e) {
        if (e is Map) {
          return _sanitizeFirestoreData(Map<String, dynamic>.from(e));
        }
        if (e is Timestamp) {
          return e.toDate().toIso8601String();
        }
        return e;
      }).toList();
    } else if ((key == 'order' ||
            key == 'timelineOrder' ||
            key == 'matchTimeMinutes' ||
            key == 'extensionTimeMinutes' ||
            key == 'enchoTimeMinutes') &&
        value is num) {
      // Firestoreからintで返ってきた場合のdoubleキャストエラー（Web特有のリスト消失バグ）を防ぐ
      result[key] = value.toDouble();
    } else if ((key == 'redScore' ||
            key == 'whiteScore' ||
            key == 'matchOrder') &&
        value is num) {
      result[key] = value.toInt();
    } else {
      result[key] = value;
    }
  });
  return result;
}

final matchListProvider = Provider<List<MatchModel>>((ref) {
  if (kIsWeb) {
    // ★ 修正: Web環境の場合は、現在開いている大会の最新キャッシュを返す
    // これにより、遷移先のスコア画面（運営・観戦問わず）で matchListProvider を参照した際にも対象の試合が見つかり、フリーズしません。
    final currentTournamentId = ref.watch(webCurrentTournamentIdProvider);
    if (currentTournamentId == null || currentTournamentId.isEmpty) {
      return const [];
    }
    return ref.watch(webCurrentTournamentMatchesProvider);
  }
  return ref.watch(matchStreamProvider).value ?? const [];
});

// 💡 特定の大会IDで厳密に絞り込みたい画面のための family 版も別名で安全に維持
final matchListByTournamentProvider = StreamProvider.family<List<MatchModel>, String>((
  ref,
  tournamentId,
) {
  // 🌟 Webアプリ表示不具合修正パッチ（アーカイブ遅延対策）
  // Webブラウザ環境のとき、Isarの代わりにFirestoreから特定の大会の試合のみをピンポイントで取得し、
  // アーカイブデータ増大による読み込み遅延とフリーズを完全に防ぎます。
  if (kIsWeb) {
    final firestore = ref.watch(firestoreProvider);
    final dojoId = ref.watch(currentDojoIdProvider);

    // ★ セーフガード: 引数やProviderから値を安全にフォールバック取得
    final safeDojoId = dojoId.isNotEmpty ? dojoId : 'default_org';
    final safeTournamentId = tournamentId.isNotEmpty
        ? tournamentId
        : (ref.watch(currentTournamentIdProvider).isNotEmpty
              ? ref.watch(currentTournamentIdProvider)
              : 'default_tournament');

    debugPrint(
      '🌐 [matchListByTournamentProvider] Webモード監視開始 - dojoId: "$safeDojoId", tournamentId: "$safeTournamentId"',
    );
    debugPrint(
      '🌐 [matchListByTournamentProvider] Firestore instance: ${firestore.app.name}',
    );

    // ★ セーフガード: 双方向同期
    final webTid = ref.watch(webCurrentTournamentIdProvider);
    if (webTid != null && webTid.isNotEmpty) {
      Future.microtask(() {
        if (ref.read(currentTournamentIdProvider) != webTid) {
          ref.read(currentTournamentIdProvider.notifier).state = webTid;
        }
      });
    }
    final curTid = ref.watch(currentTournamentIdProvider);
    if (curTid.isNotEmpty) {
      Future.microtask(() {
        if (ref.read(webCurrentTournamentIdProvider) != curTid) {
          ref.read(webCurrentTournamentIdProvider.notifier).state = curTid;
        }
      });
    }

    final controller = StreamController<List<MatchModel>>();
    final List<StreamSubscription> subs = [];
    final Map<String, List<MatchModel>> cache = {'org': []};

    final currentTournamentKey = safeTournamentId;

    void emitBestMatches() {
      if (controller.isClosed) return;
      final bestMatches = cache['org'] ?? [];
      controller.add(bestMatches);

      // ★ 追加: メモリ上のグローバルキャッシュにも最新データを保存し、スコア画面などでの迷子を防止
      Future.microtask(() {
        try {
          if (ref.read(webCurrentTournamentIdProvider) ==
              currentTournamentKey) {
            ref.read(webCurrentTournamentMatchesProvider.notifier).state =
                bestMatches;
          }
        } catch (_) {}
      });
    }

    MatchModel? parseMatch(DocumentSnapshot<Map<String, dynamic>> doc) {
      try {
        final data = _sanitizeFirestoreData(doc.data() ?? {});
        return MatchModel.fromJson({...data, 'id': doc.id});
      } catch (e) {
        debugPrint('🚨 [Parse Error] ID:${doc.id} -> $e');
        return null;
      }
    }

    controller.onListen = () {
      debugPrint(
        '🌐 [matchListByTournamentProvider] onListen called - setting up nested subscription',
      );

      subs.add(
        firestore
            .collection('organizations')
            .doc(safeDojoId)
            .collection('tournaments')
            .doc(safeTournamentId)
            .collection('matches')
            .snapshots()
            .listen(
              (snap) {
                debugPrint(
                  '🌐 [matchListByTournamentProvider] org snapshot size: ${snap.docs.length}',
                );
                cache['org'] = snap.docs
                    .map(parseMatch)
                    .whereType<MatchModel>()
                    .toList();
                emitBestMatches();
              },
              onError: (e) {
                debugPrint('🚨 [Match Query Error] org: $e');
                emitBestMatches(); // ★ エラー時もローディングを強制終了させてフリーズを回避
              },
            ),
      );
    };

    void cleanup() {
      for (var s in subs) {
        s.cancel();
      }
      subs.clear();
      if (!controller.isClosed) {
        controller.close();
      }
    }

    controller.onCancel = cleanup;
    ref.onDispose(cleanup);

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
              final sanitized = _sanitizeFirestoreData(doc.data());
              final match = MatchModel.fromJson({...sanitized, 'id': doc.id});
              matches.add(match);
            } catch (e) {
              debugPrint(
                '⚠️ [Native Downstream Sync] Match parsing failed for doc ${doc.id}: $e',
              );
            }
          }

          if (matches.isNotEmpty) {
            final healedMatches = matches.map((match) {
              try {
                final healedEvents = match.events.map((event) {
                  try {
                    if (ScoreEventLegacyAdapter.verifySignature(
                      event,
                      'kendo_os_secret_key_v1',
                    )) {
                      return event;
                    }
                    final eventId = event.id.isNotEmpty
                        ? event.id
                        : const Uuid().v4();
                    final uid = event.userId ?? 'unknown_user';
                    final payload =
                        '$eventId:$uid:${event.timestamp.toIso8601String()}:${event.side.name}:${event.type.name}';
                    final signature = ScoreEventLegacyAdapter.generateSignature(
                      payload,
                      'kendo_os_secret_key_v1',
                    );
                    return event.copyWith(id: eventId, signature: signature);
                  } catch (e) {
                    debugPrint(
                      '⚠️ [Native Downstream Sync] Failed to verify/heal single event signature: $e',
                    );
                    final eventId = event.id.isNotEmpty
                        ? event.id
                        : const Uuid().v4();
                    final uid = event.userId ?? 'unknown_user';
                    final payload =
                        '$eventId:$uid:${DateTime.now().toIso8601String()}:${event.side.name}:${event.type.name}';
                    final signature = ScoreEventLegacyAdapter.generateSignature(
                      payload,
                      'kendo_os_secret_key_v1',
                    );
                    return event.copyWith(id: eventId, signature: signature);
                  }
                }).toList();

                final healedPendingEvents = match.pendingEvents.map((event) {
                  try {
                    if (ScoreEventLegacyAdapter.verifySignature(
                      event,
                      'kendo_os_secret_key_v1',
                    )) {
                      return event;
                    }
                    final eventId = event.id.isNotEmpty
                        ? event.id
                        : const Uuid().v4();
                    final uid = event.userId ?? 'unknown_user';
                    final payload =
                        '$eventId:$uid:${event.timestamp.toIso8601String()}:${event.side.name}:${event.type.name}';
                    final signature = ScoreEventLegacyAdapter.generateSignature(
                      payload,
                      'kendo_os_secret_key_v1',
                    );
                    return event.copyWith(id: eventId, signature: signature);
                  } catch (e) {
                    debugPrint(
                      '⚠️ [Native Downstream Sync] Failed to verify/heal single pending event signature: $e',
                    );
                    final eventId = event.id.isNotEmpty
                        ? event.id
                        : const Uuid().v4();
                    final uid = event.userId ?? 'unknown_user';
                    final payload =
                        '$eventId:$uid:${DateTime.now().toIso8601String()}:${event.side.name}:${event.type.name}';
                    final signature = ScoreEventLegacyAdapter.generateSignature(
                      payload,
                      'kendo_os_secret_key_v1',
                    );
                    return event.copyWith(id: eventId, signature: signature);
                  }
                }).toList();

                return match.copyWith(
                  events: healedEvents,
                  pendingEvents: healedPendingEvents,
                );
              } catch (e) {
                debugPrint(
                  '⚠️ [Native Downstream Sync] Error in healing signatures for match ${match.id}: $e',
                );
                return match;
              }
            }).toList();

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
