import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_chips.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 部門ルール一覧の1行タイルWidget（スワイプ編集・削除対応）
class CategoryRuleCategoryTile extends StatelessWidget {
  final String category;
  final CategoryRuleSet ruleSet;
  final bool isDark;
  final bool enableLiquidGlass;
  final VoidCallback onStartEditing;
  final VoidCallback onDeleteCategory;
  final VoidCallback onShowRuleDetail;

  const CategoryRuleCategoryTile({
    super.key,
    required this.category,
    required this.ruleSet,
    required this.isDark,
    required this.enableLiquidGlass,
    required this.onStartEditing,
    required this.onDeleteCategory,
    required this.onShowRuleDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Slidable(
        key: ValueKey('slidable_rule_$category'),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onStartEditing(),
              backgroundColor: AppKendoColors.blueAccent,
              foregroundColor: AppKendoColors.pureWhite,
              icon: Icons.edit,
              label: '編集',
            ),
            SlidableAction(
              onPressed: (_) => onDeleteCategory(),
              backgroundColor: AppKendoColors.redAccent,
              foregroundColor: AppKendoColors.pureWhite,
              icon: Icons.delete,
              label: '削除',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppRadius.largeValue),
              ),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
            side: enableLiquidGlass
                ? BorderSide(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
                        : const Color(0xFF000000).withValues(alpha: 0.08),
                    width: 0.5,
                  )
                : BorderSide(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0x33000000),
                  ),
          ),
          color: enableLiquidGlass
              ? (isDark
                    ? const Color(0xFF1C1C1E).withValues(alpha: 0.35)
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.65))
              : (isDark
                    ? const Color(0xFF1C1C1E)
                    : context.appColors.cardBackground),
          child: ListTile(
            onTap: onShowRuleDetail,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: AppSpacing.md,
            ),
            title: Text(
              category,
              style: const TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.subhead,
              ),
            ),
            subtitle: CategoryRuleChips(ruleSet: ruleSet, isDark: isDark),
          ),
        ),
      ),
    );
  }
}
