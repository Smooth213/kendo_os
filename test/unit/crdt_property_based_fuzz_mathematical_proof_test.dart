import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

/// 🌐 CRDT スコア状態コンバージェンス（収束）マージエンジン
class CrdtScoreConvergenceEngine {
  /// 複数端末から受信した ScoreEvent セットを決定論的にマージし、正規化された一意のイベント列を生成
  static List<ScoreEvent> merge(List<ScoreEvent> incomingEvents) {
    // 1. 冪等性: IDによる重複排除（Set / Mapによる一意化）
    final uniqueMap = <String, ScoreEvent>{};
    for (final event in incomingEvents) {
      if (!uniqueMap.containsKey(event.id)) {
        uniqueMap[event.id] = event;
      } else {
        // 同一IDの場合、論理時計が大きい方を採用（決定論的）
        if (event.logicalClock > uniqueMap[event.id]!.logicalClock) {
          uniqueMap[event.id] = event;
        }
      }
    }

    final uniqueList = uniqueMap.values.toList();

    // 2. 可換性・結合性: 論理時計（Lamport Clock）➔ タイムスタンプ ➔ ID の辞書順ソート
    uniqueList.sort((a, b) {
      final clockCompare = a.logicalClock.compareTo(b.logicalClock);
      if (clockCompare != 0) return clockCompare;

      final timeCompare = a.timestamp.compareTo(b.timestamp);
      if (timeCompare != 0) return timeCompare;

      return a.id.compareTo(b.id);
    });

    return uniqueList;
  }

  /// マージ済みイベント列から最終スコアを計算
  static Map<Side, int> computeFinalScore(List<ScoreEvent> events) {
    int redScore = 0;
    int whiteScore = 0;

    for (final ev in events) {
      if (ev.isIppon) {
        if (ev.side == Side.red) {
          redScore++;
        } else if (ev.side == Side.white) {
          whiteScore++;
        }
      }
    }

    return {Side.red: redScore, Side.white: whiteScore};
  }
}

void main() {
  group('🎲 CRDT同期エンジンの数学的無矛盾性証明（Property-Based Testing & Fuzzing）', () {
    final rng = Random(42); // シード固定で再現性を完全担保

    /// ランダムなScoreEventを生成するヘルパー
    ScoreEvent generateRandomEvent(int index, {int? forceClock}) {
      final side = rng.nextBool() ? Side.red : Side.white;
      const strikes = [
        StrikeType.men,
        StrikeType.kote,
        StrikeType.dou,
        StrikeType.tsuki,
      ];
      final strike = strikes[rng.nextInt(strikes.length)];
      final clock = forceClock ?? (index + 1);
      final timestamp = DateTime(
        2026,
        9,
        4,
        10,
        0,
        0,
      ).add(Duration(seconds: clock * 5));

      return ScoreEvent(
        id: 'ev_fuzz_$index',
        side: side,
        strikeType: strike,
        isIppon: true,
        timestamp: timestamp,
        logicalClock: clock,
      );
    }

    test(
      '1. 【可換性の証明 (Commutativity)】 100通りの順序シャッフルでも最終スコアと状態が100%同一に収束すること',
      () {
        // 50件のランダムイベント群を生成
        final baseEvents = List.generate(50, (i) => generateRandomEvent(i));
        final canonicalResult = CrdtScoreConvergenceEngine.merge(baseEvents);
        final canonicalScore = CrdtScoreConvergenceEngine.computeFinalScore(
          canonicalResult,
        );

        // 100回、ランダムに配列をシャッフルしてマージ
        for (int trial = 0; trial < 100; trial++) {
          final shuffled = List<ScoreEvent>.from(baseEvents)..shuffle(rng);
          final merged = CrdtScoreConvergenceEngine.merge(shuffled);
          final score = CrdtScoreConvergenceEngine.computeFinalScore(merged);

          // 各イベントのID順序が正準結果と完全一致すること（完全な可換性）
          expect(merged.length, canonicalResult.length);
          for (int i = 0; i < merged.length; i++) {
            expect(merged[i].id, canonicalResult[i].id);
          }

          // 最終スコアが完全に一致すること
          expect(score[Side.red], canonicalScore[Side.red]);
          expect(score[Side.white], canonicalScore[Side.white]);
        }
      },
    );

    test(
      '2. 【結合性の証明 (Associativity)】 (A ∪ B) ∪ C == A ∪ (B ∪ C) が数学的に成立すること',
      () {
        final groupA = List.generate(20, (i) => generateRandomEvent(i));
        final groupB = List.generate(20, (i) => generateRandomEvent(i + 20));
        final groupC = List.generate(20, (i) => generateRandomEvent(i + 40));

        // パターン1: (A + B) をマージ後、さらに C をマージ
        final mergeAB = CrdtScoreConvergenceEngine.merge([
          ...groupA,
          ...groupB,
        ]);
        final leftAssociative = CrdtScoreConvergenceEngine.merge([
          ...mergeAB,
          ...groupC,
        ]);

        // パターン2: (B + C) をマージ後、A とマージ
        final mergeBC = CrdtScoreConvergenceEngine.merge([
          ...groupB,
          ...groupC,
        ]);
        final rightAssociative = CrdtScoreConvergenceEngine.merge([
          ...groupA,
          ...mergeBC,
        ]);

        // 左右の結合結果が1ビットの狂いもなく完全一致すること
        expect(leftAssociative.length, rightAssociative.length);
        for (int i = 0; i < leftAssociative.length; i++) {
          expect(leftAssociative[i].id, rightAssociative[i].id);
        }
      },
    );

    test('3. 【冪等性の証明 (Idempotence)】 重複パケットが何回再送されても結果が1回適用時と不変であること', () {
      final baseEvents = List.generate(30, (i) => generateRandomEvent(i));
      final originalMerged = CrdtScoreConvergenceEngine.merge(baseEvents);
      final originalScore = CrdtScoreConvergenceEngine.computeFinalScore(
        originalMerged,
      );

      // 全イベントをランダムに2〜10回重複させたカオスストームリストを作成
      final bloatedList = <ScoreEvent>[];
      for (final event in baseEvents) {
        final repeatCount = rng.nextInt(9) + 2; // 2〜10回重複
        for (int r = 0; r < repeatCount; r++) {
          bloatedList.add(event);
        }
      }
      bloatedList.shuffle(rng);

      // 重複カオスリストをマージ
      final deduplicatedMerged = CrdtScoreConvergenceEngine.merge(bloatedList);
      final deduplicatedScore = CrdtScoreConvergenceEngine.computeFinalScore(
        deduplicatedMerged,
      );

      // 完全に単一適用時と等しいこと
      expect(deduplicatedMerged.length, originalMerged.length);
      expect(deduplicatedScore[Side.red], originalScore[Side.red]);
      expect(deduplicatedScore[Side.white], originalScore[Side.white]);
    });

    test('4. 【極限ファジング (Fuzzing)】 同一論理時計の衝突（タイブレーク）が決定論的辞書順で100%解決されること', () {
      // 全て同じ論理時計（clock: 10）を持つ競合イベントを複数端末から生成
      final conflictEvents = [
        generateRandomEvent(1, forceClock: 10),
        generateRandomEvent(2, forceClock: 10),
        generateRandomEvent(3, forceClock: 10),
      ];

      final run1 = CrdtScoreConvergenceEngine.merge(
        List.from(conflictEvents)..shuffle(rng),
      );
      final run2 = CrdtScoreConvergenceEngine.merge(
        List.from(conflictEvents)..shuffle(rng),
      );

      // 異なるシャッフル順序からマージしても、完全に同一の並び順で解決されること
      for (int i = 0; i < conflictEvents.length; i++) {
        expect(run1[i].id, run2[i].id);
      }
    });
  });
}
