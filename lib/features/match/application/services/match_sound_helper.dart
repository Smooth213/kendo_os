import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';

/// 試合操作時の音声・効果音フィードバックヘルパー
class MatchSoundHelper {
  static void playAddIpponSound({
    required SoundService soundService,
    required String audioFeedbackMode,
    required Side side,
    required PointType type,
    required String typeLabel,
    required bool isMatchFinishedNow,
  }) {
    final sideLabel = side == Side.red ? '赤' : '白';
    if (audioFeedbackMode == 'voice') {
      soundService.speak('$sideLabel、$typeLabel！');
      if (isMatchFinishedNow) {
        Future.delayed(
          const Duration(milliseconds: 1000),
          () => soundService.speak('試合終了です'),
        );
      }
    } else if (audioFeedbackMode == 'effect') {
      if (type == PointType.hansoku) {
        soundService.playHansokuSound();
      } else {
        soundService.playScoreSound(side == Side.red);
      }
      if (isMatchFinishedNow) {
        soundService.playFinishFanfare();
      }
    }
  }

  static void playUndoSound({
    required SoundService soundService,
    required String audioFeedbackMode,
  }) {
    if (audioFeedbackMode == 'voice') {
      soundService.speak('取り消し');
    } else if (audioFeedbackMode == 'effect') {
      soundService.playUndoSound();
    }
  }

  static void playTimeUpSound({
    required SoundService soundService,
    required String audioFeedbackMode,
    required bool isMatchFinished,
  }) {
    if (isMatchFinished) {
      if (audioFeedbackMode == 'voice') {
        soundService.speak('時間切れ、試合終了です');
      } else if (audioFeedbackMode == 'effect') {
        soundService.playFinishFanfare();
      }
    }
  }
}
