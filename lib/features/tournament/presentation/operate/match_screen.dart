import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/ui_message_provider.dart';
import 'package:kendo_os/shared/application/services/sound_service.dart';
import 'package:kendo_os/shared/errors/emergency_crash_preserver.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'components/match_screen/match_dialog_helper.dart';
import 'components/match_screen/match_header_widgets.dart';
import 'components/match_screen/match_loading_view.dart';
import 'components/match_screen/match_screen_body_content.dart';
import '../../../../shared/infrastructure/services/web_navigation_guard.dart';
export 'providers/match_screen_providers.dart';

class MatchScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String? tournamentId;
  const MatchScreen({super.key, required this.matchId, this.tournamentId});
  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  String? _myUserId;
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    setWebBeforeUnloadActive(true);
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
          if (currentMatch != null &&
              currentMatch.status != 'finished' &&
              currentMatch.status != 'approved') {
            ref
                .read(matchCommandProvider)
                .claimScorer(widget.matchId, _myUserId!);
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
    setWebBeforeUnloadActive(false);
    EmergencyCrashPreserver.unregisterActiveMatch(widget.matchId);
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
    String? tournamentId = widget.tournamentId;
    if (tournamentId == null || tournamentId.isEmpty) {
      try {
        tournamentId = GoRouterState.of(
          context,
        ).uri.queryParameters['tournamentId'];
      } catch (_) {}
    }
    if (tournamentId == null || tournamentId.isEmpty) {
      final curId = ref.watch(currentTournamentIdProvider);
      tournamentId = curId.isNotEmpty
          ? curId
          : ref.watch(webCurrentTournamentIdProvider);
    }
    final MatchModel? match =
        (kIsWeb && tournamentId != null && tournamentId.isNotEmpty)
        ? (ref.watch(
                matchListByTournamentProvider(tournamentId).select(
                  (asyncVal) => asyncVal.valueOrNull
                      ?.where((m) => m.id == widget.matchId)
                      .firstOrNull,
                ),
              ) ??
              ref.watch(singleMatchProvider(widget.matchId)))
        : ref.watch(singleMatchProvider(widget.matchId));
    if (match == null) return const MatchLoadingView();
    final MatchRule rule =
        match.rule ?? ref.watch(matchRuleProvider) ?? MatchRule();
    final List<MatchModel> teamMatches =
        match.groupName != null && match.groupName!.isNotEmpty
        ? (kIsWeb && tournamentId != null && tournamentId.isNotEmpty
              ? (ref
                    .watch(
                      matchListByTournamentProvider(tournamentId).select(
                        (asyncVal) => ListEqualityWrapper<MatchModel>(
                          asyncVal.valueOrNull
                                  ?.where((m) => m.groupName == match.groupName)
                                  .toList() ??
                              <MatchModel>[],
                        ),
                      ),
                    )
                    .list)
              : ref.watch(teamMatchesByGroupProvider(match.groupName!)))
        : <MatchModel>[];
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

    ref.listen<UiMessage?>(uiMessageProvider, (_, next) {
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
    EmergencyCrashPreserver.registerActiveMatch(match);
    final bool isMatchFinished =
        match.status == 'finished' || match.status == 'approved';
    final bool isInsideDock = DockSheetScope.of(context) != null;

    return PopScope(
      canPop: isMatchFinished || isInsideDock,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await MatchDialogHelper.showConfirmDialog(
          context,
          '試合画面の離脱',
          '試合がまだ終了していません。\n本当に試合操作画面から離脱しますか？',
        );
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: LiquidBackground(
        isAnimated: false, // 🔋 試合操作中の常時GPU再描画を根絶し発熱・バッテリー消費を完全抑制
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            centerTitle: true,
            backgroundColor: context.appColors.primaryAccent,
            foregroundColor: AppKendoColors.pureWhite,
            titleWidget: MatchHeaderTitle(match: match),
            actions: [MatchHeaderActions(match: match)],
          ),
          body: MatchScreenBodyContent(
            match: match,
            rule: rule,
            teamMatches: teamMatches,
            isViewOnly: isViewOnly,
            isSomeoneElseOperating: isSomeoneElseOperating,
            isApproved: isApproved,
            isReadOnly: permissions.isReadOnly,
            isInputLocked: isInputLocked,
            isTie: isTie,
            isDark: isDark,
            showSyncBar: showSyncBar,
            myUserId: _myUserId ?? '',
            tournamentId: tournamentId,
            ref: ref,
          ),
        ),
      ),
    );
  }
}
