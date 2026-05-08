import 'package:kendo_os/application/projections/match_projection.dart';

/// B-1: Projection（画面表示用データ）を保存・読み出し・監視するためのインターフェース
/// ★ Phase 5: 用途別Projection (MatchProjection / MatchListProjection) に対応
abstract class ProjectionStore {
  /// 画面表示用に最適化されたデータ（Projection）を保存する
  Future<void> save(MatchProjection projection);

  /// IDを指定してProjectionを1件取得する
  Future<MatchProjection?> get(String matchId);

  /// IDを指定してProjectionの変更をリアルタイム監視する（詳細画面用）
  Stream<MatchProjection> watch(String matchId);

  /// 大会IDなどで絞り込んだ複数の「軽量版」Projectionをリアルタイム監視する（一覧画面用）
  /// ★ 修正: MatchProjection から MatchListProjection へ戻り値を変更
  Stream<List<MatchListProjection>> watchByTournament(String tournamentId);
}