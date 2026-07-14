import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

final strokeRepositoryProvider = Provider((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  return StrokeRepository(dojoId: dojoId);
});

class StrokeRepository {
  final String dojoId;
  final FirebaseFirestore _db;

  StrokeRepository({required this.dojoId, FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _strokesCollection =>
      _db.collection('organizations').doc(dojoId).collection('strokes');

  /// 新しい線をFirestoreに保存する
  Future<void> addStroke(StrokeModel stroke) async {
    try {
      await _strokesCollection.doc(stroke.id).set(stroke.toMap());
      debugPrint('✅ 線を保存しました: ID=${stroke.id}, ProgramID=${stroke.programId}');
    } catch (e) {
      debugPrint('❌ 保存エラー: $e');
    }
  }

  /// 特定のプログラムに引かれた線をリアルタイムで取得する
  Stream<List<StrokeModel>> watchStrokes(String programId) {
    // ★物理調停：インデックス(programId ASC, createdAt ASC)に合わせて昇順でソートし、
    // 重複IDの排除とisSharedフィルタリングをインメモリで安全に行います。
    return _strokesCollection
        .where('programId', isEqualTo: programId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          final uniqueStrokes = <String, StrokeModel>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final stroke = StrokeModel.fromMap({...data, 'id': doc.id});
            if (stroke.isShared) {
              uniqueStrokes[stroke.id] = stroke;
            }
          }
          return uniqueStrokes.values.toList();
        });
  }

  /// 特定のプログラムに引かれた線をすべて消去する
  Future<void> clearStrokes(String programId) async {
    try {
      debugPrint('🧹 全消去命令を送信: ProgramID=$programId');
      final snapshot = await _strokesCollection
          .where('programId', isEqualTo: programId)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('✅ 全消去完了');
    } catch (e) {
      debugPrint('❌ 全消去エラー: $e');
    }
  }

  /// 直前に引かれた線を1つだけ取り消す（Undo）
  Future<void> undoLastStroke(String programId) async {
    try {
      debugPrint('🔙 Undo命令を送信: ProgramID=$programId');

      // ★ 物理調停：descending: true の複合インデックス未定義による無言のエラーを完全に回避するため、
      // 既存のwatchStrokesと同じ昇順（descending: false）クエリで全件取得し、インメモリで最後の共有ペンを削除します。
      final querySnapshot = await _strokesCollection
          .where('programId', isEqualTo: programId)
          .orderBy('createdAt', descending: false)
          .get();

      // インメモリで「isShared: true」の最新の線を特定
      final sharedStrokes = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['isShared'] as bool? ?? true;
      }).toList();

      if (sharedStrokes.isNotEmpty) {
        await sharedStrokes.last.reference.delete();
        debugPrint('✅ 削除完了');
      } else {
        debugPrint('⚠️ 削除対象が見つかりません');
      }
    } catch (e) {
      debugPrint('❌ Undoエラー: $e');
    }
  }

  /// 特定の線をID指定で削除する
  Future<void> deleteStroke(String id) async {
    try {
      await _strokesCollection.doc(id).delete();
      debugPrint('✅ 線を削除しました: ID=$id');
    } catch (e) {
      debugPrint('❌ 削除エラー: $e');
    }
  }
}
