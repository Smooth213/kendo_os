import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/match_state.dart';

void main() {
  group('🛡️ Phase 1-5: MatchStateMachine Impossible State FSM Tests', () {
    
    test('✅ 正常な遷移: notStarted -> ready -> inProgress', () {
      final state1 = MatchStateMachine.transition(MatchLifecycleState.notStarted, StateTransitionEvent.playersReady);
      expect(state1, MatchLifecycleState.ready, reason: '選手入場によりreadyへ遷移すること');

      final state2 = MatchStateMachine.transition(state1, StateTransitionEvent.startMatch);
      expect(state2, MatchLifecycleState.inProgress, reason: '試合開始によりinProgressへ遷移すること');
    });

    test('✅ 正常な遷移: completed -> undo -> inProgress (誤審の取り消し)', () {
      final state = MatchStateMachine.transition(MatchLifecycleState.completed, StateTransitionEvent.undo);
      expect(state, MatchLifecycleState.inProgress, reason: '試合終了後でもUndoにより進行中へ戻ること');
    });

    test('❌ 異常な遷移(Impossible State): completed からの startMatch は弾かれること', () {
      expect(
        () => MatchStateMachine.transition(MatchLifecycleState.completed, StateTransitionEvent.startMatch),
        throwsA(isA<InvalidStateException>()),
        reason: '終了した試合を再度startMatchすることは不可能であり、例外が発生すること',
      );
    });

    test('❌ 異常な遷移(Impossible State): notStarted からの timeUp は弾かれること', () {
      expect(
        () => MatchStateMachine.transition(MatchLifecycleState.notStarted, StateTransitionEvent.timeUp),
        throwsA(isA<InvalidStateException>()),
        reason: '開始していない試合が時間切れになることは論理的に不可能であり、例外が発生すること',
      );
    });

    test('❌ 異常な遷移(Impossible State): ready からの pause は弾かれること', () {
      expect(
        () => MatchStateMachine.transition(MatchLifecycleState.ready, StateTransitionEvent.pause),
        throwsA(isA<InvalidStateException>()),
        reason: '進行していない試合を停止(pause)することは不可能であり、例外が発生すること',
      );
    });
  });
}