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
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
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
import 'package:kendo_os/features/tournament/presentation/operate/providers/role_provider.dart';
import 'package:kendo_os/shared/widgets/sync_status_bar.dart';
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

    final rName = match.redName.contains(':')
        ? match.redName.split(':').last.trim()
        : match.redName;
    final wName = match.whiteName.contains(':')
        ? match.whiteName.split(':').last.trim()
        : match.whiteName;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '勝敗の判定',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '同点のため、判定（または引き分け）を選択してください',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, 'red'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: FittedBox(
                      child: Text(
                        '赤の判定勝ち\n($rName)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, 'white'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF38383A)
                          : Colors.grey.shade300,
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: FittedBox(
                      child: Text(
                        '白の判定勝ち\n($wName)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'draw'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '引き分け',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text(
                'キャンセル（戻る）',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ★ Phase 6: 危険操作ガード（確認ダイアログ）
  Future<bool> _showConfirmDialog(String title, String content) async {
    HapticFeedback.heavyImpact(); // 警告の意味を込めた強い振動
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Text(content),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'キャンセル',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  '実行する',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: next.isError
                ? Colors.red.shade800
                : Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
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
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            primary: true,
            centerTitle: true,
            // ★ 変更: 背景色を下部の「終了ボタン」と全く同じインディゴに設定
            backgroundColor: Colors.indigo.shade600,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (match.category != null && match.category!.isNotEmpty)
                      ? '${match.category} - ${match.matchType}'
                      : match.matchType,
                  // ★ 変更: タイトルを白抜き
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${match.redName} vs ${match.whiteName}',
                  // ★ 変更: サブタイトルは少し透過した白
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              // ★ 記録係が最も必要とする「1枚操作ガイド」へ直行させます
              const ManualHelpButton(
                manualPath: 'docs/manuals/quickstart/operator_1pager.md',
                color: Colors.white,
              ),
              // ★ 追加: 大会ホーム（試合一覧）に一気に戻るボタン
              IconButton(
                icon: const Icon(Icons.view_list_rounded, color: Colors.white),
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
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
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
                                          color: Colors.red.shade900.withValues(
                                            alpha: 0.9,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Text(
                                                  '他の記録員が入力中です',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
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
                                                  backgroundColor: Colors.white
                                                      .withValues(alpha: 0.2),
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
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
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
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
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.grey.shade100,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(8),
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
                                                      ? Colors.red.shade600
                                                      : (e.side == Side.white
                                                            ? (isDark
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .black87)
                                                            : Colors.grey);
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 1,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          '${validEvents.indexOf(e) + 1}.',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                color:
                                                                    Colors.grey,
                                                                fontWeight:
                                                                    FontWeight
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
                                                            fontSize: 12,
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
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                color:
                                                                    Colors.grey,
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
                                                    color: Colors.grey,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
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
                                                bottom: Radius.circular(8),
                                              ),
                                          child: Container(
                                            height: 36, // ★ さらに縮小
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.15,
                                                    )
                                                  : Colors.grey.shade200,
                                              borderRadius:
                                                  validEvents.isNotEmpty
                                                  ? const BorderRadius.vertical(
                                                      bottom: Radius.circular(
                                                        8,
                                                      ),
                                                    )
                                                  : BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white24
                                                    : Colors.black12,
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
                                                      : Colors.grey,
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  canUndoReal
                                                      ? '１つ前の操作を取り消す'
                                                      : '操作履歴なし',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    color: canUndoReal
                                                        ? (isDark
                                                              ? Colors.white
                                                              : Colors.black87)
                                                        : Colors.grey,
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
                                            horizontal: 16,
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
                                              const SizedBox(width: 16),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child:
                                                      _RenseikaiMasterTimerWidget(
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
                                  final groupButtonPart = Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 0,
                                      left: 8,
                                      right: 8,
                                    ),
                                    child: Column(
                                      children: [
                                        // 1段目: 観戦URLを共有 | 履歴から復元
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => ref
                                                    .read(shareProvider)
                                                    .shareMatch(match),
                                                icon: const Icon(
                                                  Icons.ios_share,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  '観戦URLを共有',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  minimumSize: const Size(
                                                    0,
                                                    30,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                // ★ 修正: 試合確定済み（approved）でも復元できるようにロックを解除
                                                onPressed: isViewOnly
                                                    ? null
                                                    : () => _showSnapshotDialog(
                                                        context,
                                                        ref,
                                                        match,
                                                      ),
                                                icon: const Icon(
                                                  Icons.history,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  '履歴から復元',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  minimumSize: const Size(
                                                    0,
                                                    30,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // 2段目: スコアを確認 | ルールを確認
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    match.isKachinuki
                                                    ? context.push(
                                                        '/kachinuki-scoreboard/${match.groupName}',
                                                      )
                                                    : context.push(
                                                        '/team-scoreboard/${match.groupName}',
                                                      ),
                                                icon: Icon(
                                                  match.isKachinuki
                                                      ? Icons.timeline
                                                      : Icons
                                                            .table_chart_outlined,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'スコアを確認',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  minimumSize: const Size(
                                                    0,
                                                    30,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _showRuleInfoSheet(
                                                      context,
                                                      match,
                                                    ),
                                                icon: const Icon(
                                                  Icons.info_outline,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'ルールを確認',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  minimumSize: const Size(
                                                    0,
                                                    30,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
                                        : Colors.grey.shade100,
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
                                          color: Colors.red.shade600,
                                          isLocked: isInputLocked,
                                        );
                                        final whitePanel = ScoreActionPanel(
                                          matchId: match.id,
                                          side: Side.white,
                                          color: isDark
                                              ? const Color(0xFF1C1C1E)
                                              : Colors.grey.shade100,
                                          textColor: isDark
                                              ? Colors.white
                                              : Colors.black87,
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
                                        : Colors.grey.shade100,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
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
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
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
                                                    showDialog(
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
                                                        : () => ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                settings.confirmBehavior ==
                                                                        'double'
                                                                    ? 'ダブルタップで確定してください'
                                                                    : '長押しで確定してください',
                                                              ),
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        1500,
                                                                  ),
                                                            ),
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
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isTie
                                                    ? Colors.red.shade700
                                                    : (isAllDone
                                                          ? Colors
                                                                .indigo
                                                                .shade700
                                                          : Colors
                                                                .teal
                                                                .shade600),
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size(
                                                  double.infinity,
                                                  36, // ★ さらに縮小して余裕を持たせる
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
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
                                                    showDialog(
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

                                                      final dynamic rawTime =
                                                          lastSettings['extensionTimeMinutes'];
                                                      final double extMins =
                                                          (rawTime is num)
                                                          ? rawTime.toDouble()
                                                          : 3.0;
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
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '$extStr（$extMins分）を開始します',
                                                          ),
                                                        ),
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
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '判定の保存に失敗しました: $e',
                                                              ),
                                                            ),
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
                                                            : () => ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    settings.confirmBehavior ==
                                                                            'double'
                                                                        ? 'ダブルタップで終了してください'
                                                                        : '長押しで終了してください',
                                                                  ),
                                                                  duration:
                                                                      const Duration(
                                                                        milliseconds:
                                                                            1500,
                                                                      ),
                                                                ),
                                                              )),
                                                  onLongPress:
                                                      settings.confirmBehavior ==
                                                          'long'
                                                      ? effectiveFinishAction
                                                      : null,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.indigo.shade600,
                                                    foregroundColor:
                                                        Colors.white,
                                                    minimumSize: const Size(
                                                      double.infinity,
                                                      36, // ★ さらに縮小して余裕を持たせる
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
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
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                                    ? Colors.white10
                                                    : Colors.black12,
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
                                            horizontal: 8,
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
                          color: Colors.black.withValues(alpha: 0.8),
                          width: double.infinity,
                          height: double.infinity,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.person_add,
                                  color: Colors.white,
                                  size: 80,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  '代表戦の選手が未設定です',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: 250,
                                  child: GlassButton(
                                    onPressed: () =>
                                        _showDaihyoSelectDialog(match),
                                    color: Colors.indigo,
                                    label: '代表者を選択する',
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
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
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                  ? Colors.teal.shade900.withValues(alpha: 0.2)
                  : Colors.teal.shade50.withValues(alpha: 0.6);
              borderSide = BorderSide(
                color: isDark ? Colors.teal.shade800 : Colors.teal.shade100,
              );
            } else {
              // 出場中選手: オレンジ系統
              cardColor = isDark
                  ? Colors.orange.shade900.withValues(alpha: 0.15)
                  : Colors.orange.shade50.withValues(alpha: 0.6);
              borderSide = BorderSide(
                color: isDark ? Colors.orange.shade800 : Colors.orange.shade100,
              );
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: borderSide,
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isSub
                      ? (isDark ? Colors.teal.shade700 : Colors.teal.shade100)
                      : (isDark
                            ? Colors.orange.shade700
                            : Colors.orange.shade100),
                  child: Text(
                    p.name.substring(0, 1),
                    style: TextStyle(
                      color: isSub
                          ? (isDark ? Colors.white : Colors.teal.shade800)
                          : (isDark ? Colors.white : Colors.orange.shade800),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  currentPosition != null
                      ? (isCurrentPosition ? 'このポジション' : '$currentPositionで出場中')
                      : '${p.gradeName} / ${p.gender}',
                  style: TextStyle(
                    color: isSub
                        ? (isDark ? Colors.teal.shade300 : Colors.teal.shade600)
                        : (isDark
                              ? Colors.orange.shade300
                              : Colors.orange.shade600),
                    fontSize: 11,
                    fontWeight: currentPosition != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: Icon(
                  isSub ? Icons.check_circle_outline : Icons.swap_horiz,
                  size: 18,
                  color: isSub
                      ? (isDark ? Colors.teal.shade300 : Colors.teal.shade600)
                      : (isDark
                            ? Colors.orange.shade300
                            : Colors.orange.shade600),
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
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '選手名の変更',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (teamName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        teamName,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: '名前を直接入力 (助っ人など)',
                              labelStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.indigo.shade800
                                      : Colors.indigo.shade100,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : Colors.grey.shade50,
                              prefixIcon: Icon(
                                Icons.edit,
                                color: isDark
                                    ? Colors.indigo.shade300
                                    : Colors.indigo.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final newName = ctrl.text.trim().isEmpty
                                ? '欠員'
                                : ctrl.text.trim();
                            await updatePlayerName(newName);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '確定',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    if (isOwnTeam && substitutes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '補欠登録の選手（タップで交代）',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.teal.shade300
                                : Colors.teal.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: substitutes.map((p) {
                            return ActionChip(
                              label: Text(p.name),
                              backgroundColor: isDark
                                  ? Colors.teal.shade900.withValues(alpha: 0.3)
                                  : Colors.teal.shade50.withValues(alpha: 0.6),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.teal.shade800
                                    : Colors.teal.shade100,
                              ),
                              labelStyle: TextStyle(
                                color: isDark
                                    ? Colors.teal.shade300
                                    : Colors.teal.shade800,
                                fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '道場の名簿から選ぶ (${match.category ?? "カテゴリ指定なし"})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.indigo.shade300
                                : Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: players.isEmpty
                            ? const Center(
                                child: Text(
                                  '名簿に登録されている選手がいません',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.only(bottom: 24),
                                children: [
                                  // 1. 出場中の選手
                                  if (sameCatActive.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        '出場中の選手 (交代・スワップ)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.orange.shade300
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                    ...sameCatActive.map(
                                      (p) => buildPlayerCard(p, isSub: false),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  if (dojoListSubstitutes.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        '同カテゴリの控え選手',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.teal.shade300
                                              : Colors.teal.shade700,
                                        ),
                                      ),
                                    ),
                                    ...dojoListSubstitutes.map(
                                      (p) => buildPlayerCard(p, isSub: true),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  const Divider(),
                                  const SizedBox(height: 8),

                                  // 2. 他のカテゴリの選手 (折りたたみ)
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      title: Text(
                                        '他のカテゴリの選手を表示',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.indigo.shade300
                                              : Colors.indigo.shade600,
                                        ),
                                      ),
                                      tilePadding: EdgeInsets.zero,
                                      childrenPadding: EdgeInsets.zero,
                                      children: [
                                        if (otherCategoryPlayers.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '他のカテゴリに選手はいません',
                                                style: TextStyle(
                                                  color: Colors.grey,
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
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '代表戦の準備',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '代表戦を戦う選手を選んでください。\n決定するとタイマーが0:00にリセットされます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.red.shade900.withValues(alpha: 0.15)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.red.shade900
                                  : Colors.red.shade100,
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
                                        ? Colors.red.shade400
                                        : Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$rTeam の代表者',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.red.shade300
                                          : Colors.red.shade800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (redPlayers.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: redPlayers
                                      .map(
                                        (p) => ChoiceChip(
                                          label: Text(p),
                                          selected: redCtrl.text == p,
                                          selectedColor: isDark
                                              ? Colors.red.shade700
                                              : Colors.red.shade200,
                                          backgroundColor: isDark
                                              ? const Color(0xFF2C2C2E)
                                              : Colors.white,
                                          labelStyle: TextStyle(
                                            color: redCtrl.text == p
                                                ? (isDark
                                                      ? Colors.white
                                                      : Colors.red.shade900)
                                                : textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          onSelected: (s) => setState(() {
                                            redCtrl.text = p;
                                          }),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextField(
                                controller: redCtrl,
                                style: TextStyle(color: textColor),
                                onChanged: (val) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: '名前を直接入力',
                                  labelStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.edit, size: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: inputBg,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.blueGrey.shade900.withValues(
                                    alpha: 0.2,
                                  )
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shield,
                                    color: Colors.grey.shade500,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$wTeam の代表者',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (whitePlayers.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: whitePlayers
                                      .map(
                                        (p) => ChoiceChip(
                                          label: Text(p),
                                          selected: whiteCtrl.text == p,
                                          selectedColor: isDark
                                              ? Colors.blueGrey.shade700
                                              : Colors.grey.shade300,
                                          backgroundColor: isDark
                                              ? const Color(0xFF2C2C2E)
                                              : Colors.white,
                                          labelStyle: TextStyle(
                                            color: whiteCtrl.text == p
                                                ? (isDark
                                                      ? Colors.white
                                                      : Colors.black)
                                                : textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          onSelected: (s) => setState(() {
                                            whiteCtrl.text = p;
                                          }),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextField(
                                controller: whiteCtrl,
                                style: TextStyle(color: textColor),
                                onChanged: (val) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: '名前を直接入力',
                                  labelStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.edit, size: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                color: Colors.teal,
                icon: Icons.autorenew,
                label: '追加して継続',
                expandContent: false,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(width: 12),
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
                            : () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    settings.confirmBehavior == 'double'
                                        ? 'ダブルタップで確定してください'
                                        : '長押しで確定してください',
                                  ),
                                  duration: const Duration(milliseconds: 1500),
                                ),
                              )),
                  onLongPress: settings.confirmBehavior == 'long'
                      ? confirmAction
                      : null,
                  icon: const Icon(Icons.verified, size: 24),
                  label: const Text(
                    '確定して終了',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.indigo.shade700
                        : Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : Colors.grey.shade100;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '次の試合を追加 (錬成会)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '次の試合に出場する選手を入力または選択してください。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            const SizedBox(height: 12),
                            // --- Red Team Player Selection ---
                            if (redPlayers.isNotEmpty) ...[
                              Text(
                                '$rTeam の選手を選択:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.teal.shade300
                                      : Colors.teal.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: redPlayers.map((p) {
                                  final isMaster = redMasterSet.contains(p);
                                  return ChoiceChip(
                                    label: Text(p),
                                    selected: redCtrl.text == p,
                                    selectedColor: isDark
                                        ? Colors.teal.shade700
                                        : Colors.teal.shade100,
                                    backgroundColor: redCtrl.text == p
                                        ? (isDark
                                              ? Colors.teal.shade700
                                              : Colors.teal.shade100)
                                        : (isMaster
                                              ? (isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : Colors.grey.shade100)
                                              : (isDark
                                                    ? const Color(0xFF1E1E20)
                                                    : Colors.grey.shade50)),
                                    side: BorderSide(
                                      color: redCtrl.text == p
                                          ? Colors.transparent
                                          : (isMaster
                                                ? Colors.transparent
                                                : (isDark
                                                      ? Colors.grey.shade800
                                                      : Colors.grey.shade300)),
                                      width: 1.0,
                                    ),
                                    labelStyle: TextStyle(
                                      color: redCtrl.text == p
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.teal.shade900)
                                          : (isMaster
                                                ? textColor
                                                : (isDark
                                                      ? Colors.grey.shade500
                                                      : Colors.grey.shade400)),
                                      fontWeight: FontWeight.bold,
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
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: redCtrl,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: '$rTeam の選手名を入力',
                                labelStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: inputBgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  size: 20,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.teal.shade400,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // --- White Team Player Selection ---
                            if (whitePlayers.isNotEmpty) ...[
                              Text(
                                '$wTeam の選手を選択:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.teal.shade300
                                      : Colors.teal.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: whitePlayers.map((p) {
                                  final isMaster = whiteMasterSet.contains(p);
                                  return ChoiceChip(
                                    label: Text(p),
                                    selected: whiteCtrl.text == p,
                                    selectedColor: isDark
                                        ? Colors.teal.shade700
                                        : Colors.teal.shade100,
                                    backgroundColor: whiteCtrl.text == p
                                        ? (isDark
                                              ? Colors.teal.shade700
                                              : Colors.teal.shade100)
                                        : (isMaster
                                              ? (isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : Colors.grey.shade100)
                                              : (isDark
                                                    ? const Color(0xFF1E1E20)
                                                    : Colors.grey.shade50)),
                                    side: BorderSide(
                                      color: whiteCtrl.text == p
                                          ? Colors.transparent
                                          : (isMaster
                                                ? Colors.transparent
                                                : (isDark
                                                      ? Colors.grey.shade800
                                                      : Colors.grey.shade300)),
                                      width: 1.0,
                                    ),
                                    labelStyle: TextStyle(
                                      color: whiteCtrl.text == p
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.teal.shade900)
                                          : (isMaster
                                                ? textColor
                                                : (isDark
                                                      ? Colors.grey.shade500
                                                      : Colors.grey.shade400)),
                                      fontWeight: FontWeight.bold,
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
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: whiteCtrl,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: '$wTeam の選手名を入力',
                                labelStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: inputBgColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  size: 20,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.teal.shade400,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    side: const BorderSide(color: Colors.grey),
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    'キャンセル',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? Colors.teal.shade600
                                        : Colors.teal,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: () async {
                                    if (!ctx.mounted) return;
                                    showDialog(
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '対戦終了',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.teal.shade300 : Colors.teal.shade800,
          ),
        ),
        content: const Text('対戦がすべて終了しました。\n次のアクションを選択してください。'),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          // ★ 錬成会・申し合わせ時の爆速「次の対戦を設定」アクションボタン
          if (match.matchScene == 'renseikai' ||
              match.matchScene == 'moushiawase' ||
              (match.rule?.isRenseikai ?? false)) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/new-match?tournamentId=${match.tournamentId ?? ""}',
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  '⚔️ 次の申し合わせ・錬成試合を追加設定',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (nextCardMatch != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/match/${nextCardMatch.id}',
                  ); // ★ go() から push() に変更して履歴を残す
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  '次の試合へ進む (${nextCardMatch.matchType})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (nextCardMatch != null) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                if (match.tournamentId != null &&
                    match.tournamentId!.startsWith('bunaiksen_')) {
                  context.go('/bunaiksen-home');
                } else {
                  context.go('/home/${match.tournamentId}');
                }
              },
              icon: const Icon(Icons.home),
              label: Text(
                (match.tournamentId != null &&
                        match.tournamentId!.startsWith('bunaiksen_'))
                    ? '部内戦ホームに戻る'
                    : '大会ホームへ戻る',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (match.groupName != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (match.isKachinuki) {
                    context.push(
                      '/kachinuki-scoreboard/${match.groupName}',
                    ); // ★ 真の解決: go()ではなくpush()にして履歴を残す
                  } else {
                    context.push(
                      '/team-scoreboard/${match.groupName}',
                    ); // ★ 真の解決: go()ではなくpush()にして履歴を残す
                  }
                },
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text(
                  'スコアボードを確認する',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRuleInfoSheet(BuildContext context, MatchModel match) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rule = match.rule;

    final bool isLegacyLeague = match.note.contains('[リーグ戦]');
    final bool isLeague = (rule?.isLeague ?? false) || isLegacyLeague;

    final bool isIndividual =
        !match.isKachinuki &&
        (match.matchType == 'individual' ||
            match.matchType == '選手' ||
            match.matchType.contains('個人戦') ||
            (rule != null &&
                rule.positions.length == 1 &&
                (rule.positions.first == '選手' ||
                    rule.positions.first == '個人戦')));

    String formatText = isIndividual ? '個人戦' : '団体戦';
    if (rule?.isRenseikai ?? false) {
      formatText = '錬成会';
    } else if (match.isKachinuki || (rule?.isKachinuki ?? false)) {
      formatText = '勝ち抜き戦';
    } else if (isLeague) {
      formatText = 'リーグ戦（総当たり）';
    }

    final double matchTime =
        rule?.matchTimeMinutes ?? match.matchTimeMinutes.toDouble();
    final isRunningTime = rule?.isRunningTime ?? match.isRunningTime;

    String timeStr = matchTime == matchTime.toInt()
        ? '${matchTime.toInt()}分'
        : '${matchTime.toInt()}分${((matchTime % 1) * 60).toInt()}秒';
    final String timeDesc = '$timeStr (${isRunningTime ? "通し/空回し" : "都度ストップ"})';

    final bool enchoUnlimited = rule?.isEnchoUnlimited ?? false;
    final double enchoMins =
        rule?.enchoTimeMinutes ?? match.extensionTimeMinutes?.toDouble() ?? 0.0;
    final int enchoCount = rule?.enchoCount ?? match.extensionCount ?? 1;
    final bool enchoEnabled =
        match.hasExtension || enchoUnlimited || enchoMins > 0;

    String enchoDesc = 'なし';
    if (enchoEnabled) {
      if (enchoUnlimited) {
        enchoDesc = 'あり (無制限)';
      } else {
        String extTimeStr = enchoMins == enchoMins.toInt()
            ? '${enchoMins.toInt()}分'
            : '${enchoMins.toInt()}分${((enchoMins % 1) * 60).toInt()}秒';
        enchoDesc = 'あり ($extTimeStr・$enchoCount回)';
      }
    }

    final bool hanteiEnabled = rule?.hasHantei ?? match.hasHantei;

    String daihyoDesc = 'なし';
    if (rule != null) {
      final bool hasRep = rule.hasRepresentativeMatch;
      final bool isIppon = rule.isDaihyoIpponShobu;
      daihyoDesc = hasRep ? (isIppon ? 'あり (一本勝負)' : 'あり (三本勝負)') : 'なし';
    } else {
      daihyoDesc = '不明（古いデータ）';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.gavel_rounded,
                  color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '試合レギュレーション',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            if (rule == null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'この試合はアップデート前に作成されたため、詳細なルールが保存されていません。新しく作成した試合では正しく表示されます。',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            _buildRuleRow('試合形式', formatText, isDark),
            _buildRuleRow('試合時間', timeDesc, isDark),

            if (rule?.isRenseikai ?? false) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '錬成会設定',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              _buildRuleRow('進行方式', rule!.renseikaiType, isDark),
              if (rule.renseikaiType == '時間制')
                _buildRuleRow('制限時間', '${rule.overallTimeMinutes} 分', isDark),
            ] else ...[
              _buildRuleRow('延長戦', enchoDesc, isDark),
              _buildRuleRow('判定', hanteiEnabled ? 'あり' : 'なし', isDark),
            ],

            if (match.isKachinuki || (rule?.isKachinuki ?? false)) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '勝ち抜き戦設定',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              _buildRuleRow(
                '無制限条件',
                rule?.kachinukiUnlimitedType ?? '大将対大将',
                isDark,
              ),
              if (rule != null && rule.positions.isNotEmpty)
                _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],

            if (!isIndividual &&
                !(rule?.isRenseikai ?? false) &&
                !match.isKachinuki &&
                !(rule?.isKachinuki ?? false) &&
                !isLeague) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '団体戦・チーム設定',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              _buildRuleRow('代表戦', daihyoDesc, isDark),
              if (rule != null && rule.positions.isNotEmpty)
                _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],

            if (!isIndividual &&
                (rule?.isRenseikai ?? false) &&
                rule != null &&
                rule.positions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'ポジション設定',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],

            if (rule != null && rule.isLeague) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'リーグ戦設定',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              if (!isIndividual && rule.positions.isNotEmpty)
                _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
              _buildRuleRow(
                '勝ち点設定',
                '勝: ${rule.winPoint} / 分: ${rule.drawPoint} / 負: ${rule.lossPoint}',
                isDark,
              ),
              _buildRuleRow(
                '同点時代表戦',
                rule.hasLeagueDaihyo ? 'あり' : 'なし',
                isDark,
              ),
            ],

            if (match.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildRuleRow('備考・メモ', match.note, isDark),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '閉じる',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnapshotDialog(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ★ 修正: 古い snapshots ではなく、新しい events (有効な操作履歴) を使用する
    final engine = KendoRuleEngine();
    final validEvents = engine.filterActiveEvents(match.events);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text(
          '操作履歴と取り消し',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: validEvents.isEmpty
              ? const Text('取り消し可能な操作履歴がありません')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: validEvents.length,
                  itemBuilder: (context, index) {
                    // 新しい順（最新が一番上）に表示
                    final eventIndex = validEvents.length - 1 - index;
                    final event = validEvents[eventIndex];

                    final sideStr = event.side == Side.red
                        ? '赤'
                        : (event.side == Side.white ? '白' : '');
                    String typeStr = '';
                    switch (event.type) {
                      case PointType.men:
                        typeStr = 'メン';
                        break;
                      case PointType.kote:
                        typeStr = 'コテ';
                        break;
                      case PointType.doIdo:
                        typeStr = 'ドウ';
                        break;
                      case PointType.tsuki:
                        typeStr = 'ツキ';
                        break;
                      case PointType.hansoku:
                        typeStr = '反則(▲)';
                        break;
                      case PointType.fusen:
                        typeStr = '不戦勝';
                        break;
                      case PointType.hantei:
                        typeStr = '判定';
                        break;
                      default:
                        typeStr = 'ポイント';
                        break;
                    }
                    final titleText = sideStr.isNotEmpty
                        ? '$sideStr $typeStr'
                        : typeStr;

                    return ListTile(
                      leading: Icon(
                        Icons.history,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      title: Text(
                        titleText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat('HH:mm:ss').format(event.timestamp),
                      ),
                      trailing: Text(
                        '${eventIndex + 1}本目まで戻る',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () async {
                        final confirm = await _showConfirmDialog(
                          '取り消しの確認',
                          'この操作(${eventIndex + 1}本目)の時点まで、試合を完全に巻き戻しますか？',
                        );
                        if (confirm) {
                          // ★ 修正: ループではなく、単一の rewindTo コマンドを発行して一気にジャンプ
                          ref
                              .read(matchCommandQueueProvider)
                              .enqueue(
                                MatchCommandModel(
                                  id: const Uuid().v4(),
                                  type: CommandType.rewindTo,
                                  payload: {
                                    'matchId': match.id,
                                    'version':
                                        eventIndex +
                                        1, // 有効なイベントの中で、タップしたもの「まで」を残す（残すべき有効イベント数）
                                  },
                                  createdAt: ref.read(timeSourceProvider).now(),
                                ),
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ), // AlertDialog
    ); // showDialog
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('無限稽古: 次の試合'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔥 挑戦者が入りました！'),
                const SizedBox(height: 12),
                Text(
                  '防衛(赤): ${nextMatch.redName} ($winnerStreak連勝中)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '挑戦(白): ${nextMatch.whiteName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('どうしますか？'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  ref
                      .read(bunaiksenInfiniteQueueProvider.notifier)
                      .setPlayers([]);
                  ref.read(bunaiksenInfiniteStreakProvider.notifier).clearAll();
                  context.pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                ),
                child: const Text('無限稽古を終了'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // 準備されていた次の2選手を待機列の先頭に戻す（重複防止フィルタリング付き）
                  final queueNotifier = ref.read(
                    bunaiksenInfiniteQueueProvider.notifier,
                  );
                  final currentQueue = ref.read(bunaiksenInfiniteQueueProvider);
                  final filteredQueue = currentQueue
                      .where(
                        (p) =>
                            p != nextMatch.redName && p != nextMatch.whiteName,
                      )
                      .toList();
                  queueNotifier.setPlayers([
                    nextMatch.redName,
                    nextMatch.whiteName,
                    ...filteredQueue,
                  ]);
                  context.pop(); // 一覧に戻る
                },
                child: const Text('一覧に戻る（休憩）'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final startMatch = nextMatch.copyWith(status: 'in_progress');
                  await ref
                      .read(matchApplicationServiceProvider)
                      .saveMatch(startMatch); // ★ 修正
                  if (context.mounted) {
                    context.pushReplacement('/match/${nextMatch.id}');
                  }
                },
                child: const Text('すぐに次の試合を開始'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('待機列の選手がいなくなりました。無限稽古を終了します')),
      );
      context.pop();
    }
  }
}

class _RenseikaiMasterTimerWidget extends ConsumerWidget {
  final String groupName;
  final bool isInputLocked;

  const _RenseikaiMasterTimerWidget({
    required this.groupName,
    required this.isInputLocked,
  });

  String _formatTime(int seconds) {
    if (seconds < 0) return '0:00';
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterTime = ref.watch(renseikaiMasterTimerProvider(groupName));
    final isRunning = ref.watch(isMasterTimerRunningProvider(groupName));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTimeUp = masterTime == 0;

    final timerBgColor = isRunning
        ? (isDark
              ? Colors.teal.shade900.withValues(alpha: 0.4)
              : Colors.teal.shade50)
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
    final timerBorderColor = isRunning
        ? (isDark ? Colors.teal.shade400 : Colors.teal.shade500)
        : (isDark ? const Color(0xFF38383A) : Colors.teal.shade200);
    final timerTextColor = isRunning
        ? (isDark ? Colors.teal.shade300 : Colors.teal.shade900)
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isInputLocked
            ? null
            : () {
                ref
                    .read(renseikaiMasterTimerProvider(groupName).notifier)
                    .toggleTimer();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: timerBgColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isTimeUp
                  ? Colors.red
                  : (isInputLocked
                        ? Colors.grey.withValues(alpha: 0.3)
                        : timerBorderColor),
              width: (isRunning && !isInputLocked) ? 4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRunning ? Icons.pause_circle : Icons.play_circle,
                color: isTimeUp
                    ? Colors.red
                    : (isRunning
                          ? (isDark
                                ? Colors.teal.shade400
                                : Colors.teal.shade600)
                          : Colors.grey),
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'トータル',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isTimeUp
                          ? Colors.red
                          : (isDark
                                ? Colors.teal.shade200
                                : Colors.teal.shade800),
                    ),
                  ),
                  Text(
                    _formatTime(masterTime),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      color: isTimeUp ? Colors.red : timerTextColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
