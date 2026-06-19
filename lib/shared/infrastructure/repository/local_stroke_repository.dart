import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import '../persistence/models/local_stroke_model.dart';

/// どこからでもリポジトリを呼び出せるようにするProvider
final localStrokeRepositoryProvider = Provider<LocalStrokeRepository>((ref) {
  final isar = kIsWeb ? null : Isar.getInstance();
  final dojoId = ref.watch(currentDojoIdProvider);
  final syncContext = ref.watch(currentSyncContextProvider);
  return LocalStrokeRepository(
    isar,
    dojoId: dojoId,
    deviceId: syncContext.deviceId,
  );
});

class LocalStrokeRepository {
  final Isar? _isar;
  final String dojoId;
  final String deviceId;
  final FirebaseFirestore _firestore;

  LocalStrokeRepository(
    this._isar, {
    required this.dojoId,
    required this.deviceId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 新しい青線（個人メモ）を保存する（Web版はFirestore、ネイティブ版はIsar）
  Future<void> addStroke(LocalStrokeModel stroke) async {
    if (kIsWeb || _isar == null) {
      final docId =
          'local-${DateTime.now().millisecondsSinceEpoch}-${stroke.pointsX.length}';
      await _firestore
          .collection('organizations')
          .doc(dojoId)
          .collection('strokes')
          .doc(docId)
          .set({
            'id': docId,
            'programId': stroke.programId,
            'points': List.generate(
              stroke.pointsX.length,
              (index) => {
                'dx': stroke.pointsX[index],
                'dy': stroke.pointsY[index],
              },
            ),
            'color': stroke.colorValue,
            'strokeWidth': stroke.strokeWidth,
            'isShared': false, // 個人線
            'deviceId': deviceId, // 自分のデバイスID
            'createdAt': stroke.createdAt.toUtc().toIso8601String(),
          });
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.localStrokeModels.put(stroke);
    });
  }

  /// 特定のプログラムに引かれた青線をリアルタイムで取得する（Web版はFirestore、ネイティブ版はIsar）
  Stream<List<LocalStrokeModel>> watchStrokes(String programId) {
    if (kIsWeb || _isar == null) {
      return _firestore
          .collection('organizations')
          .doc(dojoId)
          .collection('strokes')
          .where('programId', isEqualTo: programId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
            final list = <LocalStrokeModel>[];
            for (var doc in snapshot.docs) {
              final data = doc.data();
              final isSharedVal = data['isShared'] as bool? ?? true;
              final deviceIdVal = data['deviceId'] as String? ?? '';

              if (!isSharedVal && deviceIdVal == deviceId) {
                final pts = data['points'] as List<dynamic>? ?? [];
                final pointsX = pts
                    .map((p) => (p['dx'] as num).toDouble())
                    .toList();
                final pointsY = pts
                    .map((p) => (p['dy'] as num).toDouble())
                    .toList();
                final localStroke = LocalStrokeModel()
                  ..programId = data['programId'] ?? ''
                  ..pointsX = pointsX
                  ..pointsY = pointsY
                  ..colorValue = data['color'] as int? ?? 0xFF0000FF
                  ..strokeWidth =
                      (data['strokeWidth'] as num?)?.toDouble() ?? 3.0
                  ..createdAt =
                      DateTime.tryParse(data['createdAt'] ?? '') ??
                      DateTime.now();
                list.add(localStroke);
              }
            }
            return list;
          });
    }

    return _isar.localStrokeModels
        .filter()
        .programIdEqualTo(programId)
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  /// （Undo）直前に引いた青線を1つだけ消す
  Future<void> undoLastStroke(String programId) async {
    if (kIsWeb || _isar == null) {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(dojoId)
          .collection('strokes')
          .where('programId', isEqualTo: programId)
          .orderBy('createdAt', descending: false)
          .get();

      // インメモリで自分の最新の個人ペンを見つける
      final myStrokes = snapshot.docs.where((doc) {
        final data = doc.data();
        final isSharedVal = data['isShared'] as bool? ?? true;
        final deviceIdVal = data['deviceId'] as String? ?? '';
        return !isSharedVal && deviceIdVal == deviceId;
      }).toList();

      if (myStrokes.isNotEmpty) {
        await myStrokes.last.reference.delete();
      }
      return;
    }

    await _isar.writeTxn(() async {
      final lastStroke = await _isar.localStrokeModels
          .filter()
          .programIdEqualTo(programId)
          .sortByCreatedAtDesc()
          .findFirst();

      if (lastStroke != null) {
        await _isar.localStrokeModels.delete(lastStroke.id);
      }
    });
  }

  /// 全消去：このプログラムの青線をすべて消す
  Future<void> clearStrokes(String programId) async {
    if (kIsWeb || _isar == null) {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(dojoId)
          .collection('strokes')
          .where('programId', isEqualTo: programId)
          .get();

      final batch = _firestore.batch();
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isSharedVal = data['isShared'] as bool? ?? true;
        final deviceIdVal = data['deviceId'] as String? ?? '';
        if (!isSharedVal && deviceIdVal == deviceId) {
          batch.delete(doc.reference);
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.localStrokeModels
          .filter()
          .programIdEqualTo(programId)
          .deleteAll();
    });
  }
}
