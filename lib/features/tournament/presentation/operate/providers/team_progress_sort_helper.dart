import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';

/// 🥋 チーム試合状況の並び替え（ソート）種別
enum TeamSortType {
  /// ⚡ 進行状況順（試合中 LIVE > 待機中 > 終了）
  status,

  /// 🏟️ 試合会場順（第1コート > 第2コート...）
  court,

  /// 🔢 試合順（第1試合 > 第2試合... / order 昇順）
  matchOrder,
}

/// 🥋 チーム試合状況ソートエンジン
class TeamProgressSortHelper {
  TeamProgressSortHelper._();

  /// コート番号・優先度数値を抽出（小さい順、未指定は最後尾）
  static int extractCourtNumber(TeamProgressStatus status) {
    final text = status.currentCourtName;
    if (text.isEmpty || text.contains('コート未指定')) {
      return 999999;
    }

    // 第Xコート, 第X試合場, Xコート
    final regNum = RegExp(r'第?\s*(\d+)\s*(?:コート|試合場|場)');
    final matchNum = regNum.firstMatch(text);
    if (matchNum != null) {
      return int.tryParse(matchNum.group(1)!) ?? 999999;
    }

    // Aコート, Bコート などアルファベット
    final regAlpha = RegExp(r'([A-Za-z])\s*(?:コート|試合場)');
    final matchAlpha = regAlpha.firstMatch(text);
    if (matchAlpha != null) {
      return 10000 + matchAlpha.group(1)!.toUpperCase().codeUnitAt(0);
    }

    if (text.contains('メインコート')) return 500;
    if (text.contains('サブコート')) return 600;
    if (text.contains('部内戦コート')) return 700;

    return 999999;
  }

  /// 試合順（第何試合・order）の優先度数値を抽出（小さい順、未指定は最後尾）
  static double extractMatchOrder(TeamProgressStatus status) {
    final text = status.currentCourtName;

    // 1. currentCourtName 内の「第X試合」「X試合目」を最優先で解釈
    final regOrder = RegExp(r'(?:第\s*(\d+)\s*試合(?!場)|(\d+)\s*試合目)');
    final match = regOrder.firstMatch(text);
    if (match != null) {
      final numStr = match.group(1) ?? match.group(2);
      if (numStr != null) {
        final parsed = double.tryParse(numStr);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // 2. matches 内の最小の matchOrder / order を使用
    if (status.matches.isNotEmpty) {
      double minOrder = 999999.0;
      for (final m in status.matches) {
        if (m.matchOrder != null && m.matchOrder! > 0) {
          final mo = m.matchOrder!.toDouble();
          if (mo < minOrder) minOrder = mo;
        } else if (m.order > 0 && m.order < minOrder) {
          minOrder = m.order;
        }
      }
      if (minOrder < 999999.0) return minOrder;
    }

    return 999999.0;
  }

  /// 指定されたソート種別に基づいてチーム試合状況一覧を並び替える
  static List<TeamProgressStatus> sortTeams(
    List<TeamProgressStatus> teams,
    TeamSortType sortType,
  ) {
    final list = List<TeamProgressStatus>.from(teams);

    switch (sortType) {
      case TeamSortType.status:
        list.sort((a, b) {
          // 1. 試合中 (LIVE) 優先
          if (a.hasLiveMatch != b.hasLiveMatch) {
            return a.hasLiveMatch ? -1 : 1;
          }
          // 2. 終了カードは後方へ
          if (a.isFinished != b.isFinished) {
            return a.isFinished ? 1 : -1;
          }
          // 3. 試合会場順
          final courtCmp = extractCourtNumber(
            a,
          ).compareTo(extractCourtNumber(b));
          if (courtCmp != 0) return courtCmp;
          // 4. 試合順
          final orderCmp = extractMatchOrder(a).compareTo(extractMatchOrder(b));
          if (orderCmp != 0) return orderCmp;
          // 5. チーム名順
          return a.teamName.compareTo(b.teamName);
        });
        break;

      case TeamSortType.court:
        list.sort((a, b) {
          // 1. 試合会場順（第1コート < 第2コート...）
          final courtCmp = extractCourtNumber(
            a,
          ).compareTo(extractCourtNumber(b));
          if (courtCmp != 0) return courtCmp;
          // 2. 同一コート内は試合順（第1試合 < 第2試合...）
          final orderCmp = extractMatchOrder(a).compareTo(extractMatchOrder(b));
          if (orderCmp != 0) return orderCmp;
          // 3. 試合中 (LIVE) 優先
          if (a.hasLiveMatch != b.hasLiveMatch) {
            return a.hasLiveMatch ? -1 : 1;
          }
          // 4. チーム名順
          return a.teamName.compareTo(b.teamName);
        });
        break;

      case TeamSortType.matchOrder:
        list.sort((a, b) {
          // 1. 試合順（第1試合 < 第2試合...）
          final orderCmp = extractMatchOrder(a).compareTo(extractMatchOrder(b));
          if (orderCmp != 0) return orderCmp;
          // 2. 同一試合順はコート順（第1コート < 第2コート...）
          final courtCmp = extractCourtNumber(
            a,
          ).compareTo(extractCourtNumber(b));
          if (courtCmp != 0) return courtCmp;
          // 3. 試合中 (LIVE) 優先
          if (a.hasLiveMatch != b.hasLiveMatch) {
            return a.hasLiveMatch ? -1 : 1;
          }
          // 4. チーム名順
          return a.teamName.compareTo(b.teamName);
        });
        break;
    }

    return list;
  }
}
