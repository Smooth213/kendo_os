import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_team_section.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  testWidgets('CategoryRuleTeamSection renders daihyo settings', (
    tester,
  ) async {
    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryRuleTeamSection(
              isLeague: true,
              isNormal: true,
              categoryKey: '一般',
              themeColors: themeColors,
              hasLeagueDaihyo: true,
              isDaihyoIpponShobu: true,
              daihyoMatchTime: 3.0,
              daihyoHasExtension: true,
              daihyoEnchoTime: 3.0,
              daihyoEnchoCount: -2,
              daihyoHasHantei: true,
              winPoint: 3.0,
              lossPoint: 0.0,
              drawPoint: 1.0,
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
              formatMinutes: (m) => '$m分',
            ),
          ),
        ),
      ),
    );

    expect(find.text('代表戦あり（団体戦用）'), findsOneWidget);
    expect(find.text('１本勝負 (デフォルト)'), findsOneWidget);
    expect(find.text('代表戦の延長を有効にする'), findsOneWidget);
    expect(find.text('代表戦の判定を有効にする'), findsOneWidget);
  });
}
