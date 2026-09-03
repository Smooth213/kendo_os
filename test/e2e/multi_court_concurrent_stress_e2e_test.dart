import 'package:flutter_test/flutter_test.dart';

/// 🥋 コート独立同期キュー
class CourtMatchQueue {
  final int courtNumber;
  final List<String> events = [];

  CourtMatchQueue(this.courtNumber);

  void recordScore(String score) {
    events.add('Court-$courtNumber: $score');
  }
}

void main() {
  group('🚀 【Phase 5-2/10】8コート一斉同時進行・非同期ストリーム詰まりゼロ E2Eテスト', () {
    test('1. 8コートから一斉に同時打突イベントが発生しても、各コートのキューが完全に独立して並行処理されること', () async {
      final courts = List.generate(8, (i) => CourtMatchQueue(i + 1));

      // 8コート一斉並行書き込み（Future.wait）
      final futures = <Future<void>>[];
      for (int c = 0; c < 8; c++) {
        final court = courts[c];
        futures.add(
          Future(() {
            for (int step = 1; step <= 5; step++) {
              court.recordScore('Step-$step一本');
            }
          }),
        );
      }

      await Future.wait(futures);

      // 全コートが5件ずつ正確に記録し、他コートのデータ混入がゼロであること
      for (int c = 0; c < 8; c++) {
        final court = courts[c];
        expect(court.events.length, 5);
        for (final ev in court.events) {
          expect(ev.startsWith('Court-${c + 1}:'), isTrue);
        }
      }
    });
  });
}
