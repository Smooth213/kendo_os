import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/program_model.dart';

// ★ プロバイダーの定義
final programRepositoryProvider = Provider((ref) => ProgramRepository());

class ProgramRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. プログラムのアップロードとFirestoreへの保存
  Future<String> uploadProgram({
    required String tournamentId,
    required String title,
    required File file,
    required String fileType,
    required int pageCount,
  }) async {
    // 1. IDを発行
    final docRef = _firestore.collection('programs').doc();
    final programId = docRef.id;

    // 2. 【重要】先に「仮のデータ」をFirestoreに保存する（AIのエラーを防ぐため！）
    final program = ProgramModel(
      id: programId,
      tournamentId: tournamentId,
      title: title,
      fileUrl: '', // アップロード前なので一旦空にしておく
      fileType: fileType,
      pageCount: pageCount,
      createdAt: DateTime.now(),
    );
    await docRef.set(program.toJson());

    // 3. Storageにアップロード（ここでAIが裏で走り始める）
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final storageRef = _storage.ref().child('programs/$programId/$fileName');
    
    final uploadTask = await storageRef.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // 4. URLが取得できたら、仮データに画像URLを「追記（update）」する
    await docRef.update({'fileUrl': downloadUrl});

    return programId;
  }

  // 2. 特定の大会のプログラム一覧をリアルタイム取得
  Stream<List<ProgramModel>> watchPrograms(String tournamentId) {
    return _firestore
        .collection('programs')
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgramModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // 3. プログラムの削除（StorageとFirestore両方から完全に消し去る）
  Future<void> deleteProgram(ProgramModel program) async {
    // Storageから削除
    try {
      final storageRef = _storage.refFromURL(program.fileUrl);
      await storageRef.delete();
    } catch (e) {
      debugPrint('Storage削除エラー(無視して続行): $e');
    }

    // Firestoreから削除
    await _firestore.collection('programs').doc(program.id).delete();
    
    // 紐づく共有ストローク（線）も削除するバッチ処理
    final strokesSnapshot = await _firestore
        .collection('strokes')
        .where('programId', isEqualTo: program.id)
        .get();
    final batch = _firestore.batch();
    for (var doc in strokesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // 4. 共有ハイライト（線）のリアルタイム取得
  Stream<List<StrokeModel>> watchSharedStrokes(String programId, int pageIndex) {
    return _firestore
        .collection('strokes')
        .where('programId', isEqualTo: programId)
        .where('pageIndex', isEqualTo: pageIndex)
        .where('isShared', isEqualTo: true) // 共有フラグが立っているものだけ
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StrokeModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // 5. 共有ハイライトの保存
  Future<void> saveSharedStroke(StrokeModel stroke) async {
    final docRef = _firestore.collection('strokes').doc(stroke.id);
    await docRef.set(stroke.toJson());
  }

  // 6. 共有ハイライトの削除（消しゴム用）
  Future<void> deleteSharedStroke(String strokeId) async {
    await _firestore.collection('strokes').doc(strokeId).delete();
  }
}