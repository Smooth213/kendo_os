import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';

/// 🥋 BAND投稿用・対戦カード速報テキストフォーマッター
class BandMatchTextFormatter {
  static const String _defaultBaseUrl = 'https://kendo-os-beta.web.app';

  /// タイムライン・大会ホームの試合グループ（MatchModelのリスト）から整形テキストを生成
  static String formatFromMatchGroup({
    required List<MatchModel> matches,
    String? tournamentName,
    String? dojoId,
    String baseUrl = _defaultBaseUrl,
  }) {
    if (matches.isEmpty) return '';

    final firstMatch = matches.first;
    final buffer = StringBuffer();

    // 1. 大会名
    if (tournamentName != null && tournamentName.trim().isNotEmpty) {
      buffer.writeln('【$tournamentName】');
    }

    // 2. 属性（【錬成】【申合せ】など）
    final scene = KendoSceneHelper.detectScene(firstMatch);
    final String scenePrefix;
    switch (scene) {
      case KendoMatchScene.renseikai:
        scenePrefix = '【錬成】';
        break;
      case KendoMatchScene.moushiawase:
        scenePrefix = '【申合せ】';
        break;
      case KendoMatchScene.bunaiksen:
        scenePrefix = '【部内戦】';
        break;
      default:
        scenePrefix = '';
        break;
    }

    // 3. コート・試合順・回戦情報（noteから取得、なければcategory）
    final noteInfo = firstMatch.note.trim();
    if (noteInfo.isNotEmpty) {
      buffer.writeln('$scenePrefix$noteInfo');
    } else if (firstMatch.category != null && firstMatch.category!.isNotEmpty) {
      buffer.writeln('$scenePrefix${firstMatch.category}');
    }

    // 4. 対戦カード
    final rTeam = _cleanTeamName(firstMatch.redName);
    final wTeam = _cleanTeamName(firstMatch.whiteName);

    final isDantai =
        matches.length > 1 ||
        firstMatch.matchType.contains('団体') ||
        (firstMatch.groupName != null &&
            firstMatch.groupName!.isNotEmpty &&
            !firstMatch.matchType.contains('個人'));

    if (isDantai) {
      buffer.writeln('$rTeam vs $wTeam');
      // 進行中の試合（先鋒・次鋒等）があれば追記
      final liveMatch = matches.firstWhere(
        (m) => m.status == 'in_progress' || m.status == 'playing',
        orElse: () => firstMatch,
      );
      if (liveMatch.status == 'in_progress' || liveMatch.status == 'playing') {
        final pos = _extractPosition(liveMatch);
        final rPlayer = _extractPlayerName(liveMatch.redName);
        final wPlayer = _extractPlayerName(liveMatch.whiteName);
        if (pos.isNotEmpty) {
          buffer.writeln('進行中: $pos 赤:$rPlayer vs 白:$wPlayer');
        }
      }
    } else {
      // 個人戦
      buffer.writeln('赤: ${firstMatch.redName} vs 白: ${firstMatch.whiteName}');
    }

    // 5. リアルタイム速報URL
    final targetId =
        (firstMatch.groupName != null && firstMatch.groupName!.isNotEmpty)
        ? firstMatch.groupName!
        : firstMatch.id;
    final safeDojo = (dojoId != null && dojoId.isNotEmpty)
        ? dojoId
        : 'default_org';
    final viewerUrl =
        '$baseUrl/viewer/${Uri.encodeComponent(targetId)}?dojoId=$safeDojo';

    buffer.writeln();
    buffer.writeln('▼ リアルタイム速報・スコア詳細');
    buffer.write(viewerUrl);

    return buffer.toString();
  }

  /// 「チーム試合状況」の TeamProgressStatus から整形テキストを生成
  static String formatFromTeamStatus({
    required TeamProgressStatus status,
    String? tournamentName,
    String? dojoId,
    String baseUrl = _defaultBaseUrl,
  }) {
    final buffer = StringBuffer();

    // 1. 大会名
    if (tournamentName != null && tournamentName.trim().isNotEmpty) {
      buffer.writeln('【$tournamentName】');
    }

    // 2. 部門・コート情報
    final category = status.categoryName.trim();
    final court = status.currentCourtName.trim();
    final headerSub = [
      if (category.isNotEmpty) category,
      if (court.isNotEmpty) court,
    ].join(' ');
    if (headerSub.isNotEmpty) {
      buffer.writeln('[$headerSub]');
    }

    // 3. 対戦見出し
    if (status.matchupTitle.isNotEmpty) {
      buffer.writeln(status.matchupTitle);
    } else {
      buffer.writeln(status.teamName);
    }

    // 4. 現在の試合（LIVE中、または次の対戦）
    final live = status.inProgressMatch;
    final next = status.nextWaitingMatch;
    if (live != null) {
      final pos = _extractPosition(live);
      final r = _extractPlayerName(live.redName);
      final w = _extractPlayerName(live.whiteName);
      buffer.writeln('【試合中】$pos $r vs $w');
    } else if (next != null) {
      final pos = _extractPosition(next);
      final r = _extractPlayerName(next.redName);
      final w = _extractPlayerName(next.whiteName);
      buffer.writeln('【次の対戦】$pos $r vs $w');
    }

    // 5. リアルタイム速報URL
    final targetId =
        status.targetGroupId ??
        (status.matches.isNotEmpty ? status.matches.first.id : '');
    if (targetId.isNotEmpty) {
      final safeDojo = (dojoId != null && dojoId.isNotEmpty)
          ? dojoId
          : 'default_org';
      final viewerUrl =
          '$baseUrl/viewer/${Uri.encodeComponent(targetId)}?dojoId=$safeDojo';
      buffer.writeln();
      buffer.writeln('▼ リアルタイム速報・スコア詳細');
      buffer.write(viewerUrl);
    }

    return buffer.toString();
  }

  static String _cleanTeamName(String raw) {
    if (raw.contains(':')) {
      return raw.split(':').first.trim();
    }
    return raw.trim();
  }

  static String _extractPlayerName(String raw) {
    if (raw.contains(':')) {
      final parts = raw.split(':');
      if (parts.length > 1) return parts[1].trim();
    }
    return raw.trim();
  }

  static String _extractPosition(MatchModel match) {
    final t = match.matchType;
    final positions = [
      '先鋒',
      '次鋒',
      '中堅',
      '副将',
      '大将',
      '代表戦',
      '十将',
      '九将',
      '八将',
      '七将',
      '六将',
      '五将',
      '四将',
      '三将',
    ];
    for (final p in positions) {
      if (t.contains(p)) return '[$p]';
    }
    return '';
  }
}
