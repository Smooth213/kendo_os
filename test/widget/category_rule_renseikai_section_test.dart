import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_renseikai_section.dart';

void main() {
  testWidgets(
    'CategoryRuleRenseikaiSection renders renseikai settings when isRenseikai is true',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleRenseikaiSection(
                isRenseikai: true,
                isKachinuki: false,
                isNormal: true,
                categoryKey: '一般',
                isRunningTime: true,
                renseikaiType: '一試合制',
                overallTime: 30,
                kachinukiUnlimitedType: '大将対大将',
                onIsRunningTimeChanged: (_) {},
                onRenseikaiTypeChanged: (_) {},
                onOverallTimeChanged: (_) {},
                onKachinukiUnlimitedTypeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('ランニングタイム計測'), findsOneWidget);
      expect(find.text('進行形式'), findsOneWidget);
      expect(find.text('一試合制'), findsOneWidget);
    },
  );

  testWidgets(
    'CategoryRuleRenseikaiSection renders kachinuki settings when isKachinuki is true',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleRenseikaiSection(
                isRenseikai: false,
                isKachinuki: true,
                isNormal: true,
                categoryKey: '一般',
                isRunningTime: false,
                renseikaiType: '一試合制',
                overallTime: 30,
                kachinukiUnlimitedType: '大将対大将',
                onIsRunningTimeChanged: (_) {},
                onRenseikaiTypeChanged: (_) {},
                onOverallTimeChanged: (_) {},
                onKachinukiUnlimitedTypeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('大将 VS 大将 のときの挙動'), findsOneWidget);
      expect(find.text('延長戦を行う (デフォルト)'), findsOneWidget);
    },
  );
}
