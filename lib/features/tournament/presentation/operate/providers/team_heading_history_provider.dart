import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🥋 チームごとの前回設定された試合場番号・試合順データ
class TeamHeadingHistory {
  final int? courtNumber;
  final int? lastMatchOrder;

  const TeamHeadingHistory({this.courtNumber, this.lastMatchOrder});

  int? get nextMatchOrder =>
      lastMatchOrder != null ? lastMatchOrder! + 1 : null;

  TeamHeadingHistory copyWith({int? courtNumber, int? lastMatchOrder}) {
    return TeamHeadingHistory(
      courtNumber: courtNumber ?? this.courtNumber,
      lastMatchOrder: lastMatchOrder ?? this.lastMatchOrder,
    );
  }
}

/// 🥋 チーム別の試合場・試合順履歴管理Notifier
class TeamHeadingHistoryNotifier
    extends StateNotifier<Map<String, TeamHeadingHistory>> {
  TeamHeadingHistoryNotifier() : super(const {});

  static const String defaultKey = '__global_default__';

  /// 対象チームの前回履歴を取得（未設定時はグローバルデフォルト）
  TeamHeadingHistory? getHistory(String? teamId) {
    if (teamId != null && state.containsKey(teamId)) {
      return state[teamId];
    }
    return state[defaultKey];
  }

  /// 試合作成時の会場番号・試合順を記録
  void recordHeading({String? teamId, int? courtNumber, int? matchOrder}) {
    final updated = Map<String, TeamHeadingHistory>.from(state);
    final history = TeamHeadingHistory(
      courtNumber: courtNumber,
      lastMatchOrder: matchOrder,
    );

    if (teamId != null && teamId.isNotEmpty) {
      updated[teamId] = history;
    }
    // グローバルデフォルトとしても最新を保持
    updated[defaultKey] = history;

    state = updated;
  }

  /// 全履歴のリセット（テスト・リフレッシュ用）
  void clear() {
    state = const {};
  }
}

/// 🥋 チーム別の試合場・試合順履歴プロバイダ
final teamHeadingHistoryProvider =
    StateNotifierProvider<
      TeamHeadingHistoryNotifier,
      Map<String, TeamHeadingHistory>
    >((ref) {
      return TeamHeadingHistoryNotifier();
    });
