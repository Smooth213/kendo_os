import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_chips.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 🥋 大会運営用 部門ルール一覧表示・登録・編集・削除セクション
class CategoryRulesListSection extends StatelessWidget {
  final TournamentModel tournament;
  final bool isDark;
  final bool enableLiquidGlass;
  final TextEditingController newCategoryController;
  final List<String> presetCategories;
  final bool isFromSetup;
  final String tournamentId;
  final void Function(String name) onAddCategory;
  final void Function(String cat, CategoryRuleSet ruleSet) onStartEditing;
  final void Function(String cat) onDeleteCategory;
  final void Function(String cat, CategoryRuleSet ruleSet) onShowRuleDetail;
  final VoidCallback? onCompleteSetup;

  const CategoryRulesListSection({
    super.key,
    required this.tournament,
    required this.isDark,
    required this.enableLiquidGlass,
    required this.newCategoryController,
    required this.presetCategories,
    required this.isFromSetup,
    required this.tournamentId,
    required this.onAddCategory,
    required this.onStartEditing,
    required this.onDeleteCategory,
    required this.onShowRuleDetail,
    this.onCompleteSetup,
  });

  @override
  Widget build(BuildContext context) {
    final list = tournament.categoryRules.keys.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: newCategoryController,
                  decoration: InputDecoration(
                    hintText: '部門名を入力（例：小学生低学年の部）',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppKendoColors.grey
                          : const Color(0x8A000000),
                      fontSize: AppFontSize.bodySmall,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFFFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0x33000000),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0x33000000),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.medium,
                      borderSide: BorderSide(
                        color: const Color(0xFF3F51B5),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                ),
                onPressed: () => onAddCategory(newCategoryController.text),
              ),
            ],
          ),
        ),

        // プリセット追加のショートカット
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 定番の部門をワンタップで追加',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.subTextColor,
                    fontSize: AppFontSize.small,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: presetCategories
                        .map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: AppActionChip(
                              label: Text(name),
                              onPressed: () => onAddCategory(name),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gavel,
                        size: 48,
                        color: const Color(0x8A000000),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '部門別ルールが未登録です。\n上の入力欄から部門を追加してください。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0x8A000000),
                          fontSize: AppFontSize.bodySmall,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  // ignore: deprecated_member_use
                  cacheExtent: 1000.0,
                  itemBuilder: (context, index) {
                    final cat = list[index];
                    final ruleSet = tournament.categoryRules[cat]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Slidable(
                        key: ValueKey('slidable_rule_$cat'),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) =>
                                  onStartEditing(cat, ruleSet),
                              backgroundColor: AppKendoColors.blueAccent,
                              foregroundColor: AppKendoColors.pureWhite,
                              icon: Icons.edit,
                              label: '編集',
                            ),
                            SlidableAction(
                              onPressed: (context) => onDeleteCategory(cat),
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
                                        ? const Color(
                                            0xFFFFFFFF,
                                          ).withValues(alpha: 0.15)
                                        : const Color(
                                            0xFF000000,
                                          ).withValues(alpha: 0.08),
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
                                    ? const Color(
                                        0xFF1C1C1E,
                                      ).withValues(alpha: 0.35)
                                    : const Color(
                                        0xFFFFFFFF,
                                      ).withValues(alpha: 0.65))
                              : (isDark
                                    ? const Color(0xFF1C1C1E)
                                    : context.appColors.cardBackground),
                          child: ListTile(
                            onTap: () => onShowRuleDetail(cat, ruleSet),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: AppSpacing.md,
                            ),
                            title: Text(
                              cat,
                              style: const TextStyle(
                                fontWeight: AppFontWeight.bold,
                                fontSize: AppFontSize.subhead,
                              ),
                            ),
                            subtitle: CategoryRuleChips(
                              ruleSet: ruleSet,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (isFromSetup && list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: onCompleteSetup,
                color: AppKendoColors.indigo,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                icon: Icons.check_circle,
                label: '設定を完了して大会ホームへ進む',
                expandContent: false,
              ),
            ),
          ),
      ],
    );
  }
}
