import 'dart:collection';

/// 遠征先や体育館での完全オフライン時に発生した打突イベント・スコア更新タスクを、
/// 順序（FIFO）を100%崩すことなくインメモリに保持し、復帰時の重複・逆転を防止するセーフティキュー。
class PendingSyncQueue<T> {
  final Queue<PendingTask<T>> _queue = Queue<PendingTask<T>>();
  final Set<String> _taskIds = <String>{};

  /// キューに未同期タスクを格納する（同一taskIdの重複追加を防止）
  bool enqueue(String taskId, T data) {
    if (_taskIds.contains(taskId)) {
      return false; // すでに未同期キューに存在するため重複排除
    }
    _taskIds.add(taskId);
    _queue.add(
      PendingTask<T>(taskId: taskId, data: data, timestamp: DateTime.now()),
    );
    return true;
  }

  /// 最古の未同期タスクを1件取得する（キューからは削除しない）
  PendingTask<T>? get peek => _queue.isNotEmpty ? _queue.first : null;

  /// 指定されたtaskIdが未同期キューに存在するか判定
  bool contains(String taskId) => _taskIds.contains(taskId);

  /// 同期が成功した最古のタスクをキューから安全にパージする
  void dequeue() {
    if (_queue.isNotEmpty) {
      final removed = _queue.removeFirst();
      _taskIds.remove(removed.taskId);
    }
  }

  /// 現在スタックされている未同期の件数
  int get pendingCount => _queue.length;

  /// キューが空（すべて同期完了状態）か否か
  bool get isEmpty => _queue.isEmpty;

  /// 障害発生時にキューを完全リセットして原状復帰するためのクリア処理
  void clear() {
    _queue.clear();
    _taskIds.clear();
  }
}

/// キュー内部でタスクのメタ情報を不変カプセル化するエンティティ
class PendingTask<T> {
  final String taskId;
  final T data;
  final DateTime timestamp;

  const PendingTask({
    required this.taskId,
    required this.data,
    required this.timestamp,
  });
}
