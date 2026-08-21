import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';

/// 錬成会画面の選手候補（登録チーム・道場生・既存対戦）解決ヘルパー
class RenseikaiPlayerCandidateResolver {
  static bool isCategoryMatch(String teamCat, String matchCat) {
    final tCat = teamCat.trim();
    final mCat = matchCat.trim();
    if (mCat.isEmpty || tCat.isEmpty) return true;
    if (tCat == mCat || mCat.contains(tCat) || tCat.contains(mCat)) {
      return true;
    }
    final keywords = ['低学年', '高学年', '小学生', '中学生', '高校生', '一般'];
    for (final kw in keywords) {
      if (mCat.contains(kw) && tCat.contains(kw)) return true;
      if (mCat.contains(kw) && !tCat.contains(kw)) return false;
    }
    return true;
  }

  static bool isDojoPlayerGradeMatch(int grade, String matchCat) {
    if (matchCat.isEmpty) return true;
    if ((matchCat.contains('低学年') ||
            matchCat.contains('1・2年') ||
            matchCat.contains('3・4年')) &&
        (grade >= 1 && grade <= 4)) {
      return true;
    }
    if ((matchCat.contains('高学年') || matchCat.contains('5・6年')) &&
        (grade >= 5 && grade <= 6)) {
      return true;
    }
    if ((matchCat.contains('小学生') ||
            matchCat.contains('学童') ||
            matchCat.contains('児童')) &&
        (grade >= 1 && grade <= 6)) {
      return true;
    }
    if ((matchCat.contains('中学生') || matchCat.contains('中学')) &&
        (grade >= 7 && grade <= 9)) {
      return true;
    }
    if ((matchCat.contains('高校生') || matchCat.contains('高校')) &&
        (grade >= 10 && grade <= 12)) {
      return true;
    }
    if ((matchCat.contains('一般') ||
            matchCat.contains('成人') ||
            matchCat.contains('社会人') ||
            matchCat.contains('大学')) &&
        (grade >= 13 || grade == 0)) {
      return true;
    }

    final hasKnownSchoolLevel =
        matchCat.contains('低学年') ||
        matchCat.contains('高学年') ||
        matchCat.contains('小学生') ||
        matchCat.contains('中学生') ||
        matchCat.contains('高校生') ||
        matchCat.contains('一般');
    return !hasKnownSchoolLevel;
  }

  static List<String> extractBasePlayers(
    List<MatchModel> matches,
    String teamName,
  ) {
    final List<String> result = [];
    for (final m in matches) {
      if (m.redName.contains(':')) {
        final parts = m.redName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == teamName &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          result.add(pName);
        }
      }
      if (m.whiteName.contains(':')) {
        final parts = m.whiteName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == teamName &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          result.add(pName);
        }
      }
    }
    return result;
  }

  static List<String> resolveTeamPlayers({
    required String teamName,
    required String matchCat,
    required List<TeamModel> registeredTeams,
    required List<PlayerModel> localPlayers,
    required List<String> basePlayers,
  }) {
    final matchingTeams = registeredTeams.where((t) {
      return t.teamName.trim() == teamName.trim() ||
          teamName.trim().contains(t.teamName.trim()) ||
          t.teamName.trim().contains(teamName.trim());
    }).toList();

    TeamModel? teamData;
    for (final t in matchingTeams) {
      if (isCategoryMatch(t.category, matchCat)) {
        teamData = t;
        break;
      }
    }
    teamData ??= matchingTeams.isNotEmpty ? matchingTeams.first : null;

    final List<String> masterPlayers =
        teamData?.playerNames
            .map((n) => n.trim())
            .where(
              (n) => n.isNotEmpty && !n.contains('未定') && !n.contains('欠員'),
            )
            .toList() ??
        [];

    final List<String> dojoPlayers = localPlayers
        .where((p) {
          final org = p.organization.trim();
          if (org.isEmpty) return false;
          final orgMatch =
              org == teamName.trim() ||
              teamName.trim().contains(org) ||
              org.contains(teamName.trim());
          if (!orgMatch) return false;
          return isDojoPlayerGradeMatch(p.grade, matchCat);
        })
        .map((p) => p.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    return masterPlayers.isNotEmpty
        ? {...masterPlayers, ...basePlayers}.toList()
        : {...dojoPlayers, ...basePlayers}.toList();
  }
}
