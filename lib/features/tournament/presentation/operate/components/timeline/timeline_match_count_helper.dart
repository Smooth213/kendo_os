import 'package:kendo_os/features/match/domain/match_model.dart';

/// 🥋 タイムライン用 試合数カウントヘルパー
/// 団体戦は1試合（同じ groupName）を 1、個人戦は 1 試合を 1 とカウントします。
class TimelineMatchCountHelper {
  TimelineMatchCountHelper._();

  /// 試合リストから団体戦1試合・個人戦1試合として試合数を計算
  static int countMatches(List<MatchModel> matches) {
    final teamGroupIds = <String>{};
    int individualCount = 0;
    int orphanTeamCount = 0;

    for (final m in matches) {
      if (isIndividualMatch(m)) {
        individualCount++;
      } else {
        final gId = m.groupName;
        if (gId != null && gId.isNotEmpty) {
          teamGroupIds.add(gId);
        } else {
          orphanTeamCount++;
        }
      }
    }

    return individualCount + teamGroupIds.length + orphanTeamCount;
  }

  /// 個人戦判定ロジック
  static bool isIndividualMatch(MatchModel m) {
    if (m.isKachinuki) return false;
    final type = m.matchType;
    return type == 'individual' || type == '選手' || type.contains('個人');
  }
}
