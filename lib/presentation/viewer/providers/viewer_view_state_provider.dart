import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/application/projections/tournament_projection.dart';
import 'package:kendo_os/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/infrastructure/repository/in_memory_projection_store.dart'; 
import 'package:kendo_os/domain/entities/tournament_model.dart';
import '../../shared/providers/current_sync_context_provider.dart';
import '../../shared/providers/dojo_room_sync_provider.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';

// =========================================================================
// ★ 真のCQRS調停：画面は中央のストアのみを素直にリッスンし、
// 裏側でのクラウド同期（dojoRoomSyncProvider）の血液をそのまま美しく表示する
// =========================================================================

/// 1. 試合のプロジェクション（1試合単位）のリアルタイム監視
final viewerMatchProjectionProvider = StreamProvider.family<MatchProjection?, String>((ref, matchId) async* {
  // =========================================================================
  // 🛡️ Webアプリ表示不具合修正パッチ（ロードマップメソッド完全維持）
  // Flutter Web環境では、正常稼働が証明されている matchStreamProvider から
  // 直接最新状態を拾い上げ、即座にプロジェクションへ変換してUIを点火させます。
  // =========================================================================
  if (kIsWeb) {
    debugPrint('🌐 [Viewer Web Bypass] Web環境のため、直接メモリストリームから対象の試合をProjectionへ変換します: $matchId');
    final matches = await ref.watch(matchStreamProvider.future);
    final match = matches.where((m) => m.id == matchId).firstOrNull;
    if (match == null) {
      yield null;
    } else {
      try {
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
final viewerMatchStatusProvider = Provider.family<AsyncValue<String>, String>((ref, matchId) {
  return ref.watch(viewerMatchProjectionProvider(matchId).select(
    (async) => async.whenData((p) => p?.status ?? 'waiting')
  ));
});

/// モメンタム（勢い）だけを監視する
final viewerMatchMomentumProvider = Provider.family<AsyncValue<double>, String>((ref, matchId) {
  return ref.watch(viewerMatchProjectionProvider(matchId).select(
    (async) => async.whenData((p) => p?.momentum ?? 0.0)
  ));
});

/// タイムラインだけを監視する
final viewerMatchTimelineProvider = Provider.family<AsyncValue<List<TimelineEvent>>, String>((ref, matchId) {
  return ref.watch(viewerMatchProjectionProvider(matchId).select(
    (async) => async.whenData((p) => p?.timeline ?? [])
  ));
});


// --- 大会全体を監視するためのストリームチェーン ---
final _tournamentModelStreamProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).getTournamentStream(id);
});

final _tournamentProjectionsStreamProvider = StreamProvider.family<List<MatchListProjection>, String>((ref, id) {
  ref.watch(dojoRoomSyncProvider);
  return ref.watch(projectionStoreProvider).watchByTournament(id);
});

/// 2. 大会全体のプロジェクション（リスト・一覧用）のリアルタイム監視
final viewerTournamentProjectionProvider = Provider.family<AsyncValue<TournamentProjection?>, String>((ref, tournamentId) {
  final tournamentAsync = ref.watch(_tournamentModelStreamProvider(tournamentId));
  final projectionsAsync = ref.watch(_tournamentProjectionsStreamProvider(tournamentId));

  if (tournamentAsync.isLoading || projectionsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (tournamentAsync.hasError) {
    return AsyncValue.error(tournamentAsync.error!, tournamentAsync.stackTrace!);
  }
  if (projectionsAsync.hasError) {
    return AsyncValue.error(projectionsAsync.error!, projectionsAsync.stackTrace!);
  }

  final tournament = tournamentAsync.value;
  final projections = projectionsAsync.value ?? [];

  if (tournament == null) return const AsyncValue.data(null);

  final projection = TournamentProjectionMapper.fromProjections(tournament, projections);
  return AsyncValue.data(projection);
});

/// 🌟 部内戦画面が使用する試合一覧ストリーム
final bunaiksenMatchesProvider = StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  final dojoId = ref.watch(currentDojoIdProvider);
  ref.watch(dojoRoomSyncProvider);

  return FirebaseFirestore.instance
      .collection('organizations')
      .doc(dojoId)
      .collection('matches')
      .where('tournamentId', isEqualTo: tournamentId)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => MatchModel.fromJson(doc.data())).toList();
      });
});
