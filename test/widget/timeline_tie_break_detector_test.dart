import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_tie_break_detector.dart';

void main() {
  group('[Widget] TimelineTieBreakDetector テスト', () {
    test(
      'detectTieGroups returns empty list when rule is null or matches emptyであること',
      () {
        final ties = TimelineTieBreakDetector.detectTieGroups(
          normalMatches: [],
          rule: null,
        );
        expect(ties, isEmpty);
      },
    );

    test(
      'detectTieGroups returns empty list when rule has no matchesであること',
      () {
        final ties = TimelineTieBreakDetector.detectTieGroups(
          normalMatches: [],
          rule: MatchRule(),
        );
        expect(ties, isEmpty);
      },
    );
  });
}
