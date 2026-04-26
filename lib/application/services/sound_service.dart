import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/provider/settings_provider.dart';

// ★ Phase 4: 本格的な遅延ゼロ・オーディオエンジン（強制出力対応版）
final soundServiceProvider = Provider((ref) {
  final service = SoundService();
  // 初期化時に、現在の「マナーモード突破設定」を読み込んでエンジンに適用する
  service.configureAudio(ref.read(settingsProvider).ignoreMannerMode);
  return service;
});

class SoundService {
  // 外部（SettingsNotifier）からマナーモード設定の変更を受け取るメソッド
  Future<void> configureAudio(bool ignoreMannerMode) async {
    // respectSilence: !ignoreMannerMode とすることで、
    // 「無視する(true)」なら「沈黙を尊重しない(false)」になります
    await AudioPlayer.global.setAudioContext(AudioContextConfig(
      respectSilence: !ignoreMannerMode, 
      stayAwake: true,       
    ).build());
  }

  Future<void> playScoreSound(bool isRed) async {
    final player = AudioPlayer();
    await player.setVolume(1.0); // 最大音量
    await player.play(AssetSource(isRed ? 'sounds/red_score.mp3' : 'sounds/white_score.mp3'));
  }

  Future<void> playHansokuSound() async {
    final player = AudioPlayer();
    await player.setVolume(1.0);
    await player.play(AssetSource('sounds/hansoku.mp3'));
  }

  Future<void> playUndoSound() async {
    final player = AudioPlayer();
    await player.setVolume(1.0);
    await player.play(AssetSource('sounds/undo.mp3'));
  }

  Future<void> playFinishFanfare() async {
    final player = AudioPlayer();
    await player.setVolume(1.0);
    await player.play(AssetSource('sounds/match_end.mp3'));
  }
}