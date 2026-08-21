import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_league_title_helper.dart';

void main() {
  group('ViewerLeagueTitleHelper Tests', () {
    test('generateDescriptiveLeagueTitle generates title for team league', () {
      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          redName: 'Aチーム',
          whiteName: 'Bチーム',
          matchType: '団体戦',
        ),
        MatchModel(
          id: 'm2',
          tournamentId: 't1',
          redName: 'Aチーム',
          whiteName: 'Cチーム',
          matchType: '団体戦',
        ),
        MatchModel(
          id: 'm3',
          tournamentId: 't1',
          redName: 'Bチーム',
          whiteName: 'Cチーム',
          matchType: '団体戦',
        ),
      ];

      final title = ViewerLeagueTitleHelper.generateDescriptiveLeagueTitle(
        matches,
        ['Aチーム'],
      );

      expect(title, contains('Aチーム'));
      expect(title, contains('3チームリーグ'));
      expect(title, contains('全3試合'));
    });
  });
}
