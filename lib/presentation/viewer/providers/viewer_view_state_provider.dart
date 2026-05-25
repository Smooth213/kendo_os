import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/application/projections/match_projection.dart';
import 'package:kendo_os/application/projections/tournament_projection.dart';
import 'package:kendo_os/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/domain/entities/tournament_model.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/application/projections/projection_store.dart';
import '../../shared/providers/current_sync_context_provider.dart';

/// ★ テスト救済の核心：Firebase App 未初期化例外を100%封殺するための環境隔離プロバイダー。
/// 本番Webでは通常のインスタンスを返し、ウィジェットテスト空間では安全にモックへ差し替え可能にします。
final firestoreInstanceProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// =========================================================================
// ★ B-4: 真のCQRS - Viewerは安定した ProjectionStore のみを常時リッスンする
// =========================================================================

/// 1. 試合のプロジェクション（1試合単位）のリアルタイム監視
/// 存在しない `fromJson` のパースを排除し、道場空間の変更（currentDojoIdProvider）を
/// リアクティブグラフに組み込んだ上で、既存のストアから完璧に安全なストリームを返却します。
final viewerMatchProjectionProvider = StreamProvider.family<MatchProjection?, String>((ref, matchId) {
  ref.watch(currentDojoIdProvider);
  return ref.watch(projectionStoreProvider).watch(matchId);
});

// =========================================================================
// ★ Phase 5-3: Rebuild最適化 (Selectors)
// =========================================================================

/// 試合の基本ステータス（進行中・終了など）だけを監視する
final viewerMatchStatusProvider = Provider.family<AsyncValue<String>, String>((ref, matchId) {
  return ref.watch(viewerMatchProjectionProvider(matchId).select(
    (async) => async.whenData((p) => p?.status ?? 'waiting')
  ));
});

/// モメンタム（勢い）だけを監視する（高頻度更新用）
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


// --- 大会全体を監視するための内部Provider ---

final _tournamentModelStreamProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).getTournamentStream(id);
});

/// ★ 修正：型定義のない JSON パースを排除し、元のインメモリプロジェクションストアの
/// リアルタイム型安全チェーン（watchByTournament）へと安全に復旧マージします。
final _tournamentProjectionsStreamProvider = StreamProvider.family<List<MatchListProjection>, String>((ref, id) {
  ref.watch(currentDojoIdProvider);
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

  // 双方の最新データを使ってProjectionを生成
  final projection = TournamentProjectionMapper.fromProjections(tournament, projections);
  return AsyncValue.data(projection);
});

/// 🌟 部内戦画面等が使用する、特定の大会IDに紐づく試合一覧を抽出する Firestore ストリーム
/// 隔離した `firestoreInstanceProvider` を経由させることで、テスト空間での自爆を完全にブロック。
final bunaiksenMatchesProvider = StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  final dojoId = ref.watch(currentDojoIdProvider);
  final firestore = ref.watch(firestoreInstanceProvider);

  return firestore
      .collection('organizations')
      .doc(dojoId)
      .collection('matches')
      .where('tournamentId', isEqualTo: tournamentId)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MatchModel.fromJson(doc.data());
        }).toList();
      });
});
