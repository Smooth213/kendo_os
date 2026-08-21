import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart';

void main() {
  group('MatchFormatFormState Tests', () {
    test('getCategory returns formatted string correctly', () {
      final state1 = MatchFormatFormState(
        selectedMajorCategory: '小学生',
        selectedMinorCategory: '高学年',
      );
      expect(state1.getCategory(), '小学生高学年の部');

      final state2 = MatchFormatFormState(
        selectedMajorCategory: '初心者',
        selectedMinorCategory: '男子',
      );
      expect(state2.getCategory(), '初心者の部');
    });

    test('applyMatchRule updates fields properly', () {
      final state = MatchFormatFormState();
      final rule = MatchRule(
        matchTimeMinutes: 4.0,
        isRunningTime: true,
        enchoCount: 1,
        enchoTimeMinutes: 2.0,
      );

      final overall = TextEditingController();
      final win = TextEditingController();
      final loss = TextEditingController();
      final draw = TextEditingController();

      state.applyMatchRule(
        rule,
        overallTimeController: overall,
        winPointController: win,
        lossPointController: loss,
        drawPointController: draw,
      );

      expect(state.matchTime, 4.0);
      expect(state.isRunningTime, isTrue);
      expect(state.hasExtension, isTrue);
      expect(state.extTime, 2.0);
    });
  });
}
