/// 1-1: 試合の完全なライフサイクル状態
enum MatchLifecycleState {
  notStarted,
  waitingForPlayers,
  ready,
  inProgress,
  paused,
  encho,
  hanteiPending,
  completed,
  canceled,
  fusen,
}

/// 状態を変化させるトリガーとなるイベント
enum StateTransitionEvent {
  playersReady,
  startMatch,
  addScore,
  pause,
  resume,
  timeUp,
  startEncho,
  requestHantei,
  decideWinner,
  approve,
  undo,
}

/// 不正な状態遷移を弾くための専用例外
class InvalidStateException implements Exception {
  final String message;
  InvalidStateException(this.message);
  @override
  String toString() => 'InvalidStateException: $message';
}

/// 1-2 & 1-3: FSM (有限状態機械) 遷移テーブルとサービス
class MatchStateMachine {
  /// 現在の状態と発生したイベントから、次の正当な状態を返す
  /// 定義されていない遷移（不正な状態変更）は例外を投げる
  static MatchLifecycleState transition(MatchLifecycleState currentState, StateTransitionEvent event) {
    switch (currentState) {
      case MatchLifecycleState.notStarted:
        if (event == StateTransitionEvent.playersReady) return MatchLifecycleState.ready;
        if (event == StateTransitionEvent.startMatch) return MatchLifecycleState.inProgress;
        break;

      case MatchLifecycleState.waitingForPlayers:
        if (event == StateTransitionEvent.playersReady) return MatchLifecycleState.ready;
        break;

      case MatchLifecycleState.ready:
        if (event == StateTransitionEvent.startMatch) return MatchLifecycleState.inProgress;
        if (event == StateTransitionEvent.decideWinner) return MatchLifecycleState.fusen;
        break;

      case MatchLifecycleState.inProgress:
        if (event == StateTransitionEvent.addScore) return MatchLifecycleState.inProgress;
        if (event == StateTransitionEvent.timeUp) return MatchLifecycleState.completed;
        if (event == StateTransitionEvent.startEncho) return MatchLifecycleState.encho;
        if (event == StateTransitionEvent.decideWinner) return MatchLifecycleState.completed;
        if (event == StateTransitionEvent.pause) return MatchLifecycleState.paused;
        if (event == StateTransitionEvent.requestHantei) return MatchLifecycleState.hanteiPending;
        if (event == StateTransitionEvent.undo) return MatchLifecycleState.inProgress;
        break;

      case MatchLifecycleState.paused:
        if (event == StateTransitionEvent.resume) return MatchLifecycleState.inProgress;
        if (event == StateTransitionEvent.undo) return MatchLifecycleState.paused;
        break;

      case MatchLifecycleState.encho:
        if (event == StateTransitionEvent.addScore) return MatchLifecycleState.encho;
        if (event == StateTransitionEvent.decideWinner) return MatchLifecycleState.completed;
        if (event == StateTransitionEvent.timeUp) return MatchLifecycleState.completed;
        if (event == StateTransitionEvent.pause) return MatchLifecycleState.paused;
        if (event == StateTransitionEvent.requestHantei) return MatchLifecycleState.hanteiPending;
        if (event == StateTransitionEvent.undo) return MatchLifecycleState.encho;
        break;

      case MatchLifecycleState.hanteiPending:
        if (event == StateTransitionEvent.decideWinner) return MatchLifecycleState.completed;
        if (event == StateTransitionEvent.undo) return MatchLifecycleState.inProgress;
        break;

      case MatchLifecycleState.completed:
      case MatchLifecycleState.fusen:
        if (event == StateTransitionEvent.approve) return MatchLifecycleState.completed;
        if (event == StateTransitionEvent.undo) return MatchLifecycleState.inProgress; // 勝敗取り消しで進行中へ戻る
        break;

      case MatchLifecycleState.canceled:
        break;
    }

    // 遷移テーブルに定義されていない組み合わせは「不正」として弾く
    throw InvalidStateException(
      '不正な状態遷移です: 状態[$currentState]からイベント[$event]への遷移は許可されていません。'
    );
  }
}

/// ★ 移行用のブリッジ（DB等の古いStringデータを安全に新体系へつなぐ）
extension MatchLifecycleStateLegacyExt on MatchLifecycleState {
  String toLegacyString() {
    switch (this) {
      case MatchLifecycleState.notStarted:
      case MatchLifecycleState.waitingForPlayers:
      case MatchLifecycleState.ready:
        return 'waiting';
      case MatchLifecycleState.inProgress:
      case MatchLifecycleState.encho:
      case MatchLifecycleState.paused:
      case MatchLifecycleState.hanteiPending:
        return 'in_progress';
      case MatchLifecycleState.completed:
      case MatchLifecycleState.fusen:
      case MatchLifecycleState.canceled:
        return 'finished';
    }
  }

  static MatchLifecycleState fromLegacyString(String legacyStatus) {
    switch (legacyStatus) {
      case 'waiting': return MatchLifecycleState.ready;
      case 'in_progress': return MatchLifecycleState.inProgress;
      case 'finished': return MatchLifecycleState.completed;
      default: return MatchLifecycleState.ready;
    }
  }
}