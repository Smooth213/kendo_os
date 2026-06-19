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
  Future<ProgramModel> uploadProgram({
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

    // ★ 追加: Firestoreに仮保存する前に、アップロードデータが存在するか確実にチェックする
    if (file == null && (bytes == null || bytes.isEmpty)) {
      throw Exception('アップロードするデータがありません。ファイルが正しく選択されているか確認してください。');
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
      // ★ 修正: 空文字('')だとUI側でNetworkImageがクラッシュ(No host specified)するため、安全なダミーURLを設定
      fileUrl:
          'https://placehold.co/400x600/E8E8E8/808080.png?text=Uploading...',
      fileType: fileType,
      pageCount: pageCount,
      createdAt: DateTime.now(),
    );
    await docRef.set(program.toJson());

    // 3. Storageへのアップロード（★ 非同期にせず、完了を確実に待機する）
    final String fileName;
    if (file != null) {
      fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    } else {
      final ext = fileType == 'pdf' ? 'pdf' : 'jpg';
      fileName = '${DateTime.now().millisecondsSinceEpoch}_web_upload.$ext';
    }

    final storageRef = _storage.ref().child(
      'organizations/$dojoId/tournaments/$tournamentId/programs/$programId/$fileName',
    );

    // ★ 追加: Web環境でPDFビューアがフリーズするのを防ぐため、明示的にMIMEタイプを設定する
    final metadata = SettableMetadata(
      contentType: fileType == 'pdf' ? 'application/pdf' : 'image/jpeg',
    );

    String downloadUrl;
    try {
      if (bytes != null && bytes.isNotEmpty) {
        final uploadTask = await storageRef.putData(bytes, metadata);
        downloadUrl = await uploadTask.ref.getDownloadURL();
      } else {
        final uploadTask = await storageRef.putFile(file!, metadata);
        downloadUrl = await uploadTask.ref.getDownloadURL();
      }

      await docRef.update({'fileUrl': downloadUrl});
      return program.copyWith(fileUrl: downloadUrl);
    } catch (e) {
      await docRef.update({
        'fileUrl':
            'https://placehold.co/400x600/f8d7da/c82333.png?text=Upload+Failed',
      });
      debugPrint('Storageアップロードエラー: $e');
      throw Exception('アップロードに失敗しました。Storageのルールや通信状況を確認してください。詳細: $e');
    }
  }

  // 2. 特定の大会のプログラム一覧をリアルタイム取得
  Stream<List<ProgramModel>> watchPrograms(String tournamentId) {
    return _firestore
        .collection('organizations')
        .doc(dojoId)
        .collection('tournaments')
        .doc(tournamentId)
        .collection('programs')
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
        .map((snapshot) {
          final uniqueStrokes = <String, StrokeModel>{};
          for (var doc in snapshot.docs) {
            final stroke = StrokeModel.fromJson({...doc.data(), 'id': doc.id});
            uniqueStrokes[stroke.id] = stroke;
          }
          return uniqueStrokes.values.toList();
        });
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
