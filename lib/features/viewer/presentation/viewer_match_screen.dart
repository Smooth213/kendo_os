import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart'; // kIsWeb用

import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/features/viewer/providers/viewer_view_state_provider.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

// ★ Phase 10: 運営モードへの最速復帰用プロバイダーとロール定義のインポート
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_provider.dart';

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
    // 🛡️ 救済コンテキストフォールバック：URLパラメータに無い場合は、RoleInjectorがガッチリ保持しているグローバルキャッシュから安全に復元取得
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

    // 🌟 ずっとクルクルする（無限ローディング）不具合修正パッチ
    // Projectionストリームの初回パケットを待機中で loading に陥っている場合でも、
    // ローカルキャッシュ(matchListProvider)から即座に状態を生成して表示を点火し、
    // 画面のフリーズを完全回避する最強のフォールバック防衛線。
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

    if (kIsWeb) {
      if (asyncWebMatches != null &&
          asyncWebMatches.isLoading &&
          fallbackProjection == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      } else if (asyncWebMatches != null && asyncWebMatches.hasError) {
        return Scaffold(
          body: Center(child: Text('エラーが発生しました: ${asyncWebMatches.error}')),
        );
      } else {
        if (fallbackProjection == null) {
          return const Scaffold(body: Center(child: Text('試合データが見つかりません')));
        }
        return _buildScreen(context, ref, fallbackProjection, activeMatch);
      }
    } else {
      return viewStateAsync!.when(
        loading: () {
          if (fallbackProjection != null) {
            return _buildScreen(context, ref, fallbackProjection, activeMatch);
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
        error: (e, s) => Scaffold(body: Center(child: Text('エラーが発生しました: $e'))),
        data: (MatchProjection? projection) {
          final target = projection ?? fallbackProjection;
          if (target == null) {
            return const Scaffold(body: Center(child: Text('試合データが見つかりません')));
          }
          return _buildScreen(context, ref, target, activeMatch);
        },
      );
    }
  }

  Widget _buildScreen(
    BuildContext context,
    WidgetRef ref,
    MatchProjection projection,
    MatchModel? activeMatch,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.indigo.shade900;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppHeader(
          title: '試合状況 (観戦)',
          leading: context.canPop()
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: iconColor, size: 20),
                  tooltip: '戻る',
                  onPressed: () => context.pop(),
                )
              : null,
          actions: [
            IconButton(
              icon: Icon(Icons.qr_code_2, color: iconColor, size: 20),
              tooltip: 'この試合の観戦QRコード・リンクを共有',
              onPressed: () =>
                  _showShareDialog(context, ref, projection.tournamentId),
            ),
            ManualHelpButton(
              manualPath: 'docs/manuals/faq/viewer_faq.md',
              color: iconColor,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Column(
          children: [
            // ★ 1. ステータスバー
            _buildStatusBar(context, ref, projection),

            // 2. 特大・高視認性スコアボード
            Expanded(
              child: LargeViewerScoreboard(
                projection: projection,
                activeMatch: activeMatch,
                isDark: isDark,
              ),
            ),

            SizedBox(
              width: 0,
              height: 0,
              child: ProviderScope(
                overrides: [
                  scoreboardMatchIdProvider.overrideWithValue(matchId),
                  scoreboardNameTapProvider.overrideWithValue(null),
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
      color: Colors.blueGrey.shade700,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                '閲覧モード',
                style: TextStyle(
                  color: Colors.white,
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
              style: const TextStyle(
                color: Colors.white70,
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
    // 🛡️ ドメイン同期パッチ：QRコードから他の端末がスキャンした際にも、確実に正しいベータ環境（kendo-os-beta.web.app）の部屋に直着陸できるように修正
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
                color: Colors.white,
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
                icon: const Icon(Icons.share),
                label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
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

class LargeViewerScoreboard extends StatelessWidget {
  final MatchProjection projection;
  final MatchModel? activeMatch;
  final bool isDark;

  const LargeViewerScoreboard({
    super.key,
    required this.projection,
    required this.activeMatch,
    required this.isDark,
  });

  String _cleanName(String name) {
    if (name.contains('欠員')) return '(欠員)';
    if (!name.contains(':')) return name.trim();
    return name.split(':').last.replaceAll(')', '').trim();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _getFoulCount(Side side) {
    if (activeMatch == null) return 0;
    final engine = KendoRuleEngine();
    final activeEvents = engine.filterActiveEvents(activeMatch!.events);
    return activeEvents
        .where(
          (e) => e.side == side && (e.isHansoku || e.type == PointType.hansoku),
        )
        .length;
  }

  String _getWinner(MatchModel? match) {
    if (match == null) {
      // フォールバック: projectionのスコアから判定
      if (projection.redScore > projection.whiteScore) return 'red';
      if (projection.whiteScore > projection.redScore) return 'white';
      return 'none';
    }

    final isFinished = match.status == 'approved' || match.status == 'finished';
    if (!isFinished) return 'none';

    if (match.redScore > match.whiteScore) {
      return 'red';
    } else if (match.whiteScore > match.redScore) {
      return 'white';
    } else {
      // 引き分け時、代表戦等の決着判定
      final hasRedHantei = match.events.any(
        (e) =>
            !e.isCanceled && e.side == Side.red && e.type == PointType.hantei,
      );
      final hasWhiteHantei = match.events.any(
        (e) =>
            !e.isCanceled && e.side == Side.white && e.type == PointType.hantei,
      );
      final hasRedFusen = match.events.any(
        (e) => !e.isCanceled && e.side == Side.red && e.type == PointType.fusen,
      );
      final hasWhiteFusen = match.events.any(
        (e) =>
            !e.isCanceled && e.side == Side.white && e.type == PointType.fusen,
      );

      if (hasRedHantei || hasRedFusen) {
        return 'red';
      } else if (hasWhiteHantei || hasWhiteFusen) {
        return 'white';
      } else {
        return 'draw';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxHeight > constraints.maxWidth;
        if (isPortrait) {
          return _buildPortraitLayout(context);
        } else {
          return _buildLandscapeLayout(context);
        }
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    final redName = _cleanName(projection.redName);
    final whiteName = _cleanName(projection.whiteName);
    final redFouls = _getFoulCount(Side.red);
    final whiteFouls = _getFoulCount(Side.white);

    final isFinished =
        projection.status == 'approved' || projection.status == 'finished';
    final winner = _getWinner(activeMatch);
    final isRedWinner = isFinished && winner == 'red';
    final isWhiteWinner = isFinished && winner == 'white';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // 🔴 赤選手エリア
          Expanded(
            child: _buildPlayerCard(
              context: context,
              side: Side.red,
              name: redName,
              displays: projection.redDisplays,
              foulCount: redFouls,
              isWinner: isRedWinner,
              cardColor: isDark ? const Color(0xFF2C1616) : Colors.red.shade50,
              textColor: isDark ? Colors.red.shade300 : Colors.red.shade800,
            ),
          ),

          // ── 中央情報エリア (VS / スコア / タイマー) ──
          _buildCenterDivider(isPortrait: true),

          // ⚪ 白選手エリア
          Expanded(
            child: _buildPlayerCard(
              context: context,
              side: Side.white,
              name: whiteName,
              displays: projection.whiteDisplays,
              foulCount: whiteFouls,
              isWinner: isWhiteWinner,
              cardColor: isDark
                  ? const Color(0xFF1C2430)
                  : Colors.blueGrey.shade50,
              textColor: isDark
                  ? Colors.grey.shade300
                  : Colors.blueGrey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    final redName = _cleanName(projection.redName);
    final whiteName = _cleanName(projection.whiteName);
    final redFouls = _getFoulCount(Side.red);
    final whiteFouls = _getFoulCount(Side.white);

    final isFinished =
        projection.status == 'approved' || projection.status == 'finished';
    final winner = _getWinner(activeMatch);
    final isRedWinner = isFinished && winner == 'red';
    final isWhiteWinner = isFinished && winner == 'white';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // 🔴 赤選手エリア
          Expanded(
            child: _buildPlayerCard(
              context: context,
              side: Side.red,
              name: redName,
              displays: projection.redDisplays,
              foulCount: redFouls,
              isWinner: isRedWinner,
              cardColor: isDark ? const Color(0xFF2C1616) : Colors.red.shade50,
              textColor: isDark ? Colors.red.shade300 : Colors.red.shade800,
            ),
          ),

          // ── 中央情報エリア (VS / スコア / タイマー) ──
          _buildCenterDivider(isPortrait: false),

          // ⚪ 白選手エリア
          Expanded(
            child: _buildPlayerCard(
              context: context,
              side: Side.white,
              name: whiteName,
              displays: projection.whiteDisplays,
              foulCount: whiteFouls,
              isWinner: isWhiteWinner,
              cardColor: isDark
                  ? const Color(0xFF1C2430)
                  : Colors.blueGrey.shade50,
              textColor: isDark
                  ? Colors.grey.shade300
                  : Colors.blueGrey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard({
    required BuildContext context,
    required Side side,
    required String name,
    required List<PointDisplay> displays,
    required int foulCount,
    required bool isWinner,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.xlarge,
        border: Border.all(
          color: isWinner
              ? Colors.amber.shade600
              : (isDark ? Colors.white10 : Colors.black12),
          width: isWinner ? 4.0 : 1.0,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: FittedBox(
        fit: BoxFit.contain, // 🛡️ 究極のレイアウト崩れ・オーバーフロー防止
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 勝者インジケーター
            if (isWinner)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber.shade600,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '勝者',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: Colors.amber.shade600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

            // 選手名
            Text(
              name,
              style: TextStyle(
                fontSize: AppFontSize.scoreboardTimer, // 🌟 視認性を高める48pt
                fontWeight: AppFontWeight.bold,
                color: textColor,
                letterSpacing: 1.5,
              ),
              maxLines: 1,
            ),

            const SizedBox(height: AppSpacing.lg),

            // 🌟 技マーク（メ、コ、ド、ツ、反、判定など）＆ 勝敗確定時の丸囲み
            _buildLargePointBox(displays, isWinner, side),

            const SizedBox(height: AppSpacing.md),

            // 反則表示 (▲)
            if (foulCount > 0)
              Text(
                List.filled(foulCount, '▲').join(''),
                style: const TextStyle(
                  fontSize: AppFontSize.hero, // 反則マークも特大表示
                  color: Colors.amber,
                  fontWeight: AppFontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargePointBox(
    List<PointDisplay> displays,
    bool isWinner,
    Side side,
  ) {
    final color = side == Side.red
        ? (isDark ? Colors.red.shade400 : Colors.red.shade700)
        : (isDark ? Colors.grey.shade300 : Colors.blueGrey.shade800);

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🏆 勝敗がついた際は、2本の取得枠全体を大きく丸で囲む（公式記録と同様の仕様）
          if (isWinner)
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.6),
                  width: 3.5, // 存在感のある太い丸枠
                ),
              ),
            ),

          // 1本目のポイント（左上配置）
          if (displays.isNotEmpty)
            Positioned(
              top: 14,
              left: AppSpacing.lg,
              child: _buildPointBadge(displays[0], color),
            ),

          // 2本目のポイント（右下配置）
          if (displays.length > 1)
            Positioned(
              bottom: 14,
              right: AppSpacing.lg,
              child: _buildPointBadge(displays[1], color),
            ),
        ],
      ),
    );
  }

  Widget _buildPointBadge(PointDisplay pd, Color color) {
    const double fs = 24; // 🌟 24pt
    const double badgeSize = 42; // 🌟 42pxのバッジ

    // ３本勝負の合計１本目のみ◯で囲む（'反'や'判定'等も含めすべて）
    if (pd.isFirstMatchPoint) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.7 : 1.0),
            width: 2.5,
          ),
        ),
        child: Text(
          pd.mark == '判定' ? '判' : pd.mark,
          style: TextStyle(
            fontSize: fs,
            fontWeight: AppFontWeight.bold,
            color: color,
            height: 1.0,
          ),
        ),
      );
    } else {
      return Container(
        width: badgeSize,
        height: badgeSize,
        alignment: Alignment.center,
        child: Text(
          pd.mark == '判定' ? '判' : pd.mark,
          style: TextStyle(
            fontSize: fs,
            fontWeight: AppFontWeight.bold,
            color: color,
            height: 1.0,
          ),
        ),
      );
    }
  }

  Widget _buildCenterDivider({required bool isPortrait}) {
    final timerText = _formatDuration(projection.remainingSeconds);
    final isTimerRunning = projection.timerIsRunning;

    // タイマーのテキストカラー
    final timerColor = isTimerRunning
        ? Colors.orangeAccent
        : (isDark ? Colors.white70 : Colors.black87);

    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.grey.shade200,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isTimerRunning ? Colors.orangeAccent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, color: timerColor, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Text(
              timerText,
              style: TextStyle(
                fontSize: AppFontSize.jumbo, // 🌟 タイマーも特大表示
                fontWeight: AppFontWeight.bold,
                fontFamily: 'monospace',
                color: timerColor,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // スコア対比
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.indigo.shade600,
                borderRadius: AppRadius.small,
              ),
              child: Text(
                '${projection.redScore} - ${projection.whiteScore}',
                style: const TextStyle(
                  fontSize: AppFontSize.display,
                  fontWeight: AppFontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isPortrait ? 16.0 : 0.0,
        horizontal: isPortrait ? 0.0 : 16.0,
      ),
      child: Center(child: content),
    );
  }
}
