import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kendo_os/domain/entities/audit_log.dart';
import 'dart:convert'; // ★ 追加: 構造化ログ（JSON）用
import 'dart:developer' as developer; // ★ 追加: 構造化ログ出力用

// Firestoreインスタンスを提供する（テスト時にモックと差し替え可能にするため）
final auditFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final auditProvider = Provider<AuditService>((ref) {
  return AuditService(ref.read(auditFirestoreProvider));
});

class AuditService {
  final FirebaseFirestore _firestore;
  AuditService(this._firestore);

  // ==========================================
  // ★ Phase 2-Step 1: 構造化ログ（Observability基盤）
  // テキストベースのprintを禁止し、すべてJSONフォーマットで出力する
  // ==========================================
  void _emitStructuredLog(Map<String, dynamic> payload, {bool isError = false, String? traceId}) {
    final logData = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': isError ? 'ERROR' : 'INFO',
      'traceId': ?traceId, // ★ Phase 2-3: トレースIDの付与
      ...payload,
    };
    // 開発コンソールやログ収集基盤がパースしやすいJSON文字列として出力
    developer.log(jsonEncode(logData), name: 'KendoOS.Audit');
  }

  /// 監査ログをFirestoreの 'audit_logs' コレクションに保存する
  Future<void> logAction({
    required String matchId,
    required AuditAction action,
    required String details,
    String deviceId = 'local_device', 
    int logicalClock = 0,             
    String? traceId, // ★ 追加
  }) async {
    final stopwatch = Stopwatch()..start(); // ★ 処理時間の計測開始
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';

    try {
      final log = AuditLog(
        id: const Uuid().v4(),
        matchId: matchId,
        userId: userId,
        action: action,
        details: details,
        timestamp: DateTime.now(),
        deviceId: deviceId,    
        logicalClock: logicalClock, 
      );
      
      await _firestore.collection('audit_logs').doc(log.id).set(log.toJson());

      stopwatch.stop();
      // ★ 正常終了時の構造化ログ出力
      _emitStructuredLog({
        'event': action.name,
        'matchId': matchId,
        'userId': userId,
        'details': details,
        'latencyMs': stopwatch.elapsedMilliseconds,
      }, traceId: traceId); // ★ 追加

    } catch (e) {
      stopwatch.stop();
      // ★ 失敗時の構造化ログ出力（テキストでの debugPrint は廃止）
      _emitStructuredLog({
        'event': action.name,
        'matchId': matchId,
        'userId': userId,
        'error': e.toString(),
        'latencyMs': stopwatch.elapsedMilliseconds,
      }, isError: true, traceId: traceId); // ★ 追加
    }
  }
}