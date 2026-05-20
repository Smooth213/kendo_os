import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/match_state.dart';

class MatchCorruptedState {
  final MatchModel match;

  MatchCorruptedState(this.match);

  /// 試合状態が破損しているか（未知のステータス等）を判定する
  bool get isCorrupted {
    final state = MatchLifecycleStateLegacyExt.fromLegacyString(match.status);
    return state == MatchLifecycleState.corrupted;
  }
}