import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_generation_helper.dart';

void main() {
  group('[Governance] サークル方式総当たりおよびトーナメント対戦カード生成規約', () {
    test('奇数人数リーグ戦においてダミー選手が除外され全員の試合数が均等になること', () {
      // 5名リーグ戦（総当たり対戦数は 5 * 4 / 2 = 10試合）
      final matches5 = MatchGenerationHelper.generateLeagueMatches(
        participantCount: 5,
        leagueName: 'Aリーグ',
        groupIndex: 0,
        durationMinutes: 4.0,
      );

      expect(matches5.length, 10);

      // 各選手の登場回数をカウント（全員4試合行うこと）
      final playerCounts = <int, int>{};
      for (final m in matches5) {
        final pair = m.pairDescription; // "1番 vs 5番" 形式
        final parts = pair.split(' vs ');
        final p1 = int.parse(parts[0].replaceAll('番', ''));
        final p2 = int.parse(parts[1].replaceAll('番', ''));

        expect(p1, inInclusiveRange(1, 5));
        expect(p2, inInclusiveRange(1, 5));
        expect(p1, isNot(equals(p2)));

        playerCounts[p1] = (playerCounts[p1] ?? 0) + 1;
        playerCounts[p2] = (playerCounts[p2] ?? 0) + 1;
      }

      for (int i = 1; i <= 5; i++) {
        expect(playerCounts[i], 4);
      }
    });

    test('サークル回転アルゴリズムが同一対戦の重複を発生させずに全組合せを網羅すること', () {
      // 4名リーグ戦（総試合数は 4 * 3 / 2 = 6試合）
      final matches4 = MatchGenerationHelper.generateLeagueMatches(
        participantCount: 4,
        leagueName: '予選リーグ',
        groupIndex: 0,
        durationMinutes: 3.0,
      );

      expect(matches4.length, 6);

      final uniquePairs = <String>{};
      for (final m in matches4) {
        final parts = m.pairDescription.split(' vs ');
        final p1 = int.parse(parts[0].replaceAll('番', ''));
        final p2 = int.parse(parts[1].replaceAll('番', ''));
        final key = p1 < p2 ? '$p1-$p2' : '$p2-$p1';
        expect(uniquePairs.contains(key), isFalse);
        uniquePairs.add(key);
      }

      expect(uniquePairs.length, 6);
    });

    test('トーナメント生成において3位決定戦の有無および決勝戦の配置が正確であること', () {
      // 4名トーナメント（3位決定戦あり）: 準決勝2試合 + 3位決定戦1試合 + 決勝戦1試合 = 4試合
      final matchesWithThird = MatchGenerationHelper.generateTournamentMatches(
        participantCount: 4,
        hasThirdPlace: true,
        prefix: '本戦',
        durationMinutes: 4.0,
      );

      expect(matchesWithThird.length, 4);
      expect(matchesWithThird.any((m) => m.matchTitle == '3位決定戦'), isTrue);
      expect(matchesWithThird.last.matchTitle, '決勝戦');

      // 4名トーナメント（3位決定戦なし）: 準決勝2試合 + 決勝戦1試合 = 3試合
      final matchesNoThird = MatchGenerationHelper.generateTournamentMatches(
        participantCount: 4,
        hasThirdPlace: false,
        prefix: '本戦',
        durationMinutes: 4.0,
      );

      expect(matchesNoThird.length, 3);
      expect(matchesNoThird.any((m) => m.matchTitle == '3位決定戦'), isFalse);
      expect(matchesNoThird.last.matchTitle, '決勝戦');
    });

    test('予選リーグ兼決勝トーナメント生成において進出者数がクランプされ安全に生成されること', () {
      final settings = CalculatorSettings(
        format: MatchFormatType.prelimLeagueAndTournament,
        participantCount: 12,
        courtCount: 2,
        leagueCount: 4,
        advancingCountPerLeague: 2,
        hasThirdPlaceMatch: true,
      );

      final allMatches = MatchGenerationHelper.generateMatches(settings);
      expect(allMatches, isNotEmpty);

      final leagueMatches = allMatches
          .where((m) => m.categoryName.contains('予選'))
          .toList();
      final tournamentMatches = allMatches
          .where((m) => m.categoryName.contains('決勝トーナメント'))
          .toList();

      expect(leagueMatches, isNotEmpty);
      expect(tournamentMatches, isNotEmpty);
      expect(tournamentMatches.any((m) => m.matchTitle == '3位決定戦'), isTrue);
    });
  });
}
