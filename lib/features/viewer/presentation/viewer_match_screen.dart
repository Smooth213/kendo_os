import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/features/viewer/components/large_viewer_scoreboard.dart';
import 'package:kendo_os/features/viewer/providers/viewer_view_state_provider.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_program_dock_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

export '../components/large_viewer_scoreboard.dart' show LargeViewerScoreboard;

class ViewerMatchScreen extends ConsumerWidget {
  final String matchId;
  const ViewerMatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewStateAsync = kIsWeb
        ? null
        : ref.watch(viewerMatchProjectionProvider(matchId));

    final queryTournamentId =
        GoRouterState.of(context).uri.queryParameters['tournamentId'] ?? '';
    final tournamentId = queryTournamentId.isNotEmpty
        ? queryTournamentId
        : (ref.watch(webCurrentTournamentIdProvider) ?? '');

    final asyncWebMatches = kIsWeb && tournamentId.isNotEmpty
        ? ref.watch(matchListByTournamentProvider(tournamentId))
        : null;

    final MatchModel? webMatch = asyncWebMatches?.value
        ?.where((m) => m.id == matchId)
        .firstOrNull;

    final localMatch = kIsWeb
        ? null
        : ref.watch(
            matchListProvider.select(
              (list) => list.where((m) => m.id == matchId).firstOrNull,
            ),
          );

    final MatchModel? activeMatch = kIsWeb ? webMatch : localMatch;

    MatchProjection? fallbackProjection;
    if (kIsWeb) {
      if (webMatch != null) {
        try {
          final engine = KendoRuleEngine();
          final analysis = engine.analyzeHistory(
            webMatch.events,
            webMatch,
            webMatch.rule,
          );
          fallbackProjection = MatchProjectionMapper.toProjection(
            webMatch,
            analysis,
          );
        } catch (_) {}
      }
    } else if (viewStateAsync!.isLoading || viewStateAsync.value == null) {
      if (localMatch != null) {
        try {
          final engine = KendoRuleEngine();
          final analysis = engine.analyzeHistory(
            localMatch.events,
            localMatch,
            localMatch.rule,
          );
          fallbackProjection = MatchProjectionMapper.toProjection(
            localMatch,
            analysis,
          );
        } catch (_) {}
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildBody(MatchProjection p) {
      return Column(
        children: [
          _buildStatusBar(context, ref, p),
          Expanded(
            child: LargeViewerScoreboard(
              projection: p,
              activeMatch: activeMatch,
              isDark: isDark,
            ),
          ),
        ],
      );
    }

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          title: '試合状況 (観戦)',
          leading:
              (GoRouter.of(context).canPop() || Navigator.of(context).canPop())
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => context.pop(),
                )
              : null,
          actions: [
            if (tournamentId.isNotEmpty)
              ProgramHeaderAction(
                tournamentId: tournamentId,
                isViewerMode: true,
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : context.appColors.primaryAccent,
              ),
            const ManualHelpButton(
              manualPath: 'docs/manuals/faq/viewer_faq.md',
            ),
            if (tournamentId.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.qr_code_2),
                tooltip: '観戦リンクのQRコードを表示',
                onPressed: () => _showShareDialog(context, ref, tournamentId),
              ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Stack(
          children: [
            if (kIsWeb)
              (fallbackProjection != null
                  ? buildBody(fallbackProjection)
                  : const Center(child: CircularProgressIndicator()))
            else
              viewStateAsync!.when(
                data: (p) => p == null
                    ? (fallbackProjection != null
                          ? buildBody(fallbackProjection)
                          : const Center(
                              child: Text(
                                '試合データが見つかりません',
                                style: TextStyle(
                                  color: AppKendoColors.pureWhite,
                                ),
                              ),
                            ))
                    : buildBody(p),
                loading: () => fallbackProjection != null
                    ? buildBody(fallbackProjection)
                    : const Center(child: CircularProgressIndicator()),
                error: (e, s) => fallbackProjection != null
                    ? buildBody(fallbackProjection)
                    : Center(
                        child: Text(
                          'エラー: $e',
                          style: const TextStyle(
                            color: AppKendoColors.redAccent,
                          ),
                        ),
                      ),
              ),
            Offstage(
              offstage: true,
              child: ProviderScope(
                overrides: [
                  scoreboardMatchIdProvider.overrideWithValue(matchId),
                  if (activeMatch != null)
                    scoreboardMatchProvider.overrideWithValue(activeMatch),
                  matchViewStateProvider(matchId).overrideWith((ref) {
                    return MatchViewState(
                      scoreText: '0 - 0',

                      redScore: 0,
                      whiteScore: 0,
                      isEncho: false,
                      winner: null,
                      lastEventText: '',
                      canUndo: false,
                      statusText: '',
                      syncStatus: SyncStatus.synced,
                      isViewOnly: true,
                      isInputLocked: true,
                      isAllDone: false,
                      isTie: false,
                      redCleanName: 'hidden_red\u200B',
                      whiteCleanName: 'hidden_white\u200B',
                    );
                  }),
                ],
                child: const MatchScoreboard(),
              ),
            ),
            if (tournamentId.isNotEmpty)
              FloatingProgramDockButton(
                tournamentId: tournamentId,
                isViewerMode: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(
    BuildContext context,
    WidgetRef ref,
    MatchProjection p,
  ) {
    return Container(
      width: double.infinity,
      color: const Color(0x8A000000),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility, color: AppKendoColors.pureWhite, size: 16),
              SizedBox(width: 6),
              Text(
                '閲覧モード',
                style: TextStyle(
                  color: AppKendoColors.pureWhite,
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.small,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${p.statusText} | 直前: ${p.lastEventText}',
              style: TextStyle(
                color: AppKendoColors.pureWhite.withValues(alpha: 0.7),
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(
    BuildContext context,
    WidgetRef ref,
    String tournamentId,
  ) {
    final dojoId = ref.read(currentDojoIdProvider);
    final bool isBunaiksen = tournamentId.startsWith('bunaiksen_');
    final String shareUrl = isBunaiksen
        ? 'https://kendo-os-beta.web.app/bunaiksen-viewer-home/$tournamentId?role=viewer&dojoId=$dojoId'
        : 'https://kendo-os-beta.web.app/viewer-home/$tournamentId?role=viewer&dojoId=$dojoId';

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: isBunaiksen ? '部内戦観戦リンク' : '大会観戦リンク',
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'このリンクを共有すると、\nリアルタイムで観戦できます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppFontSize.bodySmall),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                color: AppKendoColors.pureWhite,
                child: QrImageView(
                  data: shareUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        '【剣道リアルタイムViewer共有】この試合（コート）のリアルタイム打突一本速報・タイマー状態をその場で確認できます！\n'
                        'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
                        '試合速報リンク: $shareUrl',
                  ),
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKendoColors.blueGrey,
                  foregroundColor: AppKendoColors.pureWhite,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
