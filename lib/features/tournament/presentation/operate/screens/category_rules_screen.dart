import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_form_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_list_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_bottom_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_multi_scene_tabs_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_advanced_tabs_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_dialogs.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

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
  String? _editingCategory;

  // 編集中のルールセット状態保持用
  bool _useAdvancedRule = false;
  List<String> _editingAdvancedKeywords = const [
    '準決勝',
    '準決',
    '決勝',
    'final',
    '3位決定',
    '3決',
    'ベスト4',
  ];
  String _editingMatchType = '個人戦';
  bool _editingIsRenseikai = false;

  // 道場遠征用マルチシーン設定
  bool _isMultiScene = false;
  bool _useHonsenRule = true;
  bool _useRenseikaiRule = true;
  bool _useMoushiawaseRule = true;
  double _renseikaiTime = 2.0;
  bool _renseikaiIsRunningTime = true;
  bool _renseikaiHasHantei = true;
  String _renseikaiType = '一試合制';
  int _renseikaiOverallTime = 30;

  double _moushiawaseTime = 2.0;
  bool _moushiawaseIsRunningTime = true;
  bool _moushiawaseHasHantei = true;
  String _moushiawaseType = '一試合制';
  int _moushiawaseOverallTime = 30;

  // 通常戦の設定
  double _normalTime = 3.0;
  bool _normalIsRunningTime = false;
  bool _normalIsIpponShobu = false;
  int _normalIpponLimit = 2;
  int _normalHansokuLimit = 2;
  bool _normalHasHantei = false;
  bool _normalHasExtension = false;
  bool _normalIsEnchoUnlimited = false;
  double _normalEnchoTime = 2.0;
  int _normalEnchoCount = 1;
  String _normalKachinukiUnlimitedType = '大将対大将';
  bool _normalHasLeagueDaihyo = false;
  bool _normalIsDaihyoIpponShobu = true;
  double _normalWinPoint = 0.0;
  double _normalLossPoint = 0.0;
  double _normalDrawPoint = 0.0;
  String _normalRenseikaiType = '一試合制';
  int _normalOverallTime = 30;

  // 上位戦の設定
  double _advancedTime = 3.0;
  bool _advancedIsRunningTime = false;
  bool _advancedIsIpponShobu = false;
  int _advancedIpponLimit = 2;
  int _advancedHansokuLimit = 2;
  bool _advancedHasHantei = false;
  bool _advancedHasExtension = true;
  bool _advancedIsEnchoUnlimited = true;
  double _advancedEnchoTime = 3.0;
  int _advancedEnchoCount = 0;
  String _advancedKachinukiUnlimitedType = '大将対大将';
  bool _advancedHasLeagueDaihyo = false;
  bool _advancedIsDaihyoIpponShobu = true;
  double _advancedWinPoint = 0.0;
  double _advancedLossPoint = 0.0;
  double _advancedDrawPoint = 0.0;
  String _advancedRenseikaiType = '一試合制';
  int _advancedOverallTime = 30;

  // 代表戦の詳細設定 (通常戦用)
  double _normalDaihyoMatchTime = 0.0; // 0.0: 無制限
  bool _normalDaihyoHasExtension = true;
  double _normalDaihyoEnchoTime = 3.0;
  int _normalDaihyoEnchoCount = -2; // -2: 無制限
  bool _normalDaihyoHasHantei = false;

  // 代表戦の詳細設定 (上位戦用)
  double _advancedDaihyoMatchTime = 0.0; // 0.0: 無制限
  bool _advancedDaihyoHasExtension = true;
  double _advancedDaihyoEnchoTime = 3.0;
  int _advancedDaihyoEnchoCount = -2; // -2: 無制限
  bool _advancedDaihyoHasHantei = false;

  final _newCategoryController = TextEditingController();
  final _keywordsController = TextEditingController();

  final List<String> _presetCategories = [
    '小学生の部',
    '小学生低学年の部',
    '小学生高学年の部',
    '中学生の部',
    '中学生男子の部',
    '中学生女子の部',
    '高校生男子の部',
    '高校生女子の部',
    '一般男子の部',
    '一般女子の部',
  ];

  @override
  void dispose() {
    _newCategoryController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _startEditing(String category, CategoryRuleSet rules) {
    setState(() {
      _editingCategory = category;
      _useAdvancedRule = rules.useAdvancedRule;

      _isMultiScene = rules.isMultiScene;
      _useHonsenRule = rules.useHonsenRule;
      _useRenseikaiRule = rules.useRenseikaiRule;
      _useMoushiawaseRule = rules.useMoushiawaseRule;
      _renseikaiTime = rules.renseikaiRule.matchTimeMinutes;
      _renseikaiIsRunningTime = rules.renseikaiRule.isRunningTime;
      _renseikaiHasHantei = rules.renseikaiRule.hasHantei;
      _renseikaiType = rules.renseikaiRule.renseikaiType;
      _renseikaiOverallTime = rules.renseikaiRule.overallTimeMinutes;

      _moushiawaseTime = rules.moushiawaseRule.matchTimeMinutes;
      _moushiawaseIsRunningTime = rules.moushiawaseRule.isRunningTime;
      _moushiawaseHasHantei = rules.moushiawaseRule.hasHantei;
      _moushiawaseType = rules.moushiawaseRule.renseikaiType;
      _moushiawaseOverallTime = rules.moushiawaseRule.overallTimeMinutes;

      // 通常戦設定
      _normalTime = rules.normalRule.matchTimeMinutes;
      _normalIsRunningTime = rules.normalRule.isRunningTime;
      _normalIsIpponShobu = rules.normalRule.isIpponShobu;
      _normalIpponLimit = rules.normalRule.ipponLimit;
      _normalHansokuLimit = rules.normalRule.hansokuLimit;
      _normalHasHantei = rules.normalRule.hasHantei;
      _normalHasExtension =
          rules.normalRule.enchoCount > 0 || rules.normalRule.isEnchoUnlimited;
      _normalIsEnchoUnlimited = rules.normalRule.isEnchoUnlimited;
      _normalEnchoTime = rules.normalRule.enchoTimeMinutes;
      _normalEnchoCount = rules.normalRule.enchoCount;
      _normalKachinukiUnlimitedType = rules.normalRule.kachinukiUnlimitedType;
      _normalHasLeagueDaihyo = rules.normalRule.hasLeagueDaihyo;
      _normalIsDaihyoIpponShobu = rules.normalRule.isDaihyoIpponShobu;
      _normalWinPoint = rules.normalRule.winPoint;
      _normalLossPoint = rules.normalRule.lossPoint;
      _normalDrawPoint = rules.normalRule.drawPoint;
      _normalRenseikaiType = rules.normalRule.renseikaiType;
      _normalOverallTime = rules.normalRule.overallTimeMinutes;

      // 上位戦設定
      _advancedTime = rules.advancedRule.matchTimeMinutes;
      _advancedIsRunningTime = rules.advancedRule.isRunningTime;
      _advancedIsIpponShobu = rules.advancedRule.isIpponShobu;
      _advancedIpponLimit = rules.advancedRule.ipponLimit;
      _advancedHansokuLimit = rules.advancedRule.hansokuLimit;
      _advancedHasHantei = rules.advancedRule.hasHantei;
      _advancedHasExtension =
          rules.advancedRule.enchoCount > 0 ||
          rules.advancedRule.isEnchoUnlimited;
      _advancedIsEnchoUnlimited = rules.advancedRule.isEnchoUnlimited;
      _advancedEnchoTime = rules.advancedRule.enchoTimeMinutes;
      _advancedEnchoCount = rules.advancedRule.enchoCount;
      _advancedKachinukiUnlimitedType =
          rules.advancedRule.kachinukiUnlimitedType;
      _advancedHasLeagueDaihyo = rules.advancedRule.hasLeagueDaihyo;
      _advancedIsDaihyoIpponShobu = rules.advancedRule.isDaihyoIpponShobu;
      _advancedWinPoint = rules.advancedRule.winPoint;
      _advancedLossPoint = rules.advancedRule.lossPoint;
      _advancedDrawPoint = rules.advancedRule.drawPoint;
      _advancedRenseikaiType = rules.advancedRule.renseikaiType;
      _advancedOverallTime = rules.advancedRule.overallTimeMinutes;
      _editingAdvancedKeywords = List.from(rules.advancedKeywords);
      _keywordsController.text = _editingAdvancedKeywords.join(', ');

      _normalDaihyoMatchTime = rules.normalRule.daihyoMatchTimeMinutes;
      _normalDaihyoHasExtension = rules.normalRule.daihyoHasExtension;
      _normalDaihyoEnchoTime = rules.normalRule.daihyoEnchoTimeMinutes;
      _normalDaihyoEnchoCount = rules.normalRule.daihyoEnchoCount;
      _normalDaihyoHasHantei = rules.normalRule.daihyoHasHantei;

      _advancedDaihyoMatchTime = rules.advancedRule.daihyoMatchTimeMinutes;
      _advancedDaihyoHasExtension = rules.advancedRule.daihyoHasExtension;
      _advancedDaihyoEnchoTime = rules.advancedRule.daihyoEnchoTimeMinutes;
      _advancedDaihyoEnchoCount = rules.advancedRule.daihyoEnchoCount;
      _advancedDaihyoHasHantei = rules.advancedRule.daihyoHasHantei;

      _editingIsRenseikai = rules.normalRule.isRenseikai;
      if (rules.normalRule.isRenseikai) {
        _editingMatchType = '錬成会';
      } else if (rules.normalRule.isKachinuki) {
        _editingMatchType = '勝ち抜き戦';
      } else if (rules.normalRule.isLeague) {
        _editingMatchType = rules.normalRule.hasLeagueDaihyo
            ? 'リーグ団体戦'
            : 'リーグ個人戦';
      } else if (rules.normalRule.hasLeagueDaihyo) {
        _editingMatchType = '団体戦';
      } else if (rules.matchType.isNotEmpty) {
        _editingMatchType = rules.matchType;
      } else {
        _editingMatchType = category.contains('団体') ? '団体戦' : '個人戦';
      }
    });
  }

  MatchRule _buildNormalMatchRule(String category) {
    return CategoryRuleMatchHelper.buildMatchRule(
      category: category,
      matchType: _editingMatchType,
      matchTime: _normalTime,
      isRunningTime: _normalIsRunningTime,
      isIpponShobu: _normalIsIpponShobu,
      ipponLimit: _normalIpponLimit,
      hansokuLimit: _normalHansokuLimit,
      hasHantei: _normalHasHantei,
      hasExtension: _normalHasExtension,
      isEnchoUnlimited: _normalIsEnchoUnlimited,
      enchoTime: _normalEnchoTime,
      enchoCount: _normalEnchoCount,
      kachinukiUnlimitedType: _normalKachinukiUnlimitedType,
      isDaihyoIpponShobu: _normalIsDaihyoIpponShobu,
      winPoint: _normalWinPoint,
      lossPoint: _normalLossPoint,
      drawPoint: _normalDrawPoint,
      isRenseikai: _editingIsRenseikai,
      renseikaiType: _normalRenseikaiType,
      overallTime: _normalOverallTime,
      daihyoMatchTime: _normalDaihyoMatchTime,
      daihyoHasExtension: _normalDaihyoHasExtension,
      daihyoEnchoTime: _normalDaihyoEnchoTime,
      daihyoEnchoCount: _normalDaihyoEnchoCount,
      daihyoHasHantei: _normalDaihyoHasHantei,
    );
  }

  MatchRule _buildAdvancedMatchRule(String category) {
    return CategoryRuleMatchHelper.buildMatchRule(
      category: category,
      matchType: _editingMatchType,
      matchTime: _advancedTime,
      isRunningTime: _advancedIsRunningTime,
      isIpponShobu: _advancedIsIpponShobu,
      ipponLimit: _advancedIpponLimit,
      hansokuLimit: _advancedHansokuLimit,
      hasHantei: _advancedHasHantei,
      hasExtension: _advancedHasExtension,
      isEnchoUnlimited: _advancedIsEnchoUnlimited,
      enchoTime: _advancedEnchoTime,
      enchoCount: _advancedEnchoCount,
      kachinukiUnlimitedType: _advancedKachinukiUnlimitedType,
      isDaihyoIpponShobu: _advancedIsDaihyoIpponShobu,
      winPoint: _advancedWinPoint,
      lossPoint: _advancedLossPoint,
      drawPoint: _advancedDrawPoint,
      isRenseikai: _editingIsRenseikai,
      renseikaiType: _advancedRenseikaiType,
      overallTime: _advancedOverallTime,
      daihyoMatchTime: _advancedDaihyoMatchTime,
      daihyoHasExtension: _advancedDaihyoHasExtension,
      daihyoEnchoTime: _advancedDaihyoEnchoTime,
      daihyoEnchoCount: _advancedDaihyoEnchoCount,
      daihyoHasHantei: _advancedDaihyoHasHantei,
    );
  }

  Future<void> _saveCategoryRules(TournamentModel tournament) async {
    if (_editingCategory == null) return;

    final category = _editingCategory!;
    final normalRule = _buildNormalMatchRule(category);
    final advancedRule = _buildAdvancedMatchRule(category);

    final renseikaiRule = MatchRule(
      matchTimeMinutes: _renseikaiTime,
      isRunningTime: _renseikaiIsRunningTime,
      hasHantei: _renseikaiHasHantei,
      enchoCount: 0,
      isEnchoUnlimited: false,
      isRenseikai: true,
      renseikaiType: _renseikaiType,
      overallTimeMinutes: _renseikaiOverallTime,
    );

    final moushiawaseRule = MatchRule(
      matchTimeMinutes: _moushiawaseTime,
      isRunningTime: _moushiawaseIsRunningTime,
      hasHantei: _moushiawaseHasHantei,
      enchoCount: 0,
      isEnchoUnlimited: false,
      isRenseikai: true,
      renseikaiType: _moushiawaseType,
      overallTimeMinutes: _moushiawaseOverallTime,
    );

    final newRuleSet = CategoryRuleSet(
      normalRule: normalRule,
      advancedRule: advancedRule,
      useAdvancedRule: _useAdvancedRule,
      advancedKeywords: _editingAdvancedKeywords,
      matchType: _editingIsRenseikai ? '錬成会' : _editingMatchType,
      isMultiScene: _isMultiScene,
      useHonsenRule: _useHonsenRule,
      useRenseikaiRule: _useRenseikaiRule,
      useMoushiawaseRule: _useMoushiawaseRule,
      renseikaiRule: renseikaiRule,
      moushiawaseRule: moushiawaseRule,
    );

    final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
      tournament.categoryRules,
    );
    updatedCategoryRules[category] = newRuleSet;

    // 大会モデルのリスト更新
    List<String> updatedCategories = List.from(tournament.categories);
    if (!updatedCategories.contains(category)) {
      updatedCategories.add(category);
    }

    final updatedTournament = tournament.copyWith(
      categories: updatedCategories,
      categoryRules: updatedCategoryRules,
    );

    // 既存の試合を探して一括適用の判定
    final allMatches =
        ref.read(matchListByTournamentProvider(widget.tournamentId)).value ??
        [];
    final targetMatches = allMatches
        .where(
          (m) =>
              m.category == category &&
              m.status != 'finished' &&
              m.status != 'approved',
        )
        .toList();

    if (targetMatches.isNotEmpty) {
      final result = await CategoryRuleDialogs.showBulkApplyConfirmDialog(
        context: context,
        category: category,
        matchCount: targetMatches.length,
      );

      if (result == 'cancel') return;

      if (result == 'yes') {
        // 既存の試合に適用する
        List<MatchModel> matchesToSave = [];
        for (var match in targetMatches) {
          final isAdvanced =
              _useAdvancedRule &&
              CategoryRuleMatchHelper.isAdvancedMatchName(
                match.note,
                customKeywords: _editingAdvancedKeywords,
              );
          final activeRule = isAdvanced ? advancedRule : normalRule;

          final updatedMatch = match.copyWith(
            matchTimeMinutes: activeRule.matchTimeMinutes,
            isRunningTime: activeRule.isRunningTime,
            hasExtension:
                activeRule.enchoCount > 0 || activeRule.isEnchoUnlimited,
            extensionTimeMinutes: activeRule.enchoTimeMinutes,
            extensionCount: activeRule.enchoCount,
            hasHantei: activeRule.hasHantei,
            isKachinuki: activeRule.isKachinuki,
            rule: activeRule,
          );
          matchesToSave.add(updatedMatch);
        }

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
        _editingCategory = null;
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
      final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
        tournament.categoryRules,
      );
      updatedCategoryRules.remove(category);

      List<String> updatedCategories = List.from(tournament.categories);
      updatedCategories.remove(category);

      final updatedTournament = tournament.copyWith(
        categories: updatedCategories,
        categoryRules: updatedCategoryRules,
      );

      await ref
          .read(tournamentRepositoryProvider)
          .updateTournament(updatedTournament);

      if (mounted) {
        AppSnackBar.show(context, '「$category」を削除しました');
      }
    }
  }

  void _addNewCategory(TournamentModel tournament, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    if (tournament.categoryRules.containsKey(cleanName)) {
      final existingRuleSet = tournament.categoryRules[cleanName]!;
      _startEditing(cleanName, existingRuleSet);
      return;
    }

    // デフォルトルールで登録
    final newRuleSet = CategoryRuleSet(
      normalRule: const MatchRule(matchTimeMinutes: 3.0),
      advancedRule: const MatchRule(matchTimeMinutes: 3.0),
      useAdvancedRule: false,
    );

    final updatedCategoryRules = Map<String, CategoryRuleSet>.from(
      tournament.categoryRules,
    );
    updatedCategoryRules[cleanName] = newRuleSet;

    List<String> updatedCategories = List.from(tournament.categories);
    if (!updatedCategories.contains(cleanName)) {
      updatedCategories.add(cleanName);
    }

    final updatedTournament = tournament.copyWith(
      categories: updatedCategories,
      categoryRules: updatedCategoryRules,
    );

    await ref
        .read(tournamentRepositoryProvider)
        .updateTournament(updatedTournament);
    _newCategoryController.clear();

    if (mounted) {
      AppSnackBar.showSuccess(context, '「$cleanName」を追加しました');
      _startEditing(cleanName, newRuleSet);
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
          title: _editingCategory == null ? '部門別ルール設定' : 'ルールの編集',
          backgroundColor: AppKendoColors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_editingCategory != null) {
                setState(() {
                  _editingCategory = null;
                });
              } else {
                context.pop();
              }
            },
          ),
          actions: [
            if (widget.isFromSetup && _editingCategory == null)
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
            if (_editingCategory != null) {
              return _buildRuleEditor(
                tournament,
                _editingCategory!,
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
              presetCategories: _presetCategories,
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
          loading: () => const Center(child: CircularProgressIndicator()),
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
    final textColor = themeColors.textColor;
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.roundValue),
            children: [
              CategoryRuleEditorHeaderCard(
                category: category,
                textColor: textColor,
                matchType: _editingMatchType,
                isMultiScene: _isMultiScene,
                useAdvancedRule: _useAdvancedRule,
                onMatchTypeChanged: (val) {
                  setState(() {
                    _editingMatchType = val;
                  });
                },
                onMultiSceneChanged: (val) {
                  setState(() {
                    _isMultiScene = val;
                  });
                },
                onUseAdvancedRuleChanged: (val) {
                  setState(() {
                    _useAdvancedRule = val;
                  });
                },
              ),

              if (_isMultiScene) ...[
                CategoryRuleMultiSceneTabsCard(
                  useRenseikaiRule: _useRenseikaiRule,
                  useHonsenRule: _useHonsenRule,
                  useMoushiawaseRule: _useMoushiawaseRule,
                  renseikaiTime: _renseikaiTime,
                  renseikaiIsRunningTime: _renseikaiIsRunningTime,
                  renseikaiHasHantei: _renseikaiHasHantei,
                  renseikaiType: _renseikaiType,
                  renseikaiOverallTime: _renseikaiOverallTime,
                  moushiawaseTime: _moushiawaseTime,
                  moushiawaseIsRunningTime: _moushiawaseIsRunningTime,
                  moushiawaseHasHantei: _moushiawaseHasHantei,
                  moushiawaseType: _moushiawaseType,
                  moushiawaseOverallTime: _moushiawaseOverallTime,
                  honsenRuleSection: _buildRuleFormSection(
                    '🏆 本戦ルール',
                    true,
                    themeColors,
                  ),
                  onUseRenseikaiRuleChanged: (val) =>
                      setState(() => _useRenseikaiRule = val),
                  onUseHonsenRuleChanged: (val) =>
                      setState(() => _useHonsenRule = val),
                  onUseMoushiawaseRuleChanged: (val) =>
                      setState(() => _useMoushiawaseRule = val),
                  onRenseikaiTimeChanged: (val) =>
                      setState(() => _renseikaiTime = val),
                  onRenseikaiRunningChanged: (val) =>
                      setState(() => _renseikaiIsRunningTime = val),
                  onRenseikaiHanteiChanged: (val) =>
                      setState(() => _renseikaiHasHantei = val),
                  onRenseikaiTypeChanged: (val) =>
                      setState(() => _renseikaiType = val),
                  onRenseikaiOverallTimeChanged: (val) =>
                      setState(() => _renseikaiOverallTime = val),
                  onMoushiawaseTimeChanged: (val) =>
                      setState(() => _moushiawaseTime = val),
                  onMoushiawaseRunningChanged: (val) =>
                      setState(() => _moushiawaseIsRunningTime = val),
                  onMoushiawaseHanteiChanged: (val) =>
                      setState(() => _moushiawaseHasHantei = val),
                  onMoushiawaseTypeChanged: (val) =>
                      setState(() => _moushiawaseType = val),
                  onMoushiawaseOverallTimeChanged: (val) =>
                      setState(() => _moushiawaseOverallTime = val),
                ),
              ] else if (!_useAdvancedRule) ...[
                _buildRuleFormSection('通常戦（本戦）ルール', true, themeColors),
              ] else ...[
                CategoryRuleAdvancedTabsCard(
                  normalRuleSection: _buildRuleFormSection(
                    '通常戦ルール',
                    true,
                    themeColors,
                  ),
                  advancedRuleSection: _buildRuleFormSection(
                    '上位戦ルール',
                    false,
                    themeColors,
                  ),
                ),
              ],
            ],
          ),
        ),

        // 下部アクションボタン
        CategoryRuleEditorBottomBar(
          enableLiquidGlass: enableLiquidGlass,
          onCancel: () {
            setState(() {
              _editingCategory = null;
            });
          },
          onSave: () => _saveCategoryRules(tournament),
        ),
      ],
    );
  }

  Widget _buildRuleFormSection(
    String title,
    bool isNormal,
    AppThemeColors themeColors,
  ) {
    return CategoryRuleFormSection(
      title: title,
      isNormal: isNormal,
      themeColors: themeColors,
      matchType: _editingMatchType,
      isRenseikai: _editingIsRenseikai,
      categoryKey: _editingCategory ?? '',
      matchTime: isNormal ? _normalTime : _advancedTime,
      isRunningTime: isNormal ? _normalIsRunningTime : _advancedIsRunningTime,
      ipponLimit: isNormal ? _normalIpponLimit : _advancedIpponLimit,
      hansokuLimit: isNormal ? _normalHansokuLimit : _advancedHansokuLimit,
      hasHantei: isNormal ? _normalHasHantei : _advancedHasHantei,
      hasExtension: isNormal ? _normalHasExtension : _advancedHasExtension,
      isEnchoUnlimited: isNormal
          ? _normalIsEnchoUnlimited
          : _advancedIsEnchoUnlimited,
      enchoTime: isNormal ? _normalEnchoTime : _advancedEnchoTime,
      enchoCount: isNormal ? _normalEnchoCount : _advancedEnchoCount,
      kachinukiUnlimitedType: isNormal
          ? _normalKachinukiUnlimitedType
          : _advancedKachinukiUnlimitedType,
      hasLeagueDaihyo: isNormal
          ? _normalHasLeagueDaihyo
          : _advancedHasLeagueDaihyo,
      isDaihyoIpponShobu: isNormal
          ? _normalIsDaihyoIpponShobu
          : _advancedIsDaihyoIpponShobu,
      winPoint: isNormal ? _normalWinPoint : _advancedWinPoint,
      lossPoint: isNormal ? _normalLossPoint : _advancedLossPoint,
      drawPoint: isNormal ? _normalDrawPoint : _advancedDrawPoint,
      renseikaiType: isNormal ? _normalRenseikaiType : _advancedRenseikaiType,
      overallTime: isNormal ? _normalOverallTime : _advancedOverallTime,
      daihyoMatchTime: isNormal
          ? _normalDaihyoMatchTime
          : _advancedDaihyoMatchTime,
      daihyoHasExtension: isNormal
          ? _normalDaihyoHasExtension
          : _advancedDaihyoHasExtension,
      daihyoEnchoTime: isNormal
          ? _normalDaihyoEnchoTime
          : _advancedDaihyoEnchoTime,
      daihyoEnchoCount: isNormal
          ? _normalDaihyoEnchoCount
          : _advancedDaihyoEnchoCount,
      daihyoHasHantei: isNormal
          ? _normalDaihyoHasHantei
          : _advancedDaihyoHasHantei,
      keywordsController: isNormal ? null : _keywordsController,
      formatMinutes: CategoryRuleMatchHelper.formatMinutes,
      onMatchTimeChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalTime = val;
          } else {
            _advancedTime = val;
          }
        });
      },
      onIsRunningTimeChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalIsRunningTime = val;
          } else {
            _advancedIsRunningTime = val;
          }
        });
      },
      onRenseikaiTypeChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalRenseikaiType = val;
          } else {
            _advancedRenseikaiType = val;
          }
        });
      },
      onOverallTimeChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalOverallTime = val;
          } else {
            _advancedOverallTime = val;
          }
        });
      },
      onKachinukiUnlimitedTypeChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalKachinukiUnlimitedType = val;
          } else {
            _advancedKachinukiUnlimitedType = val;
          }
        });
      },
      onHasExtensionChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalHasExtension = val;
          } else {
            _advancedHasExtension = val;
          }
        });
      },
      onIsEnchoUnlimitedChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalIsEnchoUnlimited = val;
          } else {
            _advancedIsEnchoUnlimited = val;
          }
        });
      },
      onEnchoCountChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalEnchoCount = val;
          } else {
            _advancedEnchoCount = val;
          }
        });
      },
      onEnchoTimeChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalEnchoTime = val;
          } else {
            _advancedEnchoTime = val;
          }
        });
      },
      onHasHanteiChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalHasHantei = val;
          } else {
            _advancedHasHantei = val;
          }
        });
      },
      onHasLeagueDaihyoChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalHasLeagueDaihyo = val;
          } else {
            _advancedHasLeagueDaihyo = val;
          }
        });
      },
      onIsDaihyoIpponShobuChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalIsDaihyoIpponShobu = val;
          } else {
            _advancedIsDaihyoIpponShobu = val;
          }
        });
      },
      onDaihyoMatchTimeChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalDaihyoMatchTime = val;
          } else {
            _advancedDaihyoMatchTime = val;
          }
        });
      },
      onDaihyoHasExtensionChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalDaihyoHasExtension = val;
          } else {
            _advancedDaihyoHasExtension = val;
          }
        });
      },
      onDaihyoEnchoTimeChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalDaihyoEnchoTime = val;
          } else {
            _advancedDaihyoEnchoTime = val;
          }
        });
      },
      onDaihyoEnchoCountChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalDaihyoEnchoCount = val;
          } else {
            _advancedDaihyoEnchoCount = val;
          }
        });
      },
      onDaihyoHasHanteiChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalDaihyoHasHantei = val;
          } else {
            _advancedDaihyoHasHantei = val;
          }
        });
      },
      onWinPointChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalWinPoint = val;
          } else {
            _advancedWinPoint = val;
          }
        });
      },
      onLossPointChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalLossPoint = val;
          } else {
            _advancedLossPoint = val;
          }
        });
      },
      onDrawPointChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalDrawPoint = val;
          } else {
            _advancedDrawPoint = val;
          }
        });
      },
      onIpponLimitChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalIpponLimit = val;
          } else {
            _advancedIpponLimit = val;
          }
        });
      },
      onHansokuLimitChanged: (val) {
        setState(() {
          if (isNormal) {
            _normalHansokuLimit = val;
          } else {
            _advancedHansokuLimit = val;
          }
        });
      },
      onKeywordsChanged: (kws) {
        setState(() {
          _editingAdvancedKeywords = kws;
        });
      },
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
