import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart'; // ★ TTS追加
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';

final soundServiceProvider = Provider((ref) {
  final service = SoundService();
  service.configureAudio(ref.read(settingsProvider).ignoreMannerMode);
  return service;
});

class SoundService {
  final FlutterTts _tts = FlutterTts();

  SoundService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("ja-JP");
    await _tts.setSpeechRate(0.6); // 高齢者にも聞き取りやすい速度
    await _tts.setVolume(1.0);
  }

  Future<void> configureAudio(bool ignoreMannerMode) async {
    await AudioPlayer.global.setAudioContext(AudioContextConfig(
      respectSilence: !ignoreMannerMode, 
      stayAwake: true,       
    ).build());
  }

  // ★ 汎用的な読み上げメソッド
  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> playScoreSound(bool isRed) async {
    final player = AudioPlayer();
    await player.play(AssetSource(isRed ? 'sounds/red_score.mp3' : 'sounds/white_score.mp3'));
  }

  Future<void> playHansokuSound() async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/hansoku.mp3'));
  }

  Future<void> playUndoSound() async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/undo.mp3'));
  }

  Future<void> playFinishFanfare() async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/match_end.mp3'));
  }
}