import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/share_provider.dart';

void main() {
  group('[Unit] Share Service Kendo Score Formatting 検証 テスト', () {
    late ProviderContainer container;
    late ShareService shareService;

    setUp(() {
      container = ProviderContainer();
      shareService = container.read(shareProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('㋙においてFormatting 1 - 0 with first point Koteこと', () {
      final match = MatchModel(
        id: 'test_match_1',
        matchType: 'individual',
        redName: '佐々木 武',
        whiteName: '選手',
        redScore: 1,
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'ev1',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final display = shareService.buildMatchScoreDisplay(match);
      expect(display, contains('🔴 佐々木 武 1㋙ - 0 選手 ⚪️'));
    });

    test(
      'メにおいてFormatting 2 - 1 with Red first Kote (㋙) + normal Kote (コ) and White normal Menこと',
      () {
        final match = MatchModel(
          id: 'test_match_2',
          matchType: 'individual',
          redName: '佐々木 武',
          whiteName: '選手',
          redScore: 2,
          whiteScore: 1,
          events: [
            ScoreEvent(
              id: 'ev1',
              side: Side.red,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
            ScoreEvent(
              id: 'ev2',
              side: Side.white,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
            ScoreEvent(
              id: 'ev3',
              side: Side.red,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: DateTime.now(),
            ),
          ],
        );

        final display = shareService.buildMatchScoreDisplay(match);
        expect(display, contains('🔴 佐々木 武 2㋙コ - 1メ 選手 ⚪️'));
      },
    );

    test('Formatting Hansoku penalty points (反) correctlyこと', () {
      final match = MatchModel(
        id: 'test_match_3',
        matchType: 'individual',
        redName: '佐々木 武',
        whiteName: '選手',
        redScore: 0,
        whiteScore: 1,
        events: [
          ScoreEvent(
            id: 'ev1',
            side: Side.red,
            isHansoku: true,
            timestamp: DateTime.now(),
          ),
          ScoreEvent(
            id: 'ev2',
            side: Side.red,
            isHansoku: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final display = shareService.buildMatchScoreDisplay(match);
      expect(display, contains('🔴 佐々木 武 0 - 1反 選手 ⚪️'));
    });

    test('Correctly excludes undone/canceled pointsこと', () {
      final match = MatchModel(
        id: 'test_match_4',
        matchType: 'individual',
        redName: '佐々木 武',
        whiteName: '選手',
        redScore: 1,
        whiteScore: 0,
        events: [
          ScoreEvent(
            id: 'ev1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
          // Undo event for ev1
          ScoreEvent(
            id: 'ev2',
            side: Side.red,
            isUndo: true,
            targetId: 'ev1',
            timestamp: DateTime.now(),
          ),
          // Actual first point of match
          ScoreEvent(
            id: 'ev3',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final display = shareService.buildMatchScoreDisplay(match);
      expect(display, contains('🔴 佐々木 武 1㋙ - 0 選手 ⚪️'));
      expect(display, isNot(contains('メ')));
    });
  });
}
