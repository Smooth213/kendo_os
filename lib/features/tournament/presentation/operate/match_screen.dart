import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/ui_message_provider.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'components/match_screen/match_mini_log_undo_section.dart';
import 'components/match_screen/match_operate_action_buttons_grid.dart';
import 'components/match_screen/match_view_only_notice_banner.dart';
import 'components/match_screen/match_daihyo_overlay.dart';
import 'components/match_screen/match_bottom_action_section.dart';
import 'components/match_screen/match_timer_section.dart';
import 'components/match_screen/match_score_action_section.dart';
import 'components/match_screen/match_content_layout_builder.dart';
import 'components/match_screen/match_header_widgets.dart';
import 'components/match_screen/match_dialog_helper.dart';

import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/features/match/domain/match_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/shared/widgets/sync_status_bar.dart';
import 'package:kendo_os/shared/widgets/corrupted_match_banner.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

export 'package:kendo_os/shared/infrastructure/repository/team_repository.dart'
    show registeredTeamsProvider;

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

class MatchScreen extends ConsumerStatefulWidget {
  final String matchId;
  const MatchScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  String? _myUserId;
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    try {
      _myUserId = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';
    } catch (_) {
      _myUserId = 'local_user';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.matchId.isNotEmpty && mounted) {
        try {
          ref.read(soundServiceProvider);
          final matches = ref.read(matchListProvider);
          final currentMatch = matches
              .where((m) => m.id == widget.matchId)
              .firstOrNull;
          if (currentMatch != null) {
            final isDone =
                currentMatch.status == 'finished' ||
                currentMatch.status == 'approved';
            if (!isDone) {
              ref
                  .read(matchCommandProvider)
                  .claimScorer(widget.matchId, _myUserId!);
            }
          }
        } catch (_) {}
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context);
  }

  @override
  void dispose() {
    final container = _container;
    final matchId = widget.matchId;
    final userId = _myUserId;
    if (container != null && userId != null) {
      Future.microtask(() async {
        try {
          await container
              .read(matchCommandProvider)
              .releaseScorer(matchId, userId);
        } catch (_) {}
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? tournamentId;
    try {
      final uri = GoRouterState.of(context).uri;
      tournamentId = uri.queryParameters['tournamentId'];
    } catch (_) {}

    final List<MatchModel> matches =
        (kIsWeb && tournamentId != null && tournamentId.isNotEmpty)
        ? (ref.watch(matchListByTournamentProvider(tournamentId)).valueOrNull ??
              ref.watch(matchListProvider))
        : ref.watch(matchListProvider);
    final match = matches.where((m) => m.id == widget.matchId).firstOrNull;

    if (match == null) {
      return Scaffold(
        appBar: const AppHeader(title: '試合読み込み中...'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              const Text('試合データを取得しています...'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      );
    }

    final MatchRule rule =
        match.rule ?? ref.watch(matchRuleProvider) ?? MatchRule();

    final teamMatches = match.groupName != null && match.groupName!.isNotEmpty
        ? matches.where((m) => m.groupName == match.groupName).toList()
        : <MatchModel>[];

    // 錬成会マスタータイマーの初期化はプロバイダー自身で行われます

    final permissions = ref.watch(permissionProvider);
    final isSomeoneElseOperating =
        match.scorerId != null && match.scorerId != _myUserId;
    final isViewOnly = permissions.isReadOnly || isSomeoneElseOperating;
    final isInputLocked =
        isViewOnly || match.status == 'finished' || match.status == 'approved';

    final isTie = ref.watch(
      matchViewStateProvider(widget.matchId).select((vs) => vs.isTie),
    );
    final isApproved = match.status == 'approved';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<UiMessage?>(uiMessageProvider, (previous, next) {
      if (next != null) {
        if (next.isError) {
          AppSnackBar.showError(context, next.text);
        } else {
          AppSnackBar.showSuccess(context, next.text);
        }
      }
    });

    final activeRole = ref.watch(activeRoleProvider);
    final showSyncBar = activeRole != Role.viewer;

    final engine = KendoRuleEngine();
    final validEvents = engine.filterActiveEvents(match.events);
    final canUndoReal = validEvents.isNotEmpty;

    final layoutWidget = LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          centerTitle: true,
          backgroundColor: context.appColors.primaryAccent,
          foregroundColor: AppKendoColors.pureWhite,
          titleWidget: MatchHeaderTitle(match: match),
          actions: [MatchHeaderActions(match: match)],
        ),

        body: LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final double maxHeight = constraints.maxHeight;
            const double absoluteMinContentHeight = 665.0;
            final bool needsScroll = maxHeight < absoluteMinContentHeight;

            Widget buildMatchLayout(double currentHeight) {
              return SizedBox(
                width: maxWidth,
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
                                isReadOnly: permissions.isReadOnly,
                                onClaimScorer: () async {
                                  final confirmed =
                                      await MatchDialogHelper.showConfirmDialog(
                                        context,
                                        "入力権限の奪取",
                                        "他の端末の入力を強制中断し、\nこの端末で入力を開始しますか？",
                                      );
                                  if (confirmed) {
                                    await ref
                                        .read(matchCommandProvider)
                                        .forceClaimScorer(match.id, _myUserId!);
                                  }
                                },
                              );

                              final undoArea = MatchMiniLogUndoSection(
                                validEvents: validEvents,
                                canUndo: canUndoReal,
                                isDark: isDark,
                                onUndo: () => ref
                                    .read(matchCommandProvider)
                                    .undoLastEvent(match.id),
                              );

                              final timerPart = MatchTimerSection(
                                match: match,
                                rule: rule,
                                isInputLocked: isInputLocked,
                              );

                              final groupButtonPart = MatchOperateActionButtonsGrid(
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
                              );

                              final scoreboardPart = ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * 0.28,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    child: ProviderScope(
                                      overrides: [
                                        scoreboardMatchIdProvider
                                            .overrideWithValue(match.id),
                                        scoreboardMatchProvider
                                            .overrideWithValue(match),
                                        scoreboardNameTapProvider
                                            .overrideWithValue((side) {
                                              MatchDialogHelper.showNameEditBottomSheet(
                                                context: context,
                                                match: match,
                                                side: side,
                                              );
                                            }),
                                      ],

                                      child: const MatchScoreboard(),
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

                              final bottomButtonPart = MatchBottomActionSection(
                                match: match,
                                rule: rule,
                                isApproved: isApproved,
                                isViewOnly: isViewOnly,
                                isTie: isTie,
                                isAllDone: isAllDone,
                                isDark: isDark,
                                myUserId: _myUserId ?? '',
                                teamMatches: teamMatches,
                                onAddRenseikaiNext: () =>
                                    MatchDialogHelper.showNextMatchDialog(
                                      context,
                                      match,
                                    ),
                                onShowConfirmDialog: (title, content) =>
                                    MatchDialogHelper.showConfirmDialog(
                                      context,
                                      title,
                                      content,
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
                              );

                              final actionPanelPart = MatchScoreActionSection(
                                matchId: match.id,
                                isInputLocked: isInputLocked,
                                isDark: isDark,
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
                        onSelectDaihyo: () {
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
                        },
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
                : buildMatchLayout(maxHeight);
          },
        ),
      ),
    );

    return layoutWidget;
  }
}
