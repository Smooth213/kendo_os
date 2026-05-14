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

// ★ 追加: Webストリームの受信状態とエラーをUIに可視化するためのデバッグ用Provider
final webStreamStatusProvider = StateProvider<String>((ref) => 'Waiting for stream...');
final webStreamMatchCountProvider = StateProvider<int>((ref) => 0);

// ★ Phase 3: Firestore自体を提供するProvider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ★ 読み込み元を localMatchRepositoryProvider (Isar) に変更！
// 🌟 修正: さらに、最適化されたFirestore通信（進行中のみ監視＋過去データは1回取得）を組み込み、
// 取得したリモートデータを自動的にIsarへ流し込む（ダウンリンク同期）仕組みを追加。
final matchStreamProvider = StreamProvider<List<MatchModel>>((ref) async* {
  final remoteRepo = ref.watch(matchRepositoryProvider);

  // ★ 修正: Web(ブラウザ)環境では Isar (Local DB) が使えないため、Firestoreを直接見るバイパス路を通す
  if (kIsWeb) {
    try {
      ref.read(webStreamStatusProvider.notifier).state = 'Listening to Firestore...';
      await for (final matches in remoteRepo.watchAllMatches()) {
        ref.read(webStreamMatchCountProvider.notifier).state = matches.length;
        ref.read(webStreamStatusProvider.notifier).state = 'Connected: ${DateTime.now().toLocal().toString().split('.')[0]}';
        // ★ デバッグ: 取得した試合のtournamentIdを確認
        debugPrint('🔍 [matchListProvider Web] Received ${matches.length} matches');
        for (int i = 0; i < matches.length && i < 3; i++) {
          debugPrint('  [$i] ID: ${matches[i].id}, TID: "${matches[i].tournamentId}", Status: ${matches[i].status}');
        }
        // 観客席用の投影（Projection）を更新
        await _updateProjections(ref, matches);
        yield matches;
      }
    } catch (e, stack) {
      ref.read(webStreamStatusProvider.notifier).state = 'Stream Error: $e';
      debugPrint('🔥 [Web Stream Error] データ受信中に致命的なエラーが発生しました: $e\n$stack');
    }
    return; // Webの場合はここで終了
  }

  final localRepo = ref.watch(localMatchRepositoryProvider);

  // 1. アプリ起動時に1回だけ、リモートの全静的データをローカルDBへ同期する
  //    awaitで完了を待つことで、データ取得の失敗や漏れを防ぎ、堅牢性を高める
  try {
    final staticMatches = await remoteRepo.getStaticMatches();
    if (staticMatches.isNotEmpty) {
      await localRepo.saveMatchesBulk(staticMatches);
    }
  } catch (e) {
    // 起動時の同期に失敗しても、キャッシュされたデータで続行できるようにエラーは握りつぶす
    debugPrint('静的データの初期同期に失敗しました: $e');
  }

  // 2. 進行中・待機中の試合をリアルタイム監視し、更新・追加があればIsarに保存
  final sub = remoteRepo.watchActiveMatches().listen((activeMatches) async {
    if (activeMatches.isNotEmpty) {
      try {
        await localRepo.saveMatchesBulk(activeMatches);
      } catch (e) {
        // ★ 盾を装備（Zero Trust）: 不正なリアルタイムデータはクラッシュさせずに静かに破棄する
        debugPrint('🛡️ [Zero Trust] 不正なリアルタイムデータをブロックしました (無視して進行します): $e');
      }
    }
  }, onError: (e) {
    debugPrint('アクティブデータ取得エラー: $e');
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
  final defaultRule = ref.read(matchRuleProvider);
  final engine = KendoRuleEngine();
  for (var match in matches) {
    try {
      // ★ 修正: 試合ごとのルールを優先し、なければデフォルトルールを使用する
      final rule = match.rule ?? defaultRule;
      final analysis = engine.analyzeHistory(match.events, match, rule);
      final projection = MatchProjectionMapper.toMatchProjection(match, analysis);
      await ref.read(projectionStoreProvider).save(projection);
    } catch (e, stack) {
      debugPrint('🔥 [Projection Error] 試合ID: ${match.id} のProjection更新に失敗しました(スキップします): $e\n$stack');
    }
  }
}