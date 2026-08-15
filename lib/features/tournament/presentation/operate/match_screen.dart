import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart'; // ★ Phase 6: バイブレーション用
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_view_state_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
// ★ 追加: 通知司令塔
import 'package:kendo_os/features/tournament/presentation/operate/providers/ui_message_provider.dart';
// ★ Phase 7: UIのロジック委譲先
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
// ★ 追加：マスタとチーム情報を参照するためのインポート
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'components/match_screen/match_finished_navigation_dialog.dart';
import 'components/match_screen/match_hantei_dialog.dart';
import 'components/match_screen/match_infinite_next_dialog.dart';
import 'components/match_screen/match_operate_action_buttons_grid.dart';
import 'components/match_screen/match_snapshot_history_dialog.dart';
import 'components/match_screen/renseikai_master_timer_widget.dart';
// ★ Phase 3: 分割した専用Widgetをインポート
import 'package:kendo_os/features/match/domain/services/match_strategy.dart'; // ★ Phase 5: 戦略ファクトリの読み込み
import 'package:kendo_os/shared/application/services/sound_service.dart'; // ★ 追加: SoundServiceを読み込むために追加
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart'; // ★ 追加: KendoRuleEngineを使用するため
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加: TimeSource

// ★ Phase 3: 分割したWidget群
import 'package:kendo_os/shared/widgets/timer_widget.dart';
import 'package:kendo_os/shared/widgets/action_buttons.dart';
import 'package:kendo_os/shared/widgets/scoreboard.dart';
import 'package:kendo_os/features/match/domain/match_state.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rule_info_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/shared/widgets/sync_status_bar.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/shared/widgets/corrupted_match_banner.dart';

// ★ 追加：システム設定プロバイダの読み込み
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/bunaiksen_infinite_engine_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/share_provider.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});
final registeredTeamsProvider = StreamProvider.family
    .autoDispose<List<TeamModel>, String>((ref, tournamentId) {
      return ref
          .watch(teamRepositoryProvider)
          .watchTeamsByTournament(tournamentId);
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
    // ★ 修正: 画面を開き直すたびにランダムなIDが生成され「他人が操作中」と誤認され
    // タイマーがロック（止められない状態）になってしまうバグを防ぐため、固定IDを使用します。
    try {
      _myUserId = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';
    } catch (_) {
      // 🛡️ 例外セーフティガード：Firebase未初期化のテスト環境や、現場の電波断絶下での [core/no-app] による画面クラッシュを100%封殺します。
      _myUserId = 'local_user';
    }

    // ★ Step 3-3: 画面全体のタイマー(Timer.periodic)を完全に削除し、
    // タイマーが動いている場合のみ、バックグラウンドの時計（MatchTimerProvider）を動かす指示を出す
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.matchId.isNotEmpty) {
        // ★ 追加: 試合画面を開いた瞬間にSoundServiceを強制的に初期化し、音源の事前ロードを開始させる
        ref.read(soundServiceProvider);

        ref.read(matchCommandProvider).claimScorer(widget.matchId, _myUserId!);

        final match = ref
            .read(matchListProvider)
            .where((m) => m.id == widget.matchId)
            .firstOrNull;
        if (match != null) {
          if (match.status == 'corrupted' ||
              MatchLifecycleStateLegacyExt.fromLegacyString(match.status) ==
                  MatchLifecycleState.corrupted) {
            // 自動リカバリーを実施
            ref.read(matchCommandProvider).rebuildMatchSnapshot(widget.matchId);
          }
          _checkFusenOrFinish(match);
          if (match.timerIsRunning) {
            ref.read(matchTimerProvider).startLocalTicker(widget.matchId);
          }
        }
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
    if (container != null) {
      container
          .read(matchTimerProvider)
          .stopLocalTicker(
            widget.matchId,
          ); // ★ 修正: 画面を閉じる際にバックグラウンドのタイマーを正しく停止させる
      if (widget.matchId.isNotEmpty) {
        try {
          // ★ 修正: 既に終了・確定済みの場合は、古い状態での上書き（releaseScorer）を防止する
          final match = container
              .read(matchListProvider)
              .where((m) => m.id == widget.matchId)
              .firstOrNull;
          if (match != null &&
              match.status != 'finished' &&
              match.status != 'approved') {
            container
                .read(matchCommandProvider)
                .releaseScorer(widget.matchId, _myUserId!);
          }
        } catch (_) {}
      }
    }
    super.dispose();
  }

  // ★ Phase 7: ロジックを裏側(MatchApplicationService)に移動したため、
  // UI側は「変更があったらシステムの自動処理をキックする」だけの1行になります。
  void _checkFusenOrFinish(MatchModel next) {
    // 処理はすべて MatchApplicationService._finalizeIfNeeded が裏で実行します
  }

  // ★ 追加：同点時の「判定ダイアログ」
  Future<String?> _showHanteiDialog(MatchModel match) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showAppDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MatchHanteiDialog(
        redName: match.redName,
        whiteName: match.whiteName,
        isDark: isDark,
        onSelected: (result) => Navigator.pop(ctx, result),
      ),
    );
  }

  // ★ Phase 6: 危険操作ガード（確認ダイアログ）
  Future<bool> _showConfirmDialog(String title, String content) async {
    HapticFeedback.heavyImpact(); // 警告の意味を込めた強い振動
    return await showAppDialog<bool>(
          context: context,
          builder: (ctx) => AppDialog(
            titleIcon: Icons.warning_amber_rounded,
            iconColor: AppKendoColors.red,
            title: title,
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'キャンセル',
                  style: TextStyle(color: AppKendoColors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppKendoColors.hansokuRed,
                  foregroundColor: AppKendoColors.pureWhite,
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  '実行する',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // ★ 修正: 消してしまった match 本体と teamMatches を復旧
    // （タイマー秒数の更新は分離されているため、これを監視しても毎秒リビルドはされません）
    MatchModel? maybeMatch = ref.watch(
      matchListProvider.select(
        (list) => list.where((m) => m.id == widget.matchId).firstOrNull,
      ),
    );

    // =========================================================================
    // 🛡️ Webアプリ・スコア入力画面表示バグ修正パッチ
    // Riverpodの ref.watch を条件分岐（if (maybeMatch == null)）の中に置くと、
    // 一度値が取れた後に監視を解除してしまい、Firestoreのリアルタイム同期が止まる原因になります。
    // そのため、Web環境では常に監視するように変更します。
    // =========================================================================
    if (kIsWeb) {
      final tournamentId = GoRouterState.of(
        context,
      ).uri.queryParameters['tournamentId'];
      if (tournamentId != null && tournamentId.isNotEmpty) {
        // 常に監視することでFirestoreからのリアルタイムデータ流入（Stream）を途切れさせない
        final webMatches =
            ref.watch(matchListByTournamentProvider(tournamentId)).value ?? [];
        maybeMatch ??= webMatches
            .where((m) => m.id == widget.matchId)
            .firstOrNull;
      }
    }

    if (maybeMatch == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ★ ここで final な non-nullable 変数に確定させることで、クロージャー内での型プロモーション喪失エラーを一撃で完全解消します
    final MatchModel match = maybeMatch;

    // ★ 追加: DBのタイマー稼働状態(timerIsRunning)が変化した時、ローカルの時計エンジンを同期して動かす
    ref.listen<bool?>(
      matchListProvider.select(
        (list) => list
            .where((m) => m.id == widget.matchId)
            .firstOrNull
            ?.timerIsRunning,
      ),
      (previous, next) {
        if (previous != next && next != null) {
          debugPrint(
            '🕒 [MatchScreen] Provider listener detected timerIsRunning change: previous=$previous -> next=$next',
          );
          if (next) {
            debugPrint(
              '🕒 [MatchScreen] -> Calling startLocalTicker from listener',
            );
            ref.read(matchTimerProvider).startLocalTicker(widget.matchId);
          } else {
            debugPrint(
              '🕒 [MatchScreen] -> Calling stopLocalTicker from listener',
            );
            ref.read(matchTimerProvider).stopLocalTicker(widget.matchId);
          }
        }
      },
    );

    // ★ 修正: 試合に紐づいた専用ルールがあればそれをUIの表示制御に使う
    final MatchRule rule = match.rule ?? ref.watch(matchRuleProvider);

    final teamMatches = ref.watch(
      matchListProvider.select(
        (list) => match.groupName != null
            ? list.where((m) => m.groupName == match.groupName).toList()
            : <MatchModel>[],
      ),
    );

    // 錬成会（時間制）のマスタータイマーの初期化
    final groupName = match.groupName ?? '';
    if (groupName.isNotEmpty &&
        rule.isRenseikai &&
        rule.renseikaiType == '時間制') {
      final currentMaster = ref.read(renseikaiMasterTimerProvider(groupName));
      if (currentMaster == -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(renseikaiMasterTimerProvider(groupName).notifier)
              .initialize(rule.overallTimeMinutes * 60);
        });
      }
    }

    // ★ 修正: 閲覧者はRouterで弾かれるため、ここでの isViewOnly は「他端末が操作中（ロック競合）」のみを意味する
    // ★ Phase 8: 万が一URL直叩きで入られた場合の完全ガード（RoleベースのReadOnlyも組み込む）
    final permissions = ref.watch(permissionProvider);
    final isSomeoneElseOperating =
        match.scorerId != null && match.scorerId != _myUserId;
    final isViewOnly = permissions.isReadOnly || isSomeoneElseOperating;
    final isInputLocked =
        isViewOnly || match.status == 'finished' || match.status == 'approved';

    final isAllDone = ref.watch(
      matchViewStateProvider(widget.matchId).select((vs) => vs.isAllDone),
    );
    final isTie = ref.watch(
      matchViewStateProvider(widget.matchId).select((vs) => vs.isTie),
    );
    final isApproved = match.status == 'approved';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ★ Phase 7 - Step 3: エラー通知の監視（リスナー）
    ref.listen<UiMessage?>(uiMessageProvider, (previous, next) {
      if (next != null) {
        if (next.isError) {
          AppSnackBar.showError(context, next.text);
        } else {
          AppSnackBar.showSuccess(context, next.text);
        }
      }
    });

    // ★ Phase 3 修正版: ナビゲーションの復旧と、競合しないスワイプUndoの完成
    final activeRole = ref.watch(activeRoleProvider);
    final showSyncBar = activeRole != Role.viewer;

    final layoutWidget = LiquidBackground(
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: 0)),
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            centerTitle: true,
            backgroundColor: context.appColors.primaryAccent,
            foregroundColor: AppKendoColors.pureWhite,
            titleWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (match.category != null && match.category!.isNotEmpty)
                      ? '${match.category} - ${match.matchType}'
                      : match.matchType,
                  // ★ 変更: タイトルを白抜き
                  style: const TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.pureWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${match.redName} vs ${match.whiteName}',
                  // ★ 変更: サブタイトルは少し透過した白
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: AppKendoColors.pureWhite.withValues(alpha: 0.7),
                    fontWeight: AppFontWeight.medium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              // ★ 記録係が最も必要とする「1枚操作ガイド」へ直行させます
              const ManualHelpButton(
                manualPath: 'docs/manuals/quickstart/operator_1pager.md',
                color: AppKendoColors.pureWhite,
              ),
              // ★ 追加: 大会ホーム（試合一覧）に一気に戻るボタン
              IconButton(
                icon: const Icon(
                  Icons.view_list_rounded,
                  color: AppKendoColors.pureWhite,
                ),
                tooltip: '大会ホーム（試合一覧）へ戻る',
                onPressed: () {
                  if (match.tournamentId != null &&
                      match.tournamentId!.startsWith('bunaiksen_')) {
                    context.go('/bunaiksen-home');
                  } else {
                    context.go('/home/${match.tournamentId}');
                  }
                },
              ),
              // ★ Phase 6-4: 開発検証用の目のアイコン（一時的なViewer確認ボタン）を安全にパージ
              IconButton(
                // ★ 変更: 歯車アイコンも白
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppKendoColors.pureWhite,
                ),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double maxHeight = constraints.maxHeight;

              // ★ 誤作動を起こす比率計算を完全排除し、コンテンツの最小必須高さを絶対基準化
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
                            child: GestureDetector(
                              behavior: HitTestBehavior
                                  .translucent, // ボタン以外のタップも透過して検知
                              onHorizontalDragEnd: (details) {
                                if (details.primaryVelocity != null &&
                                    details.primaryVelocity!.abs() > 500) {
                                  // ★ 修正: キャンセル済みのイベントを除外して判定
                                  if (match.events.any(
                                    (e) =>
                                        !e.isCanceled &&
                                        e.type != PointType.undo,
                                  )) {
                                    HapticFeedback.mediumImpact();
                                    ref
                                        .read(matchCommandProvider)
                                        .undoLastEvent(match.id);
                                  }
                                }
                              },
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isLandscape =
                                      MediaQuery.of(context).orientation ==
                                      Orientation.landscape;
                                  final isTabletLandscape =
                                      isLandscape && constraints.maxWidth > 600;

                                  final isCorrupted =
                                      match.status == 'corrupted' ||
                                      MatchLifecycleStateLegacyExt.fromLegacyString(
                                            match.status,
                                          ) ==
                                          MatchLifecycleState.corrupted;
                                  final corruptedBanner = isCorrupted
                                      ? CorruptedMatchBanner(matchId: match.id)
                                      : const SizedBox.shrink();

                                  final viewOnlyBanner =
                                      (isSomeoneElseOperating &&
                                          !isApproved &&
                                          !permissions.isReadOnly)
                                      ? Container(
                                          width: double.infinity,
                                          color: AppKendoColors.hansokuRed
                                              .withValues(alpha: 0.9),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.sm,
                                            horizontal: AppSpacing.lg,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.warning_amber_rounded,
                                                color: AppKendoColors.pureWhite,
                                                size: 18,
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.md,
                                              ),
                                              const Expanded(
                                                child: Text(
                                                  '他の記録員が入力中です',
                                                  style: TextStyle(
                                                    color: AppKendoColors
                                                        .pureWhite,
                                                    fontWeight:
                                                        AppFontWeight.bold,
                                                    fontSize:
                                                        AppFontSize.bodySmall,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  final confirmed =
                                                      await _showConfirmDialog(
                                                        '入力権限の奪取',
                                                        '他の端末の入力を強制中断し、\nこの端末で入力を開始しますか？',
                                                      );
                                                  if (confirmed) {
                                                    await ref
                                                        .read(
                                                          matchCommandProvider,
                                                        )
                                                        .forceClaimScorer(
                                                          match.id,
                                                          _myUserId!,
                                                        );
                                                  }
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor:
                                                      AppKendoColors.pureWhite
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                  foregroundColor:
                                                      AppKendoColors.pureWhite,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal:
                                                            AppSpacing.md,
                                                        vertical: 0,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    30,
                                                  ),
                                                ),
                                                child: const Text(
                                                  '自分に切り替える',
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppFontSize.caption,
                                                    fontWeight:
                                                        AppFontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink();

                                  // ★ 修正: KendoRuleEngineを使って正確に有効なイベントのみを抽出する
                                  final engine = KendoRuleEngine();
                                  final validEvents = engine.filterActiveEvents(
                                    match.events,
                                  );
                                  final canUndoReal = validEvents.isNotEmpty;

                                  // ★ Phase 6-4: 操作履歴の透明化（ミニログ ＋ Undoボタン）
                                  final undoArea = Column(
                                    children: [
                                      // 1. 直近3件のミニログ表示エリア（★高さを完全に固定し、ボタンの圧迫を防ぐ）
                                      Container(
                                        height: 62,
                                        margin: const EdgeInsets.symmetric(
                                          // ★ 左右の余白を完全に0にパージし、画面の横幅いっぱいにフィット
                                          horizontal: 0,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                          horizontal: AppSpacing.sm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(
                                                  0xFFFFFFFF,
                                                ).withValues(alpha: 0.10)
                                              : const Color(0xFFF2F2F7),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(
                                                  AppRadius.smallValue,
                                                ),
                                              ),
                                        ),
                                        alignment: Alignment
                                            .bottomCenter, // 下から積み上がるように配置
                                        child: validEvents.isNotEmpty
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: validEvents.reversed.take(3).toList().asMap().entries.map((
                                                  entry,
                                                ) {
                                                  final e = entry.value;
                                                  final isLast = entry.key == 0;
                                                  final sideColor =
                                                      e.side == Side.red
                                                      ? AppKendoColors
                                                            .hansokuRed
                                                      : (e.side == Side.white
                                                            ? (isDark
                                                                  ? AppKendoColors
                                                                        .pureWhite
                                                                  : Colors
                                                                        .black87)
                                                            : AppKendoColors
                                                                  .grey);
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 1,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          '${validEvents.indexOf(e) + 1}.',
                                                          style: const TextStyle(
                                                            fontSize:
                                                                AppFontSize
                                                                    .badge,
                                                            color:
                                                                AppKendoColors
                                                                    .grey,
                                                            fontWeight:
                                                                AppFontWeight
                                                                    .bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Icon(
                                                          Icons.circle,
                                                          size: 8,
                                                          color: sideColor,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          e.type ==
                                                                  PointType.men
                                                              ? 'メン'
                                                              : e.type ==
                                                                    PointType
                                                                        .kote
                                                              ? 'コテ'
                                                              : e.type ==
                                                                    PointType
                                                                        .doIdo
                                                              ? 'ドウ'
                                                              : e.type ==
                                                                    PointType
                                                                        .tsuki
                                                              ? 'ツキ'
                                                              : e.type ==
                                                                    PointType
                                                                        .hansoku
                                                              ? '反則'
                                                              : '判定',
                                                          style: TextStyle(
                                                            fontSize:
                                                                AppFontSize
                                                                    .small,
                                                            fontWeight: isLast
                                                                ? FontWeight
                                                                      .w900
                                                                : FontWeight
                                                                      .normal,
                                                            color: isLast
                                                                ? sideColor
                                                                : sideColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.7,
                                                                      ),
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        Text(
                                                          DateFormat(
                                                            'HH:mm:ss',
                                                          ).format(e.timestamp),
                                                          style: const TextStyle(
                                                            fontSize:
                                                                AppFontSize
                                                                    .badge,
                                                            color:
                                                                AppKendoColors
                                                                    .grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              )
                                            : const Center(
                                                child: Text(
                                                  '操作履歴',
                                                  style: TextStyle(
                                                    color: AppKendoColors.grey,
                                                    fontSize: AppFontSize.badge,
                                                    fontWeight:
                                                        AppFontWeight.bold,
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      // 2. Undoボタン（ログの直下に配置して一体化）
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          // ★ 左右の余白を完全に0にパージし、画面の両端まで美しくフィット
                                          horizontal: 0,
                                          vertical: 0,
                                        ),
                                        child: InkWell(
                                          onTap: canUndoReal
                                              ? () {
                                                  HapticFeedback.mediumImpact();
                                                  ref
                                                      .read(
                                                        matchCommandProvider,
                                                      )
                                                      .undoLastEvent(match.id);
                                                }
                                              : null,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                bottom: Radius.circular(
                                                  AppRadius.smallValue,
                                                ),
                                              ),
                                          child: Container(
                                            height: 36, // ★ さらに縮小
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(
                                                      0xFFFFFFFF,
                                                    ).withValues(alpha: 0.15)
                                                  : AppKendoColors
                                                        .grey
                                                        .shade200,
                                              borderRadius:
                                                  validEvents.isNotEmpty
                                                  ? const BorderRadius.vertical(
                                                      bottom: Radius.circular(
                                                        AppRadius.smallValue,
                                                      ),
                                                    )
                                                  : AppRadius.small,
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(
                                                        0xFFFFFFFF,
                                                      ).withValues(alpha: 0.24)
                                                    : AppKendoColors.pureBlack
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.undo,
                                                  color: canUndoReal
                                                      ? (isDark
                                                            ? Colors
                                                                  .amber
                                                                  .shade300
                                                            : Colors
                                                                  .indigo
                                                                  .shade700)
                                                      : AppKendoColors.grey,
                                                  size: 24,
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.md,
                                                ),
                                                Text(
                                                  canUndoReal
                                                      ? '１つ前の操作を取り消す'
                                                      : '操作履歴なし',
                                                  style: TextStyle(
                                                    fontSize: AppFontSize.body,
                                                    fontWeight:
                                                        AppFontWeight.black,
                                                    color: canUndoReal
                                                        ? (context
                                                              .appColors
                                                              .textColor)
                                                        : AppKendoColors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 0,
                                      ), // ★ 操作履歴の下にある余白を限界まで削除
                                    ],
                                  );

                                  final isRenseikaiTimeBased =
                                      rule.isRenseikai &&
                                      rule.renseikaiType == '時間制';

                                  final timerPart = isRenseikaiTimeBased
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: AppSpacing.lg,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: TimerWidget(
                                                    matchId: match.id,
                                                    isInputLocked:
                                                        isInputLocked,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.lg,
                                              ),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child:
                                                      RenseikaiMasterTimerWidget(
                                                        groupName:
                                                            match.groupName ??
                                                            '',
                                                        isInputLocked:
                                                            isInputLocked,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : TimerWidget(
                                          matchId: match.id,
                                          isInputLocked: isInputLocked,
                                        );

                                  // ★ 修正: ボタンの並び順を「URL共有・復元 / スコア・ルール」に変更
                                  final groupButtonPart = MatchOperateActionButtonsGrid(
                                    isViewOnly: isViewOnly,
                                    isKachinuki: match.isKachinuki,
                                    onShareUrl: () => ref
                                        .read(shareProvider)
                                        .shareMatch(match),
                                    onRestoreHistory: () => _showSnapshotDialog(
                                      context,
                                      ref,
                                      match,
                                    ),
                                    onCheckScore: () => match.isKachinuki
                                        ? context.push(
                                            '/kachinuki-scoreboard/${match.groupName}',
                                          )
                                        : context.push(
                                            '/team-scoreboard/${match.groupName}',
                                          ),
                                    onCheckRule: () =>
                                        _showRuleInfoSheet(context, match),
                                  );

                                  final scoreboardPart = ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          constraints.maxHeight *
                                          0.28, // ★ 19.5:9でオーバーフローしないよう 0.32 から 0.28 に調整
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit
                                          .scaleDown, // ★ 枠に収まるように全体を少し縮小（スケールダウン）
                                      child: SizedBox(
                                        width: constraints.maxWidth,
                                        // ★ 修正: ProviderScope を介して動的引数を注入し、MatchScoreboard を完全に const 化
                                        child: ProviderScope(
                                          overrides: [
                                            scoreboardMatchIdProvider
                                                .overrideWithValue(match.id),
                                            scoreboardMatchProvider // ★ 追加: 最新のMatchModelを注入
                                                .overrideWithValue(match),
                                            scoreboardNameTapProvider
                                                .overrideWithValue(
                                                  (side) =>
                                                      _showNameEditBottomSheet(
                                                        match,
                                                        side,
                                                      ),
                                                ),
                                          ],
                                          child: const MatchScoreboard(),
                                        ),
                                      ),
                                    ),
                                  );

                                  final actionPanelPart = Container(
                                    color: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : const Color(0xFFF2F2F7),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final settings = ref.watch(
                                          settingsProvider,
                                        );
                                        final redPanel = ScoreActionPanel(
                                          matchId: match.id,
                                          side: Side.red,
                                          color: AppKendoColors.hansokuRed,
                                          isLocked: isInputLocked,
                                        );
                                        final whitePanel = ScoreActionPanel(
                                          matchId: match.id,
                                          side: Side.white,
                                          color: isDark
                                              ? const Color(0xFF1C1C1E)
                                              : context
                                                    .appColors
                                                    .cardBackground,
                                          textColor:
                                              context.appColors.textColor,
                                          isLocked: isInputLocked,
                                        );
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: settings.leftHanded
                                              ? [whitePanel, redPanel]
                                              : [redPanel, whitePanel],
                                        );
                                      },
                                    ),
                                  );

                                  final bottomButtonPart = Container(
                                    color: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : const Color(0xFFF2F2F7),
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.lg,
                                      0,
                                      AppSpacing.lg,
                                      0,
                                    ), // ★ 最下部の余白もゼロに
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final settings = ref.watch(
                                          settingsProvider,
                                        );

                                        if (isApproved) {
                                          return const SizedBox(
                                            height: 40,
                                            child: Center(
                                              child: Text(
                                                '公式記録確定済み',
                                                style: TextStyle(
                                                  fontWeight:
                                                      AppFontWeight.bold,
                                                  color: AppKendoColors.grey,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        if (rule.isRenseikai &&
                                            rule.renseikaiType == '時間制' &&
                                            (match.matchType ==
                                                    rule.positions.last ||
                                                match.matchType == '錬成会') &&
                                            match.status == 'finished') {
                                          return _buildRenseikaiNextButton(
                                            context,
                                            match,
                                            isViewOnly,
                                          );
                                        }

                                        if (match.status == 'finished') {
                                          final confirmAction = isViewOnly
                                              ? null
                                              : () async {
                                                  if (settings.haptic) {
                                                    HapticFeedback.heavyImpact();
                                                  }

                                                  // ★ 修正: 無限勝ち抜きモードの場合は、確定ボタンでも専用の終了・次試合生成処理へ誘導する！
                                                  if (match.isKachinuki &&
                                                      match.matchType ==
                                                          '無限勝ち抜き') {
                                                    if (settings
                                                        .showConfirmDialog) {
                                                      final confirmed =
                                                          await _showConfirmDialog(
                                                            '記録の確定',
                                                            'この試合の記録を確定して次に進みますか？\n確定後は点数の修正ができなくなります。',
                                                          );
                                                      if (!confirmed) return;
                                                    }
                                                    String winnerColor = 'draw';
                                                    if ((match.redScore as num)
                                                            .toInt() >
                                                        (match.whiteScore
                                                                as num)
                                                            .toInt()) {
                                                      winnerColor = 'red';
                                                    } else if ((match.whiteScore
                                                                as num)
                                                            .toInt() >
                                                        (match.redScore as num)
                                                            .toInt()) {
                                                      winnerColor = 'white';
                                                    }

                                                    if (!mounted ||
                                                        !context.mounted) {
                                                      return;
                                                    }
                                                    showAppDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (_) => const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                    await _handleMatchFinish(
                                                      context,
                                                      ref,
                                                      match,
                                                      winnerColor,
                                                    );
                                                    return;
                                                  }

                                                  if (settings
                                                      .showConfirmDialog) {
                                                    final confirmed =
                                                        await _showConfirmDialog(
                                                          '記録の確定',
                                                          'この試合の記録を確定して次に進みますか？\n確定後は点数の修正ができなくなります。',
                                                        );
                                                    if (!confirmed) return;
                                                  }

                                                  // ★ Phase 7: UIからは「確定してね」と頼むだけ。
                                                  // 勝ち抜き戦の次試合生成などは、すべて裏側で自動的に行われます。
                                                  await ref
                                                      .read(
                                                        matchApplicationServiceProvider,
                                                      )
                                                      .approveMatch(match.id);

                                                  if (!context.mounted) return;

                                                  // 画面遷移ロジック（UIの管轄なので残します）
                                                  final matches = ref.read(
                                                    matchListProvider,
                                                  );
                                                  final groupNextMatches = matches
                                                      .where(
                                                        (m) =>
                                                            m.groupName ==
                                                                match
                                                                    .groupName &&
                                                            m.order >
                                                                match.order &&
                                                            m.status !=
                                                                'approved' &&
                                                            m.status !=
                                                                'finished',
                                                      )
                                                      .toList();
                                                  groupNextMatches.sort(
                                                    (a, b) => a.order.compareTo(
                                                      b.order,
                                                    ),
                                                  );

                                                  if (groupNextMatches
                                                      .isNotEmpty) {
                                                    // 同じカードの続き（大将の次など）か、別カードへの移行かを判定
                                                    final nextM =
                                                        groupNextMatches.first;
                                                    final currentRedTeam =
                                                        match.redName.contains(
                                                          ':',
                                                        )
                                                        ? match.redName
                                                              .split(':')
                                                              .first
                                                              .trim()
                                                        : match.redName;
                                                    final currentWhiteTeam =
                                                        match.whiteName
                                                            .contains(':')
                                                        ? match.whiteName
                                                              .split(':')
                                                              .first
                                                              .trim()
                                                        : match.whiteName;
                                                    final nextRedTeam =
                                                        nextM.redName.contains(
                                                          ':',
                                                        )
                                                        ? nextM.redName
                                                              .split(':')
                                                              .first
                                                              .trim()
                                                        : nextM.redName;
                                                    final nextWhiteTeam =
                                                        nextM.whiteName
                                                            .contains(':')
                                                        ? nextM.whiteName
                                                              .split(':')
                                                              .first
                                                              .trim()
                                                        : nextM.whiteName;

                                                    bool isCardEndingPosition =
                                                        match.matchType ==
                                                            '大将' ||
                                                        match.matchType ==
                                                            '代表戦' ||
                                                        match.matchType ==
                                                            '個人戦' ||
                                                        match.matchType == '選手';

                                                    if (currentRedTeam ==
                                                            nextRedTeam &&
                                                        currentWhiteTeam ==
                                                            nextWhiteTeam &&
                                                        !isCardEndingPosition &&
                                                        !match.isKachinuki) {
                                                      context.push(
                                                        '/match/${nextM.id}',
                                                      ); // ★ go() から push() に変更して履歴を残す
                                                    } else {
                                                      _showMatchFinishedDialog(
                                                        context,
                                                        match,
                                                        nextM,
                                                      );
                                                    }
                                                  } else {
                                                    bool hasDaihyo =
                                                        rule.isLeague
                                                        ? rule.hasLeagueDaihyo
                                                        : rule.hasRepresentativeMatch;
                                                    if (isTie &&
                                                        match.groupName !=
                                                            null &&
                                                        match.matchType !=
                                                            '代表戦' &&
                                                        hasDaihyo) {
                                                      context.push(
                                                        '/team-scoreboard/${match.groupName}',
                                                      );
                                                    } else {
                                                      _showMatchFinishedDialog(
                                                        context,
                                                        match,
                                                        null,
                                                      );
                                                    }
                                                  }
                                                };

                                          final bool isTrulyTeamMatch =
                                              match.groupName != null &&
                                              teamMatches.length > 1;

                                          return GestureDetector(
                                            onDoubleTap:
                                                settings.confirmBehavior ==
                                                    'double'
                                                ? confirmAction
                                                : null,
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  settings.confirmBehavior ==
                                                      'single'
                                                  ? confirmAction
                                                  : (isViewOnly
                                                        ? null
                                                        : () => AppSnackBar.show(
                                                            context,
                                                            settings.confirmBehavior ==
                                                                    'double'
                                                                ? 'ダブルタップで確定してください'
                                                                : '長押しで確定してください',
                                                          )),
                                              onLongPress:
                                                  settings.confirmBehavior ==
                                                      'long'
                                                  ? confirmAction
                                                  : null,
                                              icon: Icon(
                                                (isTie && isTrulyTeamMatch)
                                                    ? Icons.balance
                                                    : (isAllDone
                                                          ? Icons.emoji_events
                                                          : Icons.verified),
                                                size: 24,
                                              ),
                                              label: Text(
                                                (isTie && isTrulyTeamMatch)
                                                    ? '記録確定・星取表へ'
                                                    : (isAllDone
                                                          ? ((match.tournamentId !=
                                                                        null &&
                                                                    match
                                                                        .tournamentId!
                                                                        .startsWith(
                                                                          'bunaiksen_',
                                                                        ))
                                                                ? '確定・部内戦ホームへ'
                                                                : '確定・大会ホームへ')
                                                          : '確定・次へ'),
                                                style: const TextStyle(
                                                  fontSize: AppFontSize.subhead,
                                                  fontWeight:
                                                      AppFontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isTie
                                                    ? AppKendoColors.hansokuRed
                                                    : (isAllDone
                                                          ? Colors
                                                                .indigo
                                                                .shade700
                                                          : Colors
                                                                .teal
                                                                .shade600),
                                                foregroundColor:
                                                    AppKendoColors.pureWhite,
                                                minimumSize: const Size(
                                                  double.infinity,
                                                  36, // ★ さらに縮小して余裕を持たせる
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: AppRadius.large,
                                                ),
                                                elevation: 4,
                                              ),
                                            ),
                                          );
                                        } else {
                                          final finishAction = isViewOnly
                                              ? null
                                              : () async {
                                                  if (settings.haptic) {
                                                    HapticFeedback.heavyImpact();
                                                  }
                                                  final strategy =
                                                      MatchStrategyFactory.getStrategy(
                                                        match,
                                                        teamMatches.length,
                                                      );
                                                  final lastSettings = ref.read(
                                                    lastUsedSettingsProvider,
                                                  );

                                                  // ★ 追加: 無限勝ち抜きモードの場合は通常の延長・判定をスキップして専用エンジンへ
                                                  if (match.isKachinuki &&
                                                      match.matchType ==
                                                          '無限勝ち抜き') {
                                                    if (settings
                                                        .showConfirmDialog) {
                                                      final confirmed =
                                                          await _showConfirmDialog(
                                                            '試合終了',
                                                            'この試合を終了しますか？',
                                                          );
                                                      if (!confirmed) return;
                                                    }
                                                    String winnerColor = 'draw';
                                                    if ((match.redScore as num)
                                                            .toInt() >
                                                        (match.whiteScore
                                                                as num)
                                                            .toInt()) {
                                                      winnerColor = 'red';
                                                    } else if ((match.whiteScore
                                                                as num)
                                                            .toInt() >
                                                        (match.redScore as num)
                                                            .toInt()) {
                                                      winnerColor = 'white';
                                                    }

                                                    if (!mounted ||
                                                        !context.mounted) {
                                                      return;
                                                    }
                                                    showAppDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (_) => const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                    await _handleMatchFinish(
                                                      context,
                                                      ref,
                                                      match,
                                                      winnerColor,
                                                    );
                                                    return;
                                                  }

                                                  if (match.redScore ==
                                                      match.whiteScore) {
                                                    final nextAction = strategy
                                                        .getNextActionOnTie(
                                                          match: match,
                                                          lastSettings:
                                                              lastSettings,
                                                        );

                                                    if (nextAction ==
                                                        NextMatchAction
                                                            .startExtension) {
                                                      final confirmed =
                                                          await _showConfirmDialog(
                                                            '延長戦',
                                                            '延長戦に入りますか？',
                                                          );
                                                      if (!confirmed) return;

                                                      final rule = match.rule;
                                                      final double extMins =
                                                          (match.extensionTimeMinutes !=
                                                                  null &&
                                                              match.extensionTimeMinutes! >
                                                                  0)
                                                          ? match
                                                                .extensionTimeMinutes!
                                                          : (match.matchType ==
                                                                    '代表戦'
                                                                ? (rule?.daihyoEnchoTimeMinutes ??
                                                                      ((lastSettings['daihyoEnchoTimeMinutes'] ??
                                                                                  lastSettings['extensionTimeMinutes'] ??
                                                                                  3.0)
                                                                              as num)
                                                                          .toDouble())
                                                                : (rule?.enchoTimeMinutes ??
                                                                      ((lastSettings['extensionTimeMinutes'] ??
                                                                                  3.0)
                                                                              as num)
                                                                          .toDouble()));
                                                      final int
                                                      currentExtCount = '延長'
                                                          .allMatches(
                                                            match.note,
                                                          )
                                                          .length;
                                                      final extStr =
                                                          '延長${currentExtCount + 1}回目';

                                                      final currentTime = ref
                                                          .read(
                                                            timeSourceProvider,
                                                          )
                                                          .now();
                                                      await ref
                                                          .read(
                                                            matchApplicationServiceProvider,
                                                          )
                                                          .saveMatch(
                                                            match
                                                                .updateRemainingSeconds(
                                                                  (extMins * 60)
                                                                      .toInt(),
                                                                  currentTime,
                                                                )
                                                                .copyWith(
                                                                  // ★ 修正
                                                                  timerStartedAt:
                                                                      null,
                                                                  note:
                                                                      match
                                                                          .note
                                                                          .isEmpty
                                                                      ? extStr
                                                                      : '${match.note} ($extStr)',
                                                                  extensionTimeMinutes:
                                                                      extMins,
                                                                ),
                                                          );

                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      AppSnackBar.show(
                                                        context,
                                                        '$extStr（$extMins分）を開始します',
                                                      );
                                                      return;
                                                    }

                                                    if (nextAction ==
                                                        NextMatchAction
                                                            .showHantei) {
                                                      final hanteiResult =
                                                          await _showHanteiDialog(
                                                            match,
                                                          );
                                                      if (hanteiResult ==
                                                          null) {
                                                        return;
                                                      }
                                                      try {
                                                        if (hanteiResult ==
                                                                'red' ||
                                                            hanteiResult ==
                                                                'white') {
                                                          final side =
                                                              hanteiResult ==
                                                                  'red'
                                                              ? Side.red
                                                              : Side.white;
                                                          // ★ 修正: 競合を防ぐため1トランザクションで終了する
                                                          await ref
                                                              .read(
                                                                matchApplicationServiceProvider,
                                                              )
                                                              .finishMatchManually(
                                                                match.id,
                                                                hanteiWinner:
                                                                    side,
                                                              );
                                                        } else if (hanteiResult ==
                                                            'draw') {
                                                          // ★ 修正: 引き分けの場合も1トランザクションで終了マーカーを残す
                                                          await ref
                                                              .read(
                                                                matchApplicationServiceProvider,
                                                              )
                                                              .finishMatchManually(
                                                                match.id,
                                                              );
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          AppSnackBar.showError(
                                                            context,
                                                            '判定の保存に失敗しました: $e',
                                                          );
                                                        }
                                                      }
                                                      return;
                                                    }
                                                  }

                                                  if (settings
                                                      .showConfirmDialog) {
                                                    final confirmed =
                                                        await _showConfirmDialog(
                                                          '試合終了',
                                                          'この試合を終了しますか？',
                                                        );
                                                    if (!confirmed) return;
                                                  }

                                                  // ★ 修正: 手動終了の場合も1トランザクションで終了マーカーを残して終了する
                                                  await ref
                                                      .read(
                                                        matchApplicationServiceProvider,
                                                      )
                                                      .finishMatchManually(
                                                        match.id,
                                                      );
                                                };

                                          return Consumer(
                                            builder: (context, ref, child) {
                                              final isProcessing = ref.watch(
                                                isMatchCommandProcessingProvider,
                                              );
                                              final effectiveFinishAction =
                                                  isProcessing
                                                  ? null
                                                  : finishAction;

                                              return GestureDetector(
                                                onDoubleTap:
                                                    settings.confirmBehavior ==
                                                        'double'
                                                    ? effectiveFinishAction
                                                    : null,
                                                child: ElevatedButton(
                                                  onPressed:
                                                      settings.confirmBehavior ==
                                                          'single'
                                                      ? effectiveFinishAction
                                                      : (isViewOnly
                                                            ? null
                                                            : () => AppSnackBar.show(
                                                                context,
                                                                settings.confirmBehavior ==
                                                                        'double'
                                                                    ? 'ダブルタップで終了してください'
                                                                    : '長押しで終了してください',
                                                              )),
                                                  onLongPress:
                                                      settings.confirmBehavior ==
                                                          'long'
                                                      ? effectiveFinishAction
                                                      : null,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppKendoColors
                                                            .indigo
                                                            .shade600,
                                                    foregroundColor:
                                                        AppKendoColors
                                                            .pureWhite,
                                                    minimumSize: const Size(
                                                      double.infinity,
                                                      36, // ★ さらに縮小して余裕を持たせる
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                              AppRadius.large,
                                                        ),
                                                    elevation: 0,
                                                  ),
                                                  child: isProcessing
                                                      ? const SizedBox(
                                                          height: 20,
                                                          width: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                      : const Text(
                                                          'この試合を終了する',
                                                          style: TextStyle(
                                                            fontSize:
                                                                AppFontSize
                                                                    .subhead,
                                                            fontWeight:
                                                                AppFontWeight
                                                                    .bold,
                                                            letterSpacing: 1.1,
                                                          ),
                                                        ),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  );

                                  if (isTabletLandscape) {
                                    return Column(
                                      children: [
                                        corruptedBanner,
                                        viewOnlyBanner,
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                flex: 5,
                                                child: Column(
                                                  children: [
                                                    timerPart,
                                                    groupButtonPart,
                                                    Expanded(
                                                      child: scoreboardPart,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              VerticalDivider(
                                                width: 1,
                                                thickness: 1,
                                                color: isDark
                                                    ? const Color(
                                                        0xFFFFFFFF,
                                                      ).withValues(alpha: 0.10)
                                                    : AppKendoColors.pureBlack
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                              ),
                                              Expanded(
                                                flex: 6,
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                      child: actionPanelPart,
                                                    ),
                                                    undoArea,
                                                    bottomButtonPart,
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    final double currentContentHeight =
                                        constraints.maxHeight;

                                    final bool needsScroll =
                                        currentContentHeight < 610.0;
                                    final double effectiveHeight = needsScroll
                                        ? 610.0
                                        : currentContentHeight;

                                    final mainContent = Column(
                                      children: [
                                        corruptedBanner,
                                        viewOnlyBanner,
                                        timerPart,
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: 0,
                                          ),
                                          child: groupButtonPart,
                                        ),
                                        // 選手名・スコアボード領域
                                        Flexible(
                                          flex: 2,
                                          child: scoreboardPart,
                                        ),
                                        // 部位ボタン（ActionPanel）領域
                                        SizedBox(
                                          width: double.infinity,
                                          height: 175,
                                          child: actionPanelPart,
                                        ),
                                        // 履歴とUndoボタン
                                        undoArea,
                                        // 最下部確定ボタン
                                        SafeArea(
                                          top: false,
                                          bottom: false,
                                          child: Padding(
                                            padding: EdgeInsets.zero,
                                            child: bottomButtonPart,
                                          ),
                                        ),
                                      ],
                                    );

                                    return needsScroll
                                        ? SingleChildScrollView(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            child: SizedBox(
                                              height: effectiveHeight,
                                              child: mainContent,
                                            ),
                                          )
                                        : mainContent; // iPhone 17 Pro などの縦長画面では、スクロールを完全排除して底辺へ100%固定フィット
                                  }
                                },
                              ),
                            ),
                          ), // Expanded
                        ], // Column children
                      ),
                      if (match.matchType == '代表戦' &&
                          (match.redName.contains('未定') ||
                              match.whiteName.contains('未定') ||
                              match.redName.contains('代表選手') ||
                              match.whiteName.contains('代表選手')))
                        Container(
                          color: AppKendoColors.pureBlack.withValues(
                            alpha: 0.8,
                          ),
                          width: double.infinity,
                          height: double.infinity,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.person_add,
                                  color: AppKendoColors.pureWhite,
                                  size: 80,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                const Text(
                                  '代表戦の選手が未設定です',
                                  style: TextStyle(
                                    color: AppKendoColors.pureWhite,
                                    fontSize: AppFontSize.header,
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                SizedBox(
                                  width: 250,
                                  child: GlassButton(
                                    onPressed: () =>
                                        _showDaihyoSelectDialog(match),
                                    color: AppKendoColors.indigo,
                                    label: '代表者を選択する',
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.roundValue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ], // Stack children
                  ), // Stack
                );
              }

              if (needsScroll) {
                // ① 縦が短い環境（古い端末、キーボード出現時等）のみ安全弁としてスクロールを許可
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: buildMatchLayout(absoluteMinContentHeight),
                );
              } else {
                // ② iPhone 17 Pro などの十分な高さがある環境では、スクロールを完全に消失させ100%ジャストフィット
                return buildMatchLayout(maxHeight);
              }
            },
          ), // LayoutBuilder
        ), // Scaffold
      ), // MediaQuery
    ); // LiquidBackground

    if (showSyncBar) {
      return Column(
        children: [
          const SyncStatusBar(),
          Expanded(child: layoutWidget),
        ],
      );
    }
    return layoutWidget;
  }

  // ★ 直感UX改修：試合中の選手変更を、状況（自チーム/相手チーム）に応じて分岐するモダンなボトムシートへ昇格
  // ★ 直感UX改修：試合中の選手変更を、状況（自チーム/相手チーム）に応じて分岐するモダンなボトムシートへ昇格
  // 追加改修：カテゴリによる自動絞り込み、控え（緑）と出場中（オレンジ）の色分け、スマートスワップ、他カテゴリ開閉を実装
  void _showNameEditBottomSheet(MatchModel match, String side) {
    String fullName = side == 'red' ? match.redName : match.whiteName;
    String teamName = fullName.contains(':')
        ? fullName.split(':').first.trim()
        : '';
    String playerName = fullName.contains(':')
        ? fullName.split(':').last.replaceAll(')', '').trim()
        : fullName;

    final ctrl = TextEditingController(
      text: playerName == '欠員' ? '' : playerName,
    );

    // 共通の保存ロジック（スマートスワップ対応）
    Future<void> updatePlayerName(
      String newName, {
      bool isSwap = false,
      MatchModel? targetMatch,
      String? targetSide,
    }) async {
      final newFullName = teamName.isNotEmpty
          ? '$teamName : $newName'
          : newName;

      if (isSwap && targetMatch != null && targetSide != null) {
        // スマートスワップ：相手のポジションと今のポジションの選手名を相互に入れ替える
        final currentFullName = teamName.isNotEmpty
            ? '$teamName : $playerName'
            : playerName;

        final updatedCurrentMatch = side == 'red'
            ? match.copyWith(redName: newFullName)
            : match.copyWith(whiteName: newFullName);

        final updatedTargetMatch = targetSide == 'red'
            ? targetMatch.copyWith(redName: currentFullName)
            : targetMatch.copyWith(whiteName: currentFullName);

        await ref.read(matchApplicationServiceProvider).saveMatchesBulk([
          updatedCurrentMatch,
          updatedTargetMatch,
        ]);
      } else {
        // 通常の更新
        final updatedMatch = side == 'red'
            ? match.copyWith(redName: newFullName)
            : match.copyWith(whiteName: newFullName);
        await ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final bgColor = themeColors.cardBackground;
    final textColor = context.appColors.textColor;

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, modalRef, child) {
          final playersAsync = modalRef.watch(playerListProvider);
          final teamsAsync = modalRef.watch(
            registeredTeamsProvider(match.tournamentId ?? ''),
          );

          final registeredTeams = teamsAsync.value ?? [];
          final players = playersAsync.value ?? [];
          final isOwnTeam = registeredTeams.any((t) => t.teamName == teamName);

          // 同一の対戦グループ(groupName)に属する試合データを取得
          final allMatches = modalRef.watch(matchListProvider);
          final currentGroupMatches = allMatches
              .where((m) => m.groupName == match.groupName)
              .toList();

          // 自チームの現在出場中選手とポジションのマッピングを特定
          final activePlayerNames = <String>{};
          final playerPositions = <String, String>{}; // 選手名 -> ポジション名
          for (final m in currentGroupMatches) {
            if (m.redName.contains(':')) {
              final parts = m.redName.split(':');
              if (parts.first.trim() == teamName) {
                final name = parts.last.trim();
                activePlayerNames.add(name);
                playerPositions[name] = m.matchType;
              }
            }
            if (m.whiteName.contains(':')) {
              final parts = m.whiteName.split(':');
              if (parts.first.trim() == teamName) {
                final name = parts.last.trim();
                activePlayerNames.add(name);
                playerPositions[name] = m.matchType;
              }
            }
          }

          // 自チームの選手のみを抽出する
          final ownTeamPlayers = players.where((p) {
            final org = p.organization.trim();
            if (org.isEmpty) return false;
            return teamName.contains(org) || org.contains(teamName);
          }).toList();

          // 登録されたチーム（TeamModel）の選手も含める
          final matchedTeam = registeredTeams.firstWhere(
            (t) => t.teamName == teamName || teamName == t.teamName,
            orElse: () {
              return registeredTeams.firstWhere(
                (t) =>
                    teamName.contains(t.teamName) ||
                    t.teamName.contains(teamName),
                orElse: () => TeamModel(
                  id: '',
                  tournamentId: '',
                  category: '',
                  teamName: '',
                  matchType: '',
                  playerNames: [],
                ),
              );
            },
          );
          final teamRegisteredPlayerNames = matchedTeam.playerNames
              .where((name) => name.isNotEmpty)
              .toSet();

          final Set<String> ownPlayerNames = ownTeamPlayers
              .map((p) => p.name)
              .toSet();
          final List<PlayerModel> finalOwnTeamPlayers = List<PlayerModel>.from(
            ownTeamPlayers,
          );

          for (final name in teamRegisteredPlayerNames) {
            if (!ownPlayerNames.contains(name)) {
              final found = players.firstWhere(
                (p) => p.name == name,
                orElse: () => PlayerModel(
                  id: 'virtual_$name',
                  lastName: name,
                  firstName: '',
                  lastNameKana: '',
                  firstNameKana: '',
                  grade: 0,
                  organization: teamName,
                ),
              );
              finalOwnTeamPlayers.add(found);
              ownPlayerNames.add(name);
            }
          }

          String getPlayerCategory(int grade) {
            if (grade == -1) return '初心者の部';
            if (grade == 0) return '幼年の部';
            if (grade >= 1 && grade <= 4) return '小学生低学年の部';
            if (grade >= 5 && grade <= 6) return '小学生高学年の部';
            if (grade >= 7 && grade <= 9) return '中学生の部';
            if (grade >= 10 && grade <= 12) return '高校生の部';
            return '一般の部';
          }

          final matchCategory = match.category ?? '';

          // 2. チーム登録された補欠選手（登録されているが、現在出場していない選手）
          final teamSubstitutes = matchedTeam.playerNames
              .where(
                (name) => name.isNotEmpty && !activePlayerNames.contains(name),
              )
              .toList();

          final teamSubstitutesPlayers = finalOwnTeamPlayers
              .where((p) => teamSubstitutes.contains(p.name))
              .toList();
          final substitutes = teamSubstitutesPlayers;

          // 選手リストの分類
          // 1. 出場中の選手（sameCatActive）: カテゴリ条件をバイパスし、自チームで現在出場中（activePlayerNamesに含まれる）なら全員ここへ配置
          final sameCatActive = finalOwnTeamPlayers
              .where((p) => activePlayerNames.contains(p.name))
              .toList();

          // 2. 控え選手（出場していない選手かつ同カテゴリ）
          final sameCategorySubstitutes = finalOwnTeamPlayers
              .where((p) => !activePlayerNames.contains(p.name))
              .where((p) {
                if (matchCategory.isEmpty) return true;
                return getPlayerCategory(p.grade) == matchCategory;
              })
              .toList();

          // クイックアクセスに優先表示する選手（チーム補欠があればそれ、無ければ同カテゴリの控え全員）
          final List<PlayerModel> quickAccessPlayers;
          if (teamSubstitutesPlayers.isNotEmpty) {
            quickAccessPlayers = teamSubstitutesPlayers;
          } else {
            quickAccessPlayers = sameCategorySubstitutes;
          }

          // リストに表示する同カテゴリの控え選手（クイックアクセスにいない選手）
          final dojoListSubstitutes = sameCategorySubstitutes
              .where((p) => !quickAccessPlayers.any((q) => q.name == p.name))
              .toList();

          // 3. 他のカテゴリの選手（自チームの出場中・控え選手以外のすべての選手）
          final otherCategoryPlayers = players.where((p) {
            // 自チームの出場中選手として表示されているものは除外
            if (sameCatActive.any((a) => a.name == p.name)) return false;
            // クイックアクセスに表示されているものは除外
            if (quickAccessPlayers.any((q) => q.name == p.name)) return false;
            // リストの控え選手に表示されているものは除外
            if (dojoListSubstitutes.any((d) => d.name == p.name)) return false;
            return true;
          }).toList();

          // 選手カードをビルドする内部関数
          Widget buildPlayerCard(PlayerModel p, {required bool isSub}) {
            final isCurrentPosition = p.name == playerName; // 自分自身
            final currentPosition = playerPositions[p.name];

            // 色分け設定
            Color cardColor;
            BorderSide borderSide;
            if (isSub) {
              // 控え選手: 緑/ティール系統
              cardColor = isDark
                  ? const Color(0xFF009688).withValues(alpha: 0.2)
                  : const Color(0xFF009688).withValues(alpha: 0.6);
              borderSide = BorderSide(
                color: isDark
                    ? const Color(0xFF009688)
                    : const Color(0xFF009688),
              );
            } else {
              // 出場中選手: オレンジ系統
              cardColor = isDark
                  ? const Color(0xFFFF9800).withValues(alpha: 0.15)
                  : const Color(0xFFFF9800).withValues(alpha: 0.6);
              borderSide = BorderSide(
                color: isDark
                    ? const Color(0xFFFF9800)
                    : const Color(0xFFFF9800),
              );
            }

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.subValue),
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.compact,
                side: borderSide,
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 0,
                ),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isSub
                      ? (isDark
                            ? const Color(0xFF009688)
                            : const Color(0xFF009688))
                      : (isDark
                            ? const Color(0xFFFF9800)
                            : const Color(0xFFFF9800)),
                  child: Text(
                    p.name.substring(0, 1),
                    style: TextStyle(
                      color: isSub
                          ? (isDark
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF009688))
                          : (isDark
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFFFF9800)),
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.small,
                    ),
                  ),
                ),
                title: Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                    fontSize: AppFontSize.body,
                  ),
                ),
                subtitle: Text(
                  currentPosition != null
                      ? (isCurrentPosition ? 'このポジション' : '$currentPositionで出場中')
                      : '${p.gradeName} / ${p.gender}',
                  style: TextStyle(
                    color: isSub
                        ? (isDark
                              ? const Color(0xFF009688)
                              : const Color(0xFF009688))
                        : (isDark
                              ? const Color(0xFFFF9800)
                              : const Color(0xFFFF9800)),
                    fontSize: AppFontSize.caption,
                    fontWeight: currentPosition != null
                        ? AppFontWeight.bold
                        : AppFontWeight.regular,
                  ),
                ),
                trailing: Icon(
                  isSub ? Icons.check_circle_outline : Icons.swap_horiz,
                  size: 18,
                  color: isSub
                      ? (isDark
                            ? const Color(0xFF009688)
                            : const Color(0xFF009688))
                      : (isDark
                            ? const Color(0xFFFF9800)
                            : const Color(0xFFFF9800)),
                ),
                onTap: isCurrentPosition
                    ? null // 自分自身はタップ不可
                    : () async {
                        if (isSub) {
                          await updatePlayerName(p.name);
                        } else {
                          // 出場中選手との交代（スマートスワップ）
                          MatchModel? targetM;
                          String? targetS;
                          for (final m in currentGroupMatches) {
                            if (m.redName.contains(':')) {
                              final parts = m.redName.split(':');
                              if (parts.first.trim() == teamName &&
                                  parts.last.trim() == p.name) {
                                targetM = m;
                                targetS = 'red';
                                break;
                              }
                            }
                            if (m.whiteName.contains(':')) {
                              final parts = m.whiteName.split(':');
                              if (parts.first.trim() == teamName &&
                                  parts.last.trim() == p.name) {
                                targetM = m;
                                targetS = 'white';
                                break;
                              }
                            }
                          }
                          await updatePlayerName(
                            p.name,
                            isSwap: true,
                            targetMatch: targetM,
                            targetSide: targetS,
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
              ),
            );
          }

          // ★ Phase 8-3: キーボードに潰されないようにコンテナごと上にスライドさせる
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Material(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xlargeValue),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0x8A000000),
                        borderRadius: AppRadius.compact,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      '選手名の変更',
                      style: TextStyle(
                        fontSize: AppFontSize.header,
                        fontWeight: AppFontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (teamName.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        teamName,
                        style: TextStyle(
                          color: const Color(0x8A000000),
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: ctrl,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: '名前を直接入力 (助っ人など)',
                              labelStyle: const TextStyle(
                                color: AppKendoColors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF3F51B5)
                                      : const Color(0xFF3F51B5),
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFF2F2F7),
                              prefixIcon: Icon(
                                Icons.edit,
                                color: isDark
                                    ? const Color(0xFF3F51B5)
                                    : const Color(0xFF3F51B5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () async {
                            final newName = ctrl.text.trim().isEmpty
                                ? '欠員'
                                : ctrl.text.trim();
                            await updatePlayerName(newName);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3F51B5),
                            foregroundColor: AppKendoColors.pureWhite,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: AppSpacing.lg,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.medium,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '確定',
                            style: TextStyle(fontWeight: AppFontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await updatePlayerName('欠員');
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text(
                          'このポジションを「欠員」にする',
                          style: TextStyle(fontWeight: AppFontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppKendoColors.hansokuRed,
                          side: BorderSide(color: AppKendoColors.hansokuRed),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.compact,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.compact,
                          ),
                        ),
                      ),
                    ),

                    if (isOwnTeam && substitutes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '補欠登録の選手（タップで交代）',
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            fontWeight: AppFontWeight.bold,
                            color: isDark
                                ? const Color(0xFF009688)
                                : const Color(0xFF009688),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: substitutes.map((p) {
                            return AppActionChip(
                              label: Text(p.name),
                              backgroundColor: isDark
                                  ? const Color(
                                      0xFF009688,
                                    ).withValues(alpha: 0.3)
                                  : const Color(
                                      0xFF009688,
                                    ).withValues(alpha: 0.6),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF009688)
                                    : const Color(0xFF009688),
                              ),
                              labelStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF009688)
                                    : const Color(0xFF009688),
                                fontWeight: AppFontWeight.bold,
                              ),
                              onPressed: () async {
                                await updatePlayerName(p.name);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    if (isOwnTeam) ...[
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '道場の名簿から選ぶ (${match.category ?? "カテゴリ指定なし"})',
                          style: TextStyle(
                            fontSize: AppFontSize.body,
                            fontWeight: AppFontWeight.bold,
                            color: isDark
                                ? const Color(0xFF3F51B5)
                                : const Color(0xFF3F51B5),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: players.isEmpty
                            ? const Center(
                                child: Text(
                                  '名簿に登録されている選手がいません',
                                  style: TextStyle(color: AppKendoColors.grey),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xl,
                                ),
                                children: [
                                  // 1. 出場中の選手
                                  if (sameCatActive.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                      ),
                                      child: Text(
                                        '出場中の選手 (交代・スワップ)',
                                        style: TextStyle(
                                          fontSize: AppFontSize.small,
                                          fontWeight: AppFontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFFFF9800)
                                              : const Color(0xFFFF9800),
                                        ),
                                      ),
                                    ),
                                    ...sameCatActive.map(
                                      (p) => buildPlayerCard(p, isSub: false),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],

                                  if (dojoListSubstitutes.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                      ),
                                      child: Text(
                                        '同カテゴリの控え選手',
                                        style: TextStyle(
                                          fontSize: AppFontSize.small,
                                          fontWeight: AppFontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFF009688)
                                              : const Color(0xFF009688),
                                        ),
                                      ),
                                    ),
                                    ...dojoListSubstitutes.map(
                                      (p) => buildPlayerCard(p, isSub: true),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],

                                  const Divider(),
                                  const SizedBox(height: AppSpacing.sm),

                                  // 2. 他のカテゴリの選手 (折りたたみ)
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: AppKendoColors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      title: Text(
                                        '他のカテゴリの選手を表示',
                                        style: TextStyle(
                                          fontSize: AppFontSize.bodySmall,
                                          fontWeight: AppFontWeight.bold,
                                          color: isDark
                                              ? context.appColors.primaryAccent
                                              : context.appColors.primaryAccent,
                                        ),
                                      ),
                                      tilePadding: EdgeInsets.zero,
                                      childrenPadding: EdgeInsets.zero,
                                      children: [
                                        if (otherCategoryPlayers.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: AppSpacing.lg,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '他のカテゴリに選手はいません',
                                                style: TextStyle(
                                                  color: AppKendoColors.grey,
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          ...otherCategoryPlayers.map((p) {
                                            final isSub = !activePlayerNames
                                                .contains(p.name);
                                            return buildPlayerCard(
                                              p,
                                              isSub: isSub,
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ] else ...[
                      const Spacer(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ★ 修正：他と同様のデザインルールとダークモードを適用した代表戦設定シート
  void _showDaihyoSelectDialog(MatchModel match) {
    String rTeam = match.redName.contains(':')
        ? match.redName.split(':').first.trim()
        : '赤';
    String wTeam = match.whiteName.contains(':')
        ? match.whiteName.split(':').first.trim()
        : '白';

    final allMatches = ref.read(matchListProvider);
    final teamMatches = allMatches
        .where((m) => m.groupName == match.groupName && m.matchType != '代表戦')
        .toList();

    List<String> redPlayers = teamMatches
        .map(
          (m) => m.redName.contains(':')
              ? m.redName.split(':').last.trim()
              : m.redName,
        )
        .where(
          (n) =>
              n.isNotEmpty &&
              !n.contains('未定') &&
              !n.contains('欠員') &&
              !n.contains('代表選手'),
        )
        .toSet()
        .toList();
    List<String> whitePlayers = teamMatches
        .map(
          (m) => m.whiteName.contains(':')
              ? m.whiteName.split(':').last.trim()
              : m.whiteName,
        )
        .where(
          (n) =>
              n.isNotEmpty &&
              !n.contains('未定') &&
              !n.contains('欠員') &&
              !n.contains('代表選手'),
        )
        .toSet()
        .toList();

    final redCtrl = TextEditingController(
      text: redPlayers.isNotEmpty ? redPlayers.first : '',
    );
    final whiteCtrl = TextEditingController(
      text: whitePlayers.isNotEmpty ? whitePlayers.first : '',
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final bgColor = themeColors.cardBackground;
    final textColor = context.appColors.textColor;
    final inputBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          // ★ Phase 8-3: ここも同様にキーボード追従型へ変更
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xlargeValue),
                ),
              ),
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0x8A000000),
                      borderRadius: AppRadius.compact,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    '代表戦の準備',
                    style: TextStyle(
                      fontSize: AppFontSize.header,
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '代表戦を戦う選手を選んでください。\n決定するとタイマーが0:00にリセットされます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: const Color(0x8A000000),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(
                                    0xFFE53935,
                                  ).withValues(alpha: 0.15)
                                : const Color(0xFFE53935),
                            borderRadius: AppRadius.large,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFFE53935),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shield,
                                    color: isDark
                                        ? const Color(0xFFE53935)
                                        : AppKendoColors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '$rTeam の代表者',
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFFE53935),
                                      fontSize: AppFontSize.subhead,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (redPlayers.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: redPlayers
                                      .map(
                                        (p) => AppChoiceChip(
                                          label: Text(p),
                                          selected: redCtrl.text == p,
                                          selectedColor: isDark
                                              ? const Color(0xFFE53935)
                                              : const Color(0xFFE53935),
                                          backgroundColor: isDark
                                              ? const Color(0xFF2C2C2E)
                                              : const Color(0xFFFFFFFF),
                                          labelStyle: TextStyle(
                                            color: redCtrl.text == p
                                                ? (isDark
                                                      ? const Color(0xFFFFFFFF)
                                                      : AppKendoColors
                                                            .hansokuRed)
                                                : textColor,
                                            fontWeight: AppFontWeight.bold,
                                          ),
                                          onSelected: (s) => setState(() {
                                            redCtrl.text = p;
                                          }),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              AppTextField(
                                controller: redCtrl,
                                style: TextStyle(color: textColor),
                                onChanged: (val) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: '名前を直接入力',
                                  labelStyle: const TextStyle(
                                    color: AppKendoColors.grey,
                                  ),
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.edit, size: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadius.small,
                                  ),
                                  filled: true,
                                  fillColor: inputBg,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF607D8B).withValues(alpha: 0.2)
                                : const Color(0xFFF2F2F7),
                            borderRadius: AppRadius.large,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : const Color(0x33000000),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shield,
                                    color: const Color(0x8A000000),
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '$wTeam の代表者',
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFFFFFFFF)
                                          : const Color(0xDE000000),
                                      fontSize: AppFontSize.subhead,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (whitePlayers.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: whitePlayers
                                      .map(
                                        (p) => AppChoiceChip(
                                          label: Text(p),
                                          selected: whiteCtrl.text == p,
                                          selectedColor: isDark
                                              ? const Color(0xFF607D8B)
                                              : const Color(0x33000000),
                                          backgroundColor: isDark
                                              ? const Color(0xFF2C2C2E)
                                              : context
                                                    .appColors
                                                    .inputBackground,
                                          labelStyle: TextStyle(
                                            color: whiteCtrl.text == p
                                                ? (context.appColors.textColor)
                                                : textColor,
                                            fontWeight: AppFontWeight.bold,
                                          ),
                                          onSelected: (s) => setState(() {
                                            whiteCtrl.text = p;
                                          }),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              AppTextField(
                                controller: whiteCtrl,
                                style: TextStyle(color: textColor),
                                onChanged: (val) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: '名前を直接入力',
                                  labelStyle: const TextStyle(
                                    color: AppKendoColors.grey,
                                  ),
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.edit, size: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadius.small,
                                  ),
                                  filled: true,
                                  fillColor: inputBg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.lg,
                        bottom: AppSpacing.xl,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F51B5),
                          foregroundColor: AppKendoColors.pureWhite,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.large,
                          ),
                          elevation: 4,
                        ),
                        onPressed: () async {
                          final rName = redCtrl.text.trim().isEmpty
                              ? '代表'
                              : redCtrl.text.trim();
                          final wName = whiteCtrl.text.trim().isEmpty
                              ? '代表'
                              : whiteCtrl.text.trim();

                          final newRed = '$rTeam : $rName';
                          final newWhite = '$wTeam : $wName';

                          final updatedMatch = match
                              .copyWith(redName: newRed, whiteName: newWhite)
                              .updateRemainingSeconds(
                                0,
                                ref.read(timeSourceProvider).now(),
                              )
                              .copyWith(timerStartedAt: null);

                          await ref
                              .read(matchApplicationServiceProvider)
                              .saveMatch(updatedMatch); // ★ 修正
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text(
                          '決定して準備完了',
                          style: TextStyle(
                            fontSize: AppFontSize.subhead,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRenseikaiNextButton(
    BuildContext context,
    MatchModel match,
    bool isViewOnly,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final masterTime = ref.watch(
          renseikaiMasterTimerProvider(match.groupName ?? ''),
        );
        final isTimeUp = masterTime == 0;
        final isInputLocked =
            match.scorerId != null && match.scorerId != _myUserId;
        final settings = ref.watch(settingsProvider);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final confirmAction = isViewOnly
            ? null
            : () async {
                if (settings.haptic) {
                  HapticFeedback.heavyImpact();
                }

                if (settings.showConfirmDialog) {
                  final confirmed = await _showConfirmDialog(
                    '記録の確定',
                    'この試合の記録を確定して終了しますか？\n確定後は点数の修正ができなくなります。',
                  );
                  if (!confirmed) return;
                }

                await ref
                    .read(matchApplicationServiceProvider)
                    .approveMatch(match.id);

                if (!context.mounted) return;
                _showMatchFinishedDialog(context, match, null);
              };

        return Row(
          children: [
            Expanded(
              child: GlassButton(
                onPressed: (isInputLocked || isTimeUp)
                    ? null
                    : () => _showNextMatchDialog(context, ref, match),
                color: AppKendoColors.teal,
                icon: Icons.autorenew,
                label: '追加して継続',
                expandContent: false,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GestureDetector(
                onDoubleTap: settings.confirmBehavior == 'double'
                    ? confirmAction
                    : null,
                child: ElevatedButton.icon(
                  onPressed: settings.confirmBehavior == 'single'
                      ? confirmAction
                      : (isViewOnly
                            ? null
                            : () => AppSnackBar.show(
                                context,
                                settings.confirmBehavior == 'double'
                                    ? 'ダブルタップで確定してください'
                                    : '長押しで確定してください',
                              )),
                  onLongPress: settings.confirmBehavior == 'long'
                      ? confirmAction
                      : null,
                  icon: const Icon(Icons.verified, size: 24),
                  label: const Text(
                    '確定して終了',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSize.bodyMedium,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF3F51B5)
                        : const Color(0xFF3F51B5),
                    foregroundColor: const Color(0xFFFFFFFF),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNextMatchDialog(
    BuildContext context,
    WidgetRef ref,
    MatchModel currentMatch,
  ) {
    String rTeam = currentMatch.redName.contains(':')
        ? currentMatch.redName.split(':').first.trim()
        : '赤';
    String wTeam = currentMatch.whiteName.contains(':')
        ? currentMatch.whiteName.split(':').first.trim()
        : '白';

    // この試合（groupName）に出ている選手の一覧を取得
    final allMatches = ref.read(matchListProvider);
    final teamMatches = allMatches
        .where((m) => m.groupName == currentMatch.groupName)
        .toList();

    // 赤チームの対戦履歴（teamMatches）から選手を抽出
    List<String> redPlayers = [];
    for (final m in teamMatches) {
      if (m.redName.contains(':')) {
        final parts = m.redName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == rTeam &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          redPlayers.add(pName);
        }
      }
      if (m.whiteName.contains(':')) {
        final parts = m.whiteName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == rTeam &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          redPlayers.add(pName);
        }
      }
    }
    redPlayers = redPlayers.toSet().toList();

    // 白チームの対戦履歴（teamMatches）から選手を抽出
    List<String> whitePlayers = [];
    for (final m in teamMatches) {
      if (m.redName.contains(':')) {
        final parts = m.redName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == wTeam &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          whitePlayers.add(pName);
        }
      }
      if (m.whiteName.contains(':')) {
        final parts = m.whiteName.split(':');
        final tName = parts.first.trim();
        final pName = parts.last.trim();
        if (tName == wTeam &&
            pName.isNotEmpty &&
            !pName.contains('未定') &&
            !pName.contains('欠員') &&
            !pName.contains('代表選手')) {
          whitePlayers.add(pName);
        }
      }
    }
    whitePlayers = whitePlayers.toSet().toList();

    // コントローラー定義
    final redCtrl = TextEditingController();
    final whiteCtrl = TextEditingController();

    final List<String> baseRedPlayers = redPlayers;
    final List<String> baseWhitePlayers = whitePlayers;

    // iOS Native カラー
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final bgColor = themeColors.cardBackground;
    final textColor = context.appColors.textColor;
    final inputBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : context.appColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : context.appColors.separatorColor;

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          // 1. 選手名簿のリアクティブな監視
          List<PlayerModel> localPlayers = [];
          try {
            localPlayers = ref.watch(playerListProvider).value ?? [];
          } catch (_) {
            // ユニットテスト環境やオフラインなどのフェールセーフ
          }

          // 2. 大会登録チーム（即席チーム・他チーム含む）のリアクティブな監視
          List<TeamModel> registeredTeams = [];
          try {
            registeredTeams =
                ref
                    .watch(
                      registeredTeamsProvider(currentMatch.tournamentId ?? ''),
                    )
                    .value ??
                [];
          } catch (_) {
            // フェールセーフ
          }

          final matchCat = currentMatch.category?.trim() ?? '';

          bool isCategoryMatch(String teamCat, String matchCat) {
            final tCat = teamCat.trim();
            final mCat = matchCat.trim();
            if (mCat.isEmpty || tCat.isEmpty) return true;
            if (tCat == mCat || mCat.contains(tCat) || tCat.contains(mCat)) {
              return true;
            }
            final keywords = ['低学年', '高学年', '小学生', '中学生', '高校生', '一般'];
            for (final kw in keywords) {
              if (mCat.contains(kw) && tCat.contains(kw)) return true;
              if (mCat.contains(kw) && !tCat.contains(kw)) return false;
            }
            return true;
          }

          bool isDojoPlayerGradeMatch(int grade, String matchCat) {
            if (matchCat.isEmpty) return true;
            if ((matchCat.contains('低学年') ||
                    matchCat.contains('1・2年') ||
                    matchCat.contains('3・4年')) &&
                (grade >= 1 && grade <= 4)) {
              return true;
            }
            if ((matchCat.contains('高学年') || matchCat.contains('5・6年')) &&
                (grade >= 5 && grade <= 6)) {
              return true;
            }
            if ((matchCat.contains('小学生') ||
                    matchCat.contains('学童') ||
                    matchCat.contains('児童')) &&
                (grade >= 1 && grade <= 6)) {
              return true;
            }
            if ((matchCat.contains('中学生') || matchCat.contains('中学')) &&
                (grade >= 7 && grade <= 9)) {
              return true;
            }
            if ((matchCat.contains('高校生') || matchCat.contains('高校')) &&
                (grade >= 10 && grade <= 12)) {
              return true;
            }
            if ((matchCat.contains('一般') ||
                    matchCat.contains('成人') ||
                    matchCat.contains('社会人') ||
                    matchCat.contains('大学')) &&
                (grade >= 13 || grade == 0)) {
              return true;
            }

            final hasKnownSchoolLevel =
                matchCat.contains('低学年') ||
                matchCat.contains('高学年') ||
                matchCat.contains('小学生') ||
                matchCat.contains('中学生') ||
                matchCat.contains('高校生') ||
                matchCat.contains('一般');
            return !hasKnownSchoolLevel;
          }

          // --- 赤チーム (rTeam) の候補選手抽出 ---
          // 2-a. 大会登録チーム (第1優先：同カテゴリの登録チーム)
          final matchingRedTeams = registeredTeams.where((t) {
            final nameMatch =
                t.teamName.trim() == rTeam.trim() ||
                rTeam.trim().contains(t.teamName.trim()) ||
                t.teamName.trim().contains(rTeam.trim());
            return nameMatch;
          }).toList();

          final redTeamData =
              matchingRedTeams.firstWhereOrNull(
                (t) => isCategoryMatch(t.category, matchCat),
              ) ??
              matchingRedTeams.firstOrNull;

          final List<String> redMasterPlayers =
              redTeamData?.playerNames
                  .map((n) => n.trim())
                  .where(
                    (n) =>
                        n.isNotEmpty && !n.contains('未定') && !n.contains('欠員'),
                  )
                  .toList() ??
              [];

          // 2-b. 道場名簿 (第2優先：カテゴリの一致する選手)
          final List<String> redDojoPlayers = localPlayers
              .where((p) {
                final org = p.organization.trim();
                if (org.isEmpty) return false;
                final orgMatch =
                    org == rTeam.trim() ||
                    rTeam.trim().contains(org) ||
                    org.contains(rTeam.trim());
                if (!orgMatch) return false;
                return isDojoPlayerGradeMatch(p.grade, matchCat);
              })
              .map((p) => p.name.trim())
              .where((n) => n.isNotEmpty)
              .toList();

          final List<String> redPlayers = redMasterPlayers.isNotEmpty
              ? {...redMasterPlayers, ...baseRedPlayers}.toList()
              : {...redDojoPlayers, ...baseRedPlayers}.toList();

          // --- 白チーム (wTeam) の候補選手抽出 ---
          // 2-c. 大会登録チーム (第1優先：同カテゴリの登録チーム)
          final matchingWhiteTeams = registeredTeams.where((t) {
            final nameMatch =
                t.teamName.trim() == wTeam.trim() ||
                wTeam.trim().contains(t.teamName.trim()) ||
                t.teamName.trim().contains(wTeam.trim());
            return nameMatch;
          }).toList();

          final whiteTeamData =
              matchingWhiteTeams.firstWhereOrNull(
                (t) => isCategoryMatch(t.category, matchCat),
              ) ??
              matchingWhiteTeams.firstOrNull;

          final List<String> whiteMasterPlayers =
              whiteTeamData?.playerNames
                  .map((n) => n.trim())
                  .where(
                    (n) =>
                        n.isNotEmpty && !n.contains('未定') && !n.contains('欠員'),
                  )
                  .toList() ??
              [];

          // 2-d. 道場名簿 (第2優先：カテゴリの一致する選手)
          final List<String> whiteDojoPlayers = localPlayers
              .where((p) {
                final org = p.organization.trim();
                if (org.isEmpty) return false;
                final orgMatch =
                    org == wTeam.trim() ||
                    wTeam.trim().contains(org) ||
                    org.contains(wTeam.trim());
                if (!orgMatch) return false;
                return isDojoPlayerGradeMatch(p.grade, matchCat);
              })
              .map((p) => p.name.trim())
              .where((n) => n.isNotEmpty)
              .toList();

          final List<String> whitePlayers = whiteMasterPlayers.isNotEmpty
              ? {...whiteMasterPlayers, ...baseWhitePlayers}.toList()
              : {...whiteDojoPlayers, ...baseWhitePlayers}.toList();

          final Set<String> redMasterSet = redPlayers.toSet();
          final Set<String> whiteMasterSet = whitePlayers.toSet();

          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xlargeValue),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    top: AppSpacing.lg,
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0x8A000000),
                          borderRadius: AppRadius.compact,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        '次の試合を追加 (錬成会)',
                        style: TextStyle(
                          fontSize: AppFontSize.header,
                          fontWeight: AppFontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '次の試合に出場する選手を入力または選択してください。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppFontSize.bodySmall,
                          color: const Color(0x8A000000),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            // --- Red Team Player Selection ---
                            if (redPlayers.isNotEmpty) ...[
                              Text(
                                '$rTeam の選手を選択:',
                                style: TextStyle(
                                  fontSize: AppFontSize.bodySmall,
                                  color: isDark
                                      ? const Color(0xFF009688)
                                      : const Color(0xFF009688),
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: redPlayers.map((p) {
                                  final isMaster = redMasterSet.contains(p);
                                  return AppChoiceChip(
                                    label: Text(p),
                                    selected: redCtrl.text == p,
                                    selectedColor: isDark
                                        ? const Color(0xFF009688)
                                        : const Color(0xFF009688),
                                    backgroundColor: redCtrl.text == p
                                        ? (isDark
                                              ? const Color(0xFF009688)
                                              : const Color(0xFF009688))
                                        : (isMaster
                                              ? (isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : AppKendoColors
                                                          .grey
                                                          .shade100)
                                              : (isDark
                                                    ? const Color(0xFF1E1E20)
                                                    : AppKendoColors
                                                          .grey
                                                          .shade50)),
                                    side: BorderSide(
                                      color: redCtrl.text == p
                                          ? AppKendoColors.transparent
                                          : (isMaster
                                                ? AppKendoColors.transparent
                                                : (context
                                                      .appColors
                                                      .separatorColor)),
                                      width: 1.0,
                                    ),
                                    labelStyle: TextStyle(
                                      color: redCtrl.text == p
                                          ? (isDark
                                                ? const Color(0xFFFFFFFF)
                                                : context
                                                      .appColors
                                                      .primaryAccent)
                                          : (isMaster
                                                ? textColor
                                                : (isDark
                                                      ? AppKendoColors
                                                            .grey
                                                            .shade500
                                                      : AppKendoColors
                                                            .grey
                                                            .shade400)),
                                      fontWeight: AppFontWeight.bold,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          redCtrl.text = p;
                                        });
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            AppTextField(
                              controller: redCtrl,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: AppFontWeight.bold,
                              ),
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: '$rTeam の選手名を入力',
                                labelStyle: const TextStyle(
                                  color: AppKendoColors.grey,
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                  horizontal: AppSpacing.lg,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  size: 20,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.medium,
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.medium,
                                  borderSide: BorderSide(
                                    color: const Color(0xFF009688),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // --- White Team Player Selection ---
                            if (whitePlayers.isNotEmpty) ...[
                              Text(
                                '$wTeam の選手を選択:',
                                style: TextStyle(
                                  fontSize: AppFontSize.bodySmall,
                                  color: isDark
                                      ? const Color(0xFF009688)
                                      : const Color(0xFF009688),
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: whitePlayers.map((p) {
                                  final isMaster = whiteMasterSet.contains(p);
                                  return AppChoiceChip(
                                    label: Text(p),
                                    selected: whiteCtrl.text == p,
                                    selectedColor: isDark
                                        ? const Color(0xFF009688)
                                        : const Color(0xFF009688),
                                    backgroundColor: whiteCtrl.text == p
                                        ? (isDark
                                              ? const Color(0xFF009688)
                                              : const Color(0xFF009688))
                                        : (isMaster
                                              ? (isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : AppKendoColors
                                                          .grey
                                                          .shade100)
                                              : (isDark
                                                    ? const Color(0xFF1E1E20)
                                                    : AppKendoColors
                                                          .grey
                                                          .shade50)),
                                    side: BorderSide(
                                      color: whiteCtrl.text == p
                                          ? AppKendoColors.transparent
                                          : (isMaster
                                                ? AppKendoColors.transparent
                                                : (context
                                                      .appColors
                                                      .separatorColor)),
                                      width: 1.0,
                                    ),
                                    labelStyle: TextStyle(
                                      color: whiteCtrl.text == p
                                          ? (isDark
                                                ? const Color(0xFFFFFFFF)
                                                : context
                                                      .appColors
                                                      .primaryAccent)
                                          : (isMaster
                                                ? textColor
                                                : (isDark
                                                      ? AppKendoColors
                                                            .grey
                                                            .shade500
                                                      : AppKendoColors
                                                            .grey
                                                            .shade400)),
                                      fontWeight: AppFontWeight.bold,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          whiteCtrl.text = p;
                                        });
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            AppTextField(
                              controller: whiteCtrl,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: AppFontWeight.bold,
                              ),
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: '$wTeam の選手名を入力',
                                labelStyle: const TextStyle(
                                  color: AppKendoColors.grey,
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                  horizontal: AppSpacing.lg,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  size: 20,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.medium,
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppRadius.medium,
                                  borderSide: BorderSide(
                                    color: const Color(0xFF009688),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.lg,
                            bottom: AppSpacing.xl,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppKendoColors.grey,
                                    side: const BorderSide(
                                      color: AppKendoColors.grey,
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.medium,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    'キャンセル',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? const Color(0xFF009688)
                                        : const Color(0xFF009688),
                                    foregroundColor: const Color(0xFFFFFFFF),
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.medium,
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: () async {
                                    if (!ctx.mounted) return;
                                    showAppDialog(
                                      context: ctx,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );

                                    final nextMatchId = const Uuid().v4();
                                    final newRed =
                                        '$rTeam : ${redCtrl.text.trim().isEmpty ? '選手' : redCtrl.text.trim()}';
                                    final newWhite =
                                        '$wTeam : ${whiteCtrl.text.trim().isEmpty ? '選手' : whiteCtrl.text.trim()}';

                                    final rule = ref.read(matchRuleProvider);
                                    final lastSettings = ref.read(
                                      lastUsedSettingsProvider,
                                    );
                                    final double exactMatchTime =
                                        (lastSettings['matchTime'] as num?)
                                            ?.toDouble() ??
                                        rule.matchTimeMinutes.toDouble();

                                    final nextMatch = MatchModel(
                                      id: nextMatchId,
                                      tournamentId: currentMatch.tournamentId,
                                      category: currentMatch.category,
                                      groupName: currentMatch.groupName,
                                      matchType: '錬成会',
                                      rule: currentMatch.rule ?? rule,
                                      redName: newRed,
                                      whiteName: newWhite,
                                      status: 'waiting',
                                      matchTimeMinutes: exactMatchTime,
                                      isRunningTime: rule.isRunningTime,
                                      order: currentMatch.order + 0.1,
                                      note: currentMatch.note,
                                    );

                                    await ref
                                        .read(matchApplicationServiceProvider)
                                        .saveMatch(nextMatch);

                                    if (!ctx.mounted) return;
                                    Navigator.of(
                                      ctx,
                                      rootNavigator: true,
                                    ).pop();
                                    if (!ctx.mounted) {
                                      return;
                                    }
                                    Navigator.pop(ctx);

                                    if (!context.mounted) {
                                      return;
                                    }
                                    context.pushReplacement(
                                      '/match/$nextMatchId',
                                    );
                                  },
                                  child: const Text(
                                    '決定して開始',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: AppFontSize.bodyMedium,
                                      fontWeight: AppFontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ★ 追加：試合終了時のナビゲーションダイアログ
  void _showMatchFinishedDialog(
    BuildContext context,
    MatchModel match,
    MatchModel? nextCardMatch,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MatchFinishedNavigationDialog(
        isRenseikai:
            match.matchScene == 'renseikai' ||
            match.matchScene == 'moushiawase' ||
            (match.rule?.isRenseikai ?? false),
        nextMatchId: nextCardMatch?.id,
        nextMatchType: nextCardMatch?.matchType,
        tournamentId: match.tournamentId,
        hasGroupName: match.groupName != null,
        isKachinuki: match.isKachinuki,
        isDark: isDark,
        onAddNextRenseikaiMatch: () {
          Navigator.pop(ctx);
          _showNextMatchDialog(context, ref, match);
        },
        onGoToNextMatch: nextCardMatch != null
            ? () {
                Navigator.pop(ctx);
                context.push('/match/${nextCardMatch.id}');
              }
            : null,
        onGoHome: () {
          Navigator.pop(ctx);
          if (match.tournamentId != null &&
              match.tournamentId!.startsWith('bunaiksen_')) {
            context.go('/bunaiksen-home');
          } else {
            context.go('/home/${match.tournamentId}');
          }
        },
        onShowScoreboard: match.groupName != null
            ? () {
                Navigator.pop(ctx);
                if (match.isKachinuki) {
                  context.push('/kachinuki-scoreboard/${match.groupName}');
                } else {
                  context.push('/team-scoreboard/${match.groupName}');
                }
              }
            : null,
      ),
    );
  }

  void _showRuleInfoSheet(BuildContext context, MatchModel match) {
    showRuleInfoBottomSheet(context, match);
  }

  void _showSnapshotDialog(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final engine = KendoRuleEngine();
    final validEvents = engine.filterActiveEvents(match.events);

    showAppDialog(
      context: context,
      builder: (ctx) => MatchSnapshotHistoryDialog(
        validEvents: validEvents,
        isDark: isDark,
        onClose: () => Navigator.pop(ctx),
        onSelectRewind: (targetVersion, eventIndex) async {
          final confirm = await _showConfirmDialog(
            '取り消しの確認',
            'この操作(${eventIndex + 1}本目)の時点まで、試合を完全に巻き戻しますか？',
          );
          if (confirm) {
            ref
                .read(matchCommandQueueProvider)
                .enqueue(
                  MatchCommandModel(
                    id: const Uuid().v4(),
                    type: CommandType.rewindTo,
                    payload: {'matchId': match.id, 'version': targetVersion},
                    createdAt: ref.read(timeSourceProvider).now(),
                  ),
                );
            if (ctx.mounted) Navigator.pop(ctx);
          }
        },
      ),
    );
  }

  // =========================================================================
  // ★ NEW: 無限勝ち抜きエンジンの試合終了処理
  // =========================================================================
  Future<void> _handleMatchFinish(
    BuildContext context,
    WidgetRef ref,
    MatchModel currentMatch,
    String winnerColor,
  ) async {
    final finishedMatch = currentMatch
        .copyWith(status: 'finished', timerStartedAt: null)
        .updateRemainingSeconds(0, ref.read(timeSourceProvider).now());
    await ref
        .read(matchApplicationServiceProvider)
        .saveMatch(finishedMatch); // ★ 修正

    final engine = ref.read(bunaiksenInfiniteEngineProvider);
    final nextMatch = await engine.processMatchResult(
      finishedMatch,
      winnerColor,
    );

    if (!mounted || !context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // プログレスダイアログを閉じる

    if (nextMatch != null) {
      final streaks = ref.read(bunaiksenInfiniteStreakProvider);
      final winnerStreak = streaks[nextMatch.redName] ?? 0;

      showAppDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return MatchInfiniteNextDialog(
            redName: nextMatch.redName,
            whiteName: nextMatch.whiteName,
            winnerStreak: winnerStreak,
            onFinishInfinite: () {
              Navigator.of(dialogContext).pop();
              ref.read(bunaiksenInfiniteQueueProvider.notifier).setPlayers([]);
              ref.read(bunaiksenInfiniteStreakProvider.notifier).clearAll();
              context.pop();
            },
            onRestAndReturn: () {
              Navigator.of(dialogContext).pop();
              final queueNotifier = ref.read(
                bunaiksenInfiniteQueueProvider.notifier,
              );
              final currentQueue = ref.read(bunaiksenInfiniteQueueProvider);
              final filteredQueue = currentQueue
                  .where(
                    (p) => p != nextMatch.redName && p != nextMatch.whiteName,
                  )
                  .toList();
              queueNotifier.setPlayers([
                nextMatch.redName,
                nextMatch.whiteName,
                ...filteredQueue,
              ]);
              context.pop();
            },
            onStartNextMatchImmediately: () async {
              Navigator.of(dialogContext).pop();
              final startMatch = nextMatch.copyWith(status: 'in_progress');
              await ref
                  .read(matchApplicationServiceProvider)
                  .saveMatch(startMatch);
              if (context.mounted) {
                context.pushReplacement('/match/${nextMatch.id}');
              }
            },
          );
        },
      );
    } else {
      AppSnackBar.show(context, '待機列の選手がいなくなりました。無限稽古を終了します');
      context.pop();
    }
  }
}

extension _FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
