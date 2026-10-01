import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_generation_helper.dart';

void main() {
  group('[Unit] サークル方式総当たり対戦カード生成および境界値単体テスト', () {
    test('参加者数が2人未満の単一リーグ戦では空リストが返却されること', () {
      final matches0 = MatchGenerationHelper.generateLeagueMatches(
        participantCount: 0,
        leagueName: 'リーグA',
        groupIndex: 0,
        durationMinutes: 3.0,
      );
      expect(matches0, isEmpty);

      final matches1 = MatchGenerationHelper.generateLeagueMatches(
        participantCount: 1,
        leagueName: 'リーグA',
        groupIndex: 0,
        durationMinutes: 3.0,
      );
      expect(matches1, isEmpty);
    });

    test('3人リーグ戦において奇数バイ処理が適用され総試合数が3試合となること', () {
      // 3人総当たり: 3 * 2 / 2 = 3試合
      final matches = MatchGenerationHelper.generateLeagueMatches(
        participantCount: 3,
        leagueName: '3人リーグ',
        groupIndex: 0,
        durationMinutes: 4.0,
      );

      expect(matches.length, 3);

      // 各選手が2試合ずつ参加すること
      final counts = <int, int>{};
      for (final m in matches) {
        final pair = m.pairDescription.split(' vs ');
        final p1 = int.parse(pair[0].replaceAll('番', ''));
        final p2 = int.parse(pair[1].replaceAll('番', ''));
        counts[p1] = (counts[p1] ?? 0) + 1;
        counts[p2] = (counts[p2] ?? 0) + 1;
      }

      expect(counts[1], 2);
      expect(counts[2], 2);
      expect(counts[3], 2);
    });

    test('6人偶数リーグ戦において全15試合が完全重複なしで生成されること', () {
      // 6 * 5 / 2 = 15試合
      final matches = MatchGenerationHelper.generateLeagueMatches(
        participantCount: 6,
        leagueName: '6人リーグ',
        groupIndex: 0,
        durationMinutes: 5.0,
      );

      expect(matches.length, 15);

      final pairSet = <String>{};
      for (final m in matches) {
        final pair = m.pairDescription.split(' vs ');
        final p1 = int.parse(pair[0].replaceAll('番', ''));
        final p2 = int.parse(pair[1].replaceAll('番', ''));
        final key = p1 < p2 ? '$p1-$p2' : '$p2-$p1';
        expect(pairSet.add(key), isTrue);
      }
      expect(pairSet.length, 15);
    });

    test('トーナメント生成において参加者数8人で準々決勝から決勝まで正しく生成されること', () {
      // 8人: 準々決勝4試合 + 準決勝2試合 + 3位決定戦1試合 + 決勝戦1試合 = 8試合
      final matches = MatchGenerationHelper.generateTournamentMatches(
        participantCount: 8,
        hasThirdPlace: true,
        prefix: 'トーナメント',
        durationMinutes: 4.0,
      );

      expect(matches.length, 8);
      expect(matches.where((m) => m.matchTitle.contains('準々決勝')).length, 4);
      expect(matches.where((m) => m.matchTitle.contains('準決勝')).length, 2);
      expect(matches.where((m) => m.matchTitle == '3位決定戦').length, 1);
      expect(matches.where((m) => m.matchTitle == '決勝戦').length, 1);
    });

    test('複合形式設定から対戦カード全体が生成され進出枠が適正に反映されること', () {
      final settings = CalculatorSettings(
        format: MatchFormatType.multiLeague,
        participantCount: 8,
        courtCount: 2,
        leagueCount: 2,
        matchDurationMinutes: 3.5,
      );

      final matches = MatchGenerationHelper.generateMatches(settings);
      // 2リーグ（各4人）: 4 * 3 / 2 = 6試合 × 2 = 12試合
      expect(matches.length, 12);
      expect(matches.every((m) => m.durationMinutes == 3.5), isTrue);
    });
  });
}
