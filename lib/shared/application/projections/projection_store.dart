import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// CQRSアーキテクチャの要となるプロジェクションストア。
/// Firestoreの生データ（MatchModel）を監視し、ルールエンジンを通した安全なUI用プロジェクションに変換して提供します。
final projectionStoreProvider = Provider<ProjectionStore>((ref) {
  return ProjectionStore(ref);
});

class ProjectionStore {
  final Ref ref;

  ProjectionStore(this.ref);

  /// クラウドから降ってきた最新のプロジェクションを直接ストアへ反映する
  void updateProjectionDirectly(MatchProjection projection) {
    // 必要に応じてインメモリキャッシュ層への反映処理を実装する
  }

  /// 1試合のデータをリアルタイム監視し、MatchProjectionへと変換する
  Stream<MatchProjection?> watch(String matchId) {
    final dojoId = ref.read(currentDojoIdProvider);
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(dojoId)
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          final match = MatchModel.fromJson(snapshot.data()!);
          final engine = KendoRuleEngine();
          final analysis = engine.analyzeHistory(
            match.events,
            match,
            match.rule,
          );
          return MatchProjectionMapper.toProjection(match, analysis);
        });
  }

  /// 大会に紐づく試合一覧をリアルタイム監視し、MatchListProjectionへと変換する
  Stream<List<MatchListProjection>> watchByTournament(String tournamentId) {
    final dojoId = ref.read(currentDojoIdProvider);
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(dojoId)
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final match = MatchModel.fromJson(doc.data());
            final engine = KendoRuleEngine();
            final analysis = engine.analyzeHistory(
              match.events,
              match,
              match.rule,
            );
            return MatchProjectionMapper.toListProjection(match, analysis);
          }).toList();
        });
  }
}
