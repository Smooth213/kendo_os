import 'package:flutter_test/flutter_test.dart';

/// 📄 国際用紙規格スケーラー（A4 vs US Letter）
class PaperSizeScaler {
  // A4: 210mm x 297mm (アスペクト比 1:1.414)
  static const double a4WidthMm = 210.0;
  static const double a4HeightMm = 297.0;

  // US Letter: 215.9mm x 279.4mm (縦が約17.6mm短い！)
  static const double letterWidthMm = 215.9;
  static const double letterHeightMm = 279.4;

  /// A4用コンテンツ高さをUS Letter内に安全に収めるための縮小率
  static double calculateScaleFactor({required bool isUsLetter}) {
    if (!isUsLetter) return 1.0;
    // 縦方向の比率でスケールダウン
    final heightRatio = letterHeightMm / a4HeightMm; // 約 0.94
    return heightRatio;
  }
}

void main() {
  group('🌌 【Phase 9-2/6】北米 US Letter 用紙規格 下見切れ防止自動スケーリングテスト', () {
    test('1. A4縦向け帳票が US Letter 印刷時にスケール率 0.94 に自動縮小され、下部マージンが確保されること', () {
      final scaleFactor = PaperSizeScaler.calculateScaleFactor(
        isUsLetter: true,
      );

      expect(scaleFactor, lessThan(1.0));
      expect(scaleFactor, closeTo(0.94, 0.01));

      const originalTableHeightMm =
          280.0; // A4では収まるが、US Letter(279.4mm)でははみ出る高さ
      final scaledHeightMm = originalTableHeightMm * scaleFactor;

      // 縮小後の高さが US Letter の用紙高（279.4mm）および余白内に完全に収まること！
      expect(scaledHeightMm, lessThan(PaperSizeScaler.letterHeightMm));
      expect(scaledHeightMm, closeTo(263.3, 0.5));
    });
  });
}
