import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';

/// 内部用対戦カード定義
class GeneratedMatch {
  final String categoryName;
  final String matchTitle;
  final String pairDescription;
  final int roundIndex;
  final int groupIndex;
  final double durationMinutes;

  GeneratedMatch({
    required this.categoryName,
    required this.matchTitle,
    required this.pairDescription,
    required this.roundIndex,
    required this.groupIndex,
    required this.durationMinutes,
  });
}

/// 🥋 試合形式に応じた対戦カード（リーグ戦・トーナメント戦）生成ヘルパー
class MatchGenerationHelper {
  MatchGenerationHelper._();

  /// 形式に応じた対戦リストの生成
  static List<GeneratedMatch> generateMatches(CalculatorSettings settings) {
    switch (settings.format) {
      case MatchFormatType.singleLeague:
        return generateLeagueMatches(
          participantCount: settings.participantCount,
          leagueName: 'リーグ戦',
          groupIndex: 0,
          durationMinutes: settings.matchDurationMinutes,
        );

      case MatchFormatType.multiLeague:
        final leagueCounts = settings.leagueParticipantCounts;
        final all = <GeneratedMatch>[];

        for (int i = 0; i < leagueCounts.length; i++) {
          final count = leagueCounts[i];
          final leagueChar = String.fromCharCode(65 + i); // 'A', 'B', 'C'...
          all.addAll(
            generateLeagueMatches(
              participantCount: count,
              leagueName: '$leagueCharリーグ',
              groupIndex: i,
              durationMinutes: settings.getLeagueMatchDuration(i),
            ),
          );
        }
        return all;

      case MatchFormatType.tournament:
        return generateTournamentMatches(
          participantCount: settings.participantCount,
          hasThirdPlace: settings.hasThirdPlaceMatch,
          prefix: 'トーナメント',
          durationMinutes: settings.tournamentMatchDuration,
        );

      case MatchFormatType.prelimLeagueAndTournament:
        final leagueCounts = settings.leagueParticipantCounts;
        final all = <GeneratedMatch>[];

        for (int i = 0; i < leagueCounts.length; i++) {
          final count = leagueCounts[i];
          final leagueChar = String.fromCharCode(65 + i);
          all.addAll(
            generateLeagueMatches(
              participantCount: count,
              leagueName: '予選$leagueCharリーグ',
              groupIndex: i,
              durationMinutes: settings.getLeagueMatchDuration(i),
            ),
          );
        }

        // 決勝トーナメント進出者
        final totalAdvancing =
            (leagueCounts.length * settings.advancingCountPerLeague).clamp(
              2,
              settings.effectiveParticipantCount,
            );
        all.addAll(
          generateTournamentMatches(
            participantCount: totalAdvancing,
            hasThirdPlace: settings.hasThirdPlaceMatch,
            prefix: '決勝トーナメント',
            groupOffset: leagueCounts.length,
            durationMinutes: settings.tournamentMatchDuration,
          ),
        );
        return all;
    }
  }

  /// サークル方式（Berger Tables）による総当たり戦カード生成
  static List<GeneratedMatch> generateLeagueMatches({
    required int participantCount,
    required String leagueName,
    required int groupIndex,
    required double durationMinutes,
  }) {
    if (participantCount < 2) return [];

    final list = <GeneratedMatch>[];
    final bool isOdd = participantCount.isOdd;
    final int n = isOdd ? participantCount + 1 : participantCount;

    // 選手番号リスト (1..n, 奇数の場合ダミーは n)
    final players = List<int>.generate(n, (i) => i + 1);
    final int rounds = n - 1;
    final int half = n ~/ 2;

    int matchNumber = 1;
    for (int r = 0; r < rounds; r++) {
      for (int i = 0; i < half; i++) {
        final p1 = players[i];
        final p2 = players[n - 1 - i];

        // ダミー(n)との試合は不戦勝（試合なし）
        if (isOdd && (p1 == n || p2 == n)) continue;

        list.add(
          GeneratedMatch(
            categoryName: leagueName,
            matchTitle: '第$matchNumber試合',
            pairDescription: '$p1番 vs $p2番',
            roundIndex: r,
            groupIndex: groupIndex,
            durationMinutes: durationMinutes,
          ),
        );
        matchNumber++;
      }

      // サークル回転 (1番選手固定、残り右回転)
      final last = players.removeLast();
      players.insert(1, last);
    }

    return list;
  }

  /// トーナメント戦カード生成
  static List<GeneratedMatch> generateTournamentMatches({
    required int participantCount,
    required bool hasThirdPlace,
    required String prefix,
    required double durationMinutes,
    int groupOffset = 0,
  }) {
    if (participantCount < 2) return [];

    final list = <GeneratedMatch>[];
    int currentTeams = participantCount;
    int round = 1;
    int matchNum = 1;

    // 決勝までの回戦シミュレーション
    while (currentTeams > 2) {
      final matchesThisRound = currentTeams ~/ 2;
      final String roundTitle = currentTeams <= 4
          ? '準決勝'
          : (currentTeams <= 8 ? '準々決勝' : '$round回戦');

      for (int m = 1; m <= matchesThisRound; m++) {
        list.add(
          GeneratedMatch(
            categoryName: prefix,
            matchTitle: '$roundTitle第$m試合',
            pairDescription: '対戦$matchNum',
            roundIndex: round,
            groupIndex: groupOffset,
            durationMinutes: durationMinutes,
          ),
        );
        matchNum++;
      }
      currentTeams = matchesThisRound + (currentTeams % 2);
      round++;
    }

    // 3位決定戦（ある場合、決勝の前）
    if (hasThirdPlace && participantCount >= 4) {
      list.add(
        GeneratedMatch(
          categoryName: prefix,
          matchTitle: '3位決定戦',
          pairDescription: '準決勝惜敗者',
          roundIndex: round,
          groupIndex: groupOffset,
          durationMinutes: durationMinutes,
        ),
      );
    }

    // 決勝戦
    list.add(
      GeneratedMatch(
        categoryName: prefix,
        matchTitle: '決勝戦',
        pairDescription: '決勝進出者',
        roundIndex: round + 1,
        groupIndex: groupOffset,
        durationMinutes: durationMinutes,
      ),
    );

    return list;
  }
}
