import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ★ Step 4-1: ネットワーク接続状態をリアルタイムで監視するProvider
final connectivityProvider = StreamProvider<bool>((ref) {
  // 初回起動時の状態チェック用
  final controller = StreamController<bool>();
  
  // 状態が変わるたびに通知を受け取る
  final subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    // 複数のネットワーク（Wi-Fiとモバイルなど）のうち、一つでも繋がっていればオンラインとする
    final isOnline = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );
    controller.add(isOnline);
  });

  // 初回チェック
  Connectivity().checkConnectivity().then((results) {
    final isOnline = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );
    controller.add(isOnline);
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

// 現在オンラインかどうかを簡単に判定できる Boolean の Provider
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? false;
});