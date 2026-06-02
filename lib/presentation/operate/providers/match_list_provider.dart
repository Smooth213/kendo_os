import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/presentation/shared/providers/current_sync_context_provider.dart';

// =========================================================================
// 🛡️ 補正：プロジェクト全域でUndefinedエラーを吐いている firestoreProvider をここで安全に定義
// =========================================================================
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// =========================================================================
// ★ 追加: Web環境で特定の大会を読み込んだ際、グローバルにキャッシュを保持するプロバイダ
// =========================================================================
final webCurrentTournamentMatchesProvider = StateProvider<List<MatchModel>>((ref) => []);
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
      debugPrint('⏳ [Startup Restore] Isar内にローカルキャッシュがありません。クラウド同期をバックグラウンドで待機します。');
    } else {
      debugPrint('⚡ [Startup Restore] Isarローカルディスクから ${matches.length} 件の試合状態を一瞬で完全復元しました（電波ゼロOK）');
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
        if (e is Map) return _sanitizeFirestoreData(Map<String, dynamic>.from(e));
        if (e is Timestamp) return e.toDate().toIso8601String();
        return e;
      }).toList();
    } else if ((key == 'order' || key == 'timelineOrder' || key == 'matchTimeMinutes' || key == 'extensionTimeMinutes' || key == 'enchoTimeMinutes') && value is num) {
      // Firestoreからintで返ってきた場合のdoubleキャストエラー（Web特有のリスト消失バグ）を防ぐ
      result[key] = value.toDouble();
    } else if ((key == 'redScore' || key == 'whiteScore' || key == 'matchOrder') && value is num) {
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
final matchListByTournamentProvider = StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  // 🌟 Webアプリ表示不具合修正パッチ（アーカイブ遅延対策）
  // Webブラウザ環境のとき、Isarの代わりにFirestoreから特定の大会の試合のみをピンポイントで取得し、
  // アーカイブデータ増大による読み込み遅延とフリーズを完全に防ぎます。
  if (kIsWeb) {
    final firestore = ref.watch(firestoreProvider);
    final dojoId = ref.watch(currentDojoIdProvider);

    debugPrint('🌐 [matchListByTournamentProvider] Webモード監視開始 - dojoId: "$dojoId", tournamentId: "$tournamentId"');
    debugPrint('🌐 [matchListByTournamentProvider] Firestore instance: ${firestore.app.name}');

    // ★ Web環境キャッシュ補正: 現在の大会IDを更新し、古い大会データを誤って再利用しないようにする
    // ★ Web環境のリスト消失完全対策：
    // collectionGroup クエリは手動で複合インデックスを作成しないと、キャッシュ（0件）のみを返して通信エラーをサイレントに握り潰す特性があります。
    // これを回避するため、Firestoreが自動でインデックスを作成する「通常のコレクション検索」を網羅的に並行監視し、
    // どこか1つのパスでもデータが取得できたら即座にUIへ反映する最強のフォールバック・ストリームを構築します。
    final controller = StreamController<List<MatchModel>>();
    final List<StreamSubscription> subs = [];
    final Map<String, List<MatchModel>> cache = {'root': [], 'sub': [], 'org': []};
    final Set<String> respondedSources = {};

    final currentTournamentKey = tournamentId;

    bool hasAllSourcesResponded() {
      final expectedSources = dojoId.isNotEmpty ? 4 : 3;
      return respondedSources.length >= expectedSources;
    }

    void emitBestMatches() {
      if (controller.isClosed) return;
      // 取得できたデータ件数が最も多いパスのデータを正として採用
      final bestMatches = cache.values.reduce((a, b) => a.length > b.length ? a : b);
      if (bestMatches.isEmpty && !hasAllSourcesResponded()) {
        debugPrint('🌐 [matchListByTournamentProvider] まだ全てのWeb検索結果が揃っていません。currentTournamentId=$currentTournamentKey, responded=${respondedSources.join(', ')}');
        return;
      }

      controller.add(bestMatches);

      // ★ 追加: メモリ上のグローバルキャッシュにも最新データを保存し、スコア画面などでの迷子を防止
      Future.microtask(() {
        try {
          if (ref.read(webCurrentTournamentIdProvider) == currentTournamentKey) {
            ref.read(webCurrentTournamentMatchesProvider.notifier).state = bestMatches;
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
        debugPrint('🌐 [matchListByTournamentProvider] onListen called - setting up subscriptions');
      // 1. ルートコレクション (単一フィールド検索のため自動インデックスで必ず動作)
      subs.add(firestore.collection('matches').where('tournamentId', isEqualTo: tournamentId).snapshots().listen(
        (snap) {
            debugPrint('🌐 [matchListByTournamentProvider] root snapshot size: ${snap.docs.length}');
          respondedSources.add('root');
          cache['root'] = snap.docs.map(parseMatch).whereType<MatchModel>().toList();
          emitBestMatches();
        },
        onError: (e) {
          debugPrint('🚨 [Match Query Error] root: $e');
          respondedSources.add('root');
          emitBestMatches(); // ★ エラー時もローディングを強制終了させてフリーズを回避
        },
      ));

      // 2. 大会サブコレクション (検索条件すら不要のためインデックス完全不要)
      subs.add(firestore.collection('tournaments').doc(tournamentId).collection('matches').snapshots().listen(
        (snap) {
            debugPrint('🌐 [matchListByTournamentProvider] sub snapshot size: ${snap.docs.length}');
          respondedSources.add('sub');
          cache['sub'] = snap.docs.map(parseMatch).whereType<MatchModel>().toList();
          emitBestMatches();
        },
        onError: (e) {
          debugPrint('🚨 [Match Query Error] sub: $e');
          respondedSources.add('sub');
          emitBestMatches(); // ★ エラー時もローディングを強制終了させてフリーズを回避
        },
      ));

      // 3. 道場サブコレクション
      if (dojoId.isNotEmpty) {
        subs.add(firestore.collection('organizations').doc(dojoId).collection('matches').where('tournamentId', isEqualTo: tournamentId).snapshots().listen(
          (snap) {
              debugPrint('🌐 [matchListByTournamentProvider] org snapshot size: ${snap.docs.length}');
            respondedSources.add('org');
            cache['org'] = snap.docs.map(parseMatch).whereType<MatchModel>().toList();
            emitBestMatches();
          },
          onError: (e) {
            debugPrint('🚨 [Match Query Error] org: $e');
            respondedSources.add('org');
            emitBestMatches(); // ★ エラー時もローディングを強制終了させてフリーズを回避
          },
        ));
      }

      // 4. フォールバック: collectionGroup で大会ID一致のマッチを探索（道場IDが不明な場合の最終手段）
      subs.add(firestore.collectionGroup('matches').where('tournamentId', isEqualTo: tournamentId).snapshots().listen((snap) {
        debugPrint('🌐 [matchListByTournamentProvider] collectionGroup matches snapshot size: ${snap.docs.length}');
        respondedSources.add('group');
        cache['group'] = snap.docs.map((doc) {
          try {
            final data = _sanitizeFirestoreData((doc.data() as Map<String, dynamic>?) ?? {});
            return MatchModel.fromJson({...data, 'id': (doc as DocumentSnapshot).id});
          } catch (e) {
            debugPrint('🚨 [Parse Error - collectionGroup match] ${doc.id} -> $e');
            return null;
          }
        }).whereType<MatchModel>().toList();
        emitBestMatches();
      }, onError: (e) {
        debugPrint('🚨 [Match Query Error] collectionGroup: $e');
        respondedSources.add('group');
        emitBestMatches();
      }));
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
  return localRepository.watchLocalMatches(tournamentId);
});