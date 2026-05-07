import 'package:kendo_os/application/projections/match_projection.dart';

/// B-1: Projection（画面表示用データ）を保存・読み出し・監視するためのインターフェース
/// Write（EventStore）とは完全に分離されたRead（読み取り）専用のStore
abstract class ProjectionStore {
  /// 画面表示用に最適化されたデータ（Projection）を保存する
  Future<void> save(MatchProjection projection);

  /// IDを指定してProjectionを1件取得する
  Future<MatchProjection?> get(String matchId);

  /// IDを指定してProjectionの変更をリアルタイム監視する（UI用）
  Stream<MatchProjection> watch(String matchId);

  /// 大会IDなどで絞り込んだ複数のProjectionをリアルタイム監視する
  Stream<List<MatchProjection>> watchByTournament(String tournamentId);
}