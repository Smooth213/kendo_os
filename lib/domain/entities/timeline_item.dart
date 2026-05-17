// 試合（Match）とコメント（Comment）を、UI層で「同じタイムライン上の要素」として
// 扱うための共有インターフェース。

enum TimelineItemType {
  match,
  comment,
}

abstract class TimelineItem {
  /// タイムライン上のユニークID (Matchの場合はMatchId、Commentの場合はCommentId)
  String get timelineId;

  /// 所属する大会ID
  String? get tournamentId;

  /// タイムラインでの並び順 (Lexical Ordering用の浮動小数点)
  double get timelineOrder;

  /// 要素の型 (Match か Comment かを描き分けるため)
  TimelineItemType get itemType;
}