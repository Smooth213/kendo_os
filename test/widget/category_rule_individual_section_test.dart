import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_individual_section.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets('CategoryRuleIndividualSection renders extension settings', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryRuleIndividualSection(
              isLeague: true,
              isNormal: true,
              categoryKey: '一般',
              themeColors: themeColors,
              hasExtension: true,
              isEnchoUnlimited: false,
              enchoCount: 1,
              enchoTime: 2.0,
              hasHantei: true,
              winPoint: 3.0,
              lossPoint: 0.0,
              drawPoint: 1.0,
              onHasExtensionChanged: (_) {},
              onIsEnchoUnlimitedChanged: (_) {},
              onEnchoCountChanged: (_) {},
              onEnchoTimeChanged: (_) {},
              onHasHanteiChanged: (_) {},
              onWinPointChanged: (_) {},
              onLossPointChanged: (_) {},
              onDrawPointChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('延長戦を有効にする'), findsOneWidget);
    expect(find.text('時間・回数無制限'), findsOneWidget);
    expect(find.text('最大延長回数'), findsOneWidget);
    expect(find.text('延長戦の時間'), findsOneWidget);
  });
}
