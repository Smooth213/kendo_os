import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audit_log.dart';

// Firestoreインスタンスを提供する（テスト時にモックと差し替え可能にするため）
final auditFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final auditProvider = Provider<AuditService>((ref) {
  return AuditService(ref.read(auditFirestoreProvider));
});

class AuditService {
  final FirebaseFirestore _firestore;
  AuditService(this._firestore);

  /// 監査ログをFirestoreの 'audit_logs' コレクションに保存する
  Future<void> logAction({
    required String matchId,
    required String action,
    required String details,
  }) async {
    try {
      // 現在のユーザーIDを取得（未ログイン時は 'unknown_user' または端末ID等）
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
      
      final log = AuditLog(
        id: const Uuid().v4(),
        matchId: matchId,
        userId: userId,
        action: action,
        details: details,
        timestamp: DateTime.now(),
      );
      
      // 試合データとは別の独立したコレクションに保存（監査ログは絶対に上書き・削除しない設計）
      await _firestore.collection('audit_logs').doc(log.id).set(log.toJson());
    } catch (e) {
      // 監査ログの保存失敗でアプリ自体を落とさないようキャッチのみ行う
      debugPrint('🚨 監査ログの保存に失敗: $e');
    }
  }
}