import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../models/local_stroke_model.dart';

/// どこからでもリポジトリを呼び出せるようにするProvider
final localStrokeRepositoryProvider = Provider<LocalStrokeRepository>((ref) {
  // すでに開かれているIsarインスタンスを取得します
  final isar = Isar.getInstance()!; 
  return LocalStrokeRepository(isar);
});

class LocalStrokeRepository {
  final Isar _isar;

  LocalStrokeRepository(this._isar);

  /// 新しい青線（個人メモ）をローカルに保存する
  Future<void> addStroke(LocalStrokeModel stroke) async {
    await _isar.writeTxn(() async {
      await _isar.localStrokeModels.put(stroke);
    });
  }

  /// 特定のプログラムに引かれた青線をリアルタイムで取得する
  Stream<List<LocalStrokeModel>> watchStrokes(String programId) {
    return _isar.localStrokeModels
        .filter()
        .programIdEqualTo(programId)
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  /// （Undo）直前に引いた青線を1つだけ消す
  Future<void> undoLastStroke(String programId) async {
    await _isar.writeTxn(() async {
      final lastStroke = await _isar.localStrokeModels
          .filter()
          .programIdEqualTo(programId)
          .sortByCreatedAtDesc() // 新しい順に並び替え
          .findFirst();          // 一番上（最新）を取得

      if (lastStroke != null) {
        await _isar.localStrokeModels.delete(lastStroke.id);
      }
    });
  }

  /// 全消去：このプログラムの青線をすべて消す
  Future<void> clearStrokes(String programId) async {
    await _isar.writeTxn(() async {
      await _isar.localStrokeModels
          .filter()
          .programIdEqualTo(programId)
          .deleteAll();
    });
  }
}