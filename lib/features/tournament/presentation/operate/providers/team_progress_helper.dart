import 'package:kendo_os/features/match/domain/match_model.dart';

/// 🥋 チーム試合状況の文字列抽出・形式判定・自チーム解決ヘルパー
class TeamProgressHelper {
  TeamProgressHelper._();

  /// 選手名またはチーム名から純粋なチーム名を抽出
  static String extractTeamName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '自チーム';
    if (trimmed.contains(':')) {
      return trimmed.split(':').first.trim();
    }
    return trimmed;
  }

  /// 選手名またはチーム名から純粋な選手名を抽出
  static String extractPlayerName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains(':')) {
      return trimmed.split(':').last.trim();
    }
    return trimmed;
  }

  /// 選手名またはチーム名を分かりやすくフォーマットするヘルパー
  static String formatPlayerOrTeamDisplay(
    String name, {
    required bool isIndividual,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '選手未定';

    if (!trimmed.contains(':')) {
      return trimmed;
    }

    final parts = trimmed.split(':');
    final team = parts[0].trim();
    final player = parts.length > 1 ? parts[1].trim() : '';

    if (isIndividual) {
      if (player.isNotEmpty) {
        return team.isNotEmpty ? '$player（$team）' : player;
      }
      return team;
    } else {
      return team.isNotEmpty ? team : player;
    }
  }

  /// 試合形式の厳密な判定ヘルパー
  static bool isIndividualMatch(MatchModel match) {
    if (isKachinukiMatch(match)) return false;
    final type = match.matchType.trim();
    if (type == '個人戦' ||
        type == 'リーグ個人戦' ||
        type == '選手' ||
        type.contains('個人')) {
      return true;
    }
    return false;
  }

  static bool isLeagueMatch(MatchModel match) {
    final type = match.matchType.trim();
    // matchTypeが明確にリーグ戦（リーグ団体戦、リーグ個人戦、〇〇リーグ等）
    if (type == 'リーグ団体戦' || type == 'リーグ個人戦') return true;
    if (type.contains('リーグ') && !type.contains('回戦') && !type.contains('決勝')) {
      return true;
    }
    return false;
  }

  static bool isKachinukiMatch(MatchModel match) {
    if (match.isKachinuki) return true;
    if (match.rule?.isKachinuki == true) return true;
    final type = match.matchType.trim();
    return type.contains('勝ち抜き') || type.contains('勝抜き');
  }

  /// 試合またはルールから錬成会・申合せのバッジ文字列（例: '【錬成】', '【申合せ】', または ''）を取得
  static String getScenePrefix(MatchModel match) {
    return getScenePrefixFromDynamic(match);
  }

  /// MatchModel / MatchListProjection / Map などの汎用試合オブジェクトから
  /// 錬成会・申合せのバッジ文字列を取得
  static String getScenePrefixFromDynamic(dynamic match) {
    if (match == null) return '';

    String scene = '';
    String ruleScene = '';
    bool ruleIsRenseikai = false;
    String matchType = '';
    String note = '';
    String? category;

    if (match is MatchModel) {
      scene = match.matchScene;
      ruleScene = match.rule?.matchScene ?? '';
      ruleIsRenseikai = match.rule?.isRenseikai ?? false;
      matchType = match.matchType;
      note = match.note;
      category = match.category;
    } else {
      try {
        scene = (match.matchScene ?? '').toString();
      } catch (_) {}
      try {
        ruleScene = (match.rule?.matchScene ?? '').toString();
      } catch (_) {}
      try {
        ruleIsRenseikai = match.rule?.isRenseikai ?? false;
      } catch (_) {}
      try {
        matchType = (match.matchType ?? '').toString();
      } catch (_) {}
      try {
        note = (match.note ?? '').toString();
      } catch (_) {}
      try {
        category = match.category?.toString();
      } catch (_) {}
    }

    final isMoushiawase =
        scene == 'moushiawase' ||
        ruleScene == 'moushiawase' ||
        matchType.contains('申し合わせ') ||
        matchType.contains('申合せ') ||
        note.contains('申し合わせ') ||
        note.contains('申合せ') ||
        (category != null &&
            (category.contains('申し合わせ') || category.contains('申合せ')));

    if (isMoushiawase) return '【申合せ】';

    final isRensei =
        scene == 'renseikai' ||
        ruleScene == 'renseikai' ||
        ruleIsRenseikai ||
        matchType.contains('錬成') ||
        note.contains('錬成') ||
        (category != null && category.contains('錬成'));

    if (isRensei) return '【錬成】';

    return '';
  }

  /// 試合データから対戦カード名（例: 団体戦：〇〇 vs ◯◯）を抽出
  static String extractTeamMatchupTitle(MatchModel match) {
    final isIndiv = isIndividualMatch(match);
    final isLeague = isLeagueMatch(match);
    final isKachinuki = isKachinukiMatch(match);

    final prefix = getScenePrefix(match);

    String formatLabel;
    if (isKachinuki) {
      formatLabel = '勝ち抜き戦：';
    } else if (isLeague && isIndiv) {
      formatLabel = 'リーグ個人戦：';
    } else if (isLeague && !isIndiv) {
      formatLabel = 'リーグ団体戦：';
    } else if (isIndiv) {
      formatLabel = '個人戦：';
    } else {
      formatLabel = '団体戦：';
    }

    final rDisplay = formatPlayerOrTeamDisplay(
      match.redName,
      isIndividual: isIndiv,
    );
    final wDisplay = formatPlayerOrTeamDisplay(
      match.whiteName,
      isIndividual: isIndiv,
    );

    final matchup = '$rDisplay vs $wDisplay';

    if (prefix.isNotEmpty) {
      return '$prefix$formatLabel$matchup';
    }
    return '$formatLabel$matchup';
  }

  /// 試合データから「第2コート (1回戦・第4試合)」のようなコート・ラウンド・試合順の表示文字列を抽出
  static String extractCourtAndRoundDisplay(MatchModel match) {
    final note = match.note.trim();
    final category = match.category ?? '';
    final group = match.groupName ?? '';
    final combinedText = '$note, $category, $group';

    // 1. コート・試合場
    String? court;
    final courtMatch = RegExp(
      r'(第?\s*\d+\s*(?:コート|試合場|場)|[A-Za-z]\s*(?:コート|試合場)|部内戦コート|メインコート|サブコート)',
    ).firstMatch(combinedText);
    if (courtMatch != null) {
      court = courtMatch.group(1)!.replaceAll(' ', '');
    }

    // 2. 回戦・ラウンド
    String? round;
    final roundMatch = RegExp(
      r'(\d+回戦|準々決勝|準決勝|決勝戦|決勝|予選リーグ|[A-Za-z]リーグ|[A-Za-z]ブロック|\d+ブロック)',
    ).firstMatch(combinedText);
    if (roundMatch != null) {
      round = roundMatch.group(1)!.replaceAll(' ', '');
    }

    // 3. 試合順（何試合目）
    String? matchOrder;
    final orderMatch = RegExp(
      r'(?:第\s*(\d+)\s*試合(?!場)|(\d+)\s*試合目)',
    ).firstMatch(combinedText);
    if (orderMatch != null) {
      final num = orderMatch.group(1) ?? orderMatch.group(2);
      if (num != null) {
        matchOrder = '第$num試合';
      }
    }

    // サブ情報の結合（例: 1回戦・第4試合）
    final subInfoParts = <String>[?round, ?matchOrder];

    final subInfo = subInfoParts.isNotEmpty
        ? ' (${subInfoParts.join('・')})'
        : '';

    if (court != null) {
      return '$court$subInfo';
    } else if (subInfoParts.isNotEmpty) {
      return 'コート未指定$subInfo';
    }

    return 'コート未指定';
  }

  /// 赤または白が「自チーム側」かどうかを判定する高精度リゾルバー
  static bool isSideOwn({
    required String sideFullName,
    required Set<String> knownTeams,
    required Set<String> knownPlayers,
    required String myDojoName,
    String? ruleTeamName,
  }) {
    final sideTeam = extractTeamName(sideFullName);
    final sidePlayer = extractPlayerName(sideFullName);

    // 1. 登録チーム名と完全一致
    if (knownTeams.contains(sideTeam) || knownTeams.contains(sideFullName)) {
      return true;
    }

    // 2. ルールで設定された自チーム名と一致
    if (ruleTeamName != null && ruleTeamName.trim().isNotEmpty) {
      final cleanRule = ruleTeamName.trim();
      if (sideTeam == cleanRule || sideFullName.contains(cleanRule)) {
        return true;
      }
    }

    // 3. 道場名を含む
    if (myDojoName.isNotEmpty) {
      if (sideTeam.contains(myDojoName) || sideFullName.contains(myDojoName)) {
        return true;
      }
    }

    // 4. 登録選手名（久安 智也など）が一致
    if (sidePlayer.isNotEmpty && knownPlayers.contains(sidePlayer)) return true;
    if (knownPlayers.isNotEmpty &&
        knownPlayers.any((p) => sideFullName.contains(p))) {
      return true;
    }

    return false;
  }

  /// 選手名・チーム名から自チームとしての表示用ヘッダータイトルを解決
  static String resolveSideTeamTitle({
    required String sideFullName,
    required Set<String> knownTeams,
    required Set<String> knownPlayers,
    required String myDojoName,
    required bool isIndividual,
  }) {
    final team = extractTeamName(sideFullName);
    final player = extractPlayerName(sideFullName);

    // コロン区切りでチーム名がある場合はそのチーム名
    if (sideFullName.contains(':') && team.isNotEmpty) {
      return team;
    }

    // チーム名が既知のチーム名に該当する場合
    if (knownTeams.contains(team)) return team;
    if (myDojoName.isNotEmpty && team.contains(myDojoName)) return team;

    // 選手名のみの場合、道場名があれば道場名、なければ選手名
    if (player.isNotEmpty && knownPlayers.contains(player)) {
      if (myDojoName.isNotEmpty) {
        return myDojoName;
      }
      return player;
    }

    return team.isNotEmpty ? team : '自チーム';
  }
}
