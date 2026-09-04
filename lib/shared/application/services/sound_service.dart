import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

final soundServiceProvider = Provider((ref) {
  final service = SoundService();
  service.configureAudio(ref.read(settingsProvider).ignoreMannerMode);
  return service;
});

/// 🔊 【Phase 8】音声再生ゼロ遅延化サービス（Audio Pre-warming & 低遅延モード）
class SoundService {
  final FlutterTts _tts;
  final AudioPlayer? _customPlayer;
  AudioPlayer? _lazyPlayer;

  AudioPlayer get _audioPlayer =>
      _customPlayer ?? (_lazyPlayer ??= AudioPlayer());

  // 事前定義アセットソース（アセットパース負荷をゼロ化）
  static final Source _redScoreSource = AssetSource('sounds/red_score.mp3');
  static final Source _whiteScoreSource = AssetSource('sounds/white_score.mp3');
  static final Source _hansokuSource = AssetSource('sounds/hansoku.mp3');
  static final Source _undoSource = AssetSource('sounds/undo.mp3');
  static final Source _finishSource = AssetSource('sounds/match_end.mp3');

  bool _isPrewarmed = false;
  bool get isPrewarmed => _isPrewarmed;

  SoundService({FlutterTts? tts, AudioPlayer? audioPlayer})
    : _tts = tts ?? FlutterTts(),
      _customPlayer = audioPlayer {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("ja-JP");
      await _tts.setSpeechRate(0.6); // 高齢審判員にも聞き取りやすい速度
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint('⚠️ [SoundService] TTS初期化スキップ (モック/Web環境): $e');
    }
  }

  /// 🔊 【Phase 8】オーディオPre-warming（事前暖機）
  /// 起動時に低遅延モードと初期ソースを設定し、初回タップ時の再生遅延（100〜300ms）を0ms化
  Future<void> prewarm() async {
    if (_isPrewarmed) return;
    try {
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _audioPlayer.setSource(_redScoreSource);
      _isPrewarmed = true;
      debugPrint('🔊 [SoundService] オーディオプリウォーミング完了（低遅延モード確立）');
    } catch (e) {
      debugPrint('⚠️ [SoundService] プリウォーミングスキップ: $e');
    }
  }

  Future<void> configureAudio(bool ignoreMannerMode) async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          respectSilence: !ignoreMannerMode,
          stayAwake: true,
        ).build(),
      );
    } catch (e) {
      debugPrint('⚠️ [SoundService] オーディオコンテキスト設定スキップ: $e');
    }
  }

  // 汎用読み上げ
  Future<void> speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('⚠️ [SoundService] 音声読み上げスキップ: $e');
    }
  }

  /// 低遅延共有プレイヤーでアセットを即時再生
  Future<void> _playAsset(Source source) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(source, mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('⚠️ [SoundService] 効果音再生スキップ: $e');
    }
  }

  Future<void> playScoreSound(bool isRed) async {
    await _playAsset(isRed ? _redScoreSource : _whiteScoreSource);
  }

  Future<void> playHansokuSound() async {
    await _playAsset(_hansokuSource);
  }

  Future<void> playUndoSound() async {
    await _playAsset(_undoSource);
  }

  Future<void> playFinishFanfare() async {
    await _playAsset(_finishSource);
  }

  /// リソース解放
  void dispose() {
    _lazyPlayer?.dispose();
  }
}
