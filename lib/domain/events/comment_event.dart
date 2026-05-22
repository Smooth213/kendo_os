/// ★ Phase 2-1: 1ファイル完全統合 兼 Event Immutable化
/// タイムライン上のコメントイベントを定義する、完全 Immutable（ const 緊縛）なドメインイベントモデル
enum CommentEventType {
  added,
  updated,
  deleted,
}

class CommentEvent {
  final String id;
  final String commentId;
  final CommentEventType type;
  final String? tournamentId;
  final String? category;
  final String? groupName;
  final String? matchGroupId;
  final String text;
  final double order;
  final DateTime timestamp;
  final String userId;
  final int logicalClock;

  const CommentEvent({
    required this.id,
    required this.commentId,
    required this.type,
    this.tournamentId,
    this.category,
    this.groupName,
    this.matchGroupId,
    this.text = '',
    this.order = 0.0,
    required this.timestamp,
    required this.userId,
    required this.logicalClock,
  });

  /// 決定論的なイベントソート順序固定（1. 論理時計 -> 2. 絶対時刻 -> 3. 識別子）
  int compareTo(CommentEvent other) {
    int clockCmp = logicalClock.compareTo(other.logicalClock);
    if (clockCmp != 0) return clockCmp;
    
    int timeCmp = timestamp.compareTo(other.timestamp);
    if (timeCmp != 0) return timeCmp;
    
    return id.compareTo(other.id);
  }
}
