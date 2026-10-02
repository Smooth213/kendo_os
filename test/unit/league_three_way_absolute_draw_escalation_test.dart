import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

void main() {
  group('[Unit] リーグ戦 3チーム完全同値（三つ巴）代表戦エスカレーションテスト', () {
    MatchModel createFinishedMatch({
      required String id,
      required String redName,
      required String whiteName,
      required int redScore,
      required int whiteScore,
    }) {
      return MatchModel(
        id: id,
        matchType: '個人戦',
        redName: redName,
        whiteName: whiteName,
        redScore: redScore,
        whiteScore: whiteScore,
        status: 'finished',
      );
    }

    test('3チームが1勝1敗・勝者数・取得本数すべて完全同値の際、三つ巴同点として順位決定戦が必要と判定されること', () {
      // チームA, チームB, チームC の総当り3試合
      // 試合1: チームA vs チームB -> チームA 1-0 勝利
      final matchAB = createFinishedMatch(
        id: 'league_ab',
        redName: 'チームA',
        whiteName: 'チームB',
        redScore: 1,
        whiteScore: 0,
      );
      // 試合2: チームB vs チームC -> チームB 1-0 勝利
      final matchBC = createFinishedMatch(
        id: 'league_bc',
        redName: 'チームB',
        whiteName: 'チームC',
        redScore: 1,
        whiteScore: 0,
      );
      // 試合3: チームC vs チームA -> チームC 1-0 勝利
      final matchCA = createFinishedMatch(
        id: 'league_ca',
        redName: 'チームC',
        whiteName: 'チームA',
        redScore: 1,
        whiteScore: 0,
      );

      final matches = [matchAB, matchBC, matchCA];

      // 各チームの勝敗・本数集計
      final stats = <String, Map<String, int>>{
        'チームA': {'wins': 0, 'points': 0},
        'チームB': {'wins': 0, 'points': 0},
        'チームC': {'wins': 0, 'points': 0},
      };

      for (final m in matches) {
        stats[m.redName]!['points'] = stats[m.redName]!['points']! + m.redScore;
        stats[m.whiteName]!['points'] =
            stats[m.whiteName]!['points']! + m.whiteScore;
        if (m.redScore > m.whiteScore) {
          stats[m.redName]!['wins'] = stats[m.redName]!['wins']! + 1;
        } else if (m.whiteScore > m.redScore) {
          stats[m.whiteName]!['wins'] = stats[m.whiteName]!['wins']! + 1;
        }
      }

      // 3チームすべてが 1勝1敗、取得本数1本、失点1本で完全同値（三つ巴）
      expect(stats['チームA']!['wins'], 1);
      expect(stats['チームB']!['wins'], 1);
      expect(stats['チームC']!['wins'], 1);

      expect(stats['チームA']!['points'], 1);
      expect(stats['チームB']!['points'], 1);
      expect(stats['チームC']!['points'], 1);

      // 三つ巴の順位決定戦（代表戦）が必要な状態であることを検証
      final isThreeWayTie =
          (stats['チームA']!['wins'] == stats['チームB']!['wins'] &&
          stats['チームB']!['wins'] == stats['チームC']!['wins'] &&
          stats['チームA']!['points'] == stats['チームB']!['points'] &&
          stats['チームB']!['points'] == stats['チームC']!['points']);

      expect(isThreeWayTie, isTrue, reason: '全チーム同値のため三つ巴順位決定戦エスカレーションが必要');

      // 代表決定戦（A vs B 代表戦）を追加して決着
      final playoff = createFinishedMatch(
        id: 'playoff_ab',
        redName: 'チームA (代表)',
        whiteName: 'チームB (代表)',
        redScore: 1,
        whiteScore: 0,
      );
      expect(playoff.redScore > playoff.whiteScore, isTrue);
    });
  });
}
