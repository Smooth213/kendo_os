import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/tournament_own_info_provider.dart';

/// タイムライン画面用 カテゴリ・チーム振り分け解決ロジックヘルパー
class TimelineCategoryTeamResolver {
  /// カテゴリ内の試合リストから、チーム毎の試合グループ（MapEntryのリスト）を生成
  static List<MapEntry<String, List<MatchModel>>> resolveMatchesByTeam({
    required List<MatchModel> catMatches,
    required List<String> ownTeams,
    TournamentOwnInfo? ownInfo,
  }) {
    final matchesByTeam = <String, List<MatchModel>>{};
    final groupToOwnTeams = <String, Set<String>>{};
    final groupToRepresentativeTeam = <String, String>{};

    String extractTeam(String rawName) {
      if (rawName.contains(':')) {
        return rawName.split(':').first.trim();
      }
      final resolved = ownInfo?.resolveTeamForPlayer(rawName.trim());
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
      return rawName.trim();
    }

    String extractPlayer(String rawName) {
      if (rawName.contains(':')) {
        return rawName.split(':').last.trim();
      }
      return rawName.trim();
    }

    for (var m in catMatches) {
      if (m.groupName != null && m.groupName!.isNotEmpty) {
        String rTeam = extractTeam(m.redName);
        String wTeam = extractTeam(m.whiteName);
        String rPlayer = extractPlayer(m.redName);
        String wPlayer = extractPlayer(m.whiteName);

        final isRedOwnForM =
            (ownInfo?.isOwnSide(
                  teamPart: rTeam,
                  namePart: rPlayer,
                  ruleTeamName: m.rule?.teamName,
                ) ??
                false) ||
            ownTeams.contains(rTeam) ||
            (m.rule?.teamName.isNotEmpty == true && rTeam == m.rule!.teamName);
        final isWhiteOwnForM =
            (ownInfo?.isOwnSide(
                  teamPart: wTeam,
                  namePart: wPlayer,
                  ruleTeamName: m.rule?.teamName,
                ) ??
                false) ||
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
      String rTeam = extractTeam(m.redName);
      String wTeam = extractTeam(m.whiteName);
      String rPlayer = extractPlayer(m.redName);
      String wPlayer = extractPlayer(m.whiteName);

      bool isRedOwn =
          (ownInfo?.isOwnSide(
                teamPart: rTeam,
                namePart: rPlayer,
                ruleTeamName: m.rule?.teamName,
              ) ??
              false) ||
          ownTeams.contains(rTeam) ||
          (m.rule?.teamName.isNotEmpty == true && rTeam == m.rule!.teamName);
      bool isWhiteOwn =
          (ownInfo?.isOwnSide(
                teamPart: wTeam,
                namePart: wPlayer,
                ruleTeamName: m.rule?.teamName,
              ) ??
              false) ||
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
