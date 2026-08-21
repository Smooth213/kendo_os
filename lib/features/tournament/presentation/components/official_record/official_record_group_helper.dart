import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';

/// 公式記録画面のカテゴリ・グループ別試合分類・登録名解決ヘルパー
class OfficialRecordGroupHelper {
  /// 試合リストからカテゴリ別のグループマップを生成
  static Map<String, Map<String, List<MatchModel>>> groupMatchesByCategory(
    List<MatchModel> matches,
  ) {
    final categoryGroups = <String, Map<String, List<MatchModel>>>{};
    for (var m in matches) {
      if (m.groupName == null || m.groupName!.isEmpty) continue;
      final cat = (m.category != null && m.category!.isNotEmpty)
          ? m.category!
          : '一般';
      categoryGroups.putIfAbsent(cat, () => {});
      categoryGroups[cat]!.putIfAbsent(m.groupName!, () => []).add(m);
    }
    return categoryGroups;
  }

  /// 個人戦IDグループを統合したグループマップを生成
  static Map<String, List<MatchModel>> mergeIndividualGroups(
    Map<String, List<MatchModel>> groupsMap,
  ) {
    final mergedGroups = <String, List<MatchModel>>{};
    final individualMergedList = <MatchModel>[];
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    groupsMap.forEach((key, matches) {
      final isIndiv = matches.any(
        (m) =>
            m.matchType == 'individual' ||
            m.matchType == '選手' ||
            m.matchType.contains('個人戦'),
      );
      final isLeague = matches.any((m) => m.note.contains('[リーグ戦]'));

      if (isIndiv &&
          !isLeague &&
          (uuidRegex.hasMatch(key) || key.length > 20)) {
        individualMergedList.addAll(matches);
      } else {
        mergedGroups[key] = matches;
      }
    });

    if (individualMergedList.isNotEmpty) {
      individualMergedList.sort((a, b) => a.order.compareTo(b.order));
      mergedGroups['__merged_individual__'] = individualMergedList;
    }

    return mergedGroups;
  }

  /// カテゴリに対応する登録チーム名・選手名セットを解決
  static (Set<String> teamNames, Set<String> playerNames)
  resolveRegisteredNames({
    required String category,
    required List<MatchModel> categoryMatches,
    required List<TeamModel> registeredTeams,
    required Set<String> allRegisteredTeamNames,
    required Set<String> allRegisteredPlayerNames,
  }) {
    final categoryRegisteredTeams = registeredTeams
        .where((t) => t.category == category)
        .toList();

    final Set<String> teamNames;
    if (categoryRegisteredTeams.isNotEmpty) {
      teamNames = categoryRegisteredTeams
          .map((t) => t.teamName.trim())
          .where((n) => n.isNotEmpty)
          .toSet();
    } else if (allRegisteredTeamNames.isNotEmpty) {
      teamNames = allRegisteredTeamNames.where((tName) {
        return categoryMatches.any((m) {
          final r = m.redName.contains(':')
              ? m.redName.split(':').first.trim()
              : m.redName.trim();
          final w = m.whiteName.contains(':')
              ? m.whiteName.split(':').first.trim()
              : m.whiteName.trim();
          return r == tName || w == tName;
        });
      }).toSet();
    } else {
      teamNames = <String>{};
    }

    final Set<String> playerNames;
    if (categoryRegisteredTeams.isNotEmpty) {
      playerNames = categoryRegisteredTeams
          .expand((t) => t.playerNames)
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toSet();
    } else if (allRegisteredPlayerNames.isNotEmpty) {
      playerNames = allRegisteredPlayerNames;
    } else {
      playerNames = <String>{};
    }

    return (teamNames, playerNames);
  }
}
