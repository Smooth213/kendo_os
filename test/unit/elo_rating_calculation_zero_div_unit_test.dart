import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

/// 🥋 剣道選手強さレーティング（Kendo Elo Rating）計算エンジン
class KendoEloRatingCalculator {
  static const double defaultKFactor = 32.0;

  /// 勝率期待値（Expected Score）の計算
  static double calculateExpectedScore(double ratingA, double ratingB) {
    // 指数オーバーフロー/アンダーフローを防ぐため、レーティング差を [-800, 800] にクランプ
    final diff = (ratingB - ratingA).clamp(-800.0, 800.0);
    final exponent = diff / 400.0;
    return 1.0 / (1.0 + math.pow(10.0, exponent));
  }

  /// 試合結果反映後の新レーティング計算
  /// actualScore: 1.0 (勝ち), 0.5 (引き分け), 0.0 (負け)
  static ({double newRatingA, double newRatingB}) calculateNewRatings({
    required double ratingA,
    required double ratingB,
    required double actualScoreA, // 1.0, 0.5, 0.0
    double kFactor = defaultKFactor,
  }) {
    final expectedA = calculateExpectedScore(ratingA, ratingB);
    final expectedB = 1.0 - expectedA;
    final actualScoreB = 1.0 - actualScoreA;

    final newA = ratingA + kFactor * (actualScoreA - expectedA);
    final newB = ratingB + kFactor * (actualScoreB - expectedB);

    // レーティング下限を 100.0 に安全保証（ゼロ除算・負数防止）
    return (
      newRatingA: newA.clamp(100.0, 5000.0),
      newRatingB: newB.clamp(100.0, 5000.0),
    );
  }
}

void main() {
  group('🥋 【Phase 1-10/10】選手強さレーティング（Elo）ゼロ除算・極限差・決定論的丸めテスト', () {
    test('1. 同等レーティング同士（1500 vs 1500）の勝ち負け・引き分けでの対称性', () {
      final winResult = KendoEloRatingCalculator.calculateNewRatings(
        ratingA: 1500.0,
        ratingB: 1500.0,
        actualScoreA: 1.0, // Aの勝ち
      );
      // K=32の場合、勝者は+16、敗者は-16
      expect(winResult.newRatingA, 1516.0);
      expect(winResult.newRatingB, 1484.0);

      final drawResult = KendoEloRatingCalculator.calculateNewRatings(
        ratingA: 1500.0,
        ratingB: 1500.0,
        actualScoreA: 0.5, // 引き分け
      );
      // 引き分けなら変動なし
      expect(drawResult.newRatingA, 1500.0);
      expect(drawResult.newRatingB, 1500.0);
    });

    test('2. 極端なレーティング差（4000 vs 100）での指数オーバーフロー・NaN・無限大ゼロ保証', () {
      final extremeResult = KendoEloRatingCalculator.calculateNewRatings(
        ratingA: 4000.0,
        ratingB: 100.0,
        actualScoreA: 1.0,
      );

      // NaN や Infinite にならず有限値であること
      expect(extremeResult.newRatingA.isFinite, isTrue);
      expect(extremeResult.newRatingB.isFinite, isTrue);
      expect(extremeResult.newRatingA.isNaN, isFalse);
      expect(extremeResult.newRatingB.isNaN, isFalse);
      expect(extremeResult.newRatingB, greaterThanOrEqualTo(100.0)); // 下限保証
    });

    test('3. 下限クランプ（100.0）による負のレーティング・ゼロ除算の完全防止', () {
      final loseResult = KendoEloRatingCalculator.calculateNewRatings(
        ratingA: 100.0,
        ratingB: 3000.0,
        actualScoreA: 0.0, // 最低レーティング者がさらに負けた場合
      );

      expect(loseResult.newRatingA, 100.0); // 100未満に沈まない
    });
  });
}
