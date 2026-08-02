import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

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

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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

  String _formatRuleSummary(MatchRule r) {
    final timeStr = r.matchTimeMinutes.truncateToDouble() == r.matchTimeMinutes
        ? r.matchTimeMinutes.toInt().toString()
        : r.matchTimeMinutes.toString();
    final formatStr = r.isIpponShobu ? '1本' : '3本';
    return '$timeStr分・$formatStr';
  }

  Widget _buildSceneSubChip({
    required String sceneKey,
    required String label,
    required MatchRule targetRule,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSel = _selectedSceneType == sceneKey;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        color: isSel
            ? Colors.white
            : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
      ),
      selected: isSel,
      selectedColor: widget.themeColors.primaryAccent,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSel
              ? widget.themeColors.primaryAccent
              : (isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade300),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedSceneType = sceneKey;
            _applyCategoryRuleSet(targetRule, sceneKey: sceneKey);
          });
        }
      },
    );
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
    final textColor = isDark ? Colors.white : Colors.black87;

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

    final selectedUnitsCount = currentFilteredUnits.where((unit) {
      return unit.matchIds.every((id) => _selectedMatchIds.contains(id));
    }).length;

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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '⚙️ 試合ルールの一括変更',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.all(20),
              children: [
                // STEP 1. 対象選択
                _buildSectionHeader('STEP 1: 変更対象の試合を選択'),
                const SizedBox(height: 8),

                // カテゴリフィルター
                _buildFilterRow(
                  label: 'カテゴリ',
                  value: _selectedCategoryFilter,
                  options: _categories,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategoryFilter = val);
                      _applyFiltersAndSelectAll();
                    }
                  },
                ),
                const SizedBox(height: 12),

                // 形式フィルター
                _buildFilterRow(
                  label: '形式・種別',
                  value: _selectedTypeFilter,
                  options: _matchTypes,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTypeFilter = val);
                      _applyFiltersAndSelectAll();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 対象試合チェックリスト
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Material(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    child: currentFilteredUnits.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('条件に一致する試合がありません'),
                            ),
                          )
                        : Scrollbar(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: currentFilteredUnits.length,
                              itemBuilder: (context, index) {
                                final unit = currentFilteredUnits[index];
                                final isChecked = unit.matchIds.every(
                                  (id) => _selectedMatchIds.contains(id),
                                );

                                return CheckboxListTile(
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  title: Text(
                                    unit.displayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                  value: isChecked,
                                  activeColor: widget.themeColors.primaryAccent,
                                  onChanged: (val) {
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
                                );
                              },
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '現在 $selectedUnitsCount 件を選択中 / 全 ${currentFilteredUnits.length} 件中',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.themeColors.primaryAccent,
                      ),
                    ),
                    if (currentFilteredUnits.isNotEmpty)
                      TextButton(
                        onPressed: () {
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
                        child: Text(
                          currentFilteredUnits.every(
                                (unit) => unit.matchIds.every(
                                  (id) => _selectedMatchIds.contains(id),
                                ),
                              )
                              ? '全解除'
                              : '全選択',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // STEP 2. 新ルールの設定
                _buildSectionHeader('STEP 2: 新しいルールを設定'),
                const SizedBox(height: 16),

                // 部門別ルールプリセットからの選択UI (アイデア1: 部門選択 ➔ シーンサブチップ)
                ...(() {
                  final asyncTournament = ref.watch(
                    tournamentProvider(widget.tournamentId),
                  );
                  final categoryRules =
                      asyncTournament.valueOrNull?.categoryRules ?? {};
                  if (categoryRules.isEmpty) return <Widget>[];

                  final selectedRuleSet = _selectedCategoryRuleName != null
                      ? categoryRules[_selectedCategoryRuleName]
                      : null;

                  return [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.themeColors.primaryAccent.withAlpha(
                          isDark ? 25 : 12,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.themeColors.primaryAccent.withAlpha(
                            isDark ? 80 : 40,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: widget.themeColors.primaryAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '部門別ルールから一括セット',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 1段目: 部門名選択チップ
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: categoryRules.entries.map((entry) {
                                final catName = entry.key;
                                final ruleSet = entry.value;
                                final isSel =
                                    _selectedCategoryRuleName == catName;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    showCheckmark: false,
                                    label: Text(catName),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSel
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade800),
                                    ),
                                    selected: isSel,
                                    selectedColor:
                                        widget.themeColors.primaryAccent,
                                    backgroundColor: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.grey.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isSel
                                            ? Colors.transparent
                                            : (isDark
                                                  ? const Color(0xFF3A3A3C)
                                                  : Colors.grey.shade300),
                                      ),
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedCategoryRuleName = catName;
                                          _selectedSceneType = 'normal';
                                          _applyCategoryRuleSet(
                                            ruleSet.normalRule,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          // 2段目: 選択中部門のシーンサブチップ（本戦・錬成会・申し合わせ・決勝戦）
                          if (selectedRuleSet != null) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, thickness: 0.5),
                            const SizedBox(height: 8),
                            Text(
                              '試合シーン・ルール用途を選択:',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // 1) 本戦 (通常)
                                  if (selectedRuleSet.useHonsenRule)
                                    _buildSceneSubChip(
                                      sceneKey: 'normal',
                                      label:
                                          '🏆 本戦 (${_formatRuleSummary(selectedRuleSet.normalRule)})',
                                      targetRule: selectedRuleSet.normalRule,
                                    ),

                                  // 2) 錬成会 (練習試合)
                                  if (selectedRuleSet.useRenseikaiRule) ...[
                                    const SizedBox(width: 6),
                                    _buildSceneSubChip(
                                      sceneKey: 'renseikai',
                                      label:
                                          '⚔️ 錬成会 (${_formatRuleSummary(selectedRuleSet.renseikaiRule)})',
                                      targetRule: selectedRuleSet.renseikaiRule,
                                    ),
                                  ],

                                  // 3) 申し合わせ
                                  if (selectedRuleSet.useMoushiawaseRule) ...[
                                    const SizedBox(width: 6),
                                    _buildSceneSubChip(
                                      sceneKey: 'moushiawase',
                                      label:
                                          '🤝 申し合わせ (${_formatRuleSummary(selectedRuleSet.moushiawaseRule)})',
                                      targetRule:
                                          selectedRuleSet.moushiawaseRule,
                                    ),
                                  ],

                                  // 4) 決勝・準決勝
                                  if (selectedRuleSet.useAdvancedRule) ...[
                                    const SizedBox(width: 6),
                                    _buildSceneSubChip(
                                      sceneKey: 'advanced',
                                      label:
                                          '🔥 決勝・準決勝 (${_formatRuleSummary(selectedRuleSet.advancedRule)})',
                                      targetRule: selectedRuleSet.advancedRule,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ];
                })(),

                if (_hasDifferingRules()) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(isDark ? 30 : 15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withAlpha(isDark ? 60 : 30),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '選択した対戦の中に、設定が異なる試合が含まれています（先頭の試合のルールを表示中）',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 基本ルールカード
                _buildCardGroup(
                  title: '⏱️ 基本ルール',
                  children: [
                    _buildDropdownRow<double>(
                      label: '試合時間',
                      value: _matchTime,
                      items: [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0],
                      labelBuilder: (v) => '${v == v.toInt() ? v.toInt() : v}分',
                      onChanged: (v) => setState(() => _matchTime = v!),
                    ),
                    const Divider(height: 20),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '一本勝負形式にする',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        '先に1本取った側を勝者とします',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _isIpponShobu,
                      activeTrackColor: widget.themeColors.primaryAccent,
                      onChanged: (v) => setState(() => _isIpponShobu = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 延長ルールカード
                _buildCardGroup(
                  title: '🔄 延長ルール（本戦・通常試合）',
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '通常試合の延長戦を行う',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: _hasExtension,
                      activeTrackColor: widget.themeColors.primaryAccent,
                      onChanged: (v) => setState(() => _hasExtension = v),
                    ),
                    if (_hasExtension) ...[
                      const Divider(height: 20),
                      _buildDropdownRow<double>(
                        label: '延長時間',
                        value: _enchoTime,
                        items: [1.0, 1.5, 2.0, 3.0],
                        labelBuilder: (v) =>
                            '${v == v.toInt() ? v.toInt() : v}分',
                        onChanged: (v) => setState(() => _enchoTime = v!),
                      ),
                      const Divider(height: 20),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '時間無制限とする（サドンデス）',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: _isEnchoUnlimited,
                        activeTrackColor: widget.themeColors.primaryAccent,
                        onChanged: (v) => setState(() => _isEnchoUnlimited = v),
                      ),
                      if (!_isEnchoUnlimited) ...[
                        const Divider(height: 20),
                        _buildDropdownRow<int>(
                          label: '延長回数上限',
                          value: _enchoCount,
                          items: [1, 2, 3, 5],
                          labelBuilder: (v) => '$v回',
                          onChanged: (v) => setState(() => _enchoCount = v!),
                        ),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // 個人戦：判定ルール
                _buildCardGroup(
                  title: '⚖️ 個人戦ルール',
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '判定（ハンテイ）の適用',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        '延長時間終了時、または引き分け時に判定を行います',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _hasHantei,
                      activeTrackColor: widget.themeColors.primaryAccent,
                      onChanged: (v) => setState(() => _hasHantei = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 団体戦：代表戦ルール
                _buildCardGroup(
                  title: '⚔️ 団体戦・代表戦ルール',
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '代表戦の適用',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        'チーム引き分け時の決定戦を有効にします',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _hasRepresentativeMatch,
                      activeTrackColor: widget.themeColors.primaryAccent,
                      onChanged: (v) =>
                          setState(() => _hasRepresentativeMatch = v),
                    ),
                    if (_hasRepresentativeMatch) ...[
                      const Divider(height: 20),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '代表戦は一本勝負',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: _isDaihyoIpponShobu,
                        activeTrackColor: widget.themeColors.primaryAccent,
                        onChanged: (v) =>
                            setState(() => _isDaihyoIpponShobu = v),
                      ),
                      const Divider(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '代表戦の延長戦は、自動的に「時間無制限・一本勝負（サドンデス）」として行われます。',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.blue.shade300
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // 錬成会ルール
                _buildCardGroup(
                  title: '🏆 錬成会（練習マッチ）設定',
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '錬成会モードを有効化',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: _isRenseikai,
                      activeTrackColor: widget.themeColors.primaryAccent,
                      onChanged: (v) => setState(() => _isRenseikai = v),
                    ),
                    if (_isRenseikai) ...[
                      const Divider(height: 20),
                      _buildDropdownRow<String>(
                        label: '試合方式',
                        value: _renseikaiType,
                        items: const ['一試合制', '複数試合制', '時間制'],
                        labelBuilder: (v) => v,
                        onChanged: (v) => setState(() => _renseikaiType = v!),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '総試合時間（分）',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _overallTimeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                suffixText: '分',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // 下部固定実行ボタン
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 20),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$totalSelectedUnitsCount件の対戦ルールを一括変更しました。',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColors.primaryAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  disabledForegroundColor: isDark
                      ? Colors.white30
                      : Colors.black38,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _selectedMatchIds.isEmpty
                      ? '適用対象の試合を選択してください'
                      : '選択した $totalSelectedUnitsCount 件にルールを適用する',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: widget.themeColors.primaryAccent,
      ),
    );
  }

  Widget _buildCardGroup({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: isDark
            ? Colors.grey.shade900.withAlpha(128)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // フィルター用の汎用Row
  Widget _buildFilterRow({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final resolvedOptions = options.contains(value)
        ? options
        : [value, ...options];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            style: TextStyle(color: textColor, fontSize: 14),
            onChanged: onChanged,
            items: resolvedOptions.map((opt) {
              return DropdownMenuItem(
                value: opt,
                child: Text(opt.isEmpty ? '未設定' : opt),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 新規ルール入力用のドロップダウンRow
  Widget _buildDropdownRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final resolvedItems = items.contains(value) ? items : [value, ...items];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            style: TextStyle(color: textColor, fontSize: 14),
            onChanged: onChanged,
            items: resolvedItems.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(labelBuilder(item)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class MatchGroupUnit {
  final String id;
  final String displayName;
  final List<String> matchIds;
  final String category;
  final String resolvedType;

  MatchGroupUnit({
    required this.id,
    required this.displayName,
    required this.matchIds,
    required this.category,
    required this.resolvedType,
  });
}
