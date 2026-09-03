import 'package:flutter_test/flutter_test.dart';

/// 🔊 シニア審判員向け周波数イコライザープロファイル
class SeniorAudioEqualizer {
  /// 年齢層に応じた推奨周波数帯（Hz）の判定
  static ({
    int targetCenterFrequencyHz,
    double gainMultiplier,
    double speechRate,
  })
  getAudioProfile({required bool isSeniorMode}) {
    if (isSeniorMode) {
      // 加齢性難聴では4kHz以上が聴取困難になるため、1.5kHz（子音の明瞭度帯域）を強調
      // 発話速度も 0.6（ゆっくり）に設定
      return (
        targetCenterFrequencyHz: 1500,
        gainMultiplier: 1.25,
        speechRate: 0.6,
      );
    }

    return (
      targetCenterFrequencyHz: 3000,
      gainMultiplier: 1.0,
      speechRate: 1.0,
    );
  }
}

void main() {
  group('👁️ 【Phase 6-2/12】シニア審判員向け1.5kHz中音域強調＆低速読み上げプロファイルテスト', () {
    test('1. シニアモード有効時、中心周波数が1,500Hzに設定され、発話速度が聞き取りやすい0.6になること', () {
      final profile = SeniorAudioEqualizer.getAudioProfile(isSeniorMode: true);

      expect(profile.targetCenterFrequencyHz, 1500);
      expect(profile.gainMultiplier, 1.25);
      expect(profile.speechRate, 0.6);
    });

    test('2. 通常モード時は標準プロファイル（3,000Hz、速度1.0）が適用されること', () {
      final profile = SeniorAudioEqualizer.getAudioProfile(isSeniorMode: false);

      expect(profile.targetCenterFrequencyHz, 3000);
      expect(profile.gainMultiplier, 1.0);
      expect(profile.speechRate, 1.0);
    });
  });
}
