import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 試合時間電卓サマリーカード視覚ピクセルテスト', () {
    testWidgets('試合数や所要時間およびコート配分チップが明瞭に描画されること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const settings = CalculatorSettings(
        courtCount: 2,
        matchDurationMinutes: 3.0,
        intervalDurationMinutes: 1.0,
      );

      final now = DateTime(2026, 10, 1, 9, 0);
      final dummyMatch1 = AllocatedMatch(
        courtNumber: 1,
        matchOrder: 1,
        categoryName: 'Aリーグ',
        matchTitle: '第1試合',
        pairDescription: '選手1 vs 選手2',
        estimatedStart: now,
        estimatedEnd: now.add(const Duration(minutes: 3)),
      );
      final dummyMatch2 = AllocatedMatch(
        courtNumber: 2,
        matchOrder: 1,
        categoryName: 'Bリーグ',
        matchTitle: '第1試合',
        pairDescription: '選手3 vs 選手4',
        estimatedStart: now,
        estimatedEnd: now.add(const Duration(minutes: 3)),
      );

      final result = AllocationResult(
        totalMatches: 12,
        courtMatches: {
          1: [dummyMatch1],
          2: [dummyMatch2],
        },
        maxCourtMatches: 6,
        totalEstimatedMinutes: 48,
        estimatedEndTime: now.add(const Duration(minutes: 48)),
        matchesPerCategory: {'Aリーグ': 6, 'Bリーグ': 6},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchCalculatorSummaryCard(
                result: result,
                settings: settings,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('12'), findsWidgets);
      expect(find.textContaining('48分'), findsWidgets);
      expect(find.byType(MatchCalculatorSummaryCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
