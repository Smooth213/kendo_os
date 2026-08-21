import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_span_builder.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

void main() {
  group('🛡️ KachinukiSpanBuilder Unit Tests', () {
    test('1. parseName handles formatted and normal names', () {
      expect(KachinukiSpanBuilder.parseName('青龍館: 山田 太郎'), {
        'last': '山田',
        'first': '太郎',
      });
      expect(KachinukiSpanBuilder.parseName('佐藤'), {'last': '佐藤', 'first': ''});
      expect(KachinukiSpanBuilder.parseName('(欠員)'), {'last': '', 'first': ''});
    });

    test('2. buildSpans generates correct spans for continuous matches', () {
      final matches = [
        MatchProjection(
          id: 'm1',
          tournamentId: 't1',
          matchType: '無限勝ち抜き',
          matchOrder: 1,
          groupName: 'group1',
          isKachinuki: true,
          remainingSeconds: 0,
          timerIsRunning: false,
          note: '',
          redName: '青龍館: 山田 太郎',
          whiteName: '白虎館: 佐藤 一郎',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          redRemaining: const ['青龍館: 鈴木 次郎'],
          whiteRemaining: const ['白虎館: 田中 三郎'],
        ),
        MatchProjection(
          id: 'm2',
          tournamentId: 't1',
          matchType: '無限勝ち抜き',
          matchOrder: 2,
          groupName: 'group1',
          isKachinuki: true,
          remainingSeconds: 0,
          timerIsRunning: false,
          note: '',
          redName: '青龍館: 山田 太郎',
          whiteName: '白虎館: 田中 三郎',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
          redRemaining: const ['青龍館: 鈴木 次郎'],
          whiteRemaining: const [],
        ),
      ];

      final spans = KachinukiSpanBuilder.buildSpans(matches);
      expect(spans.redSpans.length, 2);
      expect(spans.redSpans.first.lastName, '山田');
      expect(spans.redSpans.first.startIndex, 0);
      expect(spans.redSpans.first.endIndex, 1);

      expect(spans.whiteSpans.length, 2);
      expect(spans.whiteSpans.first.lastName, '佐藤');
      expect(spans.whiteSpans.first.startIndex, 0);
      expect(spans.whiteSpans.first.endIndex, 0);
    });
  });
}
