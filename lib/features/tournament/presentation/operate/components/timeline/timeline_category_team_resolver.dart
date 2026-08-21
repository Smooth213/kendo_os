import 'package:kendo_os/features/match/domain/match_model.dart';

/// タイムライン画面用 カテゴリ・チーム振り分け解決ロジックヘルパー
class TimelineCategoryTeamResolver {
  /// カテゴリ内の試合リストから、チーム毎の試合グループ（MapEntryのリスト）を生成
  static List<MapEntry<String, List<MatchModel>>> resolveMatchesByTeam({
    required List<MatchModel> catMatches,
    required List<String> ownTeams,
  }) {
    final matchesByTeam = <String, List<MatchModel>>{};
    final groupToOwnTeams = <String, Set<String>>{};
    final groupToRepresentativeTeam = <String, String>{};

    for (var m in catMatches) {
      if (m.groupName != null && m.groupName!.isNotEmpty) {
        String rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : m.redName;
        String wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : m.whiteName;
        final isRedOwnForM =
            ownTeams.contains(rTeam) ||
            (m.rule?.teamName.isNotEmpty == true && rTeam == m.rule!.teamName);
        final isWhiteOwnForM =
            ownTeams.contains(wTeam) ||
            (m.rule?.teamName.isNotEmpty == true && wTeam == m.rule!.teamName);
        if (isRedOwnForM) {
          groupToOwnTeams.putIfAbsent(m.groupName!, () => {}).add(rTeam);
        }
        if (isWhiteOwnForM) {
          groupToOwnTeams.putIfAbsent(m.groupName!, () => {}).add(wTeam);
        }

        // グループの代表チームを決定し、同じリーグが引き裂かれるのを防ぐ
        if (!groupToRepresentativeTeam.containsKey(m.groupName!)) {
          groupToRepresentativeTeam[m.groupName!] =
              rTeam.isNotEmpty && !rTeam.contains('代表')
              ? rTeam
              : (wTeam.isNotEmpty && !wTeam.contains('代表') ? wTeam : '設定なし');
        }
      }
    }

    for (var m in catMatches) {
      String rTeam = m.redName.contains(':')
          ? m.redName.split(':').first.trim()
          : m.redName;
      String wTeam = m.whiteName.contains(':')
          ? m.whiteName.split(':').first.trim()
          : m.whiteName;

      bool isRedOwn =
          ownTeams.contains(rTeam) ||
          (m.rule?.teamName.isNotEmpty == true && rTeam == m.rule!.teamName);
      bool isWhiteOwn =
          ownTeams.contains(wTeam) ||
          (m.rule?.teamName.isNotEmpty == true && wTeam == m.rule!.teamName);

      if (m.groupName != null && m.groupName!.isNotEmpty) {
        if (groupToOwnTeams.containsKey(m.groupName!)) {
          for (String team in groupToOwnTeams[m.groupName!]!) {
            matchesByTeam.putIfAbsent(team, () => []).add(m);
          }
        } else {
          // 自チームが含まれないグループは、代表チームをキーにして全試合を一極集中させる
          final repTeam = groupToRepresentativeTeam[m.groupName!] ?? '設定なし';
          matchesByTeam.putIfAbsent(repTeam, () => []).add(m);
        }
      } else {
        if (isRedOwn) matchesByTeam.putIfAbsent(rTeam, () => []).add(m);
        if (isWhiteOwn && wTeam != rTeam) {
          matchesByTeam.putIfAbsent(wTeam, () => []).add(m);
        }
        if (!isRedOwn && !isWhiteOwn) {
          final keyTeam = rTeam.isNotEmpty && !rTeam.contains('代表')
              ? rTeam
              : (wTeam.isNotEmpty && !wTeam.contains('代表') ? wTeam : '設定なし');
          matchesByTeam.putIfAbsent(keyTeam, () => []).add(m);
        }
      }
    }

    final sortedTeams = matchesByTeam.entries.toList();
    sortedTeams.sort((a, b) => a.key.compareTo(b.key));
    return sortedTeams;
  }
}
