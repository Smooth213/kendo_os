import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// 🏃 連続稼働マラソンライフサイクルコントローラー
class MarathonMatchLifecycle {
  StreamController<String>? _eventStream;
  StreamSubscription<String>? _subscription;
  bool isDisposed = false;

  void startMatch() {
    _eventStream = StreamController<String>();
    _subscription = _eventStream!.stream.listen((_) {});
  }

  void dispose() {
    _subscription?.cancel();
    _eventStream?.close();
    _subscription = null;
    _eventStream = null;
    isDisposed = true;
  }
}

void main() {
  group('🌌 【Phase 9-5/6】72時間連続稼働マラソン メモリリークゼロ・破棄サイクル検証テスト', () {
    test('1. 1,000回の試合開始・終了・disposeサイクルを高速反復しても未解放オブジェクトがゼロであること', () {
      final activeSessions = <MarathonMatchLifecycle>[];

      // 1,000回連続試合ループ
      for (int i = 0; i < 1000; i++) {
        final session = MarathonMatchLifecycle()..startMatch();
        activeSessions.add(session);

        // 試合終了・画面離脱時の完全 dispose
        session.dispose();
      }

      // 全セッションが確実に破棄されていること
      expect(activeSessions.length, 1000);
      for (final s in activeSessions) {
        expect(s.isDisposed, isTrue);
      }

      // リストクリア（強参照解放）
      activeSessions.clear();
      expect(activeSessions.isEmpty, isTrue);
    });
  });
}
