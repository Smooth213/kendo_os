import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/application/projections/projection_store.dart';
import 'current_sync_context_provider.dart';

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
    } else if ((key == 'order' || key == 'matchTimeMinutes' || key == 'extensionTimeMinutes' || key == 'enchoTimeMinutes') && value is num) {
      result[key] = value.toDouble();
    } else if ((key == 'redScore' || key == 'whiteScore' || key == 'matchOrder') && value is num) {
      result[key] = value.toInt();
    } else {
      result[key] = value;
    }
  });
  return result;
}

/// 🌟 核心：すべての画面（Admin/Recorder/Viewer）の裏側でFirestore Streamを常時リッスンし、
/// 他端末が更新したスコアやイベントパケットを、自端末のローカルストアへ0秒で強制マージする中央同期プロバイダー。
final dojoRoomSyncProvider = Provider<void>((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  final store = ref.watch(projectionStoreProvider);

  // 12時間耐久セッションが生きている間、バックグラウンドでの常時接続を確立
  final subscription = FirebaseFirestore.instance
      .collection('organizations')
      .doc(dojoId)
      .collection('matches')
      .snapshots()
      .listen((snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        final data = change.doc.data();
        if (data == null) continue;

        try {
          // クラウドから届いた最新の試合データを復元し、プロジェクションへ変換
          final convertedData = _sanitizeFirestoreData(data);
          final match = MatchModel.fromJson(convertedData);
          final engine = KendoRuleEngine();
          final analysis = engine.analyzeHistory(match.events, match, match.rule);
          final cloudProj = MatchProjectionMapper.toProjection(match, analysis);
          
          // 🌟 自端末のインメモリデータストア（全プロバイダの根底）へ直接流し込み、
          // 管理者画面・記録者画面・観客席のすべての表示を同時に0秒遅延更新させる
          store.updateProjectionDirectly(cloudProj);
        } catch (_) {
          // スキーマ不整合時のデータ汚染を安全にスキップ
        }
      }
    }
  }, onError: (error) {
    // 🌟 修正核心：未認証時のアクセス権限エラー（permission-denied）などをキャッチして、
    // アプリの裏側クラッシュとして処理されるのを防ぐ（一時的な通信エラーとして安全に無視）
    // debugPrint('⚠️ [DojoRoomSync] Firestore同期待機中: $error');
  });

  // 道場IDが切り替わった、またはアプリ終了時に古い通信ストリームを安全に自動パージ
  ref.onDispose(() {
    subscription.cancel();
  });
});