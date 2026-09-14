import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🌐 端末時計ズレ（Clock Skew）に対するサーバー時刻オフセット補正サービス (Plan 3-②)
/// 体育館環境での運営端末と保護者端末の時計ズレによるタイマー表示狂い（0秒誤終了判定等）を根絶します。
class ServerClockOffsetService {
  ServerClockOffsetService._();
  static final ServerClockOffsetService instance = ServerClockOffsetService._();

  Duration _offset = Duration.zero;

  /// 現在保持しているサーバー時刻とローカル端末時刻のオフセット (サーバー時刻 - ローカル時刻)
  Duration get offset => _offset;

  /// テストまたは外部同期用のオフセット直接設定
  void setOffset(Duration newOffset) {
    _offset = newOffset;
    debugPrint(
      '🌐 [ServerClockOffset] Offset updated: ${_offset.inMilliseconds}ms',
    );
  }

  /// オフセットをリセット (0ms)
  void resetOffset() {
    _offset = Duration.zero;
  }

  /// サーバー時刻とのオフセットを計測・更新 (簡易NTPプロトコル)
  /// Firestore または HTTPヘッダー等を利用して、RTT/2 を加味した精密オフセットを算出します。
  Future<Duration> syncWithServer({FirebaseFirestore? firestore}) async {
    try {
      final startTime = DateTime.now().toUtc();
      DateTime serverTime;

      final db = firestore ?? FirebaseFirestore.instance;
      // サーバータイムスタンプを取得するための ping ドキュメント (軽量読み書きまたは serverTimestamp 推定)
      final docRef = db.collection('_system_metadata').doc('clock_sync');
      final snapshot = await docRef.get().timeout(const Duration(seconds: 3));

      final endTime = DateTime.now().toUtc();
      final roundTripDuration = endTime.difference(startTime);

      if (snapshot.exists && snapshot.data()?['serverTimestamp'] != null) {
        final ts = snapshot.data()!['serverTimestamp'] as Timestamp;
        serverTime = ts.toDate().toUtc();
      } else {
        // ドキュメントが存在しない場合はRTTのみ測定して現行オフセット維持
        return _offset;
      }

      // RTT / 2 を加味して推定される現時点の真のサーバー時刻
      final estimatedServerTime = serverTime.add(
        Duration(milliseconds: (roundTripDuration.inMilliseconds / 2).round()),
      );

      _offset = estimatedServerTime.difference(endTime);
      debugPrint(
        '🌐 [ServerClockOffset] Synced with server! RTT: ${roundTripDuration.inMilliseconds}ms, Offset: ${_offset.inMilliseconds}ms',
      );
      return _offset;
    } catch (e) {
      debugPrint('🌐 [ServerClockOffset] Sync fallback (offline or error): $e');
      // オフライン・失敗時は例外を投げず、安全に既存の offset (または 0) を維持
      return _offset;
    }
  }
}

final serverClockOffsetServiceProvider = Provider<ServerClockOffsetService>((
  ref,
) {
  return ServerClockOffsetService.instance;
});
