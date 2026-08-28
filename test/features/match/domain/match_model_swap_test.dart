import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('MatchModel swapRedAndWhite tests', () {
    test('keeps player names and swaps scores and event sides correctly', () {
      final initialMatch = MatchModel(
        id: 'match-swap-1',
        matchType: '先鋒',
        redName: '誠道館 : 山田',
        whiteName: 'ライバル道場 : 田中',
        redScore: 2,
        whiteScore: 1,
        events: [
          ScoreEvent(
            id: 'ev-1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
          ScoreEvent(
            id: 'ev-2',
            side: Side.white,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
          ScoreEvent(
            id: 'ev-3',
            side: Side.red,
            strikeType: StrikeType.dou,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
          ScoreEvent(
            id: 'ev-4',
            side: Side.red,
            isHansoku: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final swapped = initialMatch.swapRedAndWhite();

      // 選手名・所属チームは維持されること
      expect(swapped.redName, '誠道館 : 山田');
      expect(swapped.whiteName, 'ライバル道場 : 田中');

      // スコアは左右入れ替わること
      expect(swapped.redScore, 1);
      expect(swapped.whiteScore, 2);

      // 各技の所属陣営（Side）が左右反転すること
      expect(swapped.events.length, 4);
      expect(swapped.events[0].side, Side.white);
      expect(swapped.events[0].strikeType, StrikeType.men);
      expect(swapped.events[1].side, Side.red);
      expect(swapped.events[1].strikeType, StrikeType.kote);
      expect(swapped.events[2].side, Side.white);
      expect(swapped.events[2].strikeType, StrikeType.dou);
      expect(swapped.events[3].side, Side.white);
      expect(swapped.events[3].isHansoku, true);
    });
  });
}
