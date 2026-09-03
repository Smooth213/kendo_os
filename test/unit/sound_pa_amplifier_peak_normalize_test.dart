import 'package:flutter_test/flutter_test.dart';

/// 🔊 体育館PAアンプ音圧ノーマライズ＆クリッピング防止エンジン
class AudioPeakNormalizer {
  /// 体育館音響向けに安全に音量を正規化（0.0 〜 1.0）
  static double normalizeVolume({
    required double rawGain,
    required bool isPaAmplifierMode,
    required bool isMuted,
  }) {
    if (isMuted) return 0.0;

    // PAアンプ接続時は、体育館音響機器の歪み（クリッピング）を防ぐため最大を0.88に制限
    final maxGain = isPaAmplifierMode ? 0.88 : 1.0;
    return rawGain.clamp(0.0, maxGain);
  }

  /// 複数音源（ブザー＋打突音）の同時再生時の合計ゲインリミッター
  static double limitMixedGain(List<double> gains) {
    if (gains.isEmpty) return 0.0;
    final total = gains.reduce((a, b) => a + b);
    if (total <= 1.0) return total;
    // 1.0を超える場合は圧縮（コンプレッサー処理）
    return 1.0;
  }
}

void main() {
  group('📱 【Phase 2-7/10】体育館PA音響出力音圧ノーマライズ＆クリッピング防止テスト', () {
    test('1. PAアンプ接続モード（isPaAmplifierMode: true）で音割れ防止リミット（0.88）が適用されること', () {
      final safeVolume = AudioPeakNormalizer.normalizeVolume(
        rawGain: 1.2, // 過大入力
        isPaAmplifierMode: true,
        isMuted: false,
      );
      expect(safeVolume, 0.88);
    });

    test('2. ミュート（マナーモード等）時の完全ゼロ（0.0）保証', () {
      final mutedVolume = AudioPeakNormalizer.normalizeVolume(
        rawGain: 0.9,
        isPaAmplifierMode: false,
        isMuted: true,
      );
      expect(mutedVolume, 0.0);
    });

    test('3. 同時発声（ブザー音0.8 + 打突コール0.5）時のミックスリミッターによる1.0超過防止', () {
      final mixed = AudioPeakNormalizer.limitMixedGain([0.8, 0.5]);
      expect(mixed, 1.0); // 1.3にならず1.0でクランプ
    });
  });
}
