import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';

void main() {
  group('🏎️ 【Phase 11: Dart AOT コンパイル関数インライン化】マイクロベンチマーク＆整合性テスト', () {
    late MatchModel testMatch;

    setUp(() {
      testMatch = MatchModel(
        id: 'test_aot_match',
        tournamentId: 'tournament_2026',
        matchType: 'individual',
        redName: '選手A',
        whiteName: '選手B',
        matchTimeMinutes: 4.0,
        timerStartedAt: DateTime(2026, 9, 4, 10, 0, 0),
        accumulatedPauseDurationMs: 15000,
      );
    });

    test(
      'calculateRemainingSeconds 100,000回連続呼び出しマイクロベンチマーク（超高速・ゼロアロケーション）',
      () {
        final now = DateTime(2026, 9, 4, 10, 1, 30);
        const iterations = 100000;

        // ウォームアップ
        for (int i = 0; i < 1000; i++) {
          testMatch.calculateRemainingSeconds(now);
        }

        final stopwatch = Stopwatch()..start();
        int lastCalculated = 0;
        for (int i = 0; i < iterations; i++) {
          lastCalculated = testMatch.calculateRemainingSeconds(now);
        }
        stopwatch.stop();

        final elapsedMs = stopwatch.elapsedMilliseconds;
        final elapsedUs = stopwatch.elapsedMicroseconds;
        final perCallUs = elapsedUs / iterations;

        // ignore: avoid_print
        print(
          '🏎️ [AOT Inline Benchmark: calculateRemainingSeconds]\n'
          '  - 実行回数: $iterations 回\n'
          '  - 総所要時間: $elapsedMs ms ($elapsedUs μs)\n'
          '  - 1回あたりの呼出コスト: ${perCallUs.toStringAsFixed(3)} μs\n'
          '  - 算出残り秒数: $lastCalculated 秒',
        );

        // 4分(240秒) - 15秒(一時停止) - 90秒(稼働) = 135秒
        expect(lastCalculated, equals(135));
        // 100,000回が 200ms 以内に完了すること（通常10〜30ms程度）
        expect(elapsedMs, lessThan(200));
      },
    );

    test('timerIsRunning 及び isDirty のインライン getter 整合性', () {
      expect(testMatch.timerIsRunning, isTrue);
      expect(testMatch.isDirty, isFalse);

      final stoppedMatch = testMatch.copyWith(timerStartedAt: null);
      expect(stoppedMatch.timerIsRunning, isFalse);
    });

    test('isHansokuIppon のインライン述語計算の正確性', () {
      final engine = KendoRuleEngine();

      expect(engine.isHansokuIppon(1), isFalse);
      expect(engine.isHansokuIppon(2), isTrue); // 2回で反則1本
      expect(engine.isHansokuIppon(3), isFalse);
      expect(engine.isHansokuIppon(4), isTrue); // 4回で反則2本
      expect(engine.isHansokuIppon(0), isFalse);
    });

    test('SyncCrdtMerger.sanitizeForSync のインラインペイロード変換', () {
      final rawData = {
        'redScore': 2,
        'whiteScore': 1,
        'matchTimeMinutes': 3,
        'nested': {'order': 1, 'category': '決勝'},
      };

      final sanitized = SyncCrdtMerger.sanitizeForSync(rawData);
      expect(sanitized['redScore'], equals(2));
      expect(sanitized['matchTimeMinutes'], equals(3.0));
      expect(sanitized['nested']['order'], equals(1.0));
      expect(sanitized['nested']['category'], equals('決勝'));
    });
  });
}
