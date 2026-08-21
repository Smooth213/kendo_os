import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
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
import 'components/match_screen/match_finished_navigation_dialog.dart';
import 'components/match_screen/match_hantei_dialog.dart';
import 'components/match_screen/match_mini_log_undo_section.dart';
import 'components/match_screen/match_operate_action_buttons_grid.dart';
import 'components/match_screen/match_snapshot_history_dialog.dart';
import 'components/match_screen/renseikai_master_timer_widget.dart';
import 'components/match_screen/match_representative_modal_bottom_sheet.dart';
import 'components/match_screen/renseikai_add_next_match_bottom_sheet.dart';
import 'components/match_screen/match_player_name_edit_bottom_sheet.dart';
import 'components/match_screen/match_view_only_notice_banner.dart';
import 'components/match_screen/match_daihyo_overlay.dart';
import 'components/match_screen/match_renseikai_next_button.dart';
import 'components/match_screen/match_infinite_handler_helper.dart';
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
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/shared/widgets/corrupted_match_banner.dart';

// ★ 追加：システム設定プロバイダの読み込み
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/last_used_settings_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/share_provider.dart';
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
                                      MatchViewOnlyNoticeBanner(
                                        isSomeoneElseOperating:
                                            isSomeoneElseOperating,
                                        isApproved: isApproved,
                                        isReadOnly: permissions.isReadOnly,
                                        onClaimScorer: () async {
                                          final confirmed =
                                              await _showConfirmDialog(
                                                "入力権限の奪取",
                                                "他の端末の入力を強制中断し、\nこの端末で入力を開始しますか？",
                                              );
                                          if (confirmed) {
                                            await ref
                                                .read(matchCommandProvider)
                                                .forceClaimScorer(
                                                  match.id,
                                                  _myUserId!,
                                                );
                                          }
                                        },
                                      );

                                  // ★ 修正: KendoRuleEngineを使って正確に有効なイベントのみを抽出する
                                  final engine = KendoRuleEngine();
                                  final validEvents = engine.filterActiveEvents(
                                    match.events,
                                  );
                                  final canUndoReal = validEvents.isNotEmpty;

                                  // ★ Phase 6-4: 操作履歴の透明化（ミニログ ＋ Undoボタン）
                                  final undoArea = MatchMiniLogUndoSection(
                                    validEvents: validEvents,
                                    canUndo: canUndoReal,
                                    isDark: isDark,
                                    onUndo: () => ref
                                        .read(matchCommandProvider)
                                        .undoLastEvent(match.id),
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
                                          return MatchRenseikaiNextButton(
                                            match: match,
                                            isViewOnly: isViewOnly,
                                            currentUserId: _myUserId ?? '',
                                            onAddNext: () =>
                                                _showNextMatchDialog(
                                                  context,
                                                  ref,
                                                  match,
                                                ),
                                            onConfirmAndFinish: () async {
                                              if (settings.showConfirmDialog) {
                                                final confirmed =
                                                    await _showConfirmDialog(
                                                      '記録の確定',
                                                      'この試合の記録を確定して終了しますか？\n確定後は点数の修正ができなくなります。',
                                                    );
                                                if (!confirmed) return;
                                              }

                                              await ref
                                                  .read(
                                                    matchApplicationServiceProvider,
                                                  )
                                                  .approveMatch(match.id);

                                              if (!context.mounted) return;
                                              _showMatchFinishedDialog(
                                                context,
                                                match,
                                                null,
                                              );
                                            },
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
                                                    await MatchInfiniteHandlerHelper.handleMatchFinish(
                                                      context: context,
                                                      ref: ref,
                                                      currentMatch: match,
                                                      winnerColor: winnerColor,
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
                                                    await MatchInfiniteHandlerHelper.handleMatchFinish(
                                                      context: context,
                                                      ref: ref,
                                                      currentMatch: match,
                                                      winnerColor: winnerColor,
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
                        MatchDaihyoOverlay(
                          onSelectDaihyo: () => _showDaihyoSelectDialog(match),
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

  void _showNameEditBottomSheet(MatchModel match, String side) {
    MatchPlayerNameEditBottomSheet.show(context, match: match, side: side);
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

    MatchRepresentativeModalBottomSheet.show(
      context,
      match: match,
      rTeam: rTeam,
      wTeam: wTeam,
      redPlayers: redPlayers,
      whitePlayers: whitePlayers,
    );
  }

  void _showNextMatchDialog(
    BuildContext context,
    WidgetRef ref,
    MatchModel currentMatch,
  ) {
    RenseikaiAddNextMatchBottomSheet.show(context, currentMatch: currentMatch);
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
}
