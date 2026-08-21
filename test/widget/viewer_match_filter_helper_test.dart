import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_filter_helper.dart';

void main() {
  group('ViewerMatchFilterHelper Tests', () {
    test(
      'extractActiveMatches correctly separates in_progress and waiting',
      () {
        final matches = [
          MatchModel(
            id: 'm1',
            tournamentId: 't1',
            redName: 'A',
            whiteName: 'B',
            matchType: '団体戦',
            groupName: '1回戦',
            status: 'in_progress',
          ),
          MatchModel(
            id: 'm2',
            tournamentId: 't1',
            redName: 'A',
            whiteName: 'B',
            matchType: '団体戦',
            groupName: '1回戦',
            status: 'waiting',
          ),
          MatchModel(
            id: 'm3',
            tournamentId: 't1',
            redName: 'C',
            whiteName: 'D',
            matchType: '団体戦',
            groupName: '2回戦',
            status: 'waiting',
          ),
        ];

        final (inProgress, waiting) =
            ViewerMatchFilterHelper.extractActiveMatches(matches);

        expect(inProgress.length, 1);
        expect(waiting.length, 1);
        expect(inProgress.first.id, 'm1');
        expect(waiting.first.id, 'm3');
      },
    );
  });
}
