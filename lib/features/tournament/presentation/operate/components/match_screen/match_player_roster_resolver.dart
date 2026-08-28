import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';

/// 選手名編集ボトムシート用のロスター・選手分類データモデル
class ResolvedPlayerRoster {
  final List<PlayerModel> sameCatActive;
  final List<PlayerModel> quickAccessPlayers;
  final List<PlayerModel> dojoListSubstitutes;
  final List<PlayerModel> otherCategoryPlayers;
  final List<PlayerModel> substitutes;
  final Set<String> activePlayerNames;
  final Map<String, String> playerPositions;

  const ResolvedPlayerRoster({
    required this.sameCatActive,
    required this.quickAccessPlayers,
    required this.dojoListSubstitutes,
    required this.otherCategoryPlayers,
    required this.substitutes,
    required this.activePlayerNames,
    required this.playerPositions,
  });
}

/// 試合画面の選手名編集時における選手・補欠・登録選手解決ヘルパー
class MatchPlayerRosterResolver {
  static String getPlayerCategory(int grade) {
    if (grade == -1) return '初心者の部';
    if (grade == 0) return '幼年の部';
    if (grade >= 1 && grade <= 4) return '小学生低学年の部';
    if (grade >= 5 && grade <= 6) return '小学生高学年の部';
    if (grade >= 7 && grade <= 9) return '中学生の部';
    if (grade >= 10 && grade <= 12) return '高校生の部';
    return '一般の部';
  }

  static ResolvedPlayerRoster resolve({
    required String teamName,
    required MatchModel match,
    required List<MatchModel> currentGroupMatches,
    required List<PlayerModel> players,
    required List<TeamModel> registeredTeams,
  }) {
    final activePlayerNames = <String>{};
    final playerPositions = <String, String>{};

    for (final m in currentGroupMatches) {
      if (m.redName.contains(':')) {
        final parts = m.redName.split(':');
        if (parts.first.trim() == teamName) {
          final name = parts.last.trim();
          activePlayerNames.add(name);
          playerPositions[name] = m.matchType;
        }
      }
      if (m.whiteName.contains(':')) {
        final parts = m.whiteName.split(':');
        if (parts.first.trim() == teamName) {
          final name = parts.last.trim();
          activePlayerNames.add(name);
          playerPositions[name] = m.matchType;
        }
      }
    }

    final ownTeamPlayers = players.where((p) {
      final org = p.organization.trim();
      if (org.isEmpty) return false;
      return teamName.contains(org) || org.contains(teamName);
    }).toList();

    final matchedTeam = registeredTeams.firstWhere(
      (t) => t.teamName == teamName || teamName == t.teamName,
      orElse: () {
        return registeredTeams.firstWhere(
          (t) => teamName.contains(t.teamName) || t.teamName.contains(teamName),
          orElse: () => TeamModel(
            id: '',
            tournamentId: '',
            category: '',
            teamName: '',
            matchType: '',
            playerNames: [],
          ),
        );
      },
    );
    final teamRegisteredPlayerNames = matchedTeam.playerNames
        .where((name) => name.isNotEmpty)
        .toSet();

    final Set<String> ownPlayerNames = ownTeamPlayers
        .map((p) => p.name)
        .toSet();
    final List<PlayerModel> finalOwnTeamPlayers = List<PlayerModel>.from(
      ownTeamPlayers,
    );

    for (final name in teamRegisteredPlayerNames) {
      if (!ownPlayerNames.contains(name)) {
        final found = players.firstWhere(
          (p) => p.name == name,
          orElse: () => PlayerModel(
            id: 'virtual_$name',
            lastName: name,
            firstName: '',
            lastNameKana: '',
            firstNameKana: '',
            grade: 0,
            organization: teamName,
          ),
        );
        finalOwnTeamPlayers.add(found);
        ownPlayerNames.add(name);
      }
    }

    final matchCategory = match.category ?? '';

    final teamSubstitutes = matchedTeam.playerNames
        .where((name) => name.isNotEmpty && !activePlayerNames.contains(name))
        .toList();

    final teamSubstitutesPlayers = finalOwnTeamPlayers
        .where((p) => teamSubstitutes.contains(p.name))
        .toList();
    final substitutes = teamSubstitutesPlayers;

    final sameCatActive = finalOwnTeamPlayers
        .where((p) => activePlayerNames.contains(p.name))
        .toList();

    final sameCategorySubstitutes = finalOwnTeamPlayers
        .where((p) => !activePlayerNames.contains(p.name))
        .where((p) {
          if (matchCategory.isEmpty) return true;
          return getPlayerCategory(p.grade) == matchCategory;
        })
        .toList();

    final List<PlayerModel> quickAccessPlayers;
    if (teamSubstitutesPlayers.isNotEmpty) {
      quickAccessPlayers = teamSubstitutesPlayers;
    } else {
      quickAccessPlayers = sameCategorySubstitutes;
    }

    final dojoListSubstitutes = sameCategorySubstitutes
        .where((p) => !quickAccessPlayers.any((q) => q.name == p.name))
        .toList();

    final otherCategoryPlayers = players.where((p) {
      if (sameCatActive.any((a) => a.name == p.name)) return false;
      if (quickAccessPlayers.any((q) => q.name == p.name)) return false;
      if (dojoListSubstitutes.any((d) => d.name == p.name)) return false;
      return true;
    }).toList();

    return ResolvedPlayerRoster(
      sameCatActive: sameCatActive,
      quickAccessPlayers: quickAccessPlayers,
      dojoListSubstitutes: dojoListSubstitutes,
      otherCategoryPlayers: otherCategoryPlayers,
      substitutes: substitutes,
      activePlayerNames: activePlayerNames,
      playerPositions: playerPositions,
    );
  }
}
