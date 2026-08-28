import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_apply_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_bottom_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_data_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_differing_banner.dart';

import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_detail_setting_cards.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_preset_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_target_select_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

void showBulkRuleEditSheet(
  BuildContext context,
  String tournamentId,
  List<MatchModel> matches, {
  bool isBunaiksen = true,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final themeColors =
      Theme.of(context).extension<AppThemeColors>() ??
      AppThemeColors.ofMode(
        isDark: isDark,
        mode: isBunaiksen ? 'bunaiksen' : 'operate',
      );

  showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return BulkRuleEditSheet(
        tournamentId: tournamentId,
        matches: matches,
        themeColors: themeColors,
      );
    },
  );
}

class BulkRuleEditSheet extends ConsumerStatefulWidget {
  final String tournamentId;
  final List<MatchModel> matches;
  final AppThemeColors themeColors;

  const BulkRuleEditSheet({
    super.key,
    required this.tournamentId,
    required this.matches,
    required this.themeColors,
  });

  @override
  ConsumerState<BulkRuleEditSheet> createState() => _BulkRuleEditSheetState();
}

class _BulkRuleEditSheetState extends ConsumerState<BulkRuleEditSheet> {
  String _selectedCategoryFilter = 'すべて';
  String _selectedTypeFilter = 'すべて';
  List<String> _selectedMatchIds = [];
  String? _loadedMatchId;
  String? _selectedCategoryRuleName;
  String _selectedSceneType = 'normal';

  late double _matchTime;
  late bool _isIpponShobu;
  late bool _hasExtension;
  late double _enchoTime;
  late int _enchoCount;
  late bool _isEnchoUnlimited;
  late bool _hasHantei;

  late bool _hasRepresentativeMatch;
  late bool _isDaihyoIpponShobu;

  late bool _isRenseikai;
  late String _renseikaiType;
  final _overallTimeController = TextEditingController();

  late List<String> _categories;
  late List<String> _matchTypes;

  bool get _isCurrentFilterTeamMatch {
    if (_selectedTypeFilter.contains('団体')) return true;
    if (_selectedTypeFilter.contains('個人')) return false;
    final selectedMatches = widget.matches
        .where((m) => _selectedMatchIds.contains(m.id))
        .toList();
    if (selectedMatches.isEmpty) return false;
    return selectedMatches.any(
      (m) => BulkRuleDataHelper.getResolvedType(m).contains('団体'),
    );
  }

  bool get _isCurrentFilterIndividualMatch {
    if (_selectedTypeFilter.contains('個人')) return true;
    if (_selectedTypeFilter.contains('団体')) return false;
    final selectedMatches = widget.matches
        .where((m) => _selectedMatchIds.contains(m.id))
        .toList();
    if (selectedMatches.isEmpty) return false;
    return selectedMatches.any(
      (m) => BulkRuleDataHelper.getResolvedType(m).contains('個人'),
    );
  }

  void _applyCategoryRuleSet(MatchRule targetRule, {String? sceneKey}) {
    final res = BulkRuleApplyHelper.computeRuleParams(
      targetRule: targetRule,
      isTeam: _isCurrentFilterTeamMatch,
      isIndiv: _isCurrentFilterIndividualMatch,
      sceneKey: sceneKey,
    );

    setState(() {
      _matchTime = res.matchTime;
      _isIpponShobu = res.isIpponShobu;
      _hasExtension = res.hasExtension;
      _enchoTime = res.enchoTime;
      _enchoCount = res.enchoCount;
      _isEnchoUnlimited = res.isEnchoUnlimited;
      _hasHantei = res.hasHantei;
      _hasRepresentativeMatch = res.hasRepresentativeMatch;
      _isDaihyoIpponShobu = res.isDaihyoIpponShobu;
      _isRenseikai = res.isRenseikai;
      _renseikaiType = res.renseikaiType;
      _overallTimeController.text = res.overallTimeMinutes.toString();
    });
  }

  void _loadTemplateRules(MatchModel m) {
    _loadedMatchId = m.id;
    final res = BulkRuleApplyHelper.loadTemplate(m);
    _matchTime = res.matchTime;
    _isIpponShobu = res.isIpponShobu;
    _hasExtension = res.hasExtension;
    _enchoTime = res.enchoTime;
    _enchoCount = res.enchoCount;
    _isEnchoUnlimited = res.isEnchoUnlimited;
    _hasHantei = res.hasHantei;
    _hasRepresentativeMatch = res.hasRepresentativeMatch;
    _isDaihyoIpponShobu = res.isDaihyoIpponShobu;
    _isRenseikai = res.isRenseikai;
    _renseikaiType = res.renseikaiType;
    _overallTimeController.text = res.overallTimeMinutes.toString();
  }

  void _updateLoadedTemplateIfNecessary() {
    final selectedMatches = widget.matches
        .where((m) => _selectedMatchIds.contains(m.id))
        .toList();
    if (selectedMatches.isEmpty) {
      _loadedMatchId = null;
      return;
    }
    final first = selectedMatches.first;
    if (_loadedMatchId != first.id) {
      _loadTemplateRules(first);
    }
  }

  bool _hasDifferingRules() {
    final selectedMatches = widget.matches
        .where((m) => _selectedMatchIds.contains(m.id))
        .toList();
    return BulkRuleDataHelper.hasDifferingRules(selectedMatches);
  }

  @override
  void initState() {
    super.initState();
    _categories = [
      'すべて',
      ...widget.matches
          .map((m) => m.category)
          .whereType<String>()
          .where((cat) => cat.isNotEmpty)
          .toSet(),
    ];

    _matchTypes = [
      'すべて',
      ...widget.matches.map(BulkRuleDataHelper.getResolvedType).toSet(),
    ];

    _matchTime = 3.0;
    _isIpponShobu = false;
    _hasExtension = false;
    _enchoTime = 3.0;
    _enchoCount = 1;
    _isEnchoUnlimited = false;
    _hasHantei = false;
    _hasRepresentativeMatch = true;
    _isDaihyoIpponShobu = true;
    _isRenseikai = false;
    _renseikaiType = '一試合制';
    _overallTimeController.text = '30';

    _applyFiltersAndSelectAll();

    final initialSelected = widget.matches
        .where((m) => _selectedMatchIds.contains(m.id))
        .toList();
    if (initialSelected.isNotEmpty) {
      _loadTemplateRules(initialSelected.first);
    }
  }

  @override
  void dispose() {
    _overallTimeController.dispose();
    super.dispose();
  }

  void _applyFiltersAndSelectAll() {
    final filteredUnits = BulkRuleDataHelper.buildGroupUnits(widget.matches)
        .where((unit) {
          final isCategoryMatch =
              _selectedCategoryFilter == 'すべて' ||
              unit.category == _selectedCategoryFilter;
          final isTypeMatch =
              _selectedTypeFilter == 'すべて' ||
              unit.resolvedType == _selectedTypeFilter;
          return isCategoryMatch && isTypeMatch;
        });

    setState(() {
      _selectedMatchIds = filteredUnits
          .expand((unit) => unit.matchIds)
          .toList();
      _updateLoadedTemplateIfNecessary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;

    final currentFilteredUnits =
        BulkRuleDataHelper.buildGroupUnits(widget.matches).where((unit) {
          final isCategoryMatch =
              _selectedCategoryFilter == 'すべて' ||
              unit.category == _selectedCategoryFilter;
          final isTypeMatch =
              _selectedTypeFilter == 'すべて' ||
              unit.resolvedType == _selectedTypeFilter;
          return isCategoryMatch && isTypeMatch;
        }).toList();

    final allUnits = BulkRuleDataHelper.buildGroupUnits(widget.matches);
    final totalSelectedUnitsCount = allUnits.where((unit) {
      return unit.matchIds.every((id) => _selectedMatchIds.contains(id));
    }).length;

    return AppBottomSheetContent(
      showDragHandle: true,
      title: '⚙️ 試合ルールの一括変更',
      titleTrailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.roundValue),
                children: [
                  // STEP 1. 対象選択
                  BulkRuleTargetSelectSection(
                    categories: _categories,
                    matchTypes: _matchTypes,
                    selectedCategoryFilter: _selectedCategoryFilter,
                    selectedTypeFilter: _selectedTypeFilter,
                    filteredUnits: currentFilteredUnits,
                    selectedMatchIds: _selectedMatchIds,
                    primaryAccent: widget.themeColors.primaryAccent,
                    isDark: isDark,
                    textColor: textColor,
                    onCategoryChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategoryFilter = val);
                        _applyFiltersAndSelectAll();
                      }
                    },
                    onTypeChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTypeFilter = val);
                        _applyFiltersAndSelectAll();
                      }
                    },
                    onToggleUnit: (unit, val) {
                      setState(() {
                        if (val == true) {
                          for (final id in unit.matchIds) {
                            if (!_selectedMatchIds.contains(id)) {
                              _selectedMatchIds.add(id);
                            }
                          }
                        } else {
                          for (final id in unit.matchIds) {
                            _selectedMatchIds.remove(id);
                          }
                        }
                        _updateLoadedTemplateIfNecessary();
                      });
                    },
                    onToggleAll: () {
                      setState(() {
                        final allSelected = currentFilteredUnits.every(
                          (unit) => unit.matchIds.every(
                            (id) => _selectedMatchIds.contains(id),
                          ),
                        );
                        if (allSelected) {
                          for (final unit in currentFilteredUnits) {
                            for (final id in unit.matchIds) {
                              _selectedMatchIds.remove(id);
                            }
                          }
                        } else {
                          for (final unit in currentFilteredUnits) {
                            for (final id in unit.matchIds) {
                              if (!_selectedMatchIds.contains(id)) {
                                _selectedMatchIds.add(id);
                              }
                            }
                          }
                        }
                        _updateLoadedTemplateIfNecessary();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // STEP 2. 新ルールの設定
                  Text(
                    'STEP 2: 新しいルールを設定',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: widget.themeColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 部門別ルールプリセットからの選択UI
                  ...(() {
                    final asyncTournament = ref.watch(
                      tournamentProvider(widget.tournamentId),
                    );
                    final categoryRules =
                        asyncTournament.valueOrNull?.categoryRules ?? {};
                    if (categoryRules.isEmpty) return <Widget>[];

                    return [
                      BulkRulePresetCard(
                        categoryRules: categoryRules,
                        selectedCategoryRuleName: _selectedCategoryRuleName,
                        selectedSceneType: _selectedSceneType,
                        primaryAccent: widget.themeColors.primaryAccent,
                        isDark: isDark,
                        textColor: textColor,
                        onSelectCategory: (catName, ruleSet) {
                          setState(() {
                            _selectedCategoryRuleName = catName;
                            _selectedSceneType = 'normal';
                            _applyCategoryRuleSet(ruleSet.normalRule);
                          });
                        },
                        onSelectScene: (sceneKey, targetRule) {
                          setState(() {
                            _selectedSceneType = sceneKey;
                            _applyCategoryRuleSet(
                              targetRule,
                              sceneKey: sceneKey,
                            );
                          });
                        },
                      ),
                    ];
                  })(),

                  if (_hasDifferingRules()) ...[
                    BulkRuleDifferingBanner(isDark: isDark),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  BulkRuleDetailSettingCards(
                    matchTime: _matchTime,
                    isIpponShobu: _isIpponShobu,
                    hasExtension: _hasExtension,
                    enchoTime: _enchoTime,
                    enchoCount: _enchoCount,
                    isEnchoUnlimited: _isEnchoUnlimited,
                    hasHantei: _hasHantei,
                    hasRepresentativeMatch: _hasRepresentativeMatch,
                    isDaihyoIpponShobu: _isDaihyoIpponShobu,
                    isRenseikai: _isRenseikai,
                    renseikaiType: _renseikaiType,
                    overallTimeController: _overallTimeController,
                    primaryAccent: widget.themeColors.primaryAccent,
                    isDark: isDark,
                    onMatchTimeChanged: (v) => setState(() => _matchTime = v),
                    onIpponShobuChanged: (v) =>
                        setState(() => _isIpponShobu = v),
                    onExtensionChanged: (v) =>
                        setState(() => _hasExtension = v),
                    onEnchoTimeChanged: (v) => setState(() => _enchoTime = v),
                    onEnchoCountChanged: (v) => setState(() => _enchoCount = v),
                    onEnchoUnlimitedChanged: (v) =>
                        setState(() => _isEnchoUnlimited = v),
                    onHanteiChanged: (v) => setState(() => _hasHantei = v),
                    onRepresentativeMatchChanged: (v) =>
                        setState(() => _hasRepresentativeMatch = v),
                    onDaihyoIpponShobuChanged: (v) =>
                        setState(() => _isDaihyoIpponShobu = v),
                    onRenseikaiChanged: (v) => setState(() => _isRenseikai = v),
                    onRenseikaiTypeChanged: (v) =>
                        setState(() => _renseikaiType = v),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),

            // 下部固定実行ボタン
            BulkRuleBottomBar(
              totalSelectedUnitsCount: totalSelectedUnitsCount,
              hasSelection: _selectedMatchIds.isNotEmpty,
              primaryAccent: widget.themeColors.primaryAccent,
              isDark: isDark,
              onApply: () async {
                final newRule = MatchRule(
                  matchTimeMinutes: _matchTime,
                  isIpponShobu: _isIpponShobu,
                  hasHantei: _hasHantei,
                  isEnchoUnlimited: _isEnchoUnlimited,
                  enchoTimeMinutes: _hasExtension ? _enchoTime : 0.0,
                  enchoCount: _isEnchoUnlimited ? 0 : _enchoCount,
                  hasRepresentativeMatch: _hasRepresentativeMatch,
                  isDaihyoIpponShobu: _isDaihyoIpponShobu,
                  isRenseikai: _isRenseikai,
                  renseikaiType: _renseikaiType,
                  overallTimeMinutes:
                      int.tryParse(_overallTimeController.text) ?? 30,
                );

                await ref
                    .read(matchCommandProvider)
                    .bulkUpdateMatchRules(
                      targetMatchIds: _selectedMatchIds,
                      newRule: newRule,
                    );

                if (context.mounted) {
                  AppSnackBar.showSuccess(
                    context,
                    '$totalSelectedUnitsCount件の対戦ルールを一括変更しました。',
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
