import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/widgets/infinite_streak_leaderboard.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

class ViewerBunaiksenHomeScreen extends ConsumerWidget {
  final String tournamentId;

  const ViewerBunaiksenHomeScreen({super.key, required this.tournamentId});

  // ★ 究極版：記号化しつつ、区切り文字を「中央揃えのアイコン」で美しく表示するWidgetエンジン
  Widget _buildScoreMarks(
    MatchModel match,
    bool isDark, {
    bool isFinished = true,
  }) {
    final textColor = isFinished
        ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
        : (isDark ? Colors.white : Colors.black87);
    final iconColor = isFinished
        ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

    if (match.redScore == 0 && match.whiteScore == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Icon(Icons.close, size: 18, color: iconColor),
      );
    }

    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(match.events, match, match.rule);

    final rDisplays = analysis.displays[Side.red] ?? [];
    final wDisplays = analysis.displays[Side.white] ?? [];

    String rMarksStr = rDisplays
        .map((d) {
          if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
          if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
          if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
          if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
          if (d.mark == '反') return '反';
          if (d.mark == '判定') return '判';
          if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
          return d.mark;
        })
        .join('');

    String wMarksStr = wDisplays
        .map((d) {
          if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
          if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
          if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
          if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
          if (d.mark == '反') return '反';
          if (d.mark == '判定') return '判';
          if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
          return d.mark;
        })
        .join('');

    final bool isDraw = match.redScore == match.whiteScore;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rMarksStr,
          style: TextStyle(
            fontSize: AppFontSize.header,
            fontWeight: AppFontWeight.bold,
            color: textColor,
            height: 1.1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(
            isDraw ? Icons.close : Icons.remove,
            size: 16,
            color: iconColor,
          ),
        ),
        Text(
          wMarksStr,
          style: TextStyle(
            fontSize: AppFontSize.header,
            fontWeight: AppFontWeight.bold,
            color: textColor,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen_viewer');
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    // 🛡️ QRアクセス防衛判定：外部のQRコード（直リンク）からスタックなしで直接ブラウザで開かれた場合のみ true と判定
    final isQrAccess = !GoRouter.of(context).canPop();

    // tournamentId から日付をパース (例: bunaiksen_20241010)
    String dateDisplay = '部内戦';
    if (tournamentId.startsWith('bunaiksen_') && tournamentId.length == 18) {
      final dateStr = tournamentId.substring(10);
      if (dateStr.length == 8) {
        dateDisplay =
            '${dateStr.substring(0, 4)}/${dateStr.substring(4, 6)}/${dateStr.substring(6, 8)}';
      }
    }

    final availableDates =
        ref.watch(bunaiksenAvailableDatesProvider).value ?? const <String>{};

    final matches = ref.watch(bunaiksenMatchesProvider(tournamentId));

    // 🌟 本部一斉ポップアップ監視トリガーをアタッチ（運営スタッフ用フラグ: false）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        listenGlobalAnnouncements(
          context,
          ref,
          tournamentId,
          isStaffRoom: false,
        );
      }
    });

    final hasInfiniteKachinuki = matches.any(
      (m) => m.isKachinuki && m.matchType == '無限勝ち抜き',
    );

    return PopScope(
      canPop: false, // ブラウザのネイティブ戻るを制御するため
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppHeader(
            backgroundColor: enableLiquidGlass
                ? Colors.transparent
                : (isDark
                      ? themeColors.cardBackground
                      : themeColors.primaryAccent),
            foregroundColor: (enableLiquidGlass || isDark)
                ? themeColors.primaryAccent
                : Colors.white,
            title: '$dateDisplay の記録 (観戦)',
            elevation: 0,
            centerTitle: true,
            // 🛡️ UI防衛：QRから直接開かれた一般観客の場合は戻るボタンを完全に消滅させ、迷子や不正操作を防止
            leading: isQrAccess
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => context.pop(),
                  ),
            actions: [
              // 🛡️ UI防衛：QRから直接開かれた一般観客の場合はカレンダーボタンを非表示にし、その日の試合のみにスコープを固定
              if (!isQrAccess)
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: '日付を選択して過去の記録を見る',
                  onPressed: () async {
                    DateTime initialDate = DateTime.now();
                    if (tournamentId.startsWith('bunaiksen_') &&
                        tournamentId.length == 18) {
                      final dateStr = tournamentId.substring(10);
                      if (dateStr.length == 8) {
                        final parsed = DateTime.tryParse(dateStr);
                        if (parsed != null) {
                          initialDate = parsed;
                        }
                      }
                    }

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      selectableDayPredicate: (DateTime date) {
                        // 🍏 厳密なるカレンダー制限仕様 of 完成：観客席側も試合の実在する過去日だけを正確に自動点灯
                        final dStr = DateFormat('yyyyMMdd').format(date);
                        final todayStr = DateFormat(
                          'yyyyMMdd',
                        ).format(DateTime.now());

                        return dStr == todayStr ||
                            availableDates.contains(dStr);
                      },
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: isDark
                                ? ColorScheme.dark(
                                    primary: themeColors.primaryAccent,
                                    onPrimary: Colors.white,
                                    surface: themeColors.cardBackground,
                                    onSurface: Colors.white,
                                  )
                                : ColorScheme.light(
                                    primary: themeColors.primaryAccent,
                                    onPrimary: Colors.white,
                                    surface: themeColors.cardBackground,
                                    onSurface: Colors.black87,
                                  ),
                            dialogTheme: DialogThemeData(
                              backgroundColor: themeColors.cardBackground,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      ref.read(bunaiksenViewDateProvider.notifier).state =
                          picked;
                      final nextTournamentId =
                          'bunaiksen_${DateFormat('yyyyMMdd').format(picked)}';
                      final dojoId = ref.read(currentDojoIdProvider);
                      if (!context.mounted) return;
                      context.pushReplacement(
                        '/bunaiksen-viewer-home/$nextTournamentId?role=viewer&dojoId=$dojoId',
                      );
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: '表示設定',
                onPressed: () {
                  showAppBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const ViewerSettingsBottomSheet(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_2),
                tooltip: '観戦リンクを共有する',
                onPressed: () =>
                    _showShareDialog(context, ref, tournamentId, dateDisplay),
              ),
              IconButton(
                icon: const Icon(Icons.leaderboard_outlined),
                // ★ 完全分離した部内戦専用の成績一覧への遷移
                onPressed: () =>
                    context.push('/bunaiksen-viewer-record/$tournamentId'),
                tooltip: '成績一覧',
              ),
            ],
          ),
          body: matches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'この日の記録はありません',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    if (hasInfiniteKachinuki) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Card(
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.large,
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        color: Colors.deepOrange,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        '無限勝ち抜き 連勝ランキング',
                                        style: TextStyle(
                                          fontSize: AppFontSize.subhead,
                                          fontWeight: AppFontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  const InfiniteStreakLeaderboard(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          color: themeColors.softAccent,
                          width: double.infinity,
                          child: Text(
                            '本日の試合一覧',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              color: themeColors.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final match = matches[index];
                        final hasScore =
                            match.redScore > 0 ||
                            match.whiteScore > 0 ||
                            match.events.isNotEmpty;
                        final isPlaying = match.status == 'in_progress';
                        final isFinished =
                            (match.status == 'finished' ||
                                match.status == 'approved' ||
                                hasScore) &&
                            !isPlaying;

                        final Color bg = isFinished
                            ? (isDark
                                  ? const Color(0xFF161618)
                                  : Colors.grey.shade50)
                            : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
                        final Color textC = isFinished
                            ? (isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade500)
                            : (isDark ? Colors.white : Colors.black87);
                        final Color noteC = isFinished
                            ? (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade500)
                            : Colors.grey;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Card(
                            margin: EdgeInsets
                                .zero, // 🛡️ 整合性パッチ：操作員画面(bunaiksen_home_screen)の設計と1ミリの狂いもなく横幅・サイズを完全統一
                            elevation: 0,
                            color: bg,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.large,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: InkWell(
                              // ★ STEP 1, 5, 9：ウィジェット内部の構造変更に左右されない安定したテスト Keys 規約の適用
                              key: Key('viewer_match_card_${match.id}'),
                              borderRadius: AppRadius.large,
                              onTap: () {
                                final dojoId = ref.read(currentDojoIdProvider);
                                // 🛡️ 閲覧スコープ防衛：観客席プレビューからの遷移のため、スコア入力画面(/match)ではなく、閲覧専用の一本速報詳細画面(/viewer)へ正しくルーティング
                                context.push(
                                  '/viewer/${match.id}?role=viewer&tournamentId=$tournamentId&dojoId=$dojoId',
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            match.note.isNotEmpty
                                                ? match.note
                                                : '部内稽古',
                                            style: TextStyle(
                                              fontSize: AppFontSize.caption,
                                              color: noteC,
                                              fontWeight: AppFontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: AppSpacing.sm,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPlaying
                                                ? Colors.blue.shade600
                                                : (isFinished
                                                      ? (isDark
                                                            ? Colors
                                                                  .grey
                                                                  .shade800
                                                            : Colors
                                                                  .grey
                                                                  .shade300)
                                                      : (isDark
                                                            ? const Color(
                                                                0xFF2C2C2E,
                                                              )
                                                            : Colors
                                                                  .grey
                                                                  .shade200)),
                                            borderRadius: AppRadius.tiny,
                                          ),
                                          child: Text(
                                            isPlaying
                                                ? '進行中'
                                                : (isFinished ? '終了' : '待機中'),
                                            style: TextStyle(
                                              fontSize: AppFontSize.badge,
                                              fontWeight: AppFontWeight.bold,
                                              color: isPlaying
                                                  ? Colors.white
                                                  : (isFinished
                                                        ? (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade400
                                                              : Colors
                                                                    .grey
                                                                    .shade600)
                                                        : (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade400
                                                              : Colors
                                                                    .grey
                                                                    .shade700)),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '第${index + 1}試合',
                                          style: TextStyle(
                                            fontSize: AppFontSize.caption,
                                            color: noteC,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            match.redName,
                                            style: TextStyle(
                                              fontSize: AppFontSize.subhead,
                                              fontWeight: AppFontWeight.bold,
                                              color: textC,
                                            ),
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.lg,
                                          ),
                                          child: isFinished
                                              ? _buildScoreMarks(
                                                  match,
                                                  isDark,
                                                  isFinished: isFinished,
                                                )
                                              : Text(
                                                  'VS',
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppFontSize.subhead,
                                                    fontWeight:
                                                        AppFontWeight.bold,
                                                    color: textC,
                                                  ),
                                                ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            match.whiteName,
                                            style: TextStyle(
                                              fontSize: AppFontSize.subhead,
                                              fontWeight: AppFontWeight.bold,
                                              color: textC,
                                            ),
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: matches.length),
                    ),
                  ],
                ),
          floatingActionButton: null,
        ),
      ),
    );
  }

  void _showShareDialog(
    BuildContext context,
    WidgetRef ref,
    String tournamentId,
    String dateDisplay,
  ) {
    final dojoId = ref.read(currentDojoIdProvider);
    // 🛡️ ドメイン同期パッチ：部内戦の観客ホーム（ViewerBunaiksenHomeScreen）側QR共有リンクも、確実に本物のベータ環境（kendo-os-beta.web.app）を指すように修正
    final String shareUrl =
        'https://kendo-os-beta.web.app/bunaiksen-viewer-home/$tournamentId?role=viewer&dojoId=$dojoId';

    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: '$dateDisplay 観戦リンク',
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'この部内戦の全試合・スコアを\n観客用に安全に共有できます。',
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
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                // ★ Phase 9最適化: 名称から「AI/OS」を排し、現場に寄り添った文言へブラッシュアップ
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        '【剣道リアルタイムViewer共有】このリンクから今日の試合結果・スコアをリアルタイムにその場で観戦・確認できます！\n'
                        'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
                        'リンク: $shareUrl',
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
            child: const Text('閉じる', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
