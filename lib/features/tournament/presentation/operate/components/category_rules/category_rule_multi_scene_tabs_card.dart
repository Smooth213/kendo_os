import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_simple_scene_rule_form.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 遠征マルチシーンルール（選択チェックボックス・3タブ表示）カード
class CategoryRuleMultiSceneTabsCard extends StatelessWidget {
  final bool useRenseikaiRule;
  final bool useHonsenRule;
  final bool useMoushiawaseRule;

  final double renseikaiTime;
  final bool renseikaiIsRunningTime;
  final bool renseikaiHasHantei;
  final String renseikaiType;
  final int renseikaiOverallTime;

  final double moushiawaseTime;
  final bool moushiawaseIsRunningTime;
  final bool moushiawaseHasHantei;
  final String moushiawaseType;
  final int moushiawaseOverallTime;

  final Widget honsenRuleSection;

  final ValueChanged<bool> onUseRenseikaiRuleChanged;
  final ValueChanged<bool> onUseHonsenRuleChanged;
  final ValueChanged<bool> onUseMoushiawaseRuleChanged;

  final ValueChanged<double> onRenseikaiTimeChanged;
  final ValueChanged<bool> onRenseikaiRunningChanged;
  final ValueChanged<bool> onRenseikaiHanteiChanged;
  final ValueChanged<String> onRenseikaiTypeChanged;
  final ValueChanged<int> onRenseikaiOverallTimeChanged;

  final ValueChanged<double> onMoushiawaseTimeChanged;
  final ValueChanged<bool> onMoushiawaseRunningChanged;
  final ValueChanged<bool> onMoushiawaseHanteiChanged;
  final ValueChanged<String> onMoushiawaseTypeChanged;
  final ValueChanged<int> onMoushiawaseOverallTimeChanged;

  const CategoryRuleMultiSceneTabsCard({
    super.key,
    required this.useRenseikaiRule,
    required this.useHonsenRule,
    required this.useMoushiawaseRule,
    required this.renseikaiTime,
    required this.renseikaiIsRunningTime,
    required this.renseikaiHasHantei,
    required this.renseikaiType,
    required this.renseikaiOverallTime,
    required this.moushiawaseTime,
    required this.moushiawaseIsRunningTime,
    required this.moushiawaseHasHantei,
    required this.moushiawaseType,
    required this.moushiawaseOverallTime,
    required this.honsenRuleSection,
    required this.onUseRenseikaiRuleChanged,
    required this.onUseHonsenRuleChanged,
    required this.onUseMoushiawaseRuleChanged,
    required this.onRenseikaiTimeChanged,
    required this.onRenseikaiRunningChanged,
    required this.onRenseikaiHanteiChanged,
    required this.onRenseikaiTypeChanged,
    required this.onRenseikaiOverallTimeChanged,
    required this.onMoushiawaseTimeChanged,
    required this.onMoushiawaseRunningChanged,
    required this.onMoushiawaseHanteiChanged,
    required this.onMoushiawaseTypeChanged,
    required this.onMoushiawaseOverallTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: (isDark ? AppKendoColors.ipponGold : const Color(0xFFD97706))
                .withValues(alpha: 0.1),
            borderRadius: AppRadius.medium,
            border: Border.all(
              color:
                  (isDark ? AppKendoColors.ipponGold : const Color(0xFFD97706))
                      .withValues(alpha: 0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '実施するルールシーンの選択',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.bodySmall,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 6),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '⚔️ 錬成会ルール',
                    style: TextStyle(fontSize: AppFontSize.body),
                  ),
                  value: useRenseikaiRule,
                  onChanged: (val) {
                    if (val != null) onUseRenseikaiRuleChanged(val);
                  },
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '🏆 本戦ルール',
                    style: TextStyle(fontSize: AppFontSize.body),
                  ),
                  value: useHonsenRule,
                  onChanged: (val) {
                    if (val != null) onUseHonsenRuleChanged(val);
                  },
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '🤝 申し合わせルール',
                    style: TextStyle(fontSize: AppFontSize.body),
                  ),
                  value: useMoushiawaseRule,
                  onChanged: (val) {
                    if (val != null) onUseMoushiawaseRuleChanged(val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TabBar(
                labelColor: AppKendoColors.indigo,
                unselectedLabelColor: AppKendoColors.grey,
                indicatorColor: AppKendoColors.indigo,
                isScrollable: true,
                labelStyle: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.body,
                ),
                tabs: [
                  Tab(text: '⚔️ 錬成会ルール'),
                  Tab(text: '🏆 本戦ルール'),
                  Tab(text: '🤝 申し合わせルール'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 450,
                child: TabBarView(
                  children: [
                    ListView(
                      children: [
                        CategorySimpleSceneRuleForm(
                          title: '⚔️ 錬成会ルール',
                          time: renseikaiTime,
                          isRunning: renseikaiIsRunningTime,
                          hasHantei: renseikaiHasHantei,
                          renseikaiType: renseikaiType,
                          overallTime: renseikaiOverallTime,
                          onTimeChanged: onRenseikaiTimeChanged,
                          onRunningChanged: onRenseikaiRunningChanged,
                          onHanteiChanged: onRenseikaiHanteiChanged,
                          onTypeChanged: onRenseikaiTypeChanged,
                          onOverallTimeChanged: onRenseikaiOverallTimeChanged,
                        ),
                      ],
                    ),
                    ListView(children: [honsenRuleSection]),
                    ListView(
                      children: [
                        CategorySimpleSceneRuleForm(
                          title: '🤝 申し合わせルール',
                          time: moushiawaseTime,
                          isRunning: moushiawaseIsRunningTime,
                          hasHantei: moushiawaseHasHantei,
                          renseikaiType: moushiawaseType,
                          overallTime: moushiawaseOverallTime,
                          onTimeChanged: onMoushiawaseTimeChanged,
                          onRunningChanged: onMoushiawaseRunningChanged,
                          onHanteiChanged: onMoushiawaseHanteiChanged,
                          onTypeChanged: onMoushiawaseTypeChanged,
                          onOverallTimeChanged: onMoushiawaseOverallTimeChanged,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
