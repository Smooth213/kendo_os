import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_simple_scene_rule_form.dart';

void main() {
  group('🛡️ CategorySimpleSceneRuleForm Widget Tests', () {
    testWidgets('Renders simple scene rule form and handles type toggle', (
      WidgetTester tester,
    ) async {
      double time = 2.0;
      bool isRunning = true;
      bool hasHantei = false;
      String type = '一試合制';
      int overallTime = 30;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategorySimpleSceneRuleForm(
                  title: '⚔️ 錬成会ルール',
                  time: time,
                  isRunning: isRunning,
                  hasHantei: hasHantei,
                  renseikaiType: type,
                  overallTime: overallTime,
                  onTimeChanged: (val) => setState(() => time = val),
                  onRunningChanged: (val) => setState(() => isRunning = val),
                  onHanteiChanged: (val) => setState(() => hasHantei = val),
                  onTypeChanged: (val) => setState(() => type = val),
                  onOverallTimeChanged: (val) =>
                      setState(() => overallTime = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('⚔️ 錬成会ルール'), findsOneWidget);
      expect(find.text('錬成形式（試合方式）'), findsOneWidget);
      expect(find.text('一試合制'), findsOneWidget);
      expect(find.text('時間制'), findsOneWidget);
      expect(find.text('1試合の時間'), findsOneWidget);
      expect(find.text('流し（タイマーを止めない）'), findsOneWidget);

      // Select '時間制'
      await tester.tap(find.text('時間制'));
      await tester.pumpAndSettle();

      expect(type, '時間制');
      expect(find.text('全体の制限時間（分）'), findsOneWidget);
    });
  });
}
