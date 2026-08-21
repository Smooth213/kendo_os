import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_view.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel(enableLiquidGlass: false);
}

void main() {
  testWidgets('CategoryRuleEditorView renders properly', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
    final keywordsController = TextEditingController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(() => _MockSettingsNotifier()),
        ],
        child: MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: CategoryRuleEditorView(
              category: '小学生高学年の部',
              themeColors: themeColors,
              enableLiquidGlass: false,
              editingMatchType: '個人戦',
              isMultiScene: false,
              useAdvancedRule: true,
              editingIsRenseikai: false,
              onMatchTypeChanged: (_) {},
              onMultiSceneChanged: (_) {},
              onUseAdvancedRuleChanged: (_) {},
              useRenseikaiRule: false,
              useHonsenRule: true,
              useMoushiawaseRule: false,
              renseikaiTime: 2.0,
              renseikaiIsRunningTime: false,
              renseikaiHasHantei: false,
              renseikaiType: '一試合制',
              renseikaiOverallTime: 30,
              moushiawaseTime: 2.0,
              moushiawaseIsRunningTime: false,
              moushiawaseHasHantei: false,
              moushiawaseType: '一試合制',
              moushiawaseOverallTime: 30,
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
              normalTime: 3.0,
              normalIsRunningTime: false,
              normalIpponLimit: 2,
              normalHansokuLimit: 2,
              normalHasHantei: false,
              normalHasExtension: false,
              normalIsEnchoUnlimited: false,
              normalEnchoTime: 2.0,
              normalEnchoCount: 1,
              normalKachinukiUnlimitedType: '大将対大将',
              normalHasLeagueDaihyo: false,
              normalIsDaihyoIpponShobu: true,
              normalWinPoint: 0.0,
              normalLossPoint: 0.0,
              normalDrawPoint: 0.0,
              normalRenseikaiType: '一試合制',
              normalOverallTime: 30,
              normalDaihyoMatchTime: 0.0,
              normalDaihyoHasExtension: true,
              normalDaihyoEnchoTime: 3.0,
              normalDaihyoEnchoCount: -2,
              normalDaihyoHasHantei: false,
              advancedTime: 3.0,
              advancedIsRunningTime: false,
              advancedIpponLimit: 2,
              advancedHansokuLimit: 2,
              advancedHasHantei: false,
              advancedHasExtension: true,
              advancedIsEnchoUnlimited: true,
              advancedEnchoTime: 3.0,
              advancedEnchoCount: 0,
              advancedKachinukiUnlimitedType: '大将対大将',
              advancedHasLeagueDaihyo: false,
              advancedIsDaihyoIpponShobu: true,
              advancedWinPoint: 0.0,
              advancedLossPoint: 0.0,
              advancedDrawPoint: 0.0,
              advancedRenseikaiType: '一試合制',
              advancedOverallTime: 30,
              advancedDaihyoMatchTime: 0.0,
              advancedDaihyoHasExtension: true,
              advancedDaihyoEnchoTime: 3.0,
              advancedDaihyoEnchoCount: -2,
              advancedDaihyoHasHantei: false,
              keywordsController: keywordsController,
              onNormalMatchTimeChanged: (_) {},
              onNormalIsRunningTimeChanged: (_) {},
              onNormalRenseikaiTypeChanged: (_) {},
              onNormalOverallTimeChanged: (_) {},
              onNormalKachinukiUnlimitedTypeChanged: (_) {},
              onNormalHasExtensionChanged: (_) {},
              onNormalIsEnchoUnlimitedChanged: (_) {},
              onNormalEnchoCountChanged: (_) {},
              onNormalEnchoTimeChanged: (_) {},
              onNormalHasHanteiChanged: (_) {},
              onNormalHasLeagueDaihyoChanged: (_) {},
              onNormalIsDaihyoIpponShobuChanged: (_) {},
              onNormalDaihyoMatchTimeChanged: (_) {},
              onNormalDaihyoHasExtensionChanged: (_) {},
              onNormalDaihyoEnchoTimeChanged: (_) {},
              onNormalDaihyoEnchoCountChanged: (_) {},
              onNormalDaihyoHasHanteiChanged: (_) {},
              onNormalWinPointChanged: (_) {},
              onNormalLossPointChanged: (_) {},
              onNormalDrawPointChanged: (_) {},
              onNormalIpponLimitChanged: (_) {},
              onNormalHansokuLimitChanged: (_) {},
              onAdvancedMatchTimeChanged: (_) {},
              onAdvancedIsRunningTimeChanged: (_) {},
              onAdvancedRenseikaiTypeChanged: (_) {},
              onAdvancedOverallTimeChanged: (_) {},
              onAdvancedKachinukiUnlimitedTypeChanged: (_) {},
              onAdvancedHasExtensionChanged: (_) {},
              onAdvancedIsEnchoUnlimitedChanged: (_) {},
              onAdvancedEnchoCountChanged: (_) {},
              onAdvancedEnchoTimeChanged: (_) {},
              onAdvancedHasHanteiChanged: (_) {},
              onAdvancedHasLeagueDaihyoChanged: (_) {},
              onAdvancedIsDaihyoIpponShobuChanged: (_) {},
              onAdvancedDaihyoMatchTimeChanged: (_) {},
              onAdvancedDaihyoHasExtensionChanged: (_) {},
              onAdvancedDaihyoEnchoTimeChanged: (_) {},
              onAdvancedDaihyoEnchoCountChanged: (_) {},
              onAdvancedDaihyoHasHanteiChanged: (_) {},
              onAdvancedWinPointChanged: (_) {},
              onAdvancedLossPointChanged: (_) {},
              onAdvancedDrawPointChanged: (_) {},
              onAdvancedIpponLimitChanged: (_) {},
              onAdvancedHansokuLimitChanged: (_) {},
              onKeywordsChanged: (_) {},
              onCancel: () {},
              onSave: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('小学生高学年の部'), findsOneWidget);
    expect(find.text('通常戦のルール'), findsOneWidget);
    expect(find.text('上位戦（準決勝・決勝）'), findsOneWidget);
    expect(find.text('試合方式'), findsOneWidget);
  });
}
