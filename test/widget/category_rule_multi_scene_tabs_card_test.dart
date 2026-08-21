import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_multi_scene_tabs_card.dart';

void main() {
  testWidgets(
    'CategoryRuleMultiSceneTabsCard renders checkboxes and tab views',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleMultiSceneTabsCard(
                useRenseikaiRule: true,
                useHonsenRule: true,
                useMoushiawaseRule: true,
                renseikaiTime: 2.0,
                renseikaiIsRunningTime: true,
                renseikaiHasHantei: true,
                renseikaiType: '一試合制',
                renseikaiOverallTime: 30,
                moushiawaseTime: 2.0,
                moushiawaseIsRunningTime: true,
                moushiawaseHasHantei: true,
                moushiawaseType: '一試合制',
                moushiawaseOverallTime: 30,
                honsenRuleSection: const Text('本戦セクション'),
                onUseRenseikaiRuleChanged: (_) {},
                onUseHonsenRuleChanged: (_) {},
                onUseMoushiawaseRuleChanged: (_) {},
                onRenseikaiTimeChanged: (_) {},
                onRenseikaiRunningChanged: (_) {},
                onRenseikaiHanteiChanged: (_) {},
                onRenseikaiTypeChanged: (_) {},
                onRenseikaiOverallTimeChanged: (_) {},
                onMoushiawaseTimeChanged: (_) {},
                onMoushiawaseRunningChanged: (_) {},
                onMoushiawaseHanteiChanged: (_) {},
                onMoushiawaseTypeChanged: (_) {},
                onMoushiawaseOverallTimeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('実施するルールシーンの選択'), findsOneWidget);
      expect(find.text('⚔️ 錬成会ルール'), findsWidgets);
      expect(find.text('🏆 本戦ルール'), findsWidgets);
      expect(find.text('🤝 申し合わせルール'), findsWidgets);
    },
  );
}
