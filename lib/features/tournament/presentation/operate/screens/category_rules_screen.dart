import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_list_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_container.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_dialogs.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart';

class CategoryRulesScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isFromSetup;
  const CategoryRulesScreen({
    super.key,
    required this.tournamentId,
    this.isFromSetup = false,
  });

  @override
  ConsumerState<CategoryRulesScreen> createState() =>
      _CategoryRulesScreenState();
}

class _CategoryRulesScreenState extends ConsumerState<CategoryRulesScreen> {
  final CategoryRulesFormState _formState = CategoryRulesFormState();

  final _newCategoryController = TextEditingController();
  final _keywordsController = TextEditingController();

  @override
  void dispose() {
    _newCategoryController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _startEditing(String category, CategoryRuleSet rules) {
    setState(() {
      _formState.populateFromRuleSet(category, rules);
      _keywordsController.text = _formState.editingAdvancedKeywords.join(', ');
    });
  }

  Future<void> _saveCategoryRules(TournamentModel tournament) async {
    if (_formState.editingCategory == null) return;

    final category = _formState.editingCategory!;
    final newRuleSet = _formState.buildCategoryRuleSet(category);

    final updatedTournament =
        CategoryRuleMatchHelper.updateTournamentWithRuleSet(
          tournament: tournament,
          category: category,
          ruleSet: newRuleSet,
        );

    // 既存の試合を探して一括適用の判定（基底部門名 ＋ 団体/個人種別の一致する試合を対象）
    final baseCat = CategoryRuleMatchHelper.cleanCategoryBaseName(category);
    final isIndivRule = newRuleSet.matchType.contains('個人');

    final allMatches =
        ref.read(matchListByTournamentProvider(widget.tournamentId)).value ??
        [];
    final targetMatches = allMatches.where((m) {
      if (m.status == 'finished' || m.status == 'approved') return false;
      final mCat = m.category?.trim() ?? '';
      if (mCat != category && mCat != baseCat) return false;

      final isIndivMatch =
          m.matchType == '個人戦' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人') ||
          mCat.contains('個人');
      return isIndivMatch == isIndivRule;
    }).toList();

    if (targetMatches.isNotEmpty) {
      final result = await CategoryRuleDialogs.showBulkApplyConfirmDialog(
        context: context,
        category: category,
        matchCount: targetMatches.length,
      );

      if (result == 'cancel') return;

      if (result == 'yes') {
        final matchesToSave = CategoryRuleMatchHelper.applyRulesToMatches(
          targetMatches: targetMatches,
          ruleSet: newRuleSet,
          useAdvancedRule: _formState.useAdvancedRule,
          advancedKeywords: _formState.editingAdvancedKeywords,
        );
        await ref
            .read(matchApplicationServiceProvider)
            .saveMatchesBulk(matchesToSave);
      }
    }

    // 大会データの保存
    await ref
        .read(tournamentRepositoryProvider)
        .updateTournament(updatedTournament);

    if (mounted) {
      AppSnackBar.showSuccess(context, '「$category」のルール設定を保存しました');
      setState(() {
        _formState.editingCategory = null;
      });
    }
  }

  Future<void> _deleteCategory(
    TournamentModel tournament,
    String category,
  ) async {
    final result = await CategoryRuleDialogs.showDeleteCategoryDialog(
      context: context,
      category: category,
    );

    if (result == true) {
      final updated = CategoryRuleMatchHelper.deleteCategoryFromTournament(
        tournament,
        category,
      );
      await ref.read(tournamentRepositoryProvider).updateTournament(updated);

      if (mounted) {
        AppSnackBar.show(context, '「$category」を削除しました');
      }
    }
  }

  void _addNewCategory(TournamentModel tournament, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final (updated, ruleKey, ruleSet) =
        CategoryRuleMatchHelper.addCategoryToTournament(tournament, cleanName);

    await ref.read(tournamentRepositoryProvider).updateTournament(updated);
    _newCategoryController.clear();

    if (mounted) {
      AppSnackBar.showSuccess(context, '「$ruleKey」を追加しました');
      _startEditing(ruleKey, ruleSet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final asyncTournament = ref.watch(tournamentProvider(widget.tournamentId));

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          title: _formState.editingCategory == null ? '試合ルール設定' : 'ルールの編集',
          backgroundColor: AppKendoColors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              if (_formState.editingCategory != null) {
                setState(() {
                  _formState.editingCategory = null;
                });
              } else {
                context.pop();
              }
            },
          ),
          actions: [
            if (widget.isFromSetup && _formState.editingCategory == null)
              TextButton(
                onPressed: () => context.go('/home/${widget.tournamentId}'),
                child: Text(
                  'スキップ',
                  style: TextStyle(
                    color: themeColors.primaryAccent,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: asyncTournament.when(
          data: (tournament) {
            if (tournament == null) {
              return const Center(child: Text('大会データが見つかりません'));
            }
            if (_formState.editingCategory != null) {
              return _buildRuleEditor(
                tournament,
                _formState.editingCategory!,
                themeColors,
              );
            }
            final enableLiquidGlass = ref.watch(
              settingsProvider.select((s) => s.enableLiquidGlass),
            );
            return CategoryRulesListSection(
              tournament: tournament,
              isDark: isDark,
              enableLiquidGlass: enableLiquidGlass,
              newCategoryController: _newCategoryController,
              presetCategories: CategoryRuleMatchHelper.presetCategories,
              isFromSetup: widget.isFromSetup,
              tournamentId: widget.tournamentId,
              onAddCategory: (name) => _addNewCategory(tournament, name),
              onStartEditing: (cat, ruleSet) => _startEditing(cat, ruleSet),
              onDeleteCategory: (cat) => _deleteCategory(tournament, cat),
              onShowRuleDetail: (cat, ruleSet) =>
                  _showRuleDetailBottomSheet(context, cat, ruleSet),
              onCompleteSetup: () => context.go('/home/${widget.tournamentId}'),
            );
          },
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (e, s) => Center(child: Text('エラーが発生しました: $e')),
        ),
      ),
    );
  }

  Widget _buildRuleEditor(
    TournamentModel tournament,
    String category,
    AppThemeColors themeColors,
  ) {
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );

    return CategoryRuleEditorContainer(
      tournament: tournament,
      category: category,
      themeColors: themeColors,
      enableLiquidGlass: enableLiquidGlass,
      formState: _formState,
      keywordsController: _keywordsController,
      onCancel: () => setState(() => _formState.editingCategory = null),
      onSave: () => _saveCategoryRules(tournament),
      setState: setState,
    );
  }

  void _showRuleDetailBottomSheet(
    BuildContext context,
    String categoryName,
    CategoryRuleSet ruleSet,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    CategoryRuleDetailBottomSheet.show(
      context,
      categoryName: categoryName,
      ruleSet: ruleSet,
      isDark: isDark,
    );
  }
}
