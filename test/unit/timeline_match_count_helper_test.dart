import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_match_count_helper.dart';

void main() {
  group('TimelineMatchCountHelper', () {
    test('個人戦は各マッチを1試合としてカウントする', () {
      final matches = [
        const MatchModel(
          id: '1',
          matchType: '個人戦',
          redName: '選手A',
          whiteName: '選手B',
        ),
        const MatchModel(
          id: '2',
          matchType: '選手',
          redName: '選手C',
          whiteName: '選手D',
        ),
        const MatchModel(
          id: '3',
          matchType: 'individual',
          redName: '選手E',
          whiteName: '選手F',
        ),
      ];

      final count = TimelineMatchCountHelper.countMatches(matches);
      expect(count, equals(3));
    });

    test('団体戦は同一 groupName の複数対戦を1試合としてカウントする', () {
      // 5人制の団体戦1試合（先鋒〜大将）
      final matches = [
        const MatchModel(
          id: 't1_1',
          matchType: '先鋒',
          redName: '道場A : 選手1',
          whiteName: '道場B : 選手1',
          groupName: 'group_team_match_1',
        ),
        const MatchModel(
          id: 't1_2',
          matchType: '次鋒',
          redName: '道場A : 選手2',
          whiteName: '道場B : 選手2',
          groupName: 'group_team_match_1',
        ),
        const MatchModel(
          id: 't1_3',
          matchType: '中堅',
          redName: '道場A : 選手3',
          whiteName: '道場B : 選手3',
          groupName: 'group_team_match_1',
        ),
        const MatchModel(
          id: 't1_4',
          matchType: '副将',
          redName: '道場A : 選手4',
          whiteName: '道場B : 選手4',
          groupName: 'group_team_match_1',
        ),
        const MatchModel(
          id: 't1_5',
          matchType: '大将',
          redName: '道場A : 選手5',
          whiteName: '道場B : 選手5',
          groupName: 'group_team_match_1',
        ),
        const MatchModel(
          id: 't1_6',
          matchType: '代表戦',
          redName: '道場A : 選手5',
          whiteName: '道場B : 選手5',
          groupName: 'group_team_match_1',
        ),
      ];

      final count = TimelineMatchCountHelper.countMatches(matches);
      // 6対戦あるが、団体戦1試合なので 1 となる
      expect(count, equals(1));
    });

    test('複数の団体戦がある場合、団体戦の試合数を正確にカウントする', () {
      final matches = [
        // 団体戦1（3人制）
        const MatchModel(
          id: 'm1',
          matchType: '先鋒',
          redName: '道場A : 選手1',
          whiteName: '道場B : 選手1',
          groupName: 'group_1',
        ),
        const MatchModel(
          id: 'm2',
          matchType: '中堅',
          redName: '道場A : 選手2',
          whiteName: '道場B : 選手2',
          groupName: 'group_1',
        ),
        const MatchModel(
          id: 'm3',
          matchType: '大将',
          redName: '道場A : 選手3',
          whiteName: '道場B : 選手3',
          groupName: 'group_1',
        ),
        // 団体戦2（3人制）
        const MatchModel(
          id: 'm4',
          matchType: '先鋒',
          redName: '道場A : 選手1',
          whiteName: '道場C : 選手1',
          groupName: 'group_2',
        ),
        const MatchModel(
          id: 'm5',
          matchType: '中堅',
          redName: '道場A : 選手2',
          whiteName: '道場C : 選手2',
          groupName: 'group_2',
        ),
        const MatchModel(
          id: 'm6',
          matchType: '大将',
          redName: '道場A : 選手3',
          whiteName: '道場C : 選手3',
          groupName: 'group_2',
        ),
      ];

      final count = TimelineMatchCountHelper.countMatches(matches);
      // 6対戦あるが、団体戦2試合なので 2 となる
      expect(count, equals(2));
    });

    test('団体戦と個人戦が混在する場合、団体戦試合数 + 個人戦試合数 を返す', () {
      final matches = [
        // 団体戦1（2対戦）
        const MatchModel(
          id: 't1',
          matchType: '先鋒',
          redName: '道場A : 選手1',
          whiteName: '道場B : 選手1',
          groupName: 'group_team_1',
        ),
        const MatchModel(
          id: 't2',
          matchType: '大将',
          redName: '道場A : 選手2',
          whiteName: '道場B : 選手2',
          groupName: 'group_team_1',
        ),
        // 個人戦2試合
        const MatchModel(
          id: 'ind1',
          matchType: '個人戦',
          redName: '選手X',
          whiteName: '選手Y',
        ),
        const MatchModel(
          id: 'ind2',
          matchType: '個人戦',
          redName: '選手Z',
          whiteName: '選手W',
        ),
      ];

      final count = TimelineMatchCountHelper.countMatches(matches);
      // 団体戦1試合 + 個人戦2試合 = 3
      expect(count, equals(3));
    });

    test('勝ち抜き戦は団体戦としてカウントされる', () {
      final matches = [
        const MatchModel(
          id: 'k1',
          matchType: '勝ち抜き戦',
          redName: '道場A : 選手1',
          whiteName: '道場B : 選手1',
          groupName: 'group_kachi_1',
          isKachinuki: true,
        ),
      ];

      final count = TimelineMatchCountHelper.countMatches(matches);
      expect(count, equals(1));
    });
  });
}
