import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stroke_model.dart';

final strokeRepositoryProvider = Provider((ref) => StrokeRepository());

class StrokeRepository {
  final _db = FirebaseFirestore.instance;

  /// 新しい線をFirestoreに保存する
  Future<void> addStroke(StrokeModel stroke) async {
    try {
      await _db.collection('strokes').doc(stroke.id).set(stroke.toMap());
      debugPrint('✅ 線を保存しました: ID=${stroke.id}, ProgramID=${stroke.programId}');
    } catch (e) {
      debugPrint('❌ 保存エラー: $e');
    }
  }

  /// 特定のプログラムに引かれた線をリアルタイムで取得する
  Stream<List<StrokeModel>> watchStrokes(String programId) {
    // ★重要: 先ほど作成したインデックス（createdAt 降順）に合わせて並び替えます
    return _db
        .collection('strokes')
        .where('programId', isEqualTo: programId)
        .orderBy('createdAt', descending: true) // ここを Descending (降順) に合わせる
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StrokeModel.fromMap(doc.data())).toList();
    });
  }

  /// 特定のプログラムに引かれた線をすべて消去する
  Future<void> clearStrokes(String programId) async {
    try {
      debugPrint('🧹 全消去命令を送信: ProgramID=$programId');
      final snapshot = await _db.collection('strokes').where('programId', isEqualTo: programId).get();
      
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

      final querySnapshot = await _db
          .collection('strokes')
          .where('programId', isEqualTo: programId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache)); // ★ サーバーとキャッシュ両方を強制チェック

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        debugPrint('✅ 削除完了');
      } else {
        debugPrint('⚠️ 削除対象が見つかりません');
      }
    } catch (e) {
      debugPrint('❌ Undoエラー: $e');
    }
  }
}