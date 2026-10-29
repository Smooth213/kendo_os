import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/application/services/match_sound_helper.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';

class MockSoundService extends Mock implements SoundService {}

void main() {
  group('[Unit] Unit 1/5において TTS音声合成・アナウンスコール境界値テスト', () {
    late MockSoundService mockSoundService;

    setUp(() {
      mockSoundService = MockSoundService();
      when(() => mockSoundService.speak(any())).thenAnswer((_) async {});
      when(
        () => mockSoundService.playScoreSound(any()),
      ).thenAnswer((_) async {});
      when(() => mockSoundService.playHansokuSound()).thenAnswer((_) async {});
      when(() => mockSoundService.playUndoSound()).thenAnswer((_) async {});
      when(() => mockSoundService.playFinishFanfare()).thenAnswer((_) async {});
    });

    test('赤面・白小手・反則のTTS音声読み上げ文字列生成が正確こと', () {
      // 赤・面
      MatchSoundHelper.playAddIpponSound(
        soundService: mockSoundService,
        audioFeedbackMode: 'voice',
        side: Side.red,
        type: PointType.men,
        typeLabel: 'メ',
        isMatchFinishedNow: false,
      );
      verify(() => mockSoundService.speak('赤、メ！')).called(1);

      // 白・コテ
      MatchSoundHelper.playAddIpponSound(
        soundService: mockSoundService,
        audioFeedbackMode: 'voice',
        side: Side.white,
        type: PointType.kote,
        typeLabel: 'コ',
        isMatchFinishedNow: false,
      );
      verify(() => mockSoundService.speak('白、コ！')).called(1);
    });

    test('取り消し（Undo）および時間切れコールが正確こと', () {
      MatchSoundHelper.playUndoSound(
        soundService: mockSoundService,
        audioFeedbackMode: 'voice',
      );
      verify(() => mockSoundService.speak('取り消し')).called(1);

      MatchSoundHelper.playTimeUpSound(
        soundService: mockSoundService,
        audioFeedbackMode: 'voice',
        isMatchFinished: true,
      );
      verify(() => mockSoundService.speak('時間切れ、試合終了です')).called(1);
    });

    test('effectモード（効果音）および無音（silent）時の分岐安全性こと', () {
      // 効果音モード
      MatchSoundHelper.playAddIpponSound(
        soundService: mockSoundService,
        audioFeedbackMode: 'effect',
        side: Side.red,
        type: PointType.men,
        typeLabel: 'メ',
        isMatchFinishedNow: false,
      );
      verify(() => mockSoundService.playScoreSound(true)).called(1);
      verifyNever(() => mockSoundService.speak(any()));

      // 無音モード（voiceでもeffectでもない場合）
      MatchSoundHelper.playAddIpponSound(
        soundService: mockSoundService,
        audioFeedbackMode: 'none',
        side: Side.white,
        type: PointType.doIdo,
        typeLabel: 'ド',
        isMatchFinishedNow: false,
      );
      verifyNever(() => mockSoundService.speak(any()));
    });
  });
}
