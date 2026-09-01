import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_bottom_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_data_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_form_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_state_holder.dart';
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
  final _state = BulkRuleStateHolder();
  late List<String> _categories;
  late List<String> _matchTypes;

  bool get _isCurrentFilterTeamMatch {
    if (_state.selectedTypeFilter.contains('団体')) return true;
    if (_state.selectedTypeFilter.contains('個人')) return false;
    final selectedMatches = widget.matches
        .where((m) => _state.selectedMatchIds.contains(m.id))
        .toList();
    if (selectedMatches.isEmpty) return false;
    return selectedMatches.any(
      (m) => BulkRuleDataHelper.getResolvedType(m).contains('団体'),
    );
  }

  void _updateLoadedTemplateIfNecessary() {
    final selectedMatches = widget.matches
        .where((m) => _state.selectedMatchIds.contains(m.id))
        .toList();
    if (selectedMatches.isEmpty) {
      _state.loadedMatchId = null;
      return;
    }
    final first = selectedMatches.first;
    if (_state.loadedMatchId != first.id) {
      _state.loadTemplateRules(first);
    }
  }

  void _applyFiltersAndSelectAll() {
    final filteredUnits = BulkRuleDataHelper.buildGroupUnits(widget.matches)
        .where((unit) {
          final isCategoryMatch =
              _state.selectedCategoryFilter == 'すべて' ||
              unit.category == _state.selectedCategoryFilter;
          final isTypeMatch =
              _state.selectedTypeFilter == 'すべて' ||
              unit.resolvedType == _state.selectedTypeFilter;
          return isCategoryMatch && isTypeMatch;
        });

    setState(() {
      _state.selectedMatchIds = filteredUnits
          .expand((unit) => unit.matchIds)
          .toList();
      _updateLoadedTemplateIfNecessary();
    });
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

    _applyFiltersAndSelectAll();

    final initialSelected = widget.matches
        .where((m) => _state.selectedMatchIds.contains(m.id))
        .toList();
    if (initialSelected.isNotEmpty) {
      _state.loadTemplateRules(initialSelected.first);
    }
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.appColors.textColor;

    final currentFilteredUnits =
        BulkRuleDataHelper.buildGroupUnits(widget.matches).where((unit) {
          final isCategoryMatch =
              _state.selectedCategoryFilter == 'すべて' ||
              unit.category == _state.selectedCategoryFilter;
          final isTypeMatch =
              _state.selectedTypeFilter == 'すべて' ||
              unit.resolvedType == _state.selectedTypeFilter;
          return isCategoryMatch && isTypeMatch;
        }).toList();

    final allUnits = BulkRuleDataHelper.buildGroupUnits(widget.matches);
    final totalSelectedUnitsCount = allUnits.where((unit) {
      return unit.matchIds.every((id) => _state.selectedMatchIds.contains(id));
    }).length;

    final selectedMatches = widget.matches
        .where((m) => _state.selectedMatchIds.contains(m.id))
        .toList();
    final hasDiffering = BulkRuleDataHelper.hasDifferingRules(selectedMatches);

    return AppBottomSheetContent(
      showDragHandle: true,
      title: '⚡ ルール一括変更',
      titleTrailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
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
                    selectedCategoryFilter: _state.selectedCategoryFilter,
                    selectedTypeFilter: _state.selectedTypeFilter,
                    filteredUnits: currentFilteredUnits,
                    selectedMatchIds: _state.selectedMatchIds,
                    primaryAccent: widget.themeColors.primaryAccent,
                    isDark: isDark,
                    textColor: textColor,
                    onCategoryChanged: (val) {
                      if (val != null) {
                        setState(() => _state.selectedCategoryFilter = val);
                        _applyFiltersAndSelectAll();
                      }
                    },
                    onTypeChanged: (val) {
                      if (val != null) {
                        setState(() => _state.selectedTypeFilter = val);
                        _applyFiltersAndSelectAll();
                      }
                    },
                    onToggleUnit: (unit, val) {
                      setState(() {
                        if (val == true) {
                          for (final id in unit.matchIds) {
                            if (!_state.selectedMatchIds.contains(id)) {
                              _state.selectedMatchIds.add(id);
                            }
                          }
                        } else {
                          for (final id in unit.matchIds) {
                            _state.selectedMatchIds.remove(id);
                          }
                        }
                        _updateLoadedTemplateIfNecessary();
                      });
                    },
                    onToggleAll: () {
                      setState(() {
                        final allSelected = currentFilteredUnits.every(
                          (unit) => unit.matchIds.every(
                            (id) => _state.selectedMatchIds.contains(id),
                          ),
                        );
                        if (allSelected) {
                          for (final unit in currentFilteredUnits) {
                            for (final id in unit.matchIds) {
                              _state.selectedMatchIds.remove(id);
                            }
                          }
                        } else {
                          for (final unit in currentFilteredUnits) {
                            for (final id in unit.matchIds) {
                              if (!_state.selectedMatchIds.contains(id)) {
                                _state.selectedMatchIds.add(id);
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
                  ...(() {
                    final asyncTournament = ref.watch(
                      tournamentProvider(widget.tournamentId),
                    );
                    final categoryRules =
                        asyncTournament.valueOrNull?.categoryRules ?? {};

                    return [
                      BulkRuleFormSection(
                        categoryRules: categoryRules,
                        selectedCategoryRuleName:
                            _state.selectedCategoryRuleName,
                        selectedSceneType: _state.selectedSceneType,
                        primaryAccent: widget.themeColors.primaryAccent,
                        isDark: isDark,
                        textColor: textColor,
                        hasDifferingRules: hasDiffering,
                        isDantai: _isCurrentFilterTeamMatch,
                        matchTime: _state.matchTime,
                        isRunningTime: _state.isRunningTime,
                        isIpponShobu: _state.isIpponShobu,
                        ipponLimit: _state.ipponLimit,
                        hansokuLimit: _state.hansokuLimit,
                        hasExtension: _state.hasExtension,
                        enchoTime: _state.enchoTime,
                        enchoCount: _state.enchoCount,
                        isEnchoUnlimited: _state.isEnchoUnlimited,
                        hasHantei: _state.hasHantei,
                        hasRepresentativeMatch: _state.hasRepresentativeMatch,
                        isDaihyoIpponShobu: _state.isDaihyoIpponShobu,
                        daihyoMatchTime: _state.daihyoMatchTime,
                        daihyoHasExtension: _state.daihyoHasExtension,
                        daihyoEnchoTime: _state.daihyoEnchoTime,
                        daihyoEnchoCount: _state.daihyoEnchoCount,
                        isDaihyoEnchoUnlimited: _state.isDaihyoEnchoUnlimited,
                        daihyoHasHantei: _state.daihyoHasHantei,
                        renseikaiType: _state.renseikaiType,
                        overallTimeController: _state.overallTimeController,
                        isKachinuki: _state.isKachinuki,
                        kachinukiUnlimitedType: _state.kachinukiUnlimitedType,
                        isLeague: _state.isLeague,
                        winPoint: _state.winPoint,
                        lossPoint: _state.lossPoint,
                        drawPoint: _state.drawPoint,
                        onSelectCategory: (catName, ruleSet) {
                          setState(() {
                            _state.selectedCategoryRuleName = catName;
                            _state.selectedSceneType = 'normal';
                            _state.applyCategoryRuleSet(
                              ruleSet.normalRule,
                              isTeam: _isCurrentFilterTeamMatch,
                            );
                          });
                        },
                        onSelectScene: (sceneKey, targetRule) {
                          setState(() {
                            _state.selectedSceneType = sceneKey;
                            _state.applyCategoryRuleSet(
                              targetRule,
                              isTeam: _isCurrentFilterTeamMatch,
                              sceneKey: sceneKey,
                            );
                          });
                        },
                        onMatchTimeChanged: (v) =>
                            setState(() => _state.matchTime = v),
                        onRunningTimeChanged: (v) =>
                            setState(() => _state.isRunningTime = v),
                        onIpponShobuChanged: (v) =>
                            setState(() => _state.isIpponShobu = v),
                        onIpponLimitChanged: (v) =>
                            setState(() => _state.ipponLimit = v),
                        onHansokuLimitChanged: (v) =>
                            setState(() => _state.hansokuLimit = v),
                        onExtensionChanged: (v) =>
                            setState(() => _state.hasExtension = v),
                        onEnchoTimeChanged: (v) =>
                            setState(() => _state.enchoTime = v),
                        onEnchoCountChanged: (v) =>
                            setState(() => _state.enchoCount = v),
                        onEnchoUnlimitedChanged: (v) =>
                            setState(() => _state.isEnchoUnlimited = v),
                        onHanteiChanged: (v) =>
                            setState(() => _state.hasHantei = v),
                        onRepresentativeMatchChanged: (v) =>
                            setState(() => _state.hasRepresentativeMatch = v),
                        onDaihyoIpponShobuChanged: (v) =>
                            setState(() => _state.isDaihyoIpponShobu = v),
                        onDaihyoMatchTimeChanged: (v) =>
                            setState(() => _state.daihyoMatchTime = v),
                        onDaihyoExtensionChanged: (v) =>
                            setState(() => _state.daihyoHasExtension = v),
                        onDaihyoEnchoTimeChanged: (v) =>
                            setState(() => _state.daihyoEnchoTime = v),
                        onDaihyoEnchoCountChanged: (v) =>
                            setState(() => _state.daihyoEnchoCount = v),
                        onDaihyoEnchoUnlimitedChanged: (v) =>
                            setState(() => _state.isDaihyoEnchoUnlimited = v),
                        onDaihyoHanteiChanged: (v) =>
                            setState(() => _state.daihyoHasHantei = v),
                        onRenseikaiTypeChanged: (v) =>
                            setState(() => _state.renseikaiType = v),
                        onOverallTimeChanged: (v) => setState(() {
                          _state.overallTimeController.text = v.toString();
                        }),
                        onKachinukiChanged: (v) =>
                            setState(() => _state.isKachinuki = v),
                        onKachinukiUnlimitedTypeChanged: (v) =>
                            setState(() => _state.kachinukiUnlimitedType = v),
                        onLeagueChanged: (v) =>
                            setState(() => _state.isLeague = v),
                        onWinPointChanged: (v) =>
                            setState(() => _state.winPoint = v),
                        onLossPointChanged: (v) =>
                            setState(() => _state.lossPoint = v),
                        onDrawPointChanged: (v) =>
                            setState(() => _state.drawPoint = v),
                      ),
                    ];
                  })(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),

            // 下部固定実行ボタン
            BulkRuleBottomBar(
              totalSelectedUnitsCount: totalSelectedUnitsCount,
              hasSelection: _state.selectedMatchIds.isNotEmpty,
              primaryAccent: widget.themeColors.primaryAccent,
              isDark: isDark,
              onApply: () async {
                final newRule = _state.buildNewRule();

                await ref
                    .read(matchCommandProvider)
                    .bulkUpdateMatchRules(
                      targetMatchIds: _state.selectedMatchIds,
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
