import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import 'match_list_provider.dart';
import 'match_command_provider.dart';

// ★ Step 3-3: 1秒ごとの「生の残り秒数」を配信するプロバイダ
// 画面全体ではなく、このプロバイダを watch している小さな Widget だけがリビルドされる
final liveRemainingSecondsProvider = StateProvider.family<int, String>((ref, matchId) {
  // Firestoreの値を初期値としてセット
  final initialSeconds = ref.watch(matchListProvider.select((list) => 
    list.where((m) => m.id == matchId).firstOrNull?.remainingSeconds ?? 0
  ));
  return initialSeconds;
});

final renseikaiMasterTimerProvider = StateProvider.family<int, String>((ref, groupName) => -1);
final isMasterTimerRunningProvider = StateProvider.family<bool, String>((ref, groupName) => false);

final matchTimerProvider = Provider<MatchTimer>((ref) {
  return MatchTimer(ref);
});

class MatchTimer {
  final Ref ref;
  Timer? _ticker;
  MatchTimer(this.ref);

  MatchCommand get _command => ref.read(matchCommandProvider);

  // ★ Step 3-3: ローカルでタイマーを回し、liveRemainingSecondsProvider を更新する
  void startLocalTicker(String matchId) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final match = _getMatch(matchId);
      if (match == null || !match.timerIsRunning) {
        timer.cancel();
        return;
      }

      final currentLive = ref.read(liveRemainingSecondsProvider(matchId));
      
      if (match.matchType == '代表戦') {
        // 代表戦はカウントアップ
        ref.read(liveRemainingSecondsProvider(matchId).notifier).state = currentLive + 1;
      } else if (currentLive > 0) {
        // 通常はカウントダウン
        final nextValue = currentLive - 1;
        ref.read(liveRemainingSecondsProvider(matchId).notifier).state = nextValue;
        
        // 0秒になったらFirestoreへ同期（試合終了判定をトリガーするため）
        if (nextValue == 0) {
          updateRemainingSeconds(matchId, 0);
          timer.cancel();
        }
      }
    });
  }

  // タイマーのスタート・ストップ
  Future<void> toggleTimer(String matchId) async {
    final match = _getMatch(matchId);
    if (match == null) return;

    if (!match.timerIsRunning && match.remainingSeconds <= 0 && match.matchType != '代表戦') return;

    final newIsRunning = !match.timerIsRunning;
    await _command.saveMatch(match.copyWith(
      timerIsRunning: newIsRunning,
      status: match.status == 'waiting' ? 'in_progress' : match.status,
    ));

    // ローカルティッカーの開始/停止
    if (newIsRunning) {
      startLocalTicker(matchId);
    } else {
      _ticker?.cancel();
      // 停止時に現在の秒数をFirestoreへ同期
      final currentLive = ref.read(liveRemainingSecondsProvider(matchId));
      updateRemainingSeconds(matchId, currentLive);
    }
  }

  // 残り秒数の同期（Firestore書き込み）
  Future<void> updateRemainingSeconds(String matchId, int seconds) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    
    // UI側の値も同期
    ref.read(liveRemainingSecondsProvider(matchId).notifier).state = seconds;
    
    await _command.saveMatch(match.copyWith(remainingSeconds: seconds < 0 ? 0 : seconds));
  }

  MatchModel? _getMatch(String id) {
    return ref.read(matchListProvider).where((m) => m.id == id).firstOrNull;
  }
}