import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_data_sanitizer.dart';

void main() {
  group('🛡️ MatchDataSanitizer Unit Tests', () {
    test(
      '1. sanitizeFirestoreData correctly maps numbers and nested structures',
      () {
        final input = {'order': 1, 'matchTimeMinutes': 4, 'redScore': 2.0};

        final sanitized = MatchDataSanitizer.sanitizeFirestoreData(input);
        expect(sanitized['order'], 1.0);
        expect(sanitized['matchTimeMinutes'], 4.0);
        expect(sanitized['redScore'], 2);
      },
    );

    test(
      '2. healRepresentativeMatch heals corrupted or finished state when events empty',
      () {
        final match = MatchModel(
          id: 'm1',
          matchType: '代表戦',
          redName: 'red',
          whiteName: 'white',
          status: 'finished',
          events: const [],
        );

        final healed = MatchDataSanitizer.healRepresentativeMatch(match);
        expect(healed.status, 'waiting');
        expect(healed.timerStartedAt, null);
      },
    );
  });
}
