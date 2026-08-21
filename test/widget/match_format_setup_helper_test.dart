import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';

void main() {
  group('MatchFormatSetupHelper Tests', () {
    test('parseCategoryToState parses correctly', () {
      expect(MatchFormatSetupHelper.parseCategoryToState('初心者の部'), (
        '初心者',
        '全体',
      ));
      expect(MatchFormatSetupHelper.parseCategoryToState('幼年の部'), ('幼年', '全体'));
      expect(MatchFormatSetupHelper.parseCategoryToState('小学生低学年の部'), (
        '小学生',
        '低学年',
      ));
      expect(MatchFormatSetupHelper.parseCategoryToState('中学生男子の部'), (
        '中学生',
        '男子',
      ));
      expect(MatchFormatSetupHelper.parseCategoryToState('高校生の部'), (
        '高校生',
        '全体',
      ));
      expect(MatchFormatSetupHelper.parseCategoryToState('一般の部'), (
        '大学・一般',
        '一般',
      ));
    });

    test('generatePositions generates correct lists', () {
      expect(MatchFormatSetupHelper.generatePositions(1), ['選手']);
      expect(MatchFormatSetupHelper.generatePositions(3), ['先鋒', '中堅', '大将']);
      expect(MatchFormatSetupHelper.generatePositions(5), [
        '先鋒',
        '次鋒',
        '中堅',
        '副将',
        '大将',
      ]);
      expect(MatchFormatSetupHelper.generatePositions(7), [
        '先鋒',
        '次鋒',
        '5将',
        '中堅',
        '3将',
        '副将',
        '大将',
      ]);
    });

    test('calculateTeamSize handles individual and team formats', () {
      expect(
        MatchFormatSetupHelper.calculateTeamSize(
          matchType: '個人戦',
          selectedTeamId: null,
          registeredTeams: [],
        ),
        1,
      );
      expect(
        MatchFormatSetupHelper.calculateTeamSize(
          matchType: '団体戦（3人制）',
          selectedTeamId: null,
          registeredTeams: [],
        ),
        3,
      );
      expect(
        MatchFormatSetupHelper.calculateTeamSize(
          matchType: '団体戦（5人制）',
          selectedTeamId: null,
          registeredTeams: [],
        ),
        5,
      );
    });
  });
}
