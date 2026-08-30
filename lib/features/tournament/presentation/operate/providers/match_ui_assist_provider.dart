import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

/// 🔄 試合画面の赤白左右反転（視点ミラーリング / 逆サイド観客席モード）Provider
///
/// true の場合、画面上の配置が「左：白、右：赤」にスワップされます。
/// ※ Firestore / Isar のドメインデータには一切影響を与えない純粋UIプロジェクションです。
final isMatchViewFlippedProvider = StateProvider.family<bool, String>((
  ref,
  matchId,
) {
  return false;
});

/// ↺ 直近イベントのスマートUndo待機状態
class PendingSmartUndoState {
  final ScoreEvent event;
  final DateTime createdAt;
  final int totalDurationSeconds;

  const PendingSmartUndoState({
    required this.event,
    required this.createdAt,
    this.totalDurationSeconds = 5,
  });
}

/// ↺ スマートUndoコントローラー
class PendingSmartUndoNotifier extends StateNotifier<PendingSmartUndoState?> {
  Timer? _timer;

  PendingSmartUndoNotifier() : super(null);

  /// 新しいスコア・反則イベントをUndo待機状態にセット（5秒後に自動消滅）
  void registerEvent(ScoreEvent event) {
    _timer?.cancel();
    state = PendingSmartUndoState(event: event, createdAt: DateTime.now());

    _timer = Timer(const Duration(seconds: 5), () {
      state = null;
    });
  }

  /// Undo実行またはユーザーによる明示的なdismiss
  void clear() {
    _timer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pendingSmartUndoProvider =
    StateNotifierProvider.family<
      PendingSmartUndoNotifier,
      PendingSmartUndoState?,
      String
    >((ref, matchId) {
      return PendingSmartUndoNotifier();
    });
