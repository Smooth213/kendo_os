import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ★ Step 7-2: 現場の「音」を司るサービス
// 低遅延での再生を目的とし、赤と白で音色を明確に分けます
final soundServiceProvider = Provider((ref) => SoundService());

class SoundService {
  // 実際の開発では assets に sound_red.mp3, sound_white.mp3 等を用意します
  // ここではシステム音を代用したロジックを示します
  
  Future<void> playScoreSound(bool isRed) async {
    if (isRed) {
      // 赤：高く鋭い音（注意喚起）
      await SystemSound.play(SystemSoundType.click); 
    } else {
      // 白：落ち着いた音
      await SystemSound.play(SystemSoundType.click); 
    }
  }

  Future<void> playFinishFanfare() async {
    // 試合終了：特別な連続音
    await SystemSound.play(SystemSoundType.click);
    await Future.delayed(const Duration(milliseconds: 100));
    await SystemSound.play(SystemSoundType.click);
  }
}