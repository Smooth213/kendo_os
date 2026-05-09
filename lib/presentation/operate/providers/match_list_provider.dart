import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:kendo_os/presentation/operate/providers/match_rule_provider.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/infrastructure/repository/in_memory_projection_store.dart';

// ★ Phase 3: Firestore自体を提供するProvider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ★ 読み込み元を localMatchRepositoryProvider (Isar) に変更！
// 🌟 修正: さらに、最適化されたFirestore通信（進行中のみ監視＋過去データは1回取得）を組み込み、
// 取得したリモートデータを自動的にIsarへ流し込む（ダウンリンク同期）仕組みを追加。
final matchStreamProvider = StreamProvider<List<MatchModel>>((ref) async* {
  final localRepo = ref.watch(localMatchRepositoryProvider);
  final remoteRepo = ref.watch(matchRepositoryProvider);

  // 1. 静的データ（待機中・終了済み）を1回だけ取得し、Isarに保存（キャッシュ化）
  remoteRepo.getStaticMatches().then((staticMatches) async {
    if (staticMatches.isNotEmpty) {
      try {
        await localRepo.saveMatchesBulk(staticMatches);
      } catch (e) {
        // ★ 盾を装備（Zero Trust）: 署名のない古いデータはクラッシュさせずに静かに破棄する
        debugPrint('🛡️ [Zero Trust] 不正な静的データをブロックしました (無視して進行します): $e');
      }
    }
  }).catchError((e) {
    debugPrint('静的データ取得エラー: $e');
  });

  // 2. 進行中の試合だけをリアルタイム監視し、更新があればIsarに保存（通信量の劇的削減）
  final sub = remoteRepo.watchInProgressMatches().listen((activeMatches) async {
    if (activeMatches.isNotEmpty) {
      try {
        await localRepo.saveMatchesBulk(activeMatches);
      } catch (e) {
        // ★ 盾を装備（Zero Trust）: 不正なリアルタイムデータはクラッシュさせずに静かに破棄する
        debugPrint('🛡️ [Zero Trust] 不正なリアルタイムデータをブロックしました (無視して進行します): $e');
      }
    }
  }, onError: (e) {
    debugPrint('進行中データ取得エラー: $e');
  });
  ref.onDispose(() => sub.cancel());

// 3. UIには常にローカル（Isar）のストリームを流し続ける（爆速描画の維持）
  await for (final matches in localRepo.watchMatches()) {
    // ★ 追加: Viewer用のProjectionStoreも更新
    await _updateProjections(ref, matches);
    yield matches;
  }
});

final matchListProvider = Provider<List<MatchModel>>((ref) {
  return ref.watch(matchStreamProvider).value ?? [];
});

// ★ 追加: Viewer用のProjectionを更新するヘルパー関数
Future<void> _updateProjections(Ref ref, List<MatchModel> matches) async {
  final rule = ref.read(matchRuleProvider);
  final engine = KendoRuleEngine();
  for (var match in matches) {
    final analysis = engine.analyzeHistory(match.events, match, rule);
    final projection = MatchProjectionMapper.toMatchProjection(match, analysis);
    await ref.read(projectionStoreProvider).save(projection);
  }
}