import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

// ★ プロバイダーの定義
final programRepositoryProvider = Provider((ref) {
  final dojoId = ref.watch(currentDojoIdProvider);
  return ProgramRepository(dojoId: dojoId);
});

class ProgramRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage? _injectedStorage;
  final String dojoId;

  FirebaseStorage get _storage => _injectedStorage ?? FirebaseStorage.instance;

  ProgramRepository({
    required this.dojoId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _injectedStorage = storage;

  // 1. プログラムのアップロードとFirestoreへの保存
  Future<String> uploadProgram({
    required String tournamentId,
    required String title,
    File? file, // ★ Web対応のため Nullable に変更
    Uint8List? bytes, // ★ Web用のバイナリデータを受け取る引数を追加
    required String fileType,
    required int pageCount,
  }) async {
    if (dojoId.isEmpty) {
      throw Exception('コンテナ(道場ID)が設定されていません');
    }

    // 1. IDを発行
    final docRef = _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('tournaments')
        .doc(tournamentId)
        .collection('programs')
        .doc();
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
    final String fileName;
    if (file != null) {
      fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    } else {
      // Webの場合はファイルパスがないため、ダミーのファイル名を生成
      final ext = fileType == 'pdf' ? 'pdf' : 'jpg';
      fileName = '${DateTime.now().millisecondsSinceEpoch}_web_upload.$ext';
    }

    // ★ Storageへの保存もコンテナ（道場）ごとに分離する
    final storageRef = _storage.ref().child(
      'organizations/$dojoId/programs/$programId/$fileName',
    );

    String downloadUrl;
    if (kIsWeb && bytes != null) {
      // ★ Webの場合：bytes（バイナリ）を使って直接アップロード
      final uploadTask = await storageRef.putData(bytes);
      downloadUrl = await uploadTask.ref.getDownloadURL();
    } else if (file != null) {
      // ★ モバイルの場合：Fileを使ってアップロード
      final uploadTask = await storageRef.putFile(file);
      downloadUrl = await uploadTask.ref.getDownloadURL();
    } else {
      throw Exception('アップロードするデータがありません。');
    }

    // 4. URLが取得できたら、仮データに画像URLを「追記（update）」する
    await docRef.update({'fileUrl': downloadUrl});

    return programId;
  }

  // 2. 特定の大会のプログラム一覧をリアルタイム取得
  Stream<List<ProgramModel>> watchPrograms(String tournamentId) {
    return _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('tournaments')
        .doc(tournamentId)
        .collection('programs')
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ProgramModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
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
    await _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('tournaments')
        .doc(program.tournamentId)
        .collection('programs')
        .doc(program.id)
        .delete();

    // 紐づく共有ストローク（線）も削除するバッチ処理
    final strokesSnapshot = await _firestore
        .collection('organizations')
        .doc(dojoId)
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
  Stream<List<StrokeModel>> watchSharedStrokes(
    String programId,
    int pageIndex,
  ) {
    return _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('strokes')
        .where('programId', isEqualTo: programId)
        .where('pageIndex', isEqualTo: pageIndex)
        .where('isShared', isEqualTo: true) // 共有フラグが立っているものだけ
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StrokeModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // 5. 共有ハイライトの保存
  Future<void> saveSharedStroke(StrokeModel stroke) async {
    final docRef = _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('strokes')
        .doc(stroke.id);
    await docRef.set(stroke.toJson());
  }

  // 6. 共有ハイライトの削除（消しゴム用）
  Future<void> deleteSharedStroke(String strokeId) async {
    await _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('strokes')
        .doc(strokeId)
        .delete();
  }
}
