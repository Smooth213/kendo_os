import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockFlutterTts extends Mock implements FlutterTts {}

class FakeSource extends Fake implements Source {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(PlayerMode.lowLatency);
    registerFallbackValue(FakeSource());
  });

  group('🔊 [Phase 8 Performance Governance] 音声再生ゼロ遅延化＆Pre-warmingテスト', () {
    late MockAudioPlayer mockAudioPlayer;
    late MockFlutterTts mockTts;
    late SoundService soundService;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();
      mockTts = MockFlutterTts();

      when(() => mockTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => mockTts.setSpeechRate(any())).thenAnswer((_) async => 1);
      when(() => mockTts.setVolume(any())).thenAnswer((_) async => 1);
      when(() => mockTts.speak(any())).thenAnswer((_) async => 1);
      when(() => mockTts.stop()).thenAnswer((_) async => 1);

      when(() => mockAudioPlayer.setPlayerMode(any())).thenAnswer((_) async {});
      when(() => mockAudioPlayer.setSource(any())).thenAnswer((_) async {});
      when(() => mockAudioPlayer.stop()).thenAnswer((_) async {});
      when(
        () => mockAudioPlayer.play(
          any(),
          volume: any(named: 'volume'),
          balance: any(named: 'balance'),
          ctx: any(named: 'ctx'),
          position: any(named: 'position'),
          mode: any(named: 'mode'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockAudioPlayer.dispose()).thenAnswer((_) async {});

      soundService = SoundService(tts: mockTts, audioPlayer: mockAudioPlayer);
    });

    tearDown(() {
      soundService.dispose();
    });

    test('1. SoundService.prewarm が正常に実行され事前暖機ステートが確立すること', () async {
      expect(soundService.isPrewarmed, isFalse);

      await soundService.prewarm();
      expect(soundService.isPrewarmed, isTrue);

      verify(
        () => mockAudioPlayer.setPlayerMode(PlayerMode.lowLatency),
      ).called(1);
      verify(() => mockAudioPlayer.setSource(any())).called(1);
    });

    test('2. 効果音の連続呼び出しが単一の共有プレイヤーを再利用して低遅延再生されること', () async {
      await soundService.prewarm();

      // 各効果音を連続呼び出し
      await soundService.playScoreSound(true);
      await soundService.playScoreSound(false);
      await soundService.playHansokuSound();
      await soundService.playUndoSound();
      await soundService.playFinishFanfare();

      // playが5回低遅延モードで呼び出されたことを検証
      verify(
        () => mockAudioPlayer.play(any(), mode: PlayerMode.lowLatency),
      ).called(5);
    });

    test('3. TTS音声読み上げが安全に呼び出されること', () async {
      await soundService.speak('赤、一本！');
      verify(() => mockTts.stop()).called(1);
      verify(() => mockTts.speak('赤、一本！')).called(1);
    });
  });
}
