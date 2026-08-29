import 'package:kendo_os/features/match/domain/match_model.dart';

typedef ClassifiedTimelineMatches = ({
  List<MapEntry<String, List<MatchModel>>> sortedGroups,
  List<MapEntry<String, List<MatchModel>>> sortedPlayers,
});

/// チーム内の試合を「団体/リーグ戦グループ」と「個人戦/選手別」に分類するヘルパー
class TimelinePlayerMatchClassifier {
  static ClassifiedTimelineMatches classifyTeamMatches({
    required List<MatchModel> teamMatchesList,
    required String teamName,
    required String sanitizedQuery,
    required Set<String> matchedMatchIds,
    required Set<String> matchedGroupNames,
    required List<String> ownTeams,
  }) {
    final catGroupedMatches = <String, List<MatchModel>>{};
    final catIndividualMatches = <MatchModel>[];

    for (var m in teamMatchesList) {
      bool forceIndividual =
          sanitizedQuery.isNotEmpty &&
          matchedMatchIds.contains(m.id) &&
          (m.groupName == null || !matchedGroupNames.contains(m.groupName!));
      if (!forceIndividual && m.groupName != null && m.groupName!.isNotEmpty) {
        catGroupedMatches.putIfAbsent(m.groupName!, () => []).add(m);
      } else {
        catIndividualMatches.add(m);
      }
    }

    final actualGroupedMatches = <String, List<MatchModel>>{};
    for (var entry in catGroupedMatches.entries) {
      final firstMatch = entry.value.first;
      final bool isLeagueMatch = firstMatch.note.contains('[リーグ戦]');
      final bool isPureIndividual =
          !firstMatch.isKachinuki &&
          (firstMatch.matchType == 'individual' ||
              firstMatch.matchType == '選手' ||
              firstMatch.matchType.contains('個人戦'));

      if (!isPureIndividual &&
          (entry.value.length > 1 || firstMatch.isKachinuki)) {
        actualGroupedMatches[entry.key] = entry.value;
      } else if (isLeagueMatch) {
        actualGroupedMatches[entry.key] = entry.value;
      } else {
        catIndividualMatches.addAll(entry.value);
      }
    }

    final matchesByPlayer = <String, List<MatchModel>>{};
    for (var m in catIndividualMatches) {
      String playerName = '選手名不明';
      bool forceIndividual =
          sanitizedQuery.isNotEmpty &&
          matchedMatchIds.contains(m.id) &&
          (m.groupName == null || !matchedGroupNames.contains(m.groupName!));
      if (forceIndividual) {
        String rPlayer = m.redName.contains(':')
            ? m.redName.split(':').last.trim()
            : m.redName;
        String wPlayer = m.whiteName.contains(':')
            ? m.whiteName.split(':').last.trim()
            : m.whiteName;
        if (rPlayer
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase()
            .contains(sanitizedQuery)) {
          playerName = rPlayer;
        } else if (wPlayer
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase()
            .contains(sanitizedQuery)) {
          playerName = wPlayer;
        } else {
          playerName = m.redName.contains(teamName) ? rPlayer : wPlayer;
        }
      } else {
        if (m.redName.contains(teamName) ||
            ownTeams.any((ot) => m.redName.contains(ot)) ||
            (m.rule?.teamName.isNotEmpty == true &&
                m.redName.contains(m.rule!.teamName))) {
          playerName = m.redName.contains(':')
              ? m.redName.split(':').last.trim()
              : m.redName;
        } else if (m.whiteName.contains(teamName) ||
            ownTeams.any((ot) => m.whiteName.contains(ot)) ||
            (m.rule?.teamName.isNotEmpty == true &&
                m.whiteName.contains(m.rule!.teamName))) {
          playerName = m.whiteName.contains(':')
              ? m.whiteName.split(':').last.trim()
              : m.whiteName;
        } else {
          playerName = m.redName.contains(':')
              ? m.redName.split(':').last.trim()
              : m.redName;
        }
      }
      matchesByPlayer.putIfAbsent(playerName, () => []).add(m);
    }

    // ★ あとから追加した試合（対戦枠・おかわりの対戦）が最上位に来るよう降順ソート
    final sortedGroups = actualGroupedMatches.entries.toList()
      ..sort((a, b) => b.value.first.order.compareTo(a.value.first.order));
    final sortedPlayers = matchesByPlayer.entries.toList()
      ..sort((a, b) {
        final bMax = b.value.fold<double>(
          0.0,
          (prev, m) => m.order > prev ? m.order : prev,
        );
        final aMax = a.value.fold<double>(
          0.0,
          (prev, m) => m.order > prev ? m.order : prev,
        );
        final cmp = bMax.compareTo(aMax);
        return cmp != 0 ? cmp : a.key.compareTo(b.key);
      });

    return (sortedGroups: sortedGroups, sortedPlayers: sortedPlayers);
  }
}
