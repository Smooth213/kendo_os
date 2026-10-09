import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_form_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] CategoryRuleFormSection 形試合設定検証', () {
    testWidgets('個人戦において形・基本判定試合スイッチが描画されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      bool isKata = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CategoryRuleFormSection(
                    title: '通常戦ルール',
                    isNormal: true,
                    themeColors: themeColors,
                    matchType: '個人戦',
                    isRenseikai: false,
                    categoryKey: '一般',
                    matchTime: 3.0,
                    isRunningTime: false,
                    isIpponShobu: false,
                    ipponLimit: 2,
                    hansokuLimit: 2,
                    hasHantei: false,
                    hasExtension: false,
                    isEnchoUnlimited: false,
                    enchoTime: 2.0,
                    enchoCount: 0,
                    kachinukiUnlimitedType: '大将対大将',
                    hasLeagueDaihyo: false,
                    isDaihyoIpponShobu: true,
                    winPoint: 0,
                    lossPoint: 0,
                    drawPoint: 0,
                    renseikaiType: '一試合制',
                    overallTime: 30,
                    daihyoMatchTime: 0,
                    daihyoHasExtension: false,
                    daihyoEnchoTime: 0,
                    daihyoEnchoCount: 0,
                    daihyoHasHantei: false,
                    isKataMatch: isKata,
                    formatMinutes: (m) => '${m.toInt()}分',
                    onMatchTimeChanged: (_) {},
                    onIsRunningTimeChanged: (_) {},
                    onIsIpponShobuChanged: (_) {},
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
                    onIsKataMatchChanged: (val) {
                      setState(() {
                        isKata = val;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // スイッチが存在すること
      expect(find.text('形・基本判定試合'), findsOneWidget);
      expect(find.text('時間計測なし・3名審判による旗判定'), findsOneWidget);
      expect(find.text('試合時間'), findsOneWidget);

      // スイッチをONにする
      await tester.tap(find.text('形・基本判定試合'));
      await tester.pumpAndSettle();

      // 試合時間設定が非表示になり、案内文が表示されること
      expect(find.text('試合時間'), findsNothing);
      expect(
        find.text('形・基本判定試合では、試合時間計測や延長戦は行われず、3名の審判による旗判定または不戦勝によって勝敗を決定します。'),
        findsOneWidget,
      );
    });

    test('CategoryRulesFormStateにおいてisKataMatchがMatchRuleに反映されること', () {
      final formState = CategoryRulesFormState();
      formState.editingMatchType = '個人戦';
      formState.normalIsKataMatch = true;

      final rule = formState.buildRuleForCategory('一般', isNormal: true);
      expect(rule.isKataMatch, isTrue);
      expect(rule.matchTimeMinutes, 0);
      expect(rule.hasHantei, isTrue);
    });
  });
}
