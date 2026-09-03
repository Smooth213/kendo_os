import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/widgets/multi_player_candidate_chip.dart';

void main() {
  group('MultiPlayerCandidateTile Widget Tests', () {
    testWidgets('renders name and subtitle, and responds to checkbox tap', (
      tester,
    ) async {
      bool? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiPlayerCandidateTile(
              name: '山田 太郎',
              subtitle: '中学2年',
              isSelected: false,
              accentColor: Colors.red,
              onChanged: (val) => changedValue = val,
            ),
          ),
        ),
      );

      expect(find.text('山田 太郎'), findsOneWidget);
      expect(find.text('中学2年'), findsOneWidget);

      await tester.tap(find.text('山田 太郎'));
      await tester.pump();
      expect(changedValue, isTrue);
    });
  });
}
