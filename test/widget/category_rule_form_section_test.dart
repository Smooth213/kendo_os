import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_form_section.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets('CategoryRuleFormSection renders title and time stepper', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryRuleFormSection(
              title: '通常戦ルール',
              isNormal: true,
              themeColors: themeColors,
              matchType: '個人戦',
              isRenseikai: false,
              categoryKey: '一般',
              matchTime: 3.0,
              isRunningTime: false,
              ipponLimit: 2,
              hansokuLimit: 2,
              hasHantei: false,
              hasExtension: true,
              isEnchoUnlimited: true,
              enchoTime: 3.0,
              enchoCount: 0,
              kachinukiUnlimitedType: '大将対大将',
              hasLeagueDaihyo: false,
              isDaihyoIpponShobu: true,
              winPoint: 0.0,
              lossPoint: 0.0,
              drawPoint: 0.0,
              renseikaiType: '一試合制',
              overallTime: 30,
              daihyoMatchTime: 0.0,
              daihyoHasExtension: true,
              daihyoEnchoTime: 3.0,
              daihyoEnchoCount: -2,
              daihyoHasHantei: false,
              formatMinutes: (m) => '$m分',
              onMatchTimeChanged: (_) {},
              onIsRunningTimeChanged: (_) {},
              onRenseikaiTypeChanged: (_) {},
              onOverallTimeChanged: (_) {},
              onKachinukiUnlimitedTypeChanged: (_) {},
              onHasExtensionChanged: (_) {},
              onIsEnchoUnlimitedChanged: (_) {},
              onEnchoCountChanged: (_) {},
              onEnchoTimeChanged: (_) {},
              onHasHanteiChanged: (_) {},
              onHasLeagueDaihyoChanged: (_) {},
              onIsDaihyoIpponShobuChanged: (_) {},
              onDaihyoMatchTimeChanged: (_) {},
              onDaihyoHasExtensionChanged: (_) {},
              onDaihyoEnchoTimeChanged: (_) {},
              onDaihyoEnchoCountChanged: (_) {},
              onDaihyoHasHanteiChanged: (_) {},
              onWinPointChanged: (_) {},
              onLossPointChanged: (_) {},
              onDrawPointChanged: (_) {},
              onIpponLimitChanged: (_) {},
              onHansokuLimitChanged: (_) {},
              onKeywordsChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('通常戦ルール'), findsOneWidget);
    expect(find.text('試合時間'), findsOneWidget);
    expect(find.text('クイック選択'), findsOneWidget);
  });
}
