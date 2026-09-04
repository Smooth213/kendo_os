import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/p2p/presentation/assets/web_viewer_html.dart';
import 'package:kendo_os/shared/utils/payload_compression_helper.dart';

/// 【Phase 5: P2Pローカル配信】端末内蔵の軽量WebSocket＆HTTPサーバー
class LocalP2pBroadcaster {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  String? _localIp;
  int _port = 8080;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  String? get localIp => _localIp;
  int get port => _port;
  int get clientCount => _clients.length;

  /// サーバー起動
  Future<String?> startServer({int port = 8080}) async {
    if (kIsWeb) return null;
    if (_isRunning && _server != null) {
      return 'http://$_localIp:$_port';
    }

    try {
      _port = port;
      _localIp = await _findLocalIp();

      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        _port,
        shared: true,
      );
      _isRunning = true;

      _server!.listen((HttpRequest request) {
        if (request.uri.path == '/ws') {
          WebSocketTransformer.upgrade(request)
              .then((WebSocket socket) {
                _clients.add(socket);
                socket.done.then((_) {
                  _clients.remove(socket);
                });
              })
              .catchError((_) {});
        } else {
          // ブラウザアクセス時に軽量リアルタイムビュアーHTMLを返却
          request.response.headers.contentType = ContentType.html;
          request.response.write(
            WebViewHtml.build(hostIp: _localIp ?? 'localhost', port: _port),
          );
          request.response.close();
        }
      });

      return 'http://$_localIp:$_port';
    } catch (e) {
      debugPrint('🔥 [P2P Server Error] Failed to start: $e');
      _isRunning = false;
      return null;
    }
  }

  /// サーバー停止
  Future<void> stopServer() async {
    if (kIsWeb) return;
    for (final client in _clients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
  }

  /// 試合状態のブロードキャスト（接続中の全端末へ即時一括送信）
  void broadcastMatch(MatchModel match, {int? remainingSeconds}) {
    if (!_isRunning || _clients.isEmpty) return;

    final data = {
      'type': 'MATCH_UPDATE',
      'id': match.id,
      'matchType': match.matchType,
      'category': match.category,
      'redName': match.redName,
      'whiteName': match.whiteName,
      'redScore': match.redScore,
      'whiteScore': match.whiteScore,
      'status': match.status,
      'remainingSeconds':
          remainingSeconds ?? match.calculateRemainingSeconds(DateTime.now()),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final payload = jsonEncode(data);
    for (final client in List<WebSocket>.from(_clients)) {
      try {
        client.add(payload);
      } catch (_) {
        _clients.remove(client);
      }
    }
  }

  /// 📶 【Phase 9】大量同期データ（大会全試合履歴等）のGzip圧縮ブロードキャスト
  void broadcastCompressedPayload(Map<String, dynamic> data) {
    if (!_isRunning || _clients.isEmpty) return;

    final jsonStr = jsonEncode(data);
    final compressedBytes = PayloadCompressionHelper.compressString(jsonStr);

    for (final client in List<WebSocket>.from(_clients)) {
      try {
        client.add(compressedBytes);
      } catch (_) {
        _clients.remove(client);
      }
    }
  }

  /// ローカルWi-Fi / テザリングのIPアドレスを探索
  Future<String> _findLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }
}

final localP2pBroadcasterProvider = Provider<LocalP2pBroadcaster>((ref) {
  final broadcaster = LocalP2pBroadcaster();
  ref.onDispose(() {
    broadcaster.stopServer();
  });
  return broadcaster;
});
