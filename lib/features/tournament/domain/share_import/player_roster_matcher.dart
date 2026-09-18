import 'package:flutter/foundation.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

/// 照合結果
@immutable
class RosterMatchResult {
  final String rawName;
  final String resolvedName;
  final PlayerModel? matchedPlayer;
  final bool isMatched;

  const RosterMatchResult({
    required this.rawName,
    required this.resolvedName,
    this.matchedPlayer,
    required this.isMatched,
  });

  /// 表示用の学年情報（例: '小学3年'）
  String? get gradeDisplay => matchedPlayer?.gradeName;

  /// バッジ表示用文字列（例: '皿田 脩人 (小学3年)' または '選手名 (名簿未登録)'）
  String get badgeText {
    if (!isMatched || matchedPlayer == null) {
      return '$resolvedName (名簿未登録)';
    }
    final g = matchedPlayer!.gradeName;
    return '$resolvedName ($g)';
  }
}

/// 照合結果付きのチームメンバー
@immutable
class MatchedTeamMember {
  final String position;
  final String rawName;
  final RosterMatchResult matchResult;

  const MatchedTeamMember({
    required this.position,
    required this.rawName,
    required this.matchResult,
  });

  String get displayName => matchResult.resolvedName;
  bool get isMatched => matchResult.isMatched;
  String? get gradeInfo => matchResult.gradeDisplay;
  PlayerModel? get matchedPlayer => matchResult.matchedPlayer;
}

/// 🥋 名簿スマート照合エンジン
class PlayerRosterMatcher {
  /// 文字列から空白文字（全角・半角・タブ等）をすべて除去
  static String normalize(String str) {
    return str.replaceAll(RegExp(r'[\s\u3000\t\r\n]+'), '');
  }

  /// 単一選手名を名簿リストとスマート照合
  static RosterMatchResult matchPlayer({
    required String rawName,
    String? teamCategory,
    required List<PlayerModel> roster,
  }) {
    final cleanRaw = rawName.trim();
    if (cleanRaw.isEmpty) {
      return const RosterMatchResult(
        rawName: '',
        resolvedName: '',
        matchedPlayer: null,
        isMatched: false,
      );
    }

    final normalizedRaw = normalize(cleanRaw);

    // 1. 完全一致 (スペース揺れを吸収してフルネームで一致)
    for (final player in roster) {
      final normPlayerName = normalize(player.name);
      final normLastFirst = normalize('${player.lastName}${player.firstName}');
      if (normalizedRaw == normPlayerName || normalizedRaw == normLastFirst) {
        return RosterMatchResult(
          rawName: cleanRaw,
          resolvedName: player.name,
          matchedPlayer: player,
          isMatched: true,
        );
      }
    }

    // 2. 苗字のみの一致（または名前部分が省略されている場合）
    final lastNameMatches = roster.where((player) {
      final normLast = normalize(player.lastName);
      return normLast.isNotEmpty && normLast == normalizedRaw;
    }).toList();

    if (lastNameMatches.isNotEmpty) {
      if (lastNameMatches.length == 1) {
        final matched = lastNameMatches.first;
        return RosterMatchResult(
          rawName: cleanRaw,
          resolvedName: matched.name,
          matchedPlayer: matched,
          isMatched: true,
        );
      }

      // 複数人が同じ苗字の場合: teamCategory（学年やカテゴリ）から推定
      final candidate = _disambiguateByCategory(lastNameMatches, teamCategory);
      if (candidate != null) {
        return RosterMatchResult(
          rawName: cleanRaw,
          resolvedName: candidate.name,
          matchedPlayer: candidate,
          isMatched: true,
        );
      }

      // カテゴリ判定できなくても、最初の選手を推定採用
      final fallback = lastNameMatches.first;
      return RosterMatchResult(
        rawName: cleanRaw,
        resolvedName: fallback.name,
        matchedPlayer: fallback,
        isMatched: true,
      );
    }

    // 3. 名簿未登録（他道場選手や助っ人等）: クレンジングされた元の名前を保持
    return RosterMatchResult(
      rawName: cleanRaw,
      resolvedName: cleanRaw,
      matchedPlayer: null,
      isMatched: false,
    );
  }

  /// チームのメンバーリスト全員を照合
  static List<MatchedTeamMember> matchTeamMembers({
    required List<ParsedTeamMember> members,
    String? teamCategory,
    required List<PlayerModel> roster,
  }) {
    return members.map((member) {
      final result = matchPlayer(
        rawName: member.name,
        teamCategory: teamCategory,
        roster: roster,
      );
      return MatchedTeamMember(
        position: member.position,
        rawName: member.name,
        matchResult: result,
      );
    }).toList();
  }

  /// 選手がカテゴリ（部門）の学年・性別条件に合致するかどうかを判定
  static bool matchesCategory(PlayerModel p, String? category) {
    if (category == null || category.isEmpty) return true;
    final cat = category.toLowerCase();
    final g = p.grade;

    // 性別の指定がある場合のチェック
    if (cat.contains('女子') && p.gender.contains('男')) {
      return false;
    }
    if (cat.contains('男子') && p.gender.contains('女')) {
      return false;
    }

    if (cat.contains('低学年')) {
      return g >= 1 && g <= 4;
    }
    if (cat.contains('高学年')) {
      return g >= 5 && g <= 6;
    }
    if (cat.contains('小学生') || cat.contains('少年')) {
      return g >= 1 && g <= 6;
    }
    if (cat.contains('中学生') || cat.contains('中学')) {
      return g >= 7 && g <= 9;
    }
    if (cat.contains('高校生') || cat.contains('高校')) {
      return g >= 10 && g <= 12;
    }
    if (cat.contains('一般') || cat.contains('成年') || cat.contains('大学')) {
      return g == 99 || g >= 13;
    }
    return true;
  }

  /// カテゴリ文字列に基づいて同姓選手の中から最も適した選手を推定
  static PlayerModel? _disambiguateByCategory(
    List<PlayerModel> candidates,
    String? category,
  ) {
    if (category == null || category.isEmpty) return null;
    final matched = candidates
        .where((p) => matchesCategory(p, category))
        .toList();
    if (matched.isNotEmpty) {
      return matched.first;
    }
    return null;
  }

  /// カテゴリ（部門）と登録状況に基づき、名簿一覧を優先度順にソート
  ///
  /// 優先順位:
  /// 1. カテゴリ（部門）に合致する選手
  /// 2. 未登録（まだ他枠に配置されていないフリーな）選手
  /// 3. 学年順（昇順）
  /// 4. 五十音順（よみがな昇順）
  static List<PlayerModel> sortRosterForCategory({
    required List<PlayerModel> roster,
    String? category,
    Map<String, String>? assignedPlayerMap,
  }) {
    final list = List<PlayerModel>.from(roster);
    list.sort((a, b) {
      final aMatch = matchesCategory(a, category);
      final bMatch = matchesCategory(b, category);
      if (aMatch != bMatch) {
        return aMatch ? -1 : 1; // カテゴリ一致が最優先
      }

      if (assignedPlayerMap != null) {
        final aAssigned =
            assignedPlayerMap.containsKey(a.id) ||
            assignedPlayerMap.containsKey(normalize(a.name));
        final bAssigned =
            assignedPlayerMap.containsKey(b.id) ||
            assignedPlayerMap.containsKey(normalize(b.name));
        if (aAssigned != bAssigned) {
          return aAssigned ? 1 : -1; // 未登録（フリー）を優先
        }
      }

      // 学年順
      if (a.grade != b.grade) {
        return a.grade.compareTo(b.grade);
      }

      // 名前順（かな昇順）
      return a.nameKana.compareTo(b.nameKana);
    });
    return list;
  }

  /// 全チームの登録状況から、どの名簿選手が既にどのチーム・ポジションに配置されているかのマップを構築
  ///
  /// キー: `PlayerModel.id` および `normalize(PlayerModel.name)`
  /// 値: 配置先情報（例: '低学年・先鋒'）
  /// 現在編集中のメンバー自身（`currentEditingMember`）は重複扱いにしないため除外します。
  static Map<String, String> buildAssignedPlayerMap({
    required List<ParsedTeamOrder> allTeams,
    required List<PlayerModel> roster,
    ParsedTeamMember? currentEditingMember,
    String? currentTeamName,
  }) {
    final map = <String, String>{};

    for (final team in allTeams) {
      final teamCategory = team.category;
      for (final member in team.members) {
        // 編集中の自分自身（同じチームかつ同じポジション・名前）は除外
        if (currentEditingMember != null &&
            currentTeamName == team.teamName &&
            currentEditingMember.position == member.position &&
            currentEditingMember.name == member.name) {
          continue;
        }

        final match = matchPlayer(
          rawName: member.name,
          teamCategory: teamCategory,
          roster: roster,
        );

        if (match.isMatched && match.matchedPlayer != null) {
          final p = match.matchedPlayer!;
          final placementInfo = '${team.teamName}・${member.position}';
          map[p.id] = placementInfo;
          map[normalize(p.name)] = placementInfo;
        }
      }
    }

    return map;
  }
}
