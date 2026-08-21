import 'package:kendo_os/features/match/domain/match_model.dart';

/// 観客席画面用 進行中・待機中試合フィルタリングヘルパー
class ViewerMatchFilterHelper {
  /// 試合リストから重複排除した進行中試合と待機試合のペアを抽出
  static (List<MatchModel> inProgress, List<MatchModel> waiting)
  extractActiveMatches(List<MatchModel> allMatchesList) {
    final uniqueInProgress = <MatchModel>[];
    final uniqueWaiting = <MatchModel>[];
    final seenMatchups = <String>{};

    for (var match in allMatchesList) {
      if (match.status == 'finished' || match.status == 'approved') continue;

      String key;
      if (match.note.contains('[リーグ戦]')) {
        final t1 = match.redName.split(':').first.trim();
        final t2 = match.whiteName.split(':').first.trim();
        final sortedTeams = [t1, t2]..sort();
        key = 'league_${match.groupName}_${sortedTeams.join("_")}';
      } else if (match.isKachinuki) {
        key = 'kachinuki_${match.groupName}';
      } else if (match.groupName != null && match.groupName!.isNotEmpty) {
        key = 'group_${match.groupName}';
      } else {
        key = 'match_${match.id}';
      }

      if (!seenMatchups.contains(key)) {
        seenMatchups.add(key);
        if (match.status == 'in_progress') {
          uniqueInProgress.add(match);
        } else if (match.status == 'waiting') {
          uniqueWaiting.add(match);
        }
      }
    }

    return (uniqueInProgress, uniqueWaiting);
  }
}
