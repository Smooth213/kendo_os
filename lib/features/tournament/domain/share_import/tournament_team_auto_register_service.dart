import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/tournament/domain/share_import/player_roster_matcher.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_name_history_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';

/// 🥋 取り込みデータからチーム＆オーダーモデルへの変換・自動登録サービス
class TournamentTeamAutoRegisterService {
  /// 選択可能な試合形式の候補定数リスト
  static const List<String> candidateMatchTypes = [
    '団体戦（5人制）',
    '団体戦（3人制）',
    '団体戦（7人制）',
    '勝ち抜き戦',
    'リーグ団体戦',
    'リーグ個人戦',
    '個人戦',
    '団体戦（それ以上）',
  ];

  /// チームの指定形式、メンバー構成やチーム名から試合形式を自動判定
  static String determineMatchType(ParsedTeamOrder team) {
    // 1. 指定済みの形式があれば最優先
    if (team.matchType.trim().isNotEmpty) {
      return team.matchType.trim();
    }

    final teamName = team.teamName;
    final positions = team.members.map((m) => m.position).toSet();
    final count = team.members.length;

    // 2. 勝ち抜き戦の判定（チーム名やカテゴリに含まれる場合）
    if (teamName.contains('勝ち抜き') || team.category.contains('勝ち抜き')) {
      return '勝ち抜き戦';
    }

    // 3. リーグ戦の判定
    if (teamName.contains('リーグ') || team.category.contains('リーグ')) {
      if (count == 1 ||
          positions.contains('個人戦') ||
          positions.contains('選手') ||
          positions.contains('個人')) {
        return 'リーグ個人戦';
      }
      return 'リーグ団体戦';
    }

    // 4. 個人戦の明示判定（チーム名やカテゴリに含まれる場合）
    if (teamName.contains('個人戦') ||
        team.category.contains('個人戦') ||
        teamName.contains('個人') ||
        team.category.contains('個人')) {
      return '個人戦';
    }

    // 5. ポジションに個人戦特有の表記がある場合
    if (positions.contains('個人戦') ||
        positions.contains('選手') ||
        positions.contains('個人')) {
      return '個人戦';
    }

    // 6. 7人制の判定
    if (positions.contains('五将') || positions.contains('三将') || count >= 7) {
      return '団体戦（7人制）';
    }

    // 7. 5人制の判定（次鋒または副将を含む、または5名以上）
    if (positions.contains('次鋒') || positions.contains('副将') || count >= 4) {
      return '団体戦（5人制）';
    }

    // 8. 1名のみの場合（個人戦と判定）
    if (count == 1) {
      return '個人戦';
    }

    // 9. 3名以下、または先鋒・中堅・大将構成
    if (count <= 3) {
      return '団体戦（3人制）';
    }

    return '団体戦（5人制）';
  }

  /// チーム名やメンバーの学年情報から大会カテゴリ（部門）を自動判定
  static String determineCategory(
    String teamName, {
    List<ParsedTeamMember>? members,
    List<PlayerModel>? roster,
  }) {
    final clean = teamName.trim();
    if (clean.contains('低学年')) {
      return '小学生低学年の部';
    }
    if (clean.contains('高学年')) {
      return '小学生高学年の部';
    }
    if (clean.contains('小学生') || clean.contains('少年')) {
      return '小学生の部';
    }
    if (clean.contains('中学生') || clean.contains('中学')) {
      return '中学生の部';
    }
    if (clean.contains('高校生') || clean.contains('高校')) {
      return '高校生の部';
    }
    if (clean.contains('一般') || clean.contains('成年') || clean.contains('大学')) {
      return '一般の部';
    }

    // 名簿（roster）の選手学年からインテリジェントに判定
    if (members != null && roster != null && roster.isNotEmpty) {
      final matchedPlayers = <PlayerModel>[];
      for (final m in members) {
        final res = PlayerRosterMatcher.matchPlayer(
          rawName: m.name,
          roster: roster,
        );
        if (res.matchedPlayer != null) {
          matchedPlayers.add(res.matchedPlayer!);
        }
      }

      if (matchedPlayers.isNotEmpty) {
        final grades = matchedPlayers.map((p) => p.grade).toList();
        final isAllElementary = grades.every((g) => g >= 1 && g <= 6);
        if (isAllElementary) {
          final isLow = grades.every((g) => g <= 3);
          if (isLow) return '小学生低学年の部';
          final isHigh = grades.every((g) => g >= 4);
          if (isHigh) return '小学生高学年の部';
          return '小学生の部';
        }
        final isAllJunior = grades.every((g) => g >= 7 && g <= 9);
        if (isAllJunior) return '中学生の部';
        final isAllHighSchool = grades.every((g) => g >= 10 && g <= 12);
        if (isAllHighSchool) return '高校生の部';
      }
    }

    // チーム名そのものをカテゴリに流用せず、安全なデフォルト部門へフォールバック
    return '一般の部';
  }

  /// 選択可能な大会カテゴリ（部門）の候補定数リスト
  static const List<String> candidateCategories = [
    '小学生低学年の部',
    '小学生高学年の部',
    '小学生の部',
    '中学生の部',
    '高校生の部',
    '一般の部',
  ];

  /// チームのカテゴリまたはチーム名から公式な部門名を決定論的に解決
  static String resolveCategory(
    ParsedTeamOrder team, {
    List<PlayerModel>? roster,
  }) {
    final cat = team.category.trim();
    if (cat.isNotEmpty) {
      if (candidateCategories.contains(cat)) return cat;
      final resolved = determineCategory(
        cat,
        members: team.members,
        roster: roster,
      );
      if (candidateCategories.contains(resolved)) return resolved;
    }
    return determineCategory(
      team.teamName,
      members: team.members,
      roster: roster,
    );
  }

  /// 取り込みチーム一覧から、大会に登録すべきカテゴリ一覧（重複なし・整列）を抽出
  static List<String> extractCategories(
    List<ParsedTeamOrder> teams, {
    List<PlayerModel>? roster,
  }) {
    final categories = <String>{};
    for (final team in teams) {
      final cat = resolveCategory(team, roster: roster);
      categories.add(cat);
    }
    return categories.toList();
  }

  /// 試合形式に応じた基準スロット定義を取得
  static List<String> getBaseSlots(String matchType) {
    if (matchType.contains('3人制')) {
      return ['先鋒', '中堅', '大将'];
    }
    if (matchType.contains('7人制')) {
      return ['先鋒', '次鋒', '五将', '中堅', '三将', '副将', '大将'];
    }
    if (matchType.contains('個人戦')) {
      return ['選手'];
    }
    return ['先鋒', '次鋒', '中堅', '副将', '大将'];
  }

  /// チームメンバーを基準スロット順に整列し、名簿照合済みの選手名リストを生成
  static List<String> buildPlayerNames({
    required ParsedTeamOrder team,
    required String matchType,
    required List<PlayerModel> roster,
  }) {
    final baseSlots = getBaseSlots(matchType);
    final slotCount = baseSlots.length;
    final assignedSlots = List<String>.filled(slotCount, '');
    final unassignedOrSubs = <String>[];

    // 各メンバーを名簿と照合
    final matchedMembers = PlayerRosterMatcher.matchTeamMembers(
      members: team.members,
      teamCategory: team.category.isNotEmpty ? team.category : team.teamName,
      roster: roster,
    );

    // ポジションごとに割り当て
    final usedMemberIndices = <int>{};

    for (int slotIdx = 0; slotIdx < baseSlots.length; slotIdx++) {
      final slotPos = baseSlots[slotIdx];
      final memberIdx = matchedMembers.indexWhere(
        (m) =>
            !usedMemberIndices.contains(matchedMembers.indexOf(m)) &&
            m.position == slotPos,
      );

      if (memberIdx != -1) {
        assignedSlots[slotIdx] = matchedMembers[memberIdx].displayName;
        usedMemberIndices.add(memberIdx);
      }
    }

    // スロットに割り当てられなかったメンバー（補欠や順不同のメンバー）
    for (int i = 0; i < matchedMembers.length; i++) {
      if (!usedMemberIndices.contains(i)) {
        unassignedOrSubs.add(matchedMembers[i].displayName);
      }
    }

    // スロットの空きを、未割り当てメンバー（補欠以外）で前方から埋める（ポジション指定が曖昧な場合）
    int unassignedPointer = 0;
    for (int slotIdx = 0; slotIdx < baseSlots.length; slotIdx++) {
      if (assignedSlots[slotIdx].isEmpty &&
          unassignedPointer < unassignedOrSubs.length) {
        // 補欠表記ではないものを優先してスロットに埋める
        final candidate = unassignedOrSubs[unassignedPointer];
        final memberObj = matchedMembers.firstWhere(
          (m) => m.displayName == candidate,
          orElse: () => matchedMembers[0],
        );
        if (!memberObj.position.contains('補')) {
          assignedSlots[slotIdx] = candidate;
          unassignedOrSubs.removeAt(unassignedPointer);
          continue;
        }
        unassignedPointer++;
      }
    }

    // 基準スロット + 残りの補欠選手リスト
    return [...assignedSlots, ...unassignedOrSubs];
  }

  /// 個人戦チームに複数選手が含まれている場合、各選手を独立した個人戦エントリーに展開・正規化
  static List<ParsedTeamOrder> normalizeIndividualTeams(
    List<ParsedTeamOrder> teams, {
    List<PlayerModel>? roster,
  }) {
    final result = <ParsedTeamOrder>[];
    for (final team in teams) {
      final matchType = determineMatchType(team);
      if ((matchType == '個人戦' || matchType == 'リーグ個人戦') &&
          team.members.length > 1) {
        final cat = resolveCategory(team, roster: roster);
        for (final m in team.members) {
          final entryName = team.teamName.contains('個人')
              ? m.name
              : '${team.teamName} ${m.name}';
          result.add(
            ParsedTeamOrder(
              teamName: entryName,
              category: cat,
              matchType: matchType,
              members: [ParsedTeamMember(position: '選手', name: m.name)],
            ),
          );
        }
      } else {
        result.add(team);
      }
    }
    return result;
  }

  /// ParsedTeamOrder のリストから Firestore 登録用の TeamModel リストを生成
  static List<TeamModel> buildTeamModels({
    required List<ParsedTeamOrder> teams,
    required String tournamentId,
    required List<PlayerModel> roster,
  }) {
    final normalizedTeams = normalizeIndividualTeams(teams, roster: roster);
    return normalizedTeams.map((team) {
      final matchType = determineMatchType(team);
      final category = resolveCategory(team, roster: roster);
      final playerNames = buildPlayerNames(
        team: team.copyWith(category: category, matchType: matchType),
        matchType: matchType,
        roster: roster,
      );

      return TeamModel(
        id: '',
        tournamentId: tournamentId,
        category: category,
        teamName: team.teamName,
        matchType: matchType,
        playerNames: playerNames,
      );
    }).toList();
  }

  /// 生成された全チームを Firestore に一括登録
  static Future<int> registerTeams({
    required List<ParsedTeamOrder> teams,
    required String tournamentId,
    required List<PlayerModel> roster,
    required TeamRepository teamRepository,
    TeamNameHistoryNotifier? teamNameHistoryNotifier,
  }) async {
    final teamModels = buildTeamModels(
      teams: teams,
      tournamentId: tournamentId,
      roster: roster,
    );

    int count = 0;
    for (final team in teamModels) {
      try {
        await teamRepository.saveTeam(team);
        teamNameHistoryNotifier?.addHistory(team.teamName);
        count++;
      } catch (e) {
        debugPrint('🔥 [ERROR] チーム一括自動登録エラー (${team.teamName}): $e');
      }
    }

    return count;
  }
}
