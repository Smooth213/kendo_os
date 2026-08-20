import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_preset_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_target_select_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_detail_setting_cards.dart';

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
  // 1. 対象選択の絞り込み状態
  String _selectedCategoryFilter = 'すべて';
  String _selectedTypeFilter = 'すべて';
  List<String> _selectedMatchIds = [];
  String? _loadedMatchId;
  String? _selectedCategoryRuleName;
  String _selectedSceneType = 'normal';

  // 2. 新ルールの状態変数
  late double _matchTime;
  late bool _isIpponShobu;
  late bool _hasExtension;
  late double _enchoTime;
  late int _enchoCount;
  late bool _isEnchoUnlimited;
  late bool _hasHantei;

  // 団体戦
  late bool _hasRepresentativeMatch;
  late bool _isDaihyoIpponShobu;

  bool get _isCurrentFilterTeamMatch {
    if (_selectedTypeFilter.contains('団体')) return true;
    if (_selectedTypeFilter.contains('個人')) return false;
    final selectedMatches = widget.matches
        .where((m) => _selectedMatchIds.contains(m.id))
        .toList();
    if (selectedMatches.isEmpty) return false;
    return selectedMatches.any((m) => _getResolvedType(m).contains('団体'));
  }

  bool get _isCurrentFilterIndividualMatch {
    if (_selectedTypeFilter.contains('個人')) return true;
    if (_selectedTypeFilter.contains('団体')) return false;
    final selectedMatches = widget.matches
        .where((m) => _selectedMatchIds.contains(m.id))
        .toList();
    if (selectedMatches.isEmpty) return false;
    return selectedMatches.any((m) => _getResolvedType(m).contains('個人'));
  }

  void _applyCategoryRuleSet(MatchRule targetRule, {String? sceneKey}) {
    final effectiveScene = sceneKey ?? targetRule.matchScene;
    final isRenseikaiOrMoushiawase =
        effectiveScene == 'renseikai' ||
        effectiveScene == 'moushiawase' ||
        targetRule.isRenseikai ||
        targetRule.matchScene == 'renseikai' ||
        targetRule.matchScene == 'moushiawase';

    // 1. 基本ルール
    _matchTime = targetRule.matchTimeMinutes;
    _isIpponShobu = targetRule.isIpponShobu;

    // 2. 延長ルール (錬成会・申し合わせ時は完全強制 OFF！)
    if (isRenseikaiOrMoushiawase) {
      _hasExtension = false;
      _isEnchoUnlimited = false;
      _enchoTime = 0.0;
      _enchoCount = 0;
    } else {
      final bool extensionEnabled =
          (targetRule.enchoTimeMinutes > 0) || targetRule.isEnchoUnlimited;
      _hasExtension = extensionEnabled;
      _isEnchoUnlimited = extensionEnabled
          ? targetRule.isEnchoUnlimited
          : false;
      _enchoTime = targetRule.enchoTimeMinutes > 0
          ? targetRule.enchoTimeMinutes
          : 3.0;
      _enchoCount = targetRule.enchoCount > 0 ? targetRule.enchoCount : 1;
    }

    // 3. 個人戦判定 & 団体戦代表戦ルール (錬成会・申し合わせ時は判定・代表戦ともに完全強制 OFF！)
    if (isRenseikaiOrMoushiawase) {
      _hasHantei = false;
      _hasRepresentativeMatch = false;
      _isDaihyoIpponShobu = false;
    } else {
      final isTeam = _isCurrentFilterTeamMatch;
      final isIndiv = _isCurrentFilterIndividualMatch;

      if (isTeam && !isIndiv) {
        _hasHantei = false;
        _hasRepresentativeMatch = targetRule.hasRepresentativeMatch;
        _isDaihyoIpponShobu = targetRule.hasRepresentativeMatch
            ? targetRule.isDaihyoIpponShobu
            : false;
      } else if (isIndiv && !isTeam) {
        _hasRepresentativeMatch = false;
        _isDaihyoIpponShobu = false;
        _hasHantei = targetRule.hasHantei;
      } else {
        _hasHantei = targetRule.hasHantei;
        _hasRepresentativeMatch = targetRule.hasRepresentativeMatch;
        _isDaihyoIpponShobu = targetRule.hasRepresentativeMatch
            ? targetRule.isDaihyoIpponShobu
            : false;
      }
    }

    // 4. 錬成会設定
    _isRenseikai = isRenseikaiOrMoushiawase || targetRule.isRenseikai;
    _renseikaiType = targetRule.renseikaiType;
    _overallTimeController.text = targetRule.overallTimeMinutes.toString();
  }

  // 錬成会
  late bool _isRenseikai;
  late String _renseikaiType;
  final _overallTimeController = TextEditingController();

  // カテゴリと種別の抽出
  late List<String> _categories;
  late List<String> _matchTypes;

  String _getResolvedType(MatchModel m) {
    if (m.isKachinuki || m.matchType == '無限勝ち抜き' || m.matchType == '勝ち抜き戦') {
      return '勝ち抜き戦';
    }
    final isLeague =
        m.note.contains('リーグ戦') ||
        m.note.contains('[リーグ戦]') ||
        m.matchType.contains('リーグ');
    final isTeam =
        m.matchType.contains('団体') ||
        const {
          '先鋒',
          '次鋒',
          '中堅',
          '副将',
          '大将',
          '代表戦',
          '代',
          '大将延長戦',
        }.contains(m.matchType);
    if (isLeague) {
      return isTeam ? 'リーグ団体戦' : 'リーグ個人戦';
    } else {
      return isTeam ? '団体戦' : '個人戦';
    }
  }

  void _loadTemplateRules(MatchModel m) {
    _loadedMatchId = m.id;
    final r = m.rule ?? const MatchRule();
    _matchTime = m.matchTimeMinutes;
    _isIpponShobu = r.isIpponShobu;
    _hasExtension = m.hasExtension;
    _enchoTime = m.extensionTimeMinutes ?? 3.0;
    _enchoCount = m.extensionCount ?? 1;
    _isEnchoUnlimited = r.isEnchoUnlimited;
    _hasHantei = m.hasHantei;
    _hasRepresentativeMatch = r.hasRepresentativeMatch;
    _isDaihyoIpponShobu = r.isDaihyoIpponShobu;
    _isRenseikai = r.isRenseikai;
    _renseikaiType = r.renseikaiType;
    _overallTimeController.text = r.overallTimeMinutes.toString();
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
    if (selectedMatches.length <= 1) return false;

    final first = selectedMatches.first;
    final firstRule = first.rule ?? const MatchRule();

    for (int i = 1; i < selectedMatches.length; i++) {
      final current = selectedMatches[i];
      final currentRule = current.rule ?? const MatchRule();

      if (current.matchTimeMinutes != first.matchTimeMinutes ||
          current.hasExtension != first.hasExtension ||
          current.extensionTimeMinutes != first.extensionTimeMinutes ||
          current.extensionCount != first.extensionCount ||
          current.hasHantei != first.hasHantei ||
          currentRule.isIpponShobu != firstRule.isIpponShobu ||
          currentRule.isEnchoUnlimited != firstRule.isEnchoUnlimited ||
          currentRule.hasRepresentativeMatch !=
              firstRule.hasRepresentativeMatch ||
          currentRule.isDaihyoIpponShobu != firstRule.isDaihyoIpponShobu ||
          currentRule.isRenseikai != firstRule.isRenseikai ||
          currentRule.renseikaiType != firstRule.renseikaiType ||
          currentRule.overallTimeMinutes != firstRule.overallTimeMinutes) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    // カテゴリと試合形式のリストを動的抽出
    _categories = [
      'すべて',
      ...widget.matches
          .map((m) => m.category)
          .whereType<String>()
          .where((cat) => cat.isNotEmpty)
          .toSet(),
    ];

    _matchTypes = ['すべて', ...widget.matches.map(_getResolvedType).toSet()];

    // デフォルトのルール状態の初期化
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

    // 初期状態で全対象を選択
    _applyFiltersAndSelectAll();

    // 選択された最初の試合のルールを仮の初期表示として読み込む
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

  List<MatchGroupUnit> _buildGroupUnits() {
    final List<MatchGroupUnit> units = [];
    final Map<String, List<MatchModel>> teamGroups = {};

    for (final m in widget.matches) {
      final type = _getResolvedType(m);
      final category = m.category ?? '';

      if (type == '団体戦' || type == 'リーグ団体戦') {
        final groupName = m.groupName != null && m.groupName!.isNotEmpty
            ? m.groupName!
            : '団体戦';
        final key = '$category::$type::$groupName';
        teamGroups.putIfAbsent(key, () => []).add(m);
      } else {
        final displayName = m.category != null && m.category!.isNotEmpty
            ? '[${m.category}] ${m.redName} vs ${m.whiteName}'
            : '${m.redName} vs ${m.whiteName}';

        units.add(
          MatchGroupUnit(
            id: 'single:${m.id}',
            displayName: displayName,
            matchIds: [m.id],
            category: category,
            resolvedType: type,
          ),
        );
      }
    }

    teamGroups.forEach((key, list) {
      final parts = key.split('::');
      final category = parts[0];
      final type = parts[1];
      final groupNameVal = parts[2];

      // Resolve human-readable name for the group if it's a UUID
      String displayGroupName = groupNameVal;
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (uuidRegex.hasMatch(groupNameVal) || groupNameVal.length > 20) {
        String rTeam = '';
        String wTeam = '';
        for (final m in list) {
          if (m.redName.contains(':') && m.whiteName.contains(':')) {
            rTeam = m.redName.split(':').first.trim();
            wTeam = m.whiteName.split(':').first.trim();
            break;
          }
        }
        if (rTeam.isNotEmpty && wTeam.isNotEmpty) {
          displayGroupName = '$rTeam vs $wTeam';
        } else {
          if (list.isNotEmpty) {
            final first = list.first;
            displayGroupName = '${first.redName} vs ${first.whiteName}';
          } else {
            displayGroupName = '団体戦対戦';
          }
        }
      }

      final displayName = category.isNotEmpty
          ? '[$category] $displayGroupName'
          : displayGroupName;

      units.add(
        MatchGroupUnit(
          id: 'team:$key',
          displayName: displayName,
          matchIds: list.map((m) => m.id).toList(),
          category: category,
          resolvedType: type,
        ),
      );
    });

    return units;
  }

  void _applyFiltersAndSelectAll() {
    final filteredUnits = _buildGroupUnits().where((unit) {
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

    // 現在のフィルターに該当する全試合（グループ化された表示単位）
    final currentFilteredUnits = _buildGroupUnits().where((unit) {
      final isCategoryMatch =
          _selectedCategoryFilter == 'すべて' ||
          unit.category == _selectedCategoryFilter;
      final isTypeMatch =
          _selectedTypeFilter == 'すべて' ||
          unit.resolvedType == _selectedTypeFilter;
      return isCategoryMatch && isTypeMatch;
    }).toList();

    final allUnits = _buildGroupUnits();
    final totalSelectedUnitsCount = allUnits.where((unit) {
      return unit.matchIds.every((id) => _selectedMatchIds.contains(id));
    }).length;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // ヘッダー部
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '⚙️ 試合ルールの一括変更',
                  style: TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

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
                _buildSectionHeader('STEP 2: 新しいルールを設定'),
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
                          _applyCategoryRuleSet(targetRule, sceneKey: sceneKey);
                        });
                      },
                    ),
                  ];
                })(),

                if (_hasDifferingRules()) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFD97706).withAlpha(isDark ? 30 : 15),
                      borderRadius: AppRadius.small,
                      border: Border.all(
                        color: const Color(
                          0xFFD4AF37,
                        ).withAlpha(isDark ? 60 : 30),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '選択した対戦の中に、設定が異なる試合が含まれています（先頭の試合のルールを表示中）',
                            style: TextStyle(
                              fontSize: AppFontSize.small,
                              color: isDark
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // STEP 2 詳細設定カード群
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
                  onIpponShobuChanged: (v) => setState(() => _isIpponShobu = v),
                  onExtensionChanged: (v) => setState(() => _hasExtension = v),
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
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFFFFFFF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withAlpha(isDark ? 50 : 20),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _selectedMatchIds.isEmpty
                    ? null
                    : () async {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColors.primaryAccent,
                  foregroundColor: AppKendoColors.pureWhite,
                  disabledBackgroundColor: context.appColors.separatorColor,
                  disabledForegroundColor: isDark
                      ? context.appColors.textColor.withValues(alpha: 0.3)
                      : context.appColors.cardBackground.withValues(
                          alpha: 0.38,
                        ),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
                  elevation: 0,
                ),
                child: Text(
                  _selectedMatchIds.isEmpty
                      ? '適用対象の試合を選択してください'
                      : '選択した $totalSelectedUnitsCount 件にルールを適用する',
                  style: const TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.subhead,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 小さなセクションヘッダー
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppFontSize.body,
        fontWeight: AppFontWeight.bold,
        color: widget.themeColors.primaryAccent,
      ),
    );
  }
}
