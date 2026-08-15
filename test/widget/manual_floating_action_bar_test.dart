import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_floating_action_bar.dart';

void main() {
  group('🛡️ ManualFloatingActionBar Widget Tests', () {
    testWidgets('Renders buttons and triggers callbacks', (
      WidgetTester tester,
    ) async {
      bool primaryTapped = false;
      bool secondaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualFloatingActionBar(
              primaryLabel: 'A4印刷',
              primaryIcon: Icons.print,
              onPrimaryPressed: () => primaryTapped = true,
              secondaryLabel: '共有/保存',
              secondaryIcon: Icons.share,
              onSecondaryPressed: () => secondaryTapped = true,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('A4印刷'), findsOneWidget);
      expect(find.text('共有/保存'), findsOneWidget);

      await tester.tap(find.text('A4印刷'));
      expect(primaryTapped, isTrue);

      await tester.tap(find.text('共有/保存'));
      expect(secondaryTapped, isTrue);
    });

    testWidgets('Renders in dark mode correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ManualFloatingActionBar(
              primaryLabel: 'PDFを開く',
              primaryIcon: Icons.open_in_new,
              secondaryLabel: '共有する',
              secondaryIcon: Icons.share,
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('PDFを開く'), findsOneWidget);
      expect(find.text('共有する'), findsOneWidget);
    });
  });
}
