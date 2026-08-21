import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 通常戦 / 上位戦の切り替えタブ表示カード
class CategoryRuleAdvancedTabsCard extends StatelessWidget {
  final Widget normalRuleSection;
  final Widget advancedRuleSection;

  const CategoryRuleAdvancedTabsCard({
    super.key,
    required this.normalRuleSection,
    required this.advancedRuleSection,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            labelColor: AppKendoColors.indigo,
            unselectedLabelColor: AppKendoColors.grey,
            indicatorColor: AppKendoColors.indigo,
            labelStyle: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodyMedium,
            ),
            tabs: [
              Tab(text: '通常戦のルール'),
              Tab(text: '上位戦（準決勝・決勝）'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 800,
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListView(children: [normalRuleSection]),
                ListView(children: [advancedRuleSection]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
