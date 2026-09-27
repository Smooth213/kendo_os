import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/match_state.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_bottom_action_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_content_layout_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_daihyo_overlay.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_dialog_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_floating_dock_entry.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_mini_log_undo_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_operate_action_buttons_grid.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_score_action_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_timer_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/match_view_only_notice_banner.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/widgets/corrupted_match_banner.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/shared/widgets/sync_status_bar.dart';

/// 試合画面のメインボディコンテンツ（スクロール、タイマー、スコアボード、アクション部、ドック）
class MatchScreenBodyContent extends StatelessWidget {
  final MatchModel match;
  final MatchRule rule;
  final List<MatchModel> teamMatches;
  final bool isViewOnly;
  final bool isSomeoneElseOperating;
  final bool isApproved;
  final bool isReadOnly;
  final bool isInputLocked;
  final bool isTie;
  final bool isDark;
  final bool showSyncBar;
  final String myUserId;
  final String? tournamentId;
  final WidgetRef ref;

  const MatchScreenBodyContent({
    super.key,
    required this.match,
    required this.rule,
    required this.teamMatches,
    required this.isViewOnly,
    required this.isSomeoneElseOperating,
    required this.isApproved,
    required this.isReadOnly,
    required this.isInputLocked,
    required this.isTie,
    required this.isDark,
    required this.showSyncBar,
    required this.myUserId,
    required this.tournamentId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final engine = KendoRuleEngine();
    final validEvents = engine.filterActiveEvents(match.events);
    final canUndoReal = validEvents.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double absoluteMinContentHeight = 665.0;
        final bool needsScroll =
            constraints.maxHeight < absoluteMinContentHeight;

        Widget buildMatchLayout(double currentHeight) {
          return SizedBox(
            width: constraints.maxWidth,
            height: currentHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCorrupted =
                              match.status == 'corrupted' ||
                              MatchLifecycleStateLegacyExt.fromLegacyString(
                                    match.status,
                                  ) ==
                                  MatchLifecycleState.corrupted;
                          final corruptedBanner = isCorrupted
                              ? CorruptedMatchBanner(matchId: match.id)
                              : const SizedBox.shrink();
                          final viewOnlyBanner = MatchViewOnlyNoticeBanner(
                            isSomeoneElseOperating: isSomeoneElseOperating,
                            isApproved: isApproved,
                            isReadOnly: isReadOnly,
                            onClaimScorer: () async {
                              final ok =
                                  await MatchDialogHelper.showConfirmDialog(
                                    context,
                                    "入力権限の奪取",
                                    "他の端末の入力を強制中断し、\nこの端末で入力を開始しますか？",
                                  );
                              if (ok) {
                                await ref
                                    .read(matchCommandProvider)
                                    .forceClaimScorer(match.id, myUserId);
                              }
                            },
                          );
                          final undoArea = RepaintBoundary(
                            child: MatchMiniLogUndoSection(
                              validEvents: validEvents,
                              canUndo: canUndoReal,
                              isDark: isDark,
                              onUndo: () => ref
                                  .read(matchCommandProvider)
                                  .undoLastEvent(match.id),
                            ),
                          );
                          final timerPart = RepaintBoundary(
                            child: MatchTimerSection(
                              match: match,
                              rule: rule,
                              isInputLocked: isInputLocked,
                            ),
                          );
                          final groupButtonPart = RepaintBoundary(
                            child: MatchOperateActionButtonsGrid(
                              isViewOnly: isViewOnly,
                              isKachinuki: match.isKachinuki,
                              onShareUrl: () =>
                                  MatchDialogHelper.showMatchShareOptionsSheet(
                                    context,
                                    match,
                                  ),
                              onRestoreHistory: () =>
                                  MatchDialogHelper.showSnapshotDialog(
                                    context,
                                    ref,
                                    match,
                                    validEvents,
                                    isDark,
                                  ),
                              onCheckScore: () => match.isKachinuki
                                  ? context.push(
                                      '/kachinuki-scoreboard/${match.groupName}',
                                    )
                                  : context.push(
                                      '/team-scoreboard/${match.groupName}',
                                    ),
                              onCheckRule: () =>
                                  MatchDialogHelper.showRuleInfoSheet(
                                    context,
                                    match,
                                  ),
                            ),
                          );
                          final scoreboardPart = RepaintBoundary(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxHeight * 0.28,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  child: MatchScoreboard(
                                    matchId: match.id,
                                    match: match,
                                    onNameTap: (side) =>
                                        MatchDialogHelper.showNameEditBottomSheet(
                                          context: context,
                                          match: match,
                                          side: side,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          );
                          final isAllDone = teamMatches.isNotEmpty
                              ? teamMatches.every(
                                  (m) =>
                                      m.status == 'finished' ||
                                      m.status == 'approved' ||
                                      m.id == match.id,
                                )
                              : true;
                          final bottomButtonPart = RepaintBoundary(
                            child: MatchBottomActionSection(
                              match: match,
                              rule: rule,
                              isApproved: isApproved,
                              isViewOnly: isViewOnly,
                              isTie: isTie,
                              isAllDone: isAllDone,
                              isDark: isDark,
                              myUserId: myUserId,
                              teamMatches: teamMatches,
                              onAddRenseikaiNext: () =>
                                  MatchDialogHelper.showNextMatchDialog(
                                    context,
                                    match,
                                  ),
                              onShowConfirmDialog: (t, c) =>
                                  MatchDialogHelper.showConfirmDialog(
                                    context,
                                    t,
                                    c,
                                  ),
                              onShowMatchFinishedDialog: (ctx, m, nextM) =>
                                  MatchDialogHelper.showMatchFinishedDialog(
                                    context: ctx,
                                    match: m,
                                    nextMatch: nextM,
                                    teamMatches: teamMatches,
                                    isDark: isDark,
                                  ),
                              onShowHanteiDialog: (m) =>
                                  MatchDialogHelper.showHanteiDialog(
                                    context: context,
                                    match: m,
                                    isDark: isDark,
                                  ),
                            ),
                          );
                          final actionPanelPart = RepaintBoundary(
                            child: MatchScoreActionSection(
                              matchId: match.id,
                              isInputLocked: isInputLocked,
                              isDark: isDark,
                            ),
                          );
                          return MatchContentLayoutBuilder(
                            constraints: constraints,
                            isDark: isDark,
                            corruptedBanner: corruptedBanner,
                            viewOnlyBanner: viewOnlyBanner,
                            timerPart: timerPart,
                            groupButtonPart: groupButtonPart,
                            scoreboardPart: scoreboardPart,
                            actionPanelPart: actionPanelPart,
                            undoArea: undoArea,
                            bottomButtonPart: bottomButtonPart,
                          );
                        },
                      ),
                    ),
                    if (showSyncBar) const SyncStatusBar(),
                  ],
                ),
                if (match.matchType == '代表戦')
                  MatchDaihyoOverlay(
                    onSelectDaihyo: () =>
                        _showRepresentativeModal(context, match, teamMatches),
                  ),
                MatchFloatingDockEntry(
                  tournamentId: match.tournamentId?.isNotEmpty == true
                      ? match.tournamentId!
                      : tournamentId,
                  isViewOnly: isViewOnly,
                ),
              ],
            ),
          );
        }

        return needsScroll
            ? SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: buildMatchLayout(absoluteMinContentHeight),
              )
            : buildMatchLayout(constraints.maxHeight);
      },
    );
  }

  void _showRepresentativeModal(
    BuildContext context,
    MatchModel match,
    List<MatchModel> teamMatches,
  ) {
    final rTeam = match.redName.split(':').first.trim();
    final wTeam = match.whiteName.split(':').first.trim();
    final redPlayers = teamMatches
        .map((m) => m.redName.split(':').last.trim())
        .toSet()
        .toList();
    final whitePlayers = teamMatches
        .map((m) => m.whiteName.split(':').last.trim())
        .toSet()
        .toList();
    MatchDialogHelper.showRepresentativeModal(
      context: context,
      match: match,
      rTeam: rTeam,
      wTeam: wTeam,
      redPlayers: redPlayers,
      whitePlayers: whitePlayers,
    );
  }
}
