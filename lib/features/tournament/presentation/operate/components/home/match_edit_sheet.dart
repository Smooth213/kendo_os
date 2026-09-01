import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_rule_and_memo_tab.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_save_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_save_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_state_holder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/home/match_edit_team_and_players_tab.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🏆 試合・団体戦対戦枠の詳細編集を行うボトムシート
class MatchEditSheet extends ConsumerStatefulWidget {
  final List<MatchModel> matches;
  final String? tournamentId;
  final AppThemeColors themeColors;
  final int initialTabIndex;

  const MatchEditSheet({
    super.key,
    required this.matches,
    this.tournamentId,
    required this.themeColors,
    this.initialTabIndex = 0,
  }) : assert(matches.length > 0, 'Matches list cannot be empty');

  @override
  ConsumerState<MatchEditSheet> createState() => _MatchEditSheetState();
}

class _MatchEditSheetState extends ConsumerState<MatchEditSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final MatchEditStateHolder _state;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _state = MatchEditStateHolder(widget.matches);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final backgroundColor = themeColors.cardBackground;
    final textColor = context.appColors.textColor;

    final sheetTitle = _state.isDantai ? '団体戦対戦の編集' : '試合情報の編集';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.largeValue),
        ),
      ),
      child: Column(
        children: [
          // Header Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
                borderRadius: AppRadius.large,
              ),
            ),
          ),

          // Header Title & Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    sheetTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // バランス用
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: themeColors.primaryAccent,
            labelColor: themeColors.primaryAccent,
            unselectedLabelColor: context.appColors.subTextColor,
            tabs: const [
              Tab(icon: Icon(Icons.people_outline), text: '対戦・選手'),
              Tab(icon: Icon(Icons.location_on_outlined), text: 'コート・メモ'),
              Tab(icon: Icon(Icons.tune), text: '一括ルール'),
            ],
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: チーム・選手情報
                MatchEditTeamAndPlayersTab(
                  isDantai: _state.isDantai,
                  redTeamController: _state.redTeamController,
                  whiteTeamController: _state.whiteTeamController,
                  redPlayerControllers: _state.redPlayerControllers,
                  whitePlayerControllers: _state.whitePlayerControllers,
                  primaryAccent: themeColors.primaryAccent,
                  isDark: isDark,
                  textColor: textColor,
                  onSwapTeamsAndPlayers: () =>
                      setState(() => _state.swapTeamsAndPlayers()),
                ),

                // TAB 2: コート・グループ情報
                MatchEditCourtAndGroupTab(
                  themeColors: themeColors,
                  courtController: _state.courtController,
                  noteController: _state.noteController,
                  isDark: isDark,
                  textColor: textColor,
                  onToggleHeadingPreset: (preset) =>
                      setState(() => _state.toggleHeadingPreset(preset)),
                  onClearCourt: () =>
                      setState(() => _state.courtController.clear()),
                ),

                // TAB 3: ルール・メモ設定
                MatchEditRuleAndMemoTab(
                  primaryAccent: themeColors.primaryAccent,
                  isDark: isDark,
                  textColor: textColor,
                  tournamentId: widget.tournamentId,
                  match: widget.matches.first,
                  isDantai: _state.isDantai,
                  selectedPresetKey: _state.selectedPresetKey,
                  selectedPresetRule: _state.selectedPresetRule,
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
                  onPresetSelected: (rule, key) =>
                      setState(() => _state.applyTargetPresetRule(rule, key)),
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
                  onHanteiChanged: (v) => setState(() => _state.hasHantei = v),
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
                  onLeagueChanged: (v) => setState(() => _state.isLeague = v),
                  onWinPointChanged: (v) => setState(() => _state.winPoint = v),
                  onLossPointChanged: (v) =>
                      setState(() => _state.lossPoint = v),
                  onDrawPointChanged: (v) =>
                      setState(() => _state.drawPoint = v),
                ),
              ],
            ),
          ),

          // 下部保存ボタン
          MatchEditSaveButton(
            isDantai: _state.isDantai,
            backgroundColor: backgroundColor,
            primaryAccent: themeColors.primaryAccent,
            isDark: isDark,
            onSave: () => MatchEditSaveHelper.executeSave(
              context: context,
              ref: ref,
              matches: widget.matches,
              isDantai: _state.isDantai,
              isSwapped: _state.isSwapped,
              initialOwnIsRed: _state.initialOwnIsRed,
              groupInput: _state.groupNameController.text.trim(),
              redTeamInput: _state.redTeamController.text.trim(),
              whiteTeamInput: _state.whiteTeamController.text.trim(),
              courtInput: _state.courtController.text.trim(),
              selectedPresetKey: _state.selectedPresetKey,
              selectedPresetRule: _state.selectedPresetRule,
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
              overallTimeMinutes:
                  int.tryParse(_state.overallTimeController.text) ?? 30,
              isKachinuki: _state.isKachinuki,
              kachinukiUnlimitedType: _state.kachinukiUnlimitedType,
              isLeague: _state.isLeague,
              winPoint: _state.winPoint,
              lossPoint: _state.lossPoint,
              drawPoint: _state.drawPoint,
              userNote: _state.noteController.text.trim(),
              status: _state.status,
              redPlayerControllers: _state.redPlayerControllers,
              whitePlayerControllers: _state.whitePlayerControllers,
            ),
          ),
        ],
      ),
    );
  }
}
