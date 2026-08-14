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
  corrupted,
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
  static MatchLifecycleState transition(
    MatchLifecycleState currentState,
    StateTransitionEvent event,
  ) {
    switch (currentState) {
      case MatchLifecycleState.notStarted:
        if (event == StateTransitionEvent.playersReady) {
          return MatchLifecycleState.ready;
        }
        if (event == StateTransitionEvent.startMatch) {
          return MatchLifecycleState.inProgress;
        }
        throw InvalidStateException(
          'notStarted状態からはplayersReadyまたはstartMatchのみ許可されています。Event: $event',
        );

      case MatchLifecycleState.waitingForPlayers:
        if (event == StateTransitionEvent.playersReady) {
          return MatchLifecycleState.ready;
        }
        throw InvalidStateException(
          'waitingForPlayers状態からはplayersReadyのみ許可されています。Event: $event',
        );

      case MatchLifecycleState.ready:
        if (event == StateTransitionEvent.startMatch) {
          return MatchLifecycleState.inProgress;
        }
        throw InvalidStateException(
          'ready状態からはstartMatchのみ許可されています。Event: $event',
        );

      case MatchLifecycleState.inProgress:
        if (event == StateTransitionEvent.addScore) {
          return MatchLifecycleState.inProgress;
        }
        if (event == StateTransitionEvent.pause) {
          return MatchLifecycleState.paused;
        }
        if (event == StateTransitionEvent.timeUp) {
          return MatchLifecycleState.completed;
        }
        if (event == StateTransitionEvent.decideWinner) {
          return MatchLifecycleState.completed;
        }
        if (event == StateTransitionEvent.startEncho) {
          return MatchLifecycleState.encho;
        }
        throw InvalidStateException(
          'inProgress状態からはaddScore, pause, timeUp, decideWinner, startEnchoのみ許可されています。Event: $event',
        );

      case MatchLifecycleState.paused:
        if (event == StateTransitionEvent.resume) {
          return MatchLifecycleState.inProgress;
        }
        if (event == StateTransitionEvent.undo) {
          return MatchLifecycleState.inProgress;
        }
        throw InvalidStateException(
          'paused状態からはresumeまたはundoのみ許可されています。Event: $event',
        );

      case MatchLifecycleState.encho:
        if (event == StateTransitionEvent.addScore) {
          return MatchLifecycleState.encho;
        }
        if (event == StateTransitionEvent.pause) {
          return MatchLifecycleState.paused;
        }
        if (event == StateTransitionEvent.timeUp) {
          return MatchLifecycleState.completed;
        }
        if (event == StateTransitionEvent.decideWinner) {
          return MatchLifecycleState.completed;
        }
        throw InvalidStateException(
          'encho状態からはaddScore, pause, timeUp, decideWinnerのみ許可されています。Event: $event',
        );

      case MatchLifecycleState.hanteiPending:
        if (event == StateTransitionEvent.decideWinner) {
          return MatchLifecycleState.completed;
        }
        throw InvalidStateException(
          'hanteiPending状態からはdecideWinnerのみ許可されています。Event: $event',
        );

      case MatchLifecycleState.completed:
        if (event == StateTransitionEvent.approve) {
          return MatchLifecycleState.completed;
        }
        if (event == StateTransitionEvent.decideWinner) {
          return MatchLifecycleState.completed; // 既に完了している場合の二重決定イベントを安全に受容
        }
        if (event == StateTransitionEvent.undo) {
          return MatchLifecycleState.inProgress;
        }
        throw InvalidStateException(
          'completed状態からはapproveまたはundoのみ許可されています。Event: $event',
        );

      case MatchLifecycleState.canceled:
      case MatchLifecycleState.corrupted:
      case MatchLifecycleState.fusen:
        throw InvalidStateException('終了状態からの不正な状態遷移イベントは拒否されます。Event: $event');
    }
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
      case MatchLifecycleState.corrupted:
        return 'corrupted';
    }
  }

  static MatchLifecycleState fromLegacyString(String legacyStatus) {
    switch (legacyStatus) {
      case 'waiting':
      case 'scheduled':
      case 'ready':
      case 'not_started':
      case 'waiting_for_players':
        return MatchLifecycleState.ready;
      case 'in_progress':
      case 'paused':
      case 'encho':
      case 'hantei_pending':
        return MatchLifecycleState.inProgress;
      case 'finished':
      case 'approved':
      case 'completed':
        return MatchLifecycleState.completed;
      case 'fusen':
        return MatchLifecycleState.fusen;
      case 'canceled':
        return MatchLifecycleState.canceled;
      case 'corrupted':
        return MatchLifecycleState.corrupted;
      default:
        return MatchLifecycleState.corrupted; // silent fallback を禁止
    }
  }
}
