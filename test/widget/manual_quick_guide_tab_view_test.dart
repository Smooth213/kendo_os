import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/manual/manual_quick_guide_tab_view.dart';

void main() {
  group('🛡️ ManualQuickGuideTabView Widget Tests', () {
    testWidgets('Renders ManualQuickGuideTabView structure correctly', (
      tester,
    ) async {
      bool printTapped = false;
      bool shareTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualQuickGuideTabView(
              assetPath: 'assets/manuals/test.pdf',
              fileName: 'test.pdf',
              onPrintPressed: () => printTapped = true,
              onSharePressed: () => shareTapped = true,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('A4印刷'), findsOneWidget);
      expect(find.text('共有/保存'), findsOneWidget);

      await tester.tap(find.text('A4印刷'));
      expect(printTapped, isTrue);

      await tester.tap(find.text('共有/保存'));
      expect(shareTapped, isTrue);

      await tester.pump(const Duration(seconds: 1));
    });
  });
}
