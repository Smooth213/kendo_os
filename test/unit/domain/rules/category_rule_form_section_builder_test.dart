import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_view.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_form_section_builder.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('CategoryRuleFormSectionBuilder テスト', () {
    late TextEditingController keywordsController;

    setUp(() {
      keywordsController = TextEditingController();
    });

    tearDown(() {
      keywordsController.dispose();
    });

    CategoryRuleEditorView createSampleView() {
      return CategoryRuleEditorView(
        category: '小学生の部',
        themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
        enableLiquidGlass: false,
        editingMatchType: '個人戦',
        isMultiScene: false,
        useAdvancedRule: false,
        editingIsRenseikai: false,
        onMatchTypeChanged: (_) {},
        onMultiSceneChanged: (_) {},
        onUseAdvancedRuleChanged: (_) {},
        useRenseikaiRule: false,
        useHonsenRule: true,
        useMoushiawaseRule: false,
        renseikaiTime: 2.0,
        renseikaiIsRunningTime: false,
        renseikaiHasHantei: true,
        renseikaiType: '一試合制',
        renseikaiOverallTime: 30,
        moushiawaseTime: 2.0,
        moushiawaseIsRunningTime: false,
        moushiawaseHasHantei: true,
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
        normalHasHantei: true,
        normalHasExtension: false,
        normalIsEnchoUnlimited: false,
        normalEnchoTime: 3.0,
        normalEnchoCount: 1,
        normalKachinukiUnlimitedType: '大将対大将',
        normalHasLeagueDaihyo: false,
        normalIsDaihyoIpponShobu: true,
        normalWinPoint: 3.0,
        normalLossPoint: 0.0,
        normalDrawPoint: 1.0,
        normalRenseikaiType: '一試合制',
        normalOverallTime: 30,
        normalDaihyoMatchTime: 0.0,
        normalDaihyoHasExtension: true,
        normalDaihyoEnchoTime: 3.0,
        normalDaihyoEnchoCount: -2,
        normalDaihyoHasHantei: false,
        advancedTime: 4.0,
        advancedIsRunningTime: false,
        advancedIpponLimit: 2,
        advancedHansokuLimit: 2,
        advancedHasHantei: true,
        advancedHasExtension: true,
        advancedIsEnchoUnlimited: true,
        advancedEnchoTime: 4.0,
        advancedEnchoCount: -1,
        advancedKachinukiUnlimitedType: '大将対大将',
        advancedHasLeagueDaihyo: false,
        advancedIsDaihyoIpponShobu: true,
        advancedWinPoint: 3.0,
        advancedLossPoint: 0.0,
        advancedDrawPoint: 1.0,
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
      );
    }

    testWidgets('通常戦用フォームセクションがクラッシュせず正常に生成されること', (tester) async {
      final view = createSampleView();
      final widget = CategoryRuleFormSectionBuilder.build(
        view: view,
        title: '通常戦ルール',
        isNormal: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: widget)),
        ),
      );

      expect(find.text('通常戦ルール'), findsOneWidget);
    });

    testWidgets('上位戦用フォームセクションがクラッシュせず正常に生成されること', (tester) async {
      final view = createSampleView();
      final widget = CategoryRuleFormSectionBuilder.build(
        view: view,
        title: '上位戦ルール',
        isNormal: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: widget)),
        ),
      );

      expect(find.text('上位戦ルール'), findsOneWidget);
    });
  });
}
