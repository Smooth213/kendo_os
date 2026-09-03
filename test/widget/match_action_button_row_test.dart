import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_action_button_row.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

void main() {
  group('MatchActionButtonRow Widget Tests', () {
    testWidgets('renders button with label and responds to single tap', (
      tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchActionButtonRow(
              label: '試合終了',
              confirmBehavior: 'single',
              onAction: () => actionTriggered = true,
              isViewOnly: false,
              backgroundColor: AppKendoColors.blueAccent,
              promptMessage: 'タップしてください',
            ),
          ),
        ),
      );

      expect(find.text('試合終了'), findsOneWidget);

      await tester.tap(find.text('試合終了'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('responds to double tap when confirmBehavior is double', (
      tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchActionButtonRow(
              label: '記録を確定して次へ',
              icon: Icons.check_circle,
              confirmBehavior: 'double',
              onAction: () => actionTriggered = true,
              isViewOnly: false,
              backgroundColor: AppKendoColors.indigo,
              promptMessage: 'ダブルタップで確定してください',
            ),
          ),
        ),
      );

      expect(find.text('記録を確定して次へ'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.tap(find.text('記録を確定して次へ'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('記録を確定して次へ'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
    });
  });
}
