import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:uuid/uuid.dart';

/// 🥋 決勝トーナメント進出方式
enum TournamentAdvancementMethod {
  /// 順位直結配置（Aリーグ1位 vs Bリーグ2位など）
  directRank,

  /// くじ引き・抽選枠配置（抽選枠1番 vs 抽選枠2番など）
  lottery,
}

/// 🥋 計算機シミュレーション結果から部内戦用MatchModel一括生成ヘルパー
class BunaiksenCalculatorMatchGenerator {
  BunaiksenCalculatorMatchGenerator._();

  /// 割り振り結果と設定からMatchModelリストを一括生成
  static List<MatchModel> generateMatches({
    required AllocationResult result,
    required CalculatorSettings settings,
    required MatchRule rule,
    required String tournamentId,
    List<String>? playerNames,
    TournamentAdvancementMethod advancementMethod =
        TournamentAdvancementMethod.directRank,
    double baseOrder = 0.0,
  }) {
    // 1. 全コートの AllocatedMatch をタイムライン順（推定開始時刻順）にフラット化
    final allAllocated = <AllocatedMatch>[];
    for (final matches in result.courtMatches.values) {
      allAllocated.addAll(matches);
    }
    // 推定開始時間、次点でコート番号・試合順でソート
    allAllocated.sort((a, b) {
      final timeCmp = a.estimatedStart.compareTo(b.estimatedStart);
      if (timeCmp != 0) return timeCmp;
      final courtCmp = a.courtNumber.compareTo(b.courtNumber);
      if (courtCmp != 0) return courtCmp;
      return a.matchOrder.compareTo(b.matchOrder);
    });

    if (allAllocated.isEmpty) return [];

    // 2. トーナメント戦カード間のIDリンク（勝者・敗者伝播用）マップの構築
    final matchIdMap = <AllocatedMatch, String>{};
    for (final m in allAllocated) {
      matchIdMap[m] = const Uuid().v4();
    }

    final tournamentLinkMap = _buildTournamentLinks(allAllocated, matchIdMap);

    // 3. リーグ別の選手名配分マップの準備
    final leaguePlayersMap = _distributeLeaguePlayers(
      settings: settings,
      playerNames: playerNames,
    );

    // 4. 各 AllocatedMatch を MatchModel に変換
    final matchesToSave = <MatchModel>[];
    for (int i = 0; i < allAllocated.length; i++) {
      final allocated = allAllocated[i];
      final matchId = matchIdMap[allocated]!;
      final isTournamentMatch = _isTournamentCategory(allocated.categoryName);

      // 対戦選手名の決定（赤・白）
      final (redName, whiteName) = _determinePlayerNames(
        allocated: allocated,
        settings: settings,
        playerNames: playerNames,
        leaguePlayersMap: leaguePlayersMap,
        tournamentLinkMap: tournamentLinkMap,
        advancementMethod: advancementMethod,
      );

      final isLeague = !isTournamentMatch;
      final matchRule = rule.copyWith(
        matchTimeMinutes: allocated.durationMinutes,
        isLeague: isLeague,
        winPoint: isLeague ? (rule.winPoint > 0 ? rule.winPoint : 3.0) : 0.0,
        drawPoint: isLeague ? (rule.drawPoint > 0 ? rule.drawPoint : 1.0) : 0.0,
        lossPoint: 0.0,
      );

      matchesToSave.add(
        MatchModel(
          id: matchId,
          tournamentId: tournamentId,
          category: allocated.categoryName,
          matchType: isLeague ? 'リーグ戦' : 'トーナメント',
          groupName: _resolveGroupName(allocated.categoryName),
          matchOrder: allocated.matchOrder,
          redName: redName,
          whiteName: whiteName,
          matchTimeMinutes: allocated.durationMinutes,
          hasExtension: rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited,
          extensionTimeMinutes: rule.enchoTimeMinutes,
          status: 'waiting',
          order:
              baseOrder + (allocated.courtNumber * 1000) + allocated.matchOrder,
          rule: matchRule,
          note:
              '[${allocated.categoryName}] ${allocated.matchTitle} (第${allocated.courtNumber}コート 第${allocated.matchOrder}試合)',
        ),
      );
    }

    return matchesToSave;
  }

  static bool _isTournamentCategory(String categoryName) {
    return categoryName.contains('トーナメント') ||
        categoryName.contains('決勝') ||
        categoryName.contains('準決勝') ||
        categoryName == '3位決定戦';
  }

  static String _resolveGroupName(String categoryName) {
    if (categoryName.contains('トーナメント') || categoryName.contains('決勝')) {
      return 'tournament';
    }
    return 'league_$categoryName';
  }

  /// リーグごとの参加選手一覧を作成
  static Map<int, List<String>> _distributeLeaguePlayers({
    required CalculatorSettings settings,
    required List<String>? playerNames,
  }) {
    final map = <int, List<String>>{};
    if (playerNames == null || playerNames.isEmpty) return map;

    // 1リーグ総当たりの場合は全選手を0番グループに集約
    if (settings.format == MatchFormatType.singleLeague) {
      map[0] = List<String>.from(playerNames);
      return map;
    }

    final counts = settings.leagueParticipantCounts;
    int offset = 0;
    for (int i = 0; i < counts.length; i++) {
      final count = counts[i];
      final end = (offset + count).clamp(0, playerNames.length);
      if (offset < playerNames.length) {
        map[i] = playerNames.sublist(offset, end);
      } else {
        map[i] = [];
      }
      offset += count;
    }
    return map;
  }

  /// トーナメント戦のカード間勝者・敗者リンクを事前構築
  static Map<AllocatedMatch, _TournamentLinkInfo> _buildTournamentLinks(
    List<AllocatedMatch> allAllocated,
    Map<AllocatedMatch, String> matchIdMap,
  ) {
    final links = <AllocatedMatch, _TournamentLinkInfo>{};
    final tournamentMatches = allAllocated
        .where((m) => _isTournamentCategory(m.categoryName))
        .toList();

    if (tournamentMatches.isEmpty) return links;

    // 試合タイトルからステージ（回戦、準決勝、3位決定戦、決勝）を分類
    final semiFinals = tournamentMatches
        .where((m) => m.matchTitle.contains('準決勝'))
        .toList();
    final finals = tournamentMatches
        .where(
          (m) => m.matchTitle.contains('決勝戦') && !m.matchTitle.contains('準'),
        )
        .toList();
    final thirdPlaces = tournamentMatches
        .where((m) => m.matchTitle.contains('3位決定戦'))
        .toList();

    // 準決勝が2試合あり、決勝がある場合、決勝に勝者タグを紐付け
    if (semiFinals.length >= 2 && finals.isNotEmpty) {
      final finalMatch = finals.first;
      final semi1Id = matchIdMap[semiFinals[0]]!;
      final semi2Id = matchIdMap[semiFinals[1]]!;

      links[finalMatch] = _TournamentLinkInfo(
        redPlaceholder: '[準決勝1勝者] winner($semi1Id)',
        whitePlaceholder: '[準決勝2勝者] winner($semi2Id)',
      );

      // 3位決定戦がある場合、惜敗者タグを紐付け
      if (thirdPlaces.isNotEmpty) {
        final thirdMatch = thirdPlaces.first;
        links[thirdMatch] = _TournamentLinkInfo(
          redPlaceholder: '[準決勝1惜敗者] loser($semi1Id)',
          whitePlaceholder: '[準決勝2惜敗者] loser($semi2Id)',
        );
      }
    }

    return links;
  }

  /// 選手名（赤・白）の解決
  static (String, String) _determinePlayerNames({
    required AllocatedMatch allocated,
    required CalculatorSettings settings,
    required List<String>? playerNames,
    required Map<int, List<String>> leaguePlayersMap,
    required Map<AllocatedMatch, _TournamentLinkInfo> tournamentLinkMap,
    required TournamentAdvancementMethod advancementMethod,
  }) {
    final isTournament = _isTournamentCategory(allocated.categoryName);

    // 1. トーナメント後続試合（決勝・3位決定戦など）のリンクがある場合
    if (tournamentLinkMap.containsKey(allocated)) {
      final link = tournamentLinkMap[allocated]!;
      return (link.redPlaceholder, link.whitePlaceholder);
    }

    // 2. 予選L＋決勝Tの決勝トーナメント1回戦（進出枠）
    if (isTournament &&
        settings.format == MatchFormatType.prelimLeagueAndTournament) {
      return _determinePrelimAdvancementNames(
        allocated: allocated,
        settings: settings,
        advancementMethod: advancementMethod,
      );
    }

    // 3. 純粋トーナメント戦の1回戦
    if (isTournament && settings.format == MatchFormatType.tournament) {
      return _determinePureTournamentNames(
        allocated: allocated,
        playerNames: playerNames,
      );
    }

    // 4. リーグ戦（1リーグ or 複数リーグ）
    return _determineLeagueNames(
      allocated: allocated,
      settings: settings,
      playerNames: playerNames,
      leaguePlayersMap: leaguePlayersMap,
    );
  }

  /// 予選リーグからの進出枠の名前解決
  static (String, String) _determinePrelimAdvancementNames({
    required AllocatedMatch allocated,
    required CalculatorSettings settings,
    required TournamentAdvancementMethod advancementMethod,
  }) {
    if (advancementMethod == TournamentAdvancementMethod.lottery) {
      final matchNum = RegExp(r'第(\d+)試合').firstMatch(allocated.matchTitle);
      final matchIdx = matchNum != null
          ? (int.tryParse(matchNum.group(1)!) ?? allocated.matchOrder)
          : allocated.matchOrder;
      final seed1 = (matchIdx - 1) * 2 + 1;
      final seed2 = (matchIdx - 1) * 2 + 2;
      return ('[抽選枠 $seed1番]', '[抽選枠 $seed2番]');
    }

    // 順位直結配置
    final leagueCounts = settings.leagueParticipantCounts;
    final leagueChars = List.generate(
      leagueCounts.length,
      (i) => String.fromCharCode(65 + i),
    );

    // 2リーグの場合
    if (leagueChars.length == 2) {
      if (settings.advancingCountPerLeague == 1) {
        return ('[${leagueChars[0]}リーグ1位]', '[${leagueChars[1]}リーグ1位]');
      } else {
        // 各2名進出（準決勝2試合）
        if (allocated.matchTitle.contains('第1試合') ||
            allocated.matchOrder == 1) {
          return ('[${leagueChars[0]}リーグ1位]', '[${leagueChars[1]}リーグ2位]');
        } else {
          return ('[${leagueChars[1]}リーグ1位]', '[${leagueChars[0]}リーグ2位]');
        }
      }
    }

    // 3リーグ以上の場合
    final matchOrder = allocated.matchOrder;
    final rIdx = (matchOrder - 1) * 2;
    final wIdx = rIdx + 1;
    final rName = rIdx < leagueChars.length
        ? '[${leagueChars[rIdx]}リーグ1位]'
        : '[進出者$rIdx]';
    final wName = wIdx < leagueChars.length
        ? '[${leagueChars[wIdx]}リーグ1位]'
        : '[進出者$wIdx]';
    return (rName, wName);
  }

  /// 純粋トーナメント戦のカード名前解決
  static (String, String) _determinePureTournamentNames({
    required AllocatedMatch allocated,
    required List<String>? playerNames,
  }) {
    final matchIdx = allocated.matchOrder;
    final p1Idx = (matchIdx - 1) * 2;
    final p2Idx = p1Idx + 1;

    if (playerNames != null && p1Idx < playerNames.length) {
      final p1 = playerNames[p1Idx];
      final p2 = p2Idx < playerNames.length ? playerNames[p2Idx] : '未定';
      return (p1, p2);
    }

    return ('${p1Idx + 1}番選手', '${p2Idx + 1}番選手');
  }

  /// リーグ戦の名前解決（Berger Tables番号パース）
  static (String, String) _determineLeagueNames({
    required AllocatedMatch allocated,
    required CalculatorSettings settings,
    required List<String>? playerNames,
    required Map<int, List<String>> leaguePlayersMap,
  }) {
    // pairDescription: '1番 vs 2番' など
    final regex = RegExp(r'(\d+)番\s*vs\s*(\d+)番');
    final match = regex.firstMatch(allocated.pairDescription);

    int p1Num = 1;
    int p2Num = 2;
    if (match != null) {
      p1Num = int.tryParse(match.group(1) ?? '1') ?? 1;
      p2Num = int.tryParse(match.group(2) ?? '2') ?? 2;
    }

    // リーグのプレフィックス特定（Aリーグ、Bリーグなど）
    final category = allocated.categoryName;
    int leagueIndex = 0;
    String leagueChar = '';
    final leagueMatch = RegExp(r'([A-Za-z])リーグ').firstMatch(category);
    if (leagueMatch != null) {
      leagueChar = leagueMatch.group(1)!;
      final code = leagueChar.codeUnitAt(0);
      if (code >= 65 && code <= 90) {
        leagueIndex = code - 65;
      }
    }

    final leaguePlayers = leaguePlayersMap[leagueIndex] ?? [];
    if (leaguePlayers.isNotEmpty &&
        (p1Num - 1) < leaguePlayers.length &&
        (p2Num - 1) < leaguePlayers.length) {
      return (leaguePlayers[p1Num - 1], leaguePlayers[p2Num - 1]);
    }

    // 仮名モード
    if (leagueChar.isNotEmpty) {
      return ('$leagueChar$p1Num', '$leagueChar$p2Num');
    }
    return ('$p1Num番選手', '$p2Num番選手');
  }
}

class _TournamentLinkInfo {
  final String redPlaceholder;
  final String whitePlaceholder;

  _TournamentLinkInfo({
    required this.redPlaceholder,
    required this.whitePlaceholder,
  });
}
