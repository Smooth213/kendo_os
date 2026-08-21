import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_group_helper.dart';

void main() {
  group('OfficialRecordGroupHelper Tests', () {
    test('groupMatchesByCategory correctly groups matches', () {
      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          redName: 'A',
          whiteName: 'B',
          matchType: '団体戦',
          groupName: '1回戦',
          category: '小学生の部',
        ),
        MatchModel(
          id: 'm2',
          tournamentId: 't1',
          redName: 'C',
          whiteName: 'D',
          matchType: '団体戦',
          groupName: '1回戦',
          category: '小学生の部',
        ),
      ];

      final grouped = OfficialRecordGroupHelper.groupMatchesByCategory(matches);
      expect(grouped.containsKey('小学生の部'), isTrue);
      expect(grouped['小学生の部']!['1回戦']!.length, 2);
    });
  });
}
