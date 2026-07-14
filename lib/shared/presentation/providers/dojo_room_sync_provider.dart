import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/application/projections/projection_store.dart';
import 'current_sync_context_provider.dart';
import 'auth_session_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';

Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> data) {
  final Map<String, dynamic> result = {};
  data.forEach((key, value) {
    if (value is Timestamp) {
      result[key] = value.toDate().toIso8601String();
    } else if (value is Map) {
      result[key] = _sanitizeFirestoreData(Map<String, dynamic>.from(value));
    } else if (value is List) {
      result[key] = value.map((e) {
        if (e is Map) {
          return _sanitizeFirestoreData(Map<String, dynamic>.from(e));
        }
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

final dojoRoomSyncProvider = Provider<void>((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  // 🔑 認証セッション状態をwatchし、ログイン成功時に自動的にこのプロバイダーを再起動する
  ref.watch(authSessionProvider);

  // ★ 修正: watchだと集計データが更新されるたびに通信リスナーが再起動（無限ループ）してしまうため、readに変更
  final store = ref.read(projectionStoreProvider);

  debugPrint('📡 [DojoRoomSync] ダウンストリーム同期起動: 道場ID = $dojoId');

  if (dojoId.isEmpty) {
    debugPrint('⚠️ [DojoRoomSync] 道場IDが空のため待機します');
    return;
  }

  StreamSubscription<QuerySnapshot>? subscription;
  bool isDisposed = false;

  // ★ 修正核心: 非同期処理を完全に直列化し、ローカルDBのパージが
  // 100% 完了してから Firestore の監視を開始するように変更。
  // これにより、パージ中に新道場のデータを受信してしまい、直後にクリアされて
  // データが空になる＆旧データが残存する競合バグを物理的に根絶します。
  Future<void> initializeSyncPipeline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ★ 修正: sync_provider と dojo_room_sync_provider で別々のキーを使うとワイプ処理が競合し、
      // Isarのトランザクションロックで一方が失敗するため、共通のキーを使用して一元管理します。
      final lastDojoId = prefs.getString('global_last_dojo_id_v4');

      if (lastDojoId != null && lastDojoId.isNotEmpty && lastDojoId != dojoId) {
        // ★ 処理が重複しないよう、検知した瞬間にとりあえず新しいIDを保存しておく
        await prefs.setString('global_last_dojo_id_v4', dojoId);

        debugPrint(
          '🔄 [DojoRoomSync] テナント切り替え検知: $lastDojoId -> $dojoId. 古いローカルデータを完全パージします。',
        );

        if (!kIsWeb) {
          try {
            final isar = Isar.getInstance();
            if (isar != null) {
              await isar.writeTxn(() async {
                // ★ 修正: isar.clear() は監視ストリームを破壊しUIの更新を止めてしまうため無効化
              });
              debugPrint('🧹 [DojoRoomSync] Isarワイプをスキップしました（ストリーム保護）');
            } else {
              debugPrint(
                '⚠️ [DojoRoomSync] Isar.getInstance() が null です。セーフティネットとして手動削除を実行します',
              );
            }

            // ★ セーフティネット: メモリ上の試合を1件ずつ消去
            try {
              final localRepo = ref.read(localMatchRepositoryProvider);
              final allMatches = ref.read(matchListProvider);
              for (var m in allMatches) {
                await localRepo.deleteMatch(m.id);
              }
            } catch (e) {
              debugPrint('🔥 [DojoRoomSync] セーフティネット削除エラー: $e');
            }
          } catch (e) {
            debugPrint('🔥 [DojoRoomSync] Isarのワイプに失敗しました: $e');
          }
        }
      }

      // 既に更新済みなのでここでは何もしない
      if (lastDojoId == null || lastDojoId.isEmpty) {
        await prefs.setString('global_last_dojo_id_v4', dojoId);
      }
    } catch (e) {
      debugPrint('⚠️ [DojoRoomSync] SharedPreferencesアクセスエラー: $e');
    }

    // ★ 追加: 非同期パージ中に道場IDが再び切り替わったり画面が閉じられた場合、
    // 古い通信が裏で生き残る（ゾンビストリーム）のを防ぐための物理ブロック
    if (isDisposed) return;

    try {
      // 🌟 パージ完了後に初めてストリームを開通する（競合ゼロ）
      subscription = ref
          .read(firestoreProvider)
          .collection('organizations')
          .doc(dojoId)
          .collection('matches')
          .snapshots()
          .listen(
            (snapshot) {
              debugPrint(
                '📡 [DojoRoomSync] データを検知: ${snapshot.docChanges.length}件の変更を受信',
              );
              for (final change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added ||
                    change.type == DocumentChangeType.modified) {
                  final data = change.doc.data();
                  if (data == null) continue;

                  try {
                    final convertedData = _sanitizeFirestoreData(data);
                    final match = MatchModel.fromJson(convertedData);
                    final engine = KendoRuleEngine();
                    final analysis = engine.analyzeHistory(
                      match.events,
                      match,
                      match.rule,
                    );
                    final cloudProj = MatchProjectionMapper.toProjection(
                      match,
                      analysis,
                    );

                    store.updateProjectionDirectly(cloudProj);

                    if (!kIsWeb) {
                      ref.read(localMatchRepositoryProvider).saveMatch(match);
                      debugPrint(
                        '✅ [DojoRoomSync] Isarへ試合データを保存完了: ID=${match.id}',
                      );
                    }
                  } catch (e) {
                    debugPrint('⚠️ [DojoRoomSync] データ変換/保存エラー: $e');
                  }
                } else if (change.type == DocumentChangeType.removed) {
                  // ★ 追加: クラウド側で削除された試合があればローカルからも消去し、古いデータが残らないようにする
                  final data = change.doc.data();
                  if (data != null && !kIsWeb) {
                    final deletedId = change.doc.id;
                    ref
                        .read(localMatchRepositoryProvider)
                        .deleteMatch(deletedId);
                    debugPrint(
                      '🧹 [DojoRoomSync] クラウドでの削除を検知しローカルから消去: ID=$deletedId',
                    );
                  }
                }
              }
            },
            onError: (error) {
              debugPrint('🔥 [DojoRoomSync] 致命的な通信エラー: $error');
            },
          );
    } catch (e) {
      debugPrint('⚠️ [DojoRoomSync] Firestoreへの接続をスキップしました: $e');
    }
  }

  // 直列化した初期化プロセスをキック
  initializeSyncPipeline();

  // 道場IDが切り替わった、またはアプリ終了時に古い通信ストリームを安全に自動パージ
  ref.onDispose(() {
    isDisposed = true;
    subscription?.cancel();
  });
});
