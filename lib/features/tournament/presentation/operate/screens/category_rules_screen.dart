import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_list_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_view.dart';
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

    return CategoryRuleEditorView(
      category: category,
      themeColors: themeColors,
      enableLiquidGlass: enableLiquidGlass,
      editingMatchType: _formState.editingMatchType,
      isMultiScene: _formState.isMultiScene,
      useAdvancedRule: _formState.useAdvancedRule,
      editingIsRenseikai: _formState.editingIsRenseikai,
      onMatchTypeChanged: (val) =>
          setState(() => _formState.editingMatchType = val),
      onMultiSceneChanged: (val) =>
          setState(() => _formState.isMultiScene = val),
      onUseAdvancedRuleChanged: (val) =>
          setState(() => _formState.useAdvancedRule = val),
      useRenseikaiRule: _formState.useRenseikaiRule,
      useHonsenRule: _formState.useHonsenRule,
      useMoushiawaseRule: _formState.useMoushiawaseRule,
      renseikaiTime: _formState.renseikaiTime,
      renseikaiIsRunningTime: _formState.renseikaiIsRunningTime,
      renseikaiHasHantei: _formState.renseikaiHasHantei,
      renseikaiType: _formState.renseikaiType,
      renseikaiOverallTime: _formState.renseikaiOverallTime,
      moushiawaseTime: _formState.moushiawaseTime,
      moushiawaseIsRunningTime: _formState.moushiawaseIsRunningTime,
      moushiawaseHasHantei: _formState.moushiawaseHasHantei,
      moushiawaseType: _formState.moushiawaseType,
      moushiawaseOverallTime: _formState.moushiawaseOverallTime,
      onUseRenseikaiRuleChanged: (val) =>
          setState(() => _formState.useRenseikaiRule = val),
      onUseHonsenRuleChanged: (val) =>
          setState(() => _formState.useHonsenRule = val),
      onUseMoushiawaseRuleChanged: (val) =>
          setState(() => _formState.useMoushiawaseRule = val),
      onRenseikaiTimeChanged: (val) =>
          setState(() => _formState.renseikaiTime = val),
      onRenseikaiRunningChanged: (val) =>
          setState(() => _formState.renseikaiIsRunningTime = val),
      onRenseikaiHanteiChanged: (val) =>
          setState(() => _formState.renseikaiHasHantei = val),
      onRenseikaiTypeChanged: (val) =>
          setState(() => _formState.renseikaiType = val),
      onRenseikaiOverallTimeChanged: (val) =>
          setState(() => _formState.renseikaiOverallTime = val),
      onMoushiawaseTimeChanged: (val) =>
          setState(() => _formState.moushiawaseTime = val),
      onMoushiawaseRunningChanged: (val) =>
          setState(() => _formState.moushiawaseIsRunningTime = val),
      onMoushiawaseHanteiChanged: (val) =>
          setState(() => _formState.moushiawaseHasHantei = val),
      onMoushiawaseTypeChanged: (val) =>
          setState(() => _formState.moushiawaseType = val),
      onMoushiawaseOverallTimeChanged: (val) =>
          setState(() => _formState.moushiawaseOverallTime = val),
      normalTime: _formState.normalTime,
      normalIsRunningTime: _formState.normalIsRunningTime,
      normalIpponLimit: _formState.normalIpponLimit,
      normalHansokuLimit: _formState.normalHansokuLimit,
      normalHasHantei: _formState.normalHasHantei,
      normalHasExtension: _formState.normalHasExtension,
      normalIsEnchoUnlimited: _formState.normalIsEnchoUnlimited,
      normalEnchoTime: _formState.normalEnchoTime,
      normalEnchoCount: _formState.normalEnchoCount,
      normalKachinukiUnlimitedType: _formState.normalKachinukiUnlimitedType,
      normalHasLeagueDaihyo: _formState.normalHasLeagueDaihyo,
      normalIsDaihyoIpponShobu: _formState.normalIsDaihyoIpponShobu,
      normalWinPoint: _formState.normalWinPoint,
      normalLossPoint: _formState.normalLossPoint,
      normalDrawPoint: _formState.normalDrawPoint,
      normalRenseikaiType: _formState.normalRenseikaiType,
      normalOverallTime: _formState.normalOverallTime,
      normalDaihyoMatchTime: _formState.normalDaihyoMatchTime,
      normalDaihyoHasExtension: _formState.normalDaihyoHasExtension,
      normalDaihyoEnchoTime: _formState.normalDaihyoEnchoTime,
      normalDaihyoEnchoCount: _formState.normalDaihyoEnchoCount,
      normalDaihyoHasHantei: _formState.normalDaihyoHasHantei,
      advancedTime: _formState.advancedTime,
      advancedIsRunningTime: _formState.advancedIsRunningTime,
      advancedIpponLimit: _formState.advancedIpponLimit,
      advancedHansokuLimit: _formState.advancedHansokuLimit,
      advancedHasHantei: _formState.advancedHasHantei,
      advancedHasExtension: _formState.advancedHasExtension,
      advancedIsEnchoUnlimited: _formState.advancedIsEnchoUnlimited,
      advancedEnchoTime: _formState.advancedEnchoTime,
      advancedEnchoCount: _formState.advancedEnchoCount,
      advancedKachinukiUnlimitedType: _formState.advancedKachinukiUnlimitedType,
      advancedHasLeagueDaihyo: _formState.advancedHasLeagueDaihyo,
      advancedIsDaihyoIpponShobu: _formState.advancedIsDaihyoIpponShobu,
      advancedWinPoint: _formState.advancedWinPoint,
      advancedLossPoint: _formState.advancedLossPoint,
      advancedDrawPoint: _formState.advancedDrawPoint,
      advancedRenseikaiType: _formState.advancedRenseikaiType,
      advancedOverallTime: _formState.advancedOverallTime,
      advancedDaihyoMatchTime: _formState.advancedDaihyoMatchTime,
      advancedDaihyoHasExtension: _formState.advancedDaihyoHasExtension,
      advancedDaihyoEnchoTime: _formState.advancedDaihyoEnchoTime,
      advancedDaihyoEnchoCount: _formState.advancedDaihyoEnchoCount,
      advancedDaihyoHasHantei: _formState.advancedDaihyoHasHantei,
      keywordsController: _keywordsController,
      onNormalMatchTimeChanged: (val) =>
          setState(() => _formState.normalTime = val),
      onNormalIsRunningTimeChanged: (val) =>
          setState(() => _formState.normalIsRunningTime = val),
      onNormalRenseikaiTypeChanged: (val) =>
          setState(() => _formState.normalRenseikaiType = val),
      onNormalOverallTimeChanged: (val) =>
          setState(() => _formState.normalOverallTime = val),
      onNormalKachinukiUnlimitedTypeChanged: (val) =>
          setState(() => _formState.normalKachinukiUnlimitedType = val),
      onNormalHasExtensionChanged: (val) =>
          setState(() => _formState.normalHasExtension = val),
      onNormalIsEnchoUnlimitedChanged: (val) =>
          setState(() => _formState.normalIsEnchoUnlimited = val),
      onNormalEnchoCountChanged: (val) =>
          setState(() => _formState.normalEnchoCount = val),
      onNormalEnchoTimeChanged: (val) =>
          setState(() => _formState.normalEnchoTime = val),
      onNormalHasHanteiChanged: (val) =>
          setState(() => _formState.normalHasHantei = val),
      onNormalHasLeagueDaihyoChanged: (val) =>
          setState(() => _formState.normalHasLeagueDaihyo = val),
      onNormalIsDaihyoIpponShobuChanged: (val) =>
          setState(() => _formState.normalIsDaihyoIpponShobu = val),
      onNormalDaihyoMatchTimeChanged: (val) =>
          setState(() => _formState.normalDaihyoMatchTime = val),
      onNormalDaihyoHasExtensionChanged: (val) =>
          setState(() => _formState.normalDaihyoHasExtension = val),
      onNormalDaihyoEnchoTimeChanged: (val) =>
          setState(() => _formState.normalDaihyoEnchoTime = val),
      onNormalDaihyoEnchoCountChanged: (val) =>
          setState(() => _formState.normalDaihyoEnchoCount = val),
      onNormalDaihyoHasHanteiChanged: (val) =>
          setState(() => _formState.normalDaihyoHasHantei = val),
      onNormalWinPointChanged: (val) =>
          setState(() => _formState.normalWinPoint = val),
      onNormalLossPointChanged: (val) =>
          setState(() => _formState.normalLossPoint = val),
      onNormalDrawPointChanged: (val) =>
          setState(() => _formState.normalDrawPoint = val),
      onNormalIpponLimitChanged: (val) =>
          setState(() => _formState.normalIpponLimit = val),
      onNormalHansokuLimitChanged: (val) =>
          setState(() => _formState.normalHansokuLimit = val),
      onAdvancedMatchTimeChanged: (val) =>
          setState(() => _formState.advancedTime = val),
      onAdvancedIsRunningTimeChanged: (val) =>
          setState(() => _formState.advancedIsRunningTime = val),
      onAdvancedRenseikaiTypeChanged: (val) =>
          setState(() => _formState.advancedRenseikaiType = val),
      onAdvancedOverallTimeChanged: (val) =>
          setState(() => _formState.advancedOverallTime = val),
      onAdvancedKachinukiUnlimitedTypeChanged: (val) =>
          setState(() => _formState.advancedKachinukiUnlimitedType = val),
      onAdvancedHasExtensionChanged: (val) =>
          setState(() => _formState.advancedHasExtension = val),
      onAdvancedIsEnchoUnlimitedChanged: (val) =>
          setState(() => _formState.advancedIsEnchoUnlimited = val),
      onAdvancedEnchoCountChanged: (val) =>
          setState(() => _formState.advancedEnchoCount = val),
      onAdvancedEnchoTimeChanged: (val) =>
          setState(() => _formState.advancedEnchoTime = val),
      onAdvancedHasHanteiChanged: (val) =>
          setState(() => _formState.advancedHasHantei = val),
      onAdvancedHasLeagueDaihyoChanged: (val) =>
          setState(() => _formState.advancedHasLeagueDaihyo = val),
      onAdvancedIsDaihyoIpponShobuChanged: (val) =>
          setState(() => _formState.advancedIsDaihyoIpponShobu = val),
      onAdvancedDaihyoMatchTimeChanged: (val) =>
          setState(() => _formState.advancedDaihyoMatchTime = val),
      onAdvancedDaihyoHasExtensionChanged: (val) =>
          setState(() => _formState.advancedDaihyoHasExtension = val),
      onAdvancedDaihyoEnchoTimeChanged: (val) =>
          setState(() => _formState.advancedDaihyoEnchoTime = val),
      onAdvancedDaihyoEnchoCountChanged: (val) =>
          setState(() => _formState.advancedDaihyoEnchoCount = val),
      onAdvancedDaihyoHasHanteiChanged: (val) =>
          setState(() => _formState.advancedDaihyoHasHantei = val),
      onAdvancedWinPointChanged: (val) =>
          setState(() => _formState.advancedWinPoint = val),
      onAdvancedLossPointChanged: (val) =>
          setState(() => _formState.advancedLossPoint = val),
      onAdvancedDrawPointChanged: (val) =>
          setState(() => _formState.advancedDrawPoint = val),
      onAdvancedIpponLimitChanged: (val) =>
          setState(() => _formState.advancedIpponLimit = val),
      onAdvancedHansokuLimitChanged: (val) =>
          setState(() => _formState.advancedHansokuLimit = val),
      onKeywordsChanged: (kws) =>
          setState(() => _formState.editingAdvancedKeywords = kws),
      onCancel: () => setState(() => _formState.editingCategory = null),
      onSave: () => _saveCategoryRules(tournament),
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
