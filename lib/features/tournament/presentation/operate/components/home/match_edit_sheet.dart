import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_data_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_rule_and_memo_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_team_and_players_tab.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';

/// 🏆 試合・団体戦対戦枠の詳細編集を行うボトムシート
class MatchEditSheet extends ConsumerStatefulWidget {
  final List<MatchModel> matches;
  final String? tournamentId;
  final AppThemeColors themeColors;

  const MatchEditSheet({
    super.key,
    required this.matches,
    this.tournamentId,
    required this.themeColors,
  }) : assert(matches.length > 0, 'Matches list cannot be empty');

  @override
  ConsumerState<MatchEditSheet> createState() => _MatchEditSheetState();
}

class _MatchEditSheetState extends ConsumerState<MatchEditSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late bool _isDantai;
  bool _isSwapped = false;
  late bool _initialOwnIsRed;

  // 1. チーム・選手情報
  late TextEditingController _redTeamController;
  late TextEditingController _whiteTeamController;
  late List<TextEditingController> _redPlayerControllers;
  late List<TextEditingController> _whitePlayerControllers;

  // 2. コート・グループ情報
  late TextEditingController _courtController;
  late TextEditingController _groupNameController;

  // 3. ルール・メモ
  MatchRule? _selectedPresetRule;
  String? _selectedPresetKey;
  late double _matchTime;
  late bool _isIpponShobu;
  late bool _hasHantei;
  late TextEditingController _noteController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final first = widget.matches.first;
    _isDantai = widget.matches.length > 1 || first.matchType == '団体戦';

    final r = first.rule ?? const MatchRule();

    String detectedKey;
    if (r.isRenseikai ||
        r.matchScene == 'renseikai' ||
        first.matchScene == 'renseikai') {
      detectedKey = 'renseikai';
    } else if (r.matchScene == 'moushiawase' ||
        first.matchScene == 'moushiawase') {
      detectedKey = 'moushiawase';
    } else if (r.matchScene == 'honsen' || first.matchScene == 'honsen') {
      detectedKey = 'honsen';
    } else {
      detectedKey = 'honsen';
    }

    _selectedPresetKey = detectedKey;
    _selectedPresetRule = r.copyWith(
      matchScene: detectedKey,
      isRenseikai: detectedKey == 'renseikai',
    );

    final extractedRedTeam = MatchEditDataHelper.extractTeamName(
      first.redName,
      r.teamName.isNotEmpty ? r.teamName : '赤チーム',
      _isDantai,
    );
    final extractedWhiteTeam = MatchEditDataHelper.extractTeamName(
      first.whiteName,
      '白チーム',
      _isDantai,
    );

    final originalRuleTeam = r.teamName.trim();
    if (originalRuleTeam.isNotEmpty) {
      if (originalRuleTeam == extractedWhiteTeam) {
        _initialOwnIsRed = false;
      } else {
        _initialOwnIsRed = true;
      }
    } else {
      _initialOwnIsRed = true;
    }

    _redTeamController = TextEditingController(text: extractedRedTeam);
    _whiteTeamController = TextEditingController(text: extractedWhiteTeam);

    _redPlayerControllers = widget.matches
        .map(
          (m) => TextEditingController(
            text: MatchEditDataHelper.extractPlayerName(m.redName),
          ),
        )
        .toList();
    _whitePlayerControllers = widget.matches
        .map(
          (m) => TextEditingController(
            text: MatchEditDataHelper.extractPlayerName(m.whiteName),
          ),
        )
        .toList();

    _courtController = TextEditingController(
      text: MatchEditDataHelper.extractHeadingText(first),
    );
    _groupNameController = TextEditingController(text: '');

    _matchTime = r.matchTimeMinutes > 0
        ? r.matchTimeMinutes
        : first.matchTimeMinutes;
    _isIpponShobu = r.isIpponShobu;
    _hasHantei = (detectedKey == 'renseikai' || detectedKey == 'moushiawase')
        ? false
        : r.hasHantei;

    _noteController = TextEditingController(
      text: MatchEditDataHelper.cleanNoteText(first.note),
    );
    _status = first.status;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _redTeamController.dispose();
    _whiteTeamController.dispose();
    for (var c in _redPlayerControllers) {
      c.dispose();
    }
    for (var c in _whitePlayerControllers) {
      c.dispose();
    }
    _courtController.dispose();
    _groupNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _swapTeamsAndPlayers() {
    setState(() {
      _isSwapped = !_isSwapped;
      final tempTeam = _redTeamController.text;
      _redTeamController.text = _whiteTeamController.text;
      _whiteTeamController.text = tempTeam;

      for (int i = 0; i < _redPlayerControllers.length; i++) {
        final tempPlayer = _redPlayerControllers[i].text;
        _redPlayerControllers[i].text = _whitePlayerControllers[i].text;
        _whitePlayerControllers[i].text = tempPlayer;
      }
    });
  }

  void _applyTargetPresetRule(MatchRule rule, String key) {
    final isRenseikaiOrMoushiawase =
        key == 'renseikai' ||
        key == 'moushiawase' ||
        rule.isRenseikai ||
        rule.matchScene == 'renseikai' ||
        rule.matchScene == 'moushiawase';

    final sanitizedRule = rule.copyWith(
      matchScene: key,
      isRenseikai: key == 'renseikai',
      hasHantei: isRenseikaiOrMoushiawase ? false : rule.hasHantei,
      enchoTimeMinutes: isRenseikaiOrMoushiawase ? 0.0 : rule.enchoTimeMinutes,
      isEnchoUnlimited: isRenseikaiOrMoushiawase
          ? false
          : rule.isEnchoUnlimited,
      hasRepresentativeMatch: isRenseikaiOrMoushiawase
          ? false
          : rule.hasRepresentativeMatch,
    );

    setState(() {
      _selectedPresetKey = key;
      _selectedPresetRule = sanitizedRule;
      _matchTime = sanitizedRule.matchTimeMinutes > 0
          ? sanitizedRule.matchTimeMinutes
          : 2.0;
      _isIpponShobu = sanitizedRule.isIpponShobu;
      _hasHantei = sanitizedRule.hasHantei;
    });
  }

  void _toggleHeadingPreset(String preset) {
    final currentText = _courtController.text.trim();
    if (currentText.isEmpty) {
      _courtController.text = preset;
      return;
    }

    final items = currentText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.contains(preset)) {
      items.remove(preset);
    } else {
      items.add(preset);
    }
    _courtController.text = items.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final backgroundColor = themeColors.cardBackground;
    final textColor = context.appColors.textColor;

    final sheetTitle = _isDantai ? '団体戦対戦の編集' : '試合情報の編集';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x33000000),
              borderRadius: AppRadius.micro,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.roundValue,
            ),
            child: Row(
              children: [
                Icon(
                  _isDantai ? Icons.groups : Icons.edit_note,
                  color: widget.themeColors.primaryAccent,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  sheetTitle,
                  style: TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: widget.themeColors.primaryAccent,
            labelColor: widget.themeColors.primaryAccent,
            unselectedLabelColor: isDark
                ? context.appColors.subTextColor
                : context.appColors.subTextColor,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
            ),
            labelStyle: const TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: AppFontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: AppFontSize.small),
            tabs: [
              Tab(
                icon: Icon(
                  _isDantai ? Icons.groups : Icons.people_alt,
                  size: 18,
                ),
                text: _isDantai ? '対戦・選手' : '選手・チーム',
              ),
              const Tab(icon: Icon(Icons.place, size: 18), text: 'コート・メモ'),
              const Tab(icon: Icon(Icons.tune, size: 18), text: '一括ルール'),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: チーム・選手
                MatchEditTeamAndPlayersTab(
                  isDantai: _isDantai,
                  redTeamController: _redTeamController,
                  whiteTeamController: _whiteTeamController,
                  redPlayerControllers: _redPlayerControllers,
                  whitePlayerControllers: _whitePlayerControllers,
                  primaryAccent: widget.themeColors.primaryAccent,
                  isDark: isDark,
                  textColor: textColor,
                  onSwapTeamsAndPlayers: _swapTeamsAndPlayers,
                ),

                // Tab 2: コート・グループ
                MatchEditCourtAndGroupTab(
                  themeColors: widget.themeColors,
                  courtController: _courtController,
                  noteController: _noteController,
                  isDark: isDark,
                  textColor: textColor,
                  onToggleHeadingPreset: _toggleHeadingPreset,
                  onClearCourt: () => setState(() => _courtController.clear()),
                ),

                // Tab 3: ルール・メモ
                MatchEditRuleAndMemoTab(
                  primaryAccent: widget.themeColors.primaryAccent,
                  isDark: isDark,
                  textColor: textColor,
                  tournamentId: widget.tournamentId,
                  match: widget.matches.first,
                  selectedPresetKey: _selectedPresetKey,
                  selectedPresetRule: _selectedPresetRule,
                  matchTime: _matchTime,
                  isIpponShobu: _isIpponShobu,
                  hasHantei: _hasHantei,
                  onPresetSelected: _applyTargetPresetRule,
                  onMatchTimeChanged: (v) {
                    setState(() {
                      _matchTime = v;
                      if (_selectedPresetRule != null) {
                        _selectedPresetRule = _selectedPresetRule!.copyWith(
                          matchTimeMinutes: v,
                        );
                      }
                    });
                  },
                  onIpponShobuChanged: (v) {
                    setState(() {
                      _isIpponShobu = v;
                      if (_selectedPresetRule != null) {
                        _selectedPresetRule = _selectedPresetRule!.copyWith(
                          isIpponShobu: v,
                        );
                      }
                    });
                  },
                  onHanteiChanged: (v) {
                    setState(() {
                      _hasHantei = v;
                      if (_selectedPresetRule != null) {
                        _selectedPresetRule = _selectedPresetRule!.copyWith(
                          hasHantei: v,
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Footer Save Button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withAlpha(isDark ? 50 : 20),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.check,
                    color: AppKendoColors.pureWhite,
                  ),
                  label: Text(
                    _isDantai ? '団体戦全体を一括保存' : '変更内容を保存',
                    style: const TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.pureWhite,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.large,
                    ),
                  ),
                  onPressed: _saveChanges,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    final groupInput = _groupNameController.text.trim();
    final redTeamInput = _redTeamController.text.trim();
    final whiteTeamInput = _whiteTeamController.text.trim();
    final courtInput = _courtController.text.trim();

    final firstMatch = widget.matches.first;
    final rawGroup = firstMatch.groupName ?? '';
    final isUuidGroup = RegExp(
      r'^[a-f0-9\-]{20,}$',
      caseSensitive: false,
    ).hasMatch(rawGroup);

    final String fallbackGroupKey =
        (rawGroup.isNotEmpty &&
            !isUuidGroup &&
            rawGroup != '1回戦' &&
            rawGroup != '2回戦')
        ? rawGroup
        : 'group_${firstMatch.id}';

    final String finalGroupName = _isDantai
        ? (courtInput.isNotEmpty
              ? courtInput
              : (groupInput.isNotEmpty ? groupInput : fallbackGroupKey))
        : (courtInput.isNotEmpty ? courtInput : groupInput);

    final bool currentOwnIsRed = _isSwapped
        ? !_initialOwnIsRed
        : _initialOwnIsRed;
    final String targetOwnTeamName = currentOwnIsRed
        ? redTeamInput
        : whiteTeamInput;

    final String sceneKey = _selectedPresetKey ?? 'honsen';
    final bool isRenseikaiBool = sceneKey == 'renseikai';
    final bool isRenseikaiOrMoushiawase =
        sceneKey == 'renseikai' || sceneKey == 'moushiawase';

    final updatedMatches = <MatchModel>[];

    for (int i = 0; i < widget.matches.length; i++) {
      final m = widget.matches[i];
      final baseRule = _selectedPresetRule ?? m.rule ?? const MatchRule();

      final updatedRule = baseRule.copyWith(
        matchScene: sceneKey,
        isRenseikai: isRenseikaiBool,
        matchTimeMinutes: _matchTime,
        isIpponShobu: _isIpponShobu,
        hasHantei: isRenseikaiOrMoushiawase ? false : _hasHantei,
        enchoTimeMinutes: isRenseikaiOrMoushiawase
            ? 0.0
            : baseRule.enchoTimeMinutes,
        isEnchoUnlimited: isRenseikaiOrMoushiawase
            ? false
            : baseRule.isEnchoUnlimited,
        hasRepresentativeMatch: isRenseikaiOrMoushiawase
            ? false
            : baseRule.hasRepresentativeMatch,
        teamName: targetOwnTeamName.isNotEmpty
            ? targetOwnTeamName
            : baseRule.teamName,
      );

      final redPlayer = _redPlayerControllers[i].text.trim();
      final whitePlayer = _whitePlayerControllers[i].text.trim();

      final finalRedName = _isDantai
          ? (redTeamInput.isNotEmpty
                ? (redPlayer.isNotEmpty
                      ? '$redTeamInput: $redPlayer'
                      : redTeamInput)
                : redPlayer)
          : redPlayer;

      final finalWhiteName = _isDantai
          ? (whiteTeamInput.isNotEmpty
                ? (whitePlayer.isNotEmpty
                      ? '$whiteTeamInput: $whitePlayer'
                      : whiteTeamInput)
                : whitePlayer)
          : whitePlayer;

      final userNote = _noteController.text.trim();
      final prefixParts = <String>[];
      if (courtInput.isNotEmpty) prefixParts.add(courtInput);
      if (groupInput.isNotEmpty) prefixParts.add(groupInput);

      final headerPrefix = prefixParts.join(' ');
      final noteCombined = headerPrefix.isNotEmpty
          ? (userNote.isNotEmpty ? '$headerPrefix\n$userNote' : headerPrefix)
          : userNote;

      final updatedMatch = m.copyWith(
        redName: finalRedName,
        whiteName: finalWhiteName,
        groupName: finalGroupName,
        note: noteCombined,
        rule: updatedRule,
        matchScene: sceneKey,
        status: _status,
      );

      updatedMatches.add(updatedMatch);
    }

    await ref
        .read(matchApplicationServiceProvider)
        .saveMatchesBulk(updatedMatches);

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        _isDantai ? '団体戦の全試合情報を一括保存しました' : '試合情報を保存・更新しました',
      );
      Navigator.pop(context);
    }
  }
}
