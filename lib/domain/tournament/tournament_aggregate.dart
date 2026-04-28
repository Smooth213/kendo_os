import '../../models/match_model.dart';

// ==========================================
// ★ Phase 6: TournamentAggregate導入
// 大会全体（複数の試合の束）とフォーマットを管理する上位クラス
// ==========================================

/// 大会形式（フォーマット）の定義
enum TournamentFormat {
  league,     // リーグ戦（総当たり）
  knockout,   // トーナメント戦（勝ち上がり）
  kachinuki,  // 勝ち抜き戦
}

class TournamentAggregate {
  final String id;
  final List<MatchModel> matches;
  final TournamentFormat format;

  TournamentAggregate({
    required this.id,
    required this.matches,
    required this.format,
  });

  /// 指定したIDの試合を取得する
  MatchModel? getMatch(String matchId) {
    try {
      return matches.firstWhere((m) => m.id == matchId);
    } catch (_) {
      return null;
    }
  }

  /// 現在の大会形式において、全試合が終了しているかを判定する
  bool get isAllMatchesFinished {
    if (matches.isEmpty) return false;
    return matches.every((m) => m.status == 'finished' || m.status == 'approved');
  }
}