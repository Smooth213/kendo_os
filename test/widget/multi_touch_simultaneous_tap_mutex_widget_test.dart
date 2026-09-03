import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🥋 マルチタッチ同時打突排他制御（Mutex）ガード
class StrikeMutexController {
  bool _isLocked = false;
  String? lastAcceptedStrike;

  bool tryRecordStrike(String strikeName) {
    if (_isLocked) return false; // 同時打突排他ロック
    _isLocked = true;
    lastAcceptedStrike = strikeName;
    return true;
  }

  void unlock() {
    _isLocked = false;
  }
}

void main() {
  group('🎨 【Phase 3-2/11】赤白同時マルチタッチタップ排他制御（Mutex）テスト', () {
    testWidgets('1. 赤面と白小手を同一フレームで同時タップした場合、片方のみ受理され二重加点が防止されること', (
      tester,
    ) async {
      final mutex = StrikeMutexController();
      int redScore = 0;
      int whiteScore = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('red_men_btn'),
                    onPressed: () {
                      if (mutex.tryRecordStrike('赤面')) {
                        redScore++;
                      }
                    },
                    child: const Text('赤 面'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('white_kote_btn'),
                    onPressed: () {
                      if (mutex.tryRecordStrike('白小手')) {
                        whiteScore++;
                      }
                    },
                    child: const Text('白 小手'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // マルチタッチをシミュレート（2つのポインタで同時タップ）
      final pointer1 = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('red_men_btn'))),
      );
      final pointer2 = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('white_kote_btn'))),
      );

      await pointer1.up();
      await pointer2.up();
      await tester.pump();

      // 合計加点は必ず1本のみ（両方同時に2本加点される事故が完全に防がれていること）
      expect(redScore + whiteScore, 1);
      expect(mutex.lastAcceptedStrike, isNotNull);
    });
  });
}
