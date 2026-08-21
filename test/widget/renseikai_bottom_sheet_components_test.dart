import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_player_candidate_resolver.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/renseikai_player_input_field.dart';

void main() {
  group('Renseikai BottomSheet Components Tests', () {
    test('RenseikaiPlayerCandidateResolver category match logic', () {
      expect(
        RenseikaiPlayerCandidateResolver.isCategoryMatch('小学生低学年の部', '小学生低学年'),
        isTrue,
      );
      expect(
        RenseikaiPlayerCandidateResolver.isCategoryMatch('中学生の部', '小学生高学年'),
        isFalse,
      );
    });

    testWidgets('RenseikaiPlayerInputField renders choices and field', (
      tester,
    ) async {
      final ctrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RenseikaiPlayerInputField(
              teamName: '練馬道場',
              players: const ['山田', '田中'],
              masterSet: const {'山田', '田中'},
              controller: ctrl,
              isDark: false,
              textColor: Colors.black,
              inputBgColor: Colors.grey.shade100,
              borderColor: Colors.grey,
              onPlayerSelected: (val) {
                ctrl.text = val;
              },
            ),
          ),
        ),
      );

      expect(find.text('練馬道場 の選手を選択:'), findsOneWidget);
      expect(find.text('山田'), findsOneWidget);
      expect(find.text('田中'), findsOneWidget);
    });
  });
}
