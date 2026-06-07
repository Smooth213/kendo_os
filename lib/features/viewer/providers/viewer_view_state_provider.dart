import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_projection_store.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

// =========================================================================
// 🛡️ Timestamp 変換ヘルパー
// =========================================================================
Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> data) {
  final Map<String, dynamic> result = {};
  data.forEach((key, value) {
    if (value is Timestamp) {
      result[key] = value.toDate().toIso8601String();
    } else if (value is Map<String, dynamic>) {
      result[key] = _sanitizeFirestoreData(value);
    } else if (value is List) {
      result[key] = value.map((e) {
        if (e is Map<String, dynamic>) return _sanitizeFirestoreData(e);
        if (e is Timestamp) return e.toDate().toIso8601String();
        return e;
      }).toList();
    } else if ((key == 'order' ||
            key == 'matchTimeMinutes' ||
            key == 'extensionTimeMinutes' ||
            key == 'enchoTimeMinutes') &&
        value is num) {
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

// =========================================================================
// ★ 真のCQRS調停：画面は中央のストアのみを素直にリッスンし、
// 裏側でのクラウド同期（dojoRoomSyncProvider）の血液をそのまま美しく表示する
// =========================================================================

/// 1. 試合のプロジェクション（1試合単位）のリアルタイム監視
final viewerMatchProjectionProvider = StreamProvider.family<MatchProjection?, String>((
  ref,
  matchId,
) async* {
  // =========================================================================
  // 🛡️ Webアプリ表示不具合修正パッチ（ロードマップメソッド完全維持）
  // Flutter Web環境では、正常稼働が証明されている matchStreamProvider から
  // 直接最新状態を拾い上げ、即座にプロジェクションへ変換してUIを点火させます。
  // =========================================================================
  if (kIsWeb) {
    debugPrint(
      '🌐 [Viewer Web Bypass] Web環境のため、クラウドから対象の試合を直接監視してProjectionへ変換します: $matchId',
    );
    // 🌟 Webアプリ表示不具合修正パッチ（アーカイブ遅延対策）
    // 全試合ストリーム(matchStreamProvider)の完了を await するとブラウザが数分間フリーズしてしまうため、
    // 対象の1試合のみをFirestoreからピンポイントでリアルタイム監視して爆速化します。
    final firestore = ref.watch(firestoreProvider);
    final dojoId = ref.watch(currentDojoIdProvider);
    final stream = firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('matches')
        .doc(matchId)
        .snapshots();

    await for (final snapshot in stream) {
      if (!snapshot.exists || snapshot.data() == null) {
        yield null;
        continue;
      }
      try {
        final data = _sanitizeFirestoreData(snapshot.data()!);
        final match = MatchModel.fromJson({...data, 'id': snapshot.id});
        final engine = KendoRuleEngine();
        final analysis = engine.analyzeHistory(match.events, match, match.rule);
        yield MatchProjectionMapper.toProjection(match, analysis);
      } catch (e) {
        debugPrint('⚠️ [Viewer Web Bypass Error] Projection変換に失敗しました: $e');
        yield null;
      }
    }
    return;
  }

  // 🍏 ネイティブ環境（シミュレータ・iPad実機アプリ）は最強ローカルファースト防衛線を100%維持
  // バックグラウンド同期マネージャーを常時稼働（リッスン状態の維持）
  ref.watch(dojoRoomSyncProvider);
  yield* ref.watch(projectionStoreProvider).watch(matchId);
});

/// 試合の基本ステータスだけを監視する
final viewerMatchStatusProvider = Provider.family<AsyncValue<String>, String>((
  ref,
  matchId,
) {
  return ref.watch(
    viewerMatchProjectionProvider(
      matchId,
    ).select((async) => async.whenData((p) => p?.status ?? 'waiting')),
  );
});

/// モメンタム（勢い）だけを監視する
final viewerMatchMomentumProvider = Provider.family<AsyncValue<double>, String>(
  (ref, matchId) {
    return ref.watch(
      viewerMatchProjectionProvider(
        matchId,
      ).select((async) => async.whenData((p) => p?.momentum ?? 0.0)),
    );
  },
);

/// タイムラインだけを監視する
final viewerMatchTimelineProvider =
    Provider.family<AsyncValue<List<TimelineEvent>>, String>((ref, matchId) {
      return ref.watch(
        viewerMatchProjectionProvider(
          matchId,
        ).select((async) => async.whenData((p) => p?.timeline ?? [])),
      );
    });

// --- 大会全体を監視するためのストリームチェーン ---
final _tournamentModelStreamProvider =
    StreamProvider.family<TournamentModel?, String>((ref, id) {
      return ref.watch(tournamentRepositoryProvider).getTournamentStream(id);
    });

/// 2. 大会全体のプロジェクション（リスト・一覧用）のリアルタイム監視
final viewerTournamentProjectionProvider =
    Provider.family<AsyncValue<TournamentProjection?>, String>((
      ref,
      tournamentId,
    ) {
      final tournamentAsync = ref.watch(
        _tournamentModelStreamProvider(tournamentId),
      );

      // 🌟 修正核心：メモリキャッシュ消失による「試合がない」表示バグを完全解決
      // Storeを介さず、単一真実である matchListProvider から対象の試合を直接取得し、
      // オンザフライで動的にProjectionへと変換する絶対安全なフローへ刷新します。
      final allMatches = ref.watch(matchListProvider);
      final targetMatches = allMatches
          .where((m) => m.tournamentId == tournamentId)
          .toList();

      // Webブラウザ等で、まだ matchListProvider にデータが載っていない場合のフォールバック取得
      if (targetMatches.isEmpty && kIsWeb) {
        final webMatchesAsync = ref.watch(
          matchListByTournamentProvider(tournamentId),
        );
        if (webMatchesAsync.isLoading) return const AsyncValue.loading();
        targetMatches.addAll(webMatchesAsync.value ?? []);
      }

      if (tournamentAsync.isLoading && targetMatches.isEmpty) {
        return const AsyncValue.loading();
      }

      if (tournamentAsync.hasError) {
        return AsyncValue.error(
          tournamentAsync.error!,
          tournamentAsync.stackTrace!,
        );
      }

      // ★ 修正: 大会情報が取得できなくても（部内戦や権限エラー等）、
      // プロジェクションの生成を止めず、ダミー大会モデルでフォールバックしてスコアを確実に表示する
      final tournament =
          tournamentAsync.value ??
          TournamentModel(
            id: tournamentId,
            organizationId: '',
            name: '大会情報',
            date: DateTime.now(),
            venue: '',
            categories: const [],
          );

      final engine = KendoRuleEngine();
      final projections = targetMatches.map((m) {
        final analysis = engine.analyzeHistory(m.events, m, m.rule);
        final proj = MatchProjectionMapper.toProjection(m, analysis);
        return MatchListProjection(
          id: proj.id,
          tournamentId: proj.tournamentId,
          matchOrder: proj.matchOrder,
          matchType: proj.matchType,
          status: proj.status,
          redName: proj.redName,
          whiteName: proj.whiteName,
          redScore: proj.redScore,
          whiteScore: proj.whiteScore,
          groupName: proj.groupName,
          isKachinuki: proj.isKachinuki,
          note: proj.note,
          firstPointSide: proj.firstPointSide,
          redPointMarks: proj.redPointMarks,
          whitePointMarks: proj.whitePointMarks,
        );
      }).toList();

      final projection = TournamentProjectionMapper.fromProjections(
        tournament,
        projections,
      );
      return AsyncValue.data(projection);
    });

/// 🌟 部内戦画面が使用する試合一覧ストリーム
final bunaiksenMatchesProvider = StreamProvider.family<List<MatchModel>, String>((
  ref,
  tournamentId,
) {
  ref.watch(dojoRoomSyncProvider);
  final dojoId = ref.watch(currentDojoIdProvider);

  // ★ 修正: 道場IDが判明している場合はインデックス不要の通常コレクションから取得する
  if (dojoId.isNotEmpty) {
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(dojoId)
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  final data = _sanitizeFirestoreData(doc.data());
                  return MatchModel.fromJson({...data, 'id': doc.id});
                } catch (e, stack) {
                  debugPrint(
                    '⚠️ [bunaiksenMatchesProvider] Error parsing match ${doc.id}: $e\n$stack',
                  );
                  return null;
                }
              })
              .whereType<MatchModel>()
              .toList();
        });
  }

  return FirebaseFirestore.instance
      .collectionGroup('matches')
      .where('tournamentId', isEqualTo: tournamentId)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                final data = _sanitizeFirestoreData(doc.data());
                return MatchModel.fromJson({...data, 'id': doc.id});
              } catch (e, stack) {
                debugPrint(
                  '⚠️ [bunaiksenMatchesProvider] Error parsing match ${doc.id}: $e\n$stack',
                );
                return null;
              }
            })
            .whereType<MatchModel>()
            .toList();
      });
});
