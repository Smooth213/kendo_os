import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Unit] 部内戦ドック 試合数・コート配分・進行シミュレーション計算テスト', () {
    // 1リーグ総当たりの試合数計算
    int calculateSingleLeagueMatches(int players) {
      if (players < 2) return 0;
      return (players * (players - 1)) ~/ 2;
    }

    // 複数リーグ総当たりの試合数計算
    int calculateMultiLeagueMatches(int totalPlayers, int leagueCount) {
      if (totalPlayers < 2 || leagueCount < 1) return 0;
      final base = totalPlayers ~/ leagueCount;
      final remainder = totalPlayers % leagueCount;
      int totalMatches = 0;
      for (int i = 0; i < leagueCount; i++) {
        final count = i < remainder ? base + 1 : base;
        totalMatches += calculateSingleLeagueMatches(count);
      }
      return totalMatches;
    }

    // トーナメントの試合数計算
    int calculateTournamentMatches(int players) {
      if (players < 2) return 0;
      return players - 1;
    }

    // 所要時間（分）計算
    int calculateDurationMinutes({
      required int totalMatches,
      required int courtCount,
      required int matchMinutes,
      required int intervalMinutes,
    }) {
      if (courtCount < 1 || totalMatches < 1) return 0;
      final matchTimeWithInterval = matchMinutes + intervalMinutes;
      final rounds = (totalMatches + courtCount - 1) ~/ courtCount;
      return rounds * matchTimeWithInterval;
    }

    test('1リーグ総当たりにおいて5名で10試合や8名で28試合の試合数が正しく算出されること', () {
      expect(calculateSingleLeagueMatches(5), equals(10));
      expect(calculateSingleLeagueMatches(8), equals(28));
      expect(calculateSingleLeagueMatches(2), equals(1));
      expect(calculateSingleLeagueMatches(1), equals(0));
    });

    test('複数リーグ総当たりで端数人数が均等分配され9名2リーグで16試合等の試合数が算出されること', () {
      // 9名を2リーグに分割 ➔ 5名(10試合) + 4名(6試合) = 16試合
      expect(calculateMultiLeagueMatches(9, 2), equals(16));

      // 8名を2リーグに分割 ➔ 4名(6試合) + 4名(6試合) = 12試合
      expect(calculateMultiLeagueMatches(8, 2), equals(12));

      // 10名を3リーグに分割 ➔ 4名(6) + 3名(3) + 3名(3) = 12試合
      expect(calculateMultiLeagueMatches(10, 3), equals(12));
    });

    test('トーナメント形式の試合数がN-1で正しく算出されること', () {
      expect(calculateTournamentMatches(8), equals(7));
      expect(calculateTournamentMatches(16), equals(15));
      expect(calculateTournamentMatches(2), equals(1));
    });

    test('コート配分と試合時間・インターバルによる想定所要時間が正しく算出されること', () {
      // 12試合、2コート、試合3分、インターバル1分 (計4分/試合)
      // ラウンド数 = 12 / 2 = 6ラウンド ➔ 6 * 4分 = 24分
      final duration = calculateDurationMinutes(
        totalMatches: 12,
        courtCount: 2,
        matchMinutes: 3,
        intervalMinutes: 1,
      );
      expect(duration, equals(24));

      // 13試合、2コート ➔ 7ラウンド * 4分 = 28分
      final durationOdd = calculateDurationMinutes(
        totalMatches: 13,
        courtCount: 2,
        matchMinutes: 3,
        intervalMinutes: 1,
      );
      expect(durationOdd, equals(28));
    });
  });
}
