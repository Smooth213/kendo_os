import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
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

  MatchRule _buildRuleForCategory(String category, {required bool isNormal}) {
    return CategoryRuleMatchHelper.buildMatchRule(
      category: category,
      matchType: _editingMatchType,
      matchTime: isNormal ? _normalTime : _advancedTime,
      isRunningTime: isNormal ? _normalIsRunningTime : _advancedIsRunningTime,
      isIpponShobu: isNormal ? _normalIsIpponShobu : _advancedIsIpponShobu,
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
      isDaihyoIpponShobu: isNormal
          ? _normalIsDaihyoIpponShobu
          : _advancedIsDaihyoIpponShobu,
      winPoint: isNormal ? _normalWinPoint : _advancedWinPoint,
      lossPoint: isNormal ? _normalLossPoint : _advancedLossPoint,
      drawPoint: isNormal ? _normalDrawPoint : _advancedDrawPoint,
      isRenseikai: _editingIsRenseikai,
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
    );
  }

  Future<void> _saveCategoryRules(TournamentModel tournament) async {
    if (_editingCategory == null) return;

    final category = _editingCategory!;
    final normalRule = _buildRuleForCategory(category, isNormal: true);
    final advancedRule = _buildRuleForCategory(category, isNormal: false);

    final newRuleSet = CategoryRuleMatchHelper.createCategoryRuleSet(
      normalRule: normalRule,
      advancedRule: advancedRule,
      useAdvancedRule: _useAdvancedRule,
      advancedKeywords: _editingAdvancedKeywords,
      matchType: _editingMatchType,
      isRenseikai: _editingIsRenseikai,
      isMultiScene: _isMultiScene,
      useHonsenRule: _useHonsenRule,
      useRenseikaiRule: _useRenseikaiRule,
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
    );

    final updatedTournament =
        CategoryRuleMatchHelper.updateTournamentWithRuleSet(
          tournament: tournament,
          category: category,
          ruleSet: newRuleSet,
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
        final matchesToSave = CategoryRuleMatchHelper.applyRulesToMatches(
          targetMatches: targetMatches,
          ruleSet: newRuleSet,
          useAdvancedRule: _useAdvancedRule,
          advancedKeywords: _editingAdvancedKeywords,
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

    final (updated, ruleSet) = CategoryRuleMatchHelper.addCategoryToTournament(
      tournament,
      cleanName,
    );

    await ref.read(tournamentRepositoryProvider).updateTournament(updated);
    _newCategoryController.clear();

    if (mounted) {
      AppSnackBar.showSuccess(context, '「$cleanName」を追加しました');
      _startEditing(cleanName, ruleSet);
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
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );

    return CategoryRuleEditorView(
      category: category,
      themeColors: themeColors,
      enableLiquidGlass: enableLiquidGlass,
      editingMatchType: _editingMatchType,
      isMultiScene: _isMultiScene,
      useAdvancedRule: _useAdvancedRule,
      editingIsRenseikai: _editingIsRenseikai,
      onMatchTypeChanged: (val) => setState(() => _editingMatchType = val),
      onMultiSceneChanged: (val) => setState(() => _isMultiScene = val),
      onUseAdvancedRuleChanged: (val) => setState(() => _useAdvancedRule = val),
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
      onUseRenseikaiRuleChanged: (val) =>
          setState(() => _useRenseikaiRule = val),
      onUseHonsenRuleChanged: (val) => setState(() => _useHonsenRule = val),
      onUseMoushiawaseRuleChanged: (val) =>
          setState(() => _useMoushiawaseRule = val),
      onRenseikaiTimeChanged: (val) => setState(() => _renseikaiTime = val),
      onRenseikaiRunningChanged: (val) =>
          setState(() => _renseikaiIsRunningTime = val),
      onRenseikaiHanteiChanged: (val) =>
          setState(() => _renseikaiHasHantei = val),
      onRenseikaiTypeChanged: (val) => setState(() => _renseikaiType = val),
      onRenseikaiOverallTimeChanged: (val) =>
          setState(() => _renseikaiOverallTime = val),
      onMoushiawaseTimeChanged: (val) => setState(() => _moushiawaseTime = val),
      onMoushiawaseRunningChanged: (val) =>
          setState(() => _moushiawaseIsRunningTime = val),
      onMoushiawaseHanteiChanged: (val) =>
          setState(() => _moushiawaseHasHantei = val),
      onMoushiawaseTypeChanged: (val) => setState(() => _moushiawaseType = val),
      onMoushiawaseOverallTimeChanged: (val) =>
          setState(() => _moushiawaseOverallTime = val),
      normalTime: _normalTime,
      normalIsRunningTime: _normalIsRunningTime,
      normalIpponLimit: _normalIpponLimit,
      normalHansokuLimit: _normalHansokuLimit,
      normalHasHantei: _normalHasHantei,
      normalHasExtension: _normalHasExtension,
      normalIsEnchoUnlimited: _normalIsEnchoUnlimited,
      normalEnchoTime: _normalEnchoTime,
      normalEnchoCount: _normalEnchoCount,
      normalKachinukiUnlimitedType: _normalKachinukiUnlimitedType,
      normalHasLeagueDaihyo: _normalHasLeagueDaihyo,
      normalIsDaihyoIpponShobu: _normalIsDaihyoIpponShobu,
      normalWinPoint: _normalWinPoint,
      normalLossPoint: _normalLossPoint,
      normalDrawPoint: _normalDrawPoint,
      normalRenseikaiType: _normalRenseikaiType,
      normalOverallTime: _normalOverallTime,
      normalDaihyoMatchTime: _normalDaihyoMatchTime,
      normalDaihyoHasExtension: _normalDaihyoHasExtension,
      normalDaihyoEnchoTime: _normalDaihyoEnchoTime,
      normalDaihyoEnchoCount: _normalDaihyoEnchoCount,
      normalDaihyoHasHantei: _normalDaihyoHasHantei,
      advancedTime: _advancedTime,
      advancedIsRunningTime: _advancedIsRunningTime,
      advancedIpponLimit: _advancedIpponLimit,
      advancedHansokuLimit: _advancedHansokuLimit,
      advancedHasHantei: _advancedHasHantei,
      advancedHasExtension: _advancedHasExtension,
      advancedIsEnchoUnlimited: _advancedIsEnchoUnlimited,
      advancedEnchoTime: _advancedEnchoTime,
      advancedEnchoCount: _advancedEnchoCount,
      advancedKachinukiUnlimitedType: _advancedKachinukiUnlimitedType,
      advancedHasLeagueDaihyo: _advancedHasLeagueDaihyo,
      advancedIsDaihyoIpponShobu: _advancedIsDaihyoIpponShobu,
      advancedWinPoint: _advancedWinPoint,
      advancedLossPoint: _advancedLossPoint,
      advancedDrawPoint: _advancedDrawPoint,
      advancedRenseikaiType: _advancedRenseikaiType,
      advancedOverallTime: _advancedOverallTime,
      advancedDaihyoMatchTime: _advancedDaihyoMatchTime,
      advancedDaihyoHasExtension: _advancedDaihyoHasExtension,
      advancedDaihyoEnchoTime: _advancedDaihyoEnchoTime,
      advancedDaihyoEnchoCount: _advancedDaihyoEnchoCount,
      advancedDaihyoHasHantei: _advancedDaihyoHasHantei,
      keywordsController: _keywordsController,
      onNormalMatchTimeChanged: (val) => setState(() => _normalTime = val),
      onNormalIsRunningTimeChanged: (val) =>
          setState(() => _normalIsRunningTime = val),
      onNormalRenseikaiTypeChanged: (val) =>
          setState(() => _normalRenseikaiType = val),
      onNormalOverallTimeChanged: (val) =>
          setState(() => _normalOverallTime = val),
      onNormalKachinukiUnlimitedTypeChanged: (val) =>
          setState(() => _normalKachinukiUnlimitedType = val),
      onNormalHasExtensionChanged: (val) =>
          setState(() => _normalHasExtension = val),
      onNormalIsEnchoUnlimitedChanged: (val) =>
          setState(() => _normalIsEnchoUnlimited = val),
      onNormalEnchoCountChanged: (val) =>
          setState(() => _normalEnchoCount = val),
      onNormalEnchoTimeChanged: (val) => setState(() => _normalEnchoTime = val),
      onNormalHasHanteiChanged: (val) => setState(() => _normalHasHantei = val),
      onNormalHasLeagueDaihyoChanged: (val) =>
          setState(() => _normalHasLeagueDaihyo = val),
      onNormalIsDaihyoIpponShobuChanged: (val) =>
          setState(() => _normalIsDaihyoIpponShobu = val),
      onNormalDaihyoMatchTimeChanged: (val) =>
          setState(() => _normalDaihyoMatchTime = val),
      onNormalDaihyoHasExtensionChanged: (val) =>
          setState(() => _normalDaihyoHasExtension = val),
      onNormalDaihyoEnchoTimeChanged: (val) =>
          setState(() => _normalDaihyoEnchoTime = val),
      onNormalDaihyoEnchoCountChanged: (val) =>
          setState(() => _normalDaihyoEnchoCount = val),
      onNormalDaihyoHasHanteiChanged: (val) =>
          setState(() => _normalDaihyoHasHantei = val),
      onNormalWinPointChanged: (val) => setState(() => _normalWinPoint = val),
      onNormalLossPointChanged: (val) => setState(() => _normalLossPoint = val),
      onNormalDrawPointChanged: (val) => setState(() => _normalDrawPoint = val),
      onNormalIpponLimitChanged: (val) =>
          setState(() => _normalIpponLimit = val),
      onNormalHansokuLimitChanged: (val) =>
          setState(() => _normalHansokuLimit = val),
      onAdvancedMatchTimeChanged: (val) => setState(() => _advancedTime = val),
      onAdvancedIsRunningTimeChanged: (val) =>
          setState(() => _advancedIsRunningTime = val),
      onAdvancedRenseikaiTypeChanged: (val) =>
          setState(() => _advancedRenseikaiType = val),
      onAdvancedOverallTimeChanged: (val) =>
          setState(() => _advancedOverallTime = val),
      onAdvancedKachinukiUnlimitedTypeChanged: (val) =>
          setState(() => _advancedKachinukiUnlimitedType = val),
      onAdvancedHasExtensionChanged: (val) =>
          setState(() => _advancedHasExtension = val),
      onAdvancedIsEnchoUnlimitedChanged: (val) =>
          setState(() => _advancedIsEnchoUnlimited = val),
      onAdvancedEnchoCountChanged: (val) =>
          setState(() => _advancedEnchoCount = val),
      onAdvancedEnchoTimeChanged: (val) =>
          setState(() => _advancedEnchoTime = val),
      onAdvancedHasHanteiChanged: (val) =>
          setState(() => _advancedHasHantei = val),
      onAdvancedHasLeagueDaihyoChanged: (val) =>
          setState(() => _advancedHasLeagueDaihyo = val),
      onAdvancedIsDaihyoIpponShobuChanged: (val) =>
          setState(() => _advancedIsDaihyoIpponShobu = val),
      onAdvancedDaihyoMatchTimeChanged: (val) =>
          setState(() => _advancedDaihyoMatchTime = val),
      onAdvancedDaihyoHasExtensionChanged: (val) =>
          setState(() => _advancedDaihyoHasExtension = val),
      onAdvancedDaihyoEnchoTimeChanged: (val) =>
          setState(() => _advancedDaihyoEnchoTime = val),
      onAdvancedDaihyoEnchoCountChanged: (val) =>
          setState(() => _advancedDaihyoEnchoCount = val),
      onAdvancedDaihyoHasHanteiChanged: (val) =>
          setState(() => _advancedDaihyoHasHantei = val),
      onAdvancedWinPointChanged: (val) =>
          setState(() => _advancedWinPoint = val),
      onAdvancedLossPointChanged: (val) =>
          setState(() => _advancedLossPoint = val),
      onAdvancedDrawPointChanged: (val) =>
          setState(() => _advancedDrawPoint = val),
      onAdvancedIpponLimitChanged: (val) =>
          setState(() => _advancedIpponLimit = val),
      onAdvancedHansokuLimitChanged: (val) =>
          setState(() => _advancedHansokuLimit = val),
      onKeywordsChanged: (kws) =>
          setState(() => _editingAdvancedKeywords = kws),
      onCancel: () => setState(() => _editingCategory = null),
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
