import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_advanced_settings_section.dart';

void main() {
  group('[Widget] CategoryRuleAdvancedSettingsSection 単体検証', () {
    testWidgets(
      'CategoryRuleAdvancedSettingsSectionにおいて 一本および反則の上限設定が描画されること',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CategoryRuleAdvancedSettingsSection(
                  isNormal: true,
                  categoryKey: '一般',
                  ipponLimit: 2,
                  hansokuLimit: 2,
                  onIpponLimitChanged: (_) {},
                  onHansokuLimitChanged: (_) {},
                  onKeywordsChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('詳細設定（反則ルール・上位戦設定）'), findsOneWidget);
      },
    );

    testWidgets(
      'CategoryRuleAdvancedSettingsSectionにおいて 詳細モード用のキーワード入力欄が描画されること',
      (tester) async {
        final controller = TextEditingController(text: '準決勝, 決勝');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CategoryRuleAdvancedSettingsSection(
                  isNormal: false,
                  categoryKey: '一般',
                  ipponLimit: 2,
                  hansokuLimit: 2,
                  keywordsController: controller,
                  onIpponLimitChanged: (_) {},
                  onHansokuLimitChanged: (_) {},
                  onKeywordsChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('自動判別用キーワード設定'), findsOneWidget);
        expect(find.text('準決勝以上'), findsOneWidget);
        expect(find.text('決勝のみ'), findsOneWidget);
      },
    );
  });
}
