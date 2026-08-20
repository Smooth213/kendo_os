import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import '../providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_leaderboard_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_share_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_single_player_select_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
// ★ Phase 8: 削除機能と権限管理用プロバイダを追加
import '../providers/match_command_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import '../components/bulk_rule_edit_sheet.dart';
import '../components/home/match_edit_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_score_marks.dart';

import 'package:uuid/uuid.dart';

class BunaiksenHomeScreen extends ConsumerWidget {
  const BunaiksenHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;

    // ★ 修正：今日ではなく「選択された日付」を基準にする
    final viewDate = ref.watch(bunaiksenViewDateProvider);
    final dateId = 'bunaiksen_${DateFormat('yyyyMMdd').format(viewDate)}';
    final dateDisplay = DateFormat('yyyy/MM/dd').format(viewDate);
    final isToday =
        DateFormat('yyyyMMdd').format(viewDate) ==
        DateFormat('yyyyMMdd').format(DateTime.now());

    final availableDates =
        ref.watch(bunaiksenAvailableDatesProvider).value ?? const <String>{};

    // 選択された日の部内戦のみ表示
    final matches = ref.watch(bunaiksenMatchesProvider(dateId));

    // 🌟 本部一斉ポップアップ監視トリガーをアタッチ（運営スタッフ用フラグ: true）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        listenGlobalAnnouncements(context, ref, dateId, isStaffRoom: true);
      }
    });

    // 無限勝ち抜きモード of 試合が存在するかどうか
    final hasInfiniteKachinuki = matches.any(
      (m) => m.isKachinuki && m.matchType == '無限勝ち抜き',
    );

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          backgroundColor: enableLiquidGlass
              ? AppKendoColors.transparent
              : themeColors.cardBackground,
          foregroundColor: isDark
              ? const Color(0xFFFFFFFF)
              : themeColors.primaryAccent,
          title: isToday ? '今日の部内戦' : '$dateDisplay の記録',
          elevation: 0,
          centerTitle: true,
          actions: [
            // ★ 新設：カレンダーボタン（ここをタップで過去の日付へ）
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: '日付を選択して過去の記録を見る',
              onPressed: () async {
                // 🛡️ クラッシュ防止仕様：初期表示日(initialDate)は必ず選択可能(selectableDayPredicateがtrueを返す)でなければならない。
                // 選択された日付(viewDate)が、今日の道場IDにおける「試合がある日」または「今日」に含まれていない場合、
                // アサーションエラーを回避するために DateTime.now() にフォールバックする。
                final todayStr = DateFormat('yyyyMMdd').format(DateTime.now());
                final viewDateStr = DateFormat('yyyyMMdd').format(viewDate);
                final bool isViewDateSelectable =
                    viewDateStr == todayStr ||
                    availableDates.contains(viewDateStr);
                final safeInitialDate = isViewDateSelectable
                    ? viewDate
                    : DateTime.now();

                final picked = await showDatePicker(
                  context: context,
                  initialDate: safeInitialDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  selectableDayPredicate: (DateTime date) {
                    // 🍏 厳密なるカレンダー制限仕様の完成：全 OS 全期間にわたり、試合のあった日だけを美しく点灯させます
                    final dStr = DateFormat('yyyyMMdd').format(date);
                    final tStr = DateFormat('yyyyMMdd').format(DateTime.now());

                    return dStr == tStr || availableDates.contains(dStr);
                  },
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: isDark
                            ? ColorScheme.dark(
                                primary: themeColors.primaryAccent,
                                onPrimary: context.appColors.textColor,
                                surface: themeColors.cardBackground,
                                onSurface: AppKendoColors.pureWhite,
                              )
                            : ColorScheme.light(
                                primary: themeColors.primaryAccent,
                                onPrimary: AppKendoColors.pureWhite,
                                surface: themeColors.cardBackground,
                                onSurface: AppKendoColors.pureBlack,
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
                  ref.read(bunaiksenViewDateProvider.notifier).state = picked;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: '観客席プレビュー',
              onPressed: () {
                ref.read(bunaiksenViewDateProvider.notifier).state = viewDate;
                final dojoId = ref.read(currentDojoIdProvider);
                context.push(
                  '/bunaiksen-viewer-home/$dateId?role=viewer&dojoId=$dojoId&tournamentId=$dateId',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: '観戦リンクを共有する',
              onPressed: () =>
                  _showShareDialog(context, ref, dateId, dateDisplay),
            ),
            IconButton(
              // ★ 修正：チェックマークから、成績や順位表を表す「リーダーボード」のアイコンに変更
              icon: const Icon(Icons.leaderboard_outlined),
              onPressed: () => context.push('/bunaiksen-record'),
              tooltip: '成績一覧',
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.go('/'),
          ),
        ),
        body: matches.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: AppKendoColors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      isToday ? '今日の試合はまだありません' : 'この日の記録はありません',
                      style: const TextStyle(color: AppKendoColors.grey),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () =>
                            _showQuickMatchSheet(context, ref, dateId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColors.primaryAccent,
                          foregroundColor: AppKendoColors.pureWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.large,
                          ),
                        ),
                        child: const Text(
                          'クイック対戦を始める',
                          style: TextStyle(
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.body,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  if (hasInfiniteKachinuki) ...[
                    const SliverToBoxAdapter(child: BunaiksenLeaderboardCard()),
                  ],
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 6.0,
                      ),
                      color: themeColors.softAccent, // ★ 修正
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '本日の試合一覧',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              color: themeColors.primaryAccent,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () =>
                                    _showQuickMatchSheet(context, ref, dateId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColors.primaryAccent,
                                  foregroundColor: AppKendoColors.pureWhite,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.medium,
                                  ),
                                ),
                                child: const Text(
                                  'クイック対戦',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: AppFontSize.caption,
                                  ),
                                ),
                              ),
                              if (matches.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                OutlinedButton.icon(
                                  onPressed: () => showBulkRuleEditSheet(
                                    context,
                                    dateId,
                                    matches,
                                    isBunaiksen: true,
                                  ),
                                  icon: Icon(
                                    Icons.gavel,
                                    size: 14,
                                    color: themeColors.primaryAccent,
                                  ),
                                  label: Text(
                                    'ルール一括変更',
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                      fontSize: AppFontSize.caption,
                                      color: themeColors.primaryAccent,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: themeColors.primaryAccent,
                                    side: BorderSide(
                                      color: themeColors.primaryAccent
                                          .withValues(alpha: 0.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.medium,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
                                : const Color(0xFFF2F2F7))
                          : (isDark
                                ? const Color(0xFF1C1C1E)
                                : context.appColors.textColor);
                      final Color textC = isFinished
                          ? (isDark
                                ? context.appColors.subTextColor
                                : context.appColors.subTextColor)
                          : (context.appColors.textColor);
                      final Color noteC = isFinished
                          ? (isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.subTextColor)
                          : AppKendoColors.grey;

                      // ★ 修正：一体化のため、外側のPaddingでリストの余白を管理
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: Slidable(
                          key: ValueKey(match.id),
                          endActionPane: ActionPane(
                            // ★ 修正：選手マスタ画面と完全に同じ滑らかな物理エンジン（ScrollMotion）に統一
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) =>
                                    _showEditNoteDialog(context, ref, match),
                                backgroundColor: AppKendoColors.blueAccent,
                                foregroundColor: AppKendoColors.pureWhite,
                                icon: Icons.edit,
                                label: '編集',
                              ),
                              SlidableAction(
                                onPressed: (context) =>
                                    _confirmDeleteMatch(context, ref, match.id),
                                backgroundColor: AppKendoColors.redAccent,
                                foregroundColor: AppKendoColors.pureWhite,
                                icon: Icons.delete,
                                label: '削除',
                                // ★ 修正：カードの角丸と完全に一致させる
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(AppRadius.largeValue),
                                ),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            margin: EdgeInsets.zero, // ★ 重要：ここをゼロにすることで隙間を消す
                            color: bg,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.large,
                              side: BorderSide(
                                color: isDark
                                    ? const Color(
                                        0xFFFFFFFF,
                                      ).withValues(alpha: 0.10)
                                    : const Color(
                                        0xFF000000,
                                      ).withValues(alpha: 0.05),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: AppRadius.large,
                              onTap: () {
                                final dojoId = ref.read(currentDojoIdProvider);
                                context.push(
                                  '/match/${match.id}?tournamentId=$dateId&dojoId=$dojoId',
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
                                            horizontal: AppSpacing.subValue,
                                            vertical: AppSpacing.xxs,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: AppSpacing.sm,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPlaying
                                                ? const Color(0xFF2196F3)
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
                                                  ? AppKendoColors.pureWhite
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
                                              ? BunaiksenScoreMarks(
                                                  match: match,
                                                  isDark: isDark,
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
                        ),
                      );
                    }, childCount: matches.length),
                  ),
                ],
              ),
        floatingActionButton: isToday
            ? FloatingActionButton.extended(
                backgroundColor: themeColors.primaryAccent, // ★ 修正
                foregroundColor: AppKendoColors.pureWhite,
                icon: const Icon(Icons.add),
                label: const Text(
                  '試合作成',
                  style: TextStyle(
                    fontSize: AppFontSize.subhead,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                onPressed: () => context.push('/bunaiksen-setup'),
              )
            : null, // ★ 今日以外を表示している時は作成ボタンを出さない
      ),
    );
  }

  void _confirmDeleteMatch(
    BuildContext context,
    WidgetRef ref,
    String matchId,
  ) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: '試合の削除',
        titleIcon: Icons.warning_amber_rounded,
        iconColor: AppKendoColors.red,
        content: const Text('この試合データを完全に削除します。この操作は取り消せません。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(matchCommandProvider).deleteMatch(matchId);
            },
            child: const Text(
              '削除',
              style: TextStyle(
                color: AppKendoColors.red,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return MatchEditSheet(
          matches: [match],
          tournamentId: match.tournamentId,
          themeColors: themeColors,
        );
      },
    );
  }

  void _showShareDialog(
    BuildContext context,
    WidgetRef ref,
    String tournamentId,
    String dateDisplay,
  ) {
    final dojoId = ref.read(currentDojoIdProvider);
    BunaiksenShareDialog.show(
      context,
      tournamentId: tournamentId,
      dateDisplay: dateDisplay,
      dojoId: dojoId,
    );
  }

  void _showQuickMatchSheet(
    BuildContext context,
    WidgetRef ref,
    String dateId,
  ) {
    String redPlayer = '選手A';
    String whitePlayer = '選手B';
    String selectedCourt = '部内戦コート';
    String selectedGroupName = '部内対戦';
    final initialRule = ref.read(bunaiksenRuleProvider);
    double selectedMatchTime = 2.0;
    bool selectedIsIpponShobu = initialRule.isIpponShobu;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setStateSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            top: AppSpacing.lg,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x8A000000),
                  borderRadius: AppRadius.micro,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'クイック対戦',
                style: TextStyle(
                  fontSize: AppFontSize.headline,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '赤・白の選手を選択して「試合スタート」を押すとすぐに計測が始まります',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0x8A000000),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // 赤選手
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppKendoColors.red.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '赤',
                            style: TextStyle(
                              fontSize: AppFontSize.body,
                              fontWeight: AppFontWeight.bold,
                              color: AppKendoColors.hansokuRed,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          InkWell(
                            onTap: () async {
                              final picked = await _selectSinglePlayerSheet(
                                context,
                                ref,
                                '赤',
                                AppKendoColors.hansokuRed,
                              );
                              if (picked != null) {
                                setStateSheet(() => redPlayer = picked);
                              }
                            },
                            borderRadius: AppRadius.small,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFFFFFFF),
                                borderRadius: AppRadius.small,
                                border: Border.all(
                                  color: AppKendoColors.hansokuRed.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      redPlayer,
                                      style: TextStyle(
                                        fontSize: AppFontSize.subhead,
                                        fontWeight: AppFontWeight.bold,
                                        color: themeColors.textColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: AppKendoColors.hansokuRed,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: AppFontWeight.black,
                        fontSize: AppFontSize.subhead,
                        color: AppKendoColors.grey,
                      ),
                    ),
                  ),
                  // 白選手
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppKendoColors.blueGrey.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF607D8B)
                              : const Color(0xFF607D8B),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '白',
                            style: TextStyle(
                              fontSize: AppFontSize.body,
                              fontWeight: AppFontWeight.bold,
                              color: isDark
                                  ? const Color(
                                      0xFFFFFFFF,
                                    ).withValues(alpha: 0.7)
                                  : const Color(0xFF607D8B),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          InkWell(
                            onTap: () async {
                              final picked = await _selectSinglePlayerSheet(
                                context,
                                ref,
                                '白',
                                isDark
                                    ? context.appColors.subTextColor
                                    : context.appColors.subTextColor,
                              );
                              if (picked != null) {
                                setStateSheet(() => whitePlayer = picked);
                              }
                            },
                            borderRadius: AppRadius.small,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFFFFFFF),
                                borderRadius: AppRadius.small,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF607D8B)
                                      : const Color(
                                          0xFF607D8B,
                                        ).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      whitePlayer,
                                      style: TextStyle(
                                        fontSize: AppFontSize.subhead,
                                        fontWeight: AppFontWeight.bold,
                                        color: themeColors.textColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: isDark
                                        ? const Color(
                                            0xFFFFFFFF,
                                          ).withValues(alpha: 0.7)
                                        : const Color(0xFF607D8B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 試合時間＆勝負設定
              Container(
                padding: const EdgeInsets.all(AppSpacing.modernValue),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: AppRadius.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 試合時間 (＋／－ カプセルステッパー)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xDE000000),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '試合時間',
                              style: TextStyle(
                                fontSize: AppFontSize.bodySmall,
                                fontWeight: AppFontWeight.bold,
                                color: themeColors.textColor,
                              ),
                            ),
                          ],
                        ),
                        // ＋／－ カプセルコントローラー
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3A3A3C)
                                : const Color(0xFFFFFFFF),
                            borderRadius: AppRadius.round,
                            border: Border.all(
                              color: themeColors.primaryAccent.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 32,
                                ),
                                color: selectedMatchTime > 0.5
                                    ? themeColors.primaryAccent
                                    : AppKendoColors.grey,
                                onPressed: selectedMatchTime > 0.5
                                    ? () => setStateSheet(
                                        () => selectedMatchTime =
                                            (selectedMatchTime - 0.5).clamp(
                                              0.5,
                                              10.0,
                                            ),
                                      )
                                    : null,
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 54),
                                alignment: Alignment.center,
                                child: Text(
                                  selectedMatchTime % 1 == 0
                                      ? '${selectedMatchTime.toInt()}分'
                                      : '$selectedMatchTime分',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: AppFontSize.body,
                                    color: themeColors.textColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 32,
                                ),
                                color: selectedMatchTime < 10.0
                                    ? themeColors.primaryAccent
                                    : AppKendoColors.grey,
                                onPressed: selectedMatchTime < 10.0
                                    ? () => setStateSheet(
                                        () => selectedMatchTime =
                                            (selectedMatchTime + 0.5).clamp(
                                              0.5,
                                              10.0,
                                            ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 勝負形式 (3本勝負 / 1本勝負)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xDE000000),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '勝負形式',
                              style: TextStyle(
                                fontSize: AppFontSize.bodySmall,
                                fontWeight: AppFontWeight.bold,
                                color: themeColors.textColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // 3本勝負
                            InkWell(
                              onTap: () => setStateSheet(
                                () => selectedIsIpponShobu = false,
                              ),
                              borderRadius: AppRadius.large,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.modernValue,
                                  vertical: AppSpacing.subValue,
                                ),
                                decoration: BoxDecoration(
                                  color: !selectedIsIpponShobu
                                      ? themeColors.primaryAccent
                                      : (isDark
                                            ? const Color(0xFF3A3A3C)
                                            : const Color(0xFFFFFFFF)),
                                  borderRadius: AppRadius.large,
                                  border: Border.all(
                                    color: !selectedIsIpponShobu
                                        ? themeColors.primaryAccent
                                        : const Color(0x33000000),
                                  ),
                                ),
                                child: Text(
                                  '3本勝負',
                                  style: TextStyle(
                                    fontSize: AppFontSize.small,
                                    fontWeight: !selectedIsIpponShobu
                                        ? AppFontWeight.bold
                                        : AppFontWeight.regular,
                                    color: !selectedIsIpponShobu
                                        ? AppKendoColors.pureWhite
                                        : themeColors.textColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // 1本勝負
                            InkWell(
                              onTap: () => setStateSheet(
                                () => selectedIsIpponShobu = true,
                              ),
                              borderRadius: AppRadius.large,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.modernValue,
                                  vertical: AppSpacing.subValue,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedIsIpponShobu
                                      ? themeColors.primaryAccent
                                      : (isDark
                                            ? const Color(0xFF3A3A3C)
                                            : const Color(0xFFFFFFFF)),
                                  borderRadius: AppRadius.large,
                                  border: Border.all(
                                    color: selectedIsIpponShobu
                                        ? themeColors.primaryAccent
                                        : const Color(0x33000000),
                                  ),
                                ),
                                child: Text(
                                  '1本勝負',
                                  style: TextStyle(
                                    fontSize: AppFontSize.small,
                                    fontWeight: selectedIsIpponShobu
                                        ? AppFontWeight.bold
                                        : AppFontWeight.regular,
                                    color: selectedIsIpponShobu
                                        ? AppKendoColors.pureWhite
                                        : themeColors.textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final dojoId = ref.read(currentDojoIdProvider);
                    final baseRule = ref.read(bunaiksenRuleProvider);
                    final matchId = const Uuid().v4();

                    final matchRule = baseRule.copyWith(
                      matchTimeMinutes: selectedMatchTime,
                      isIpponShobu: selectedIsIpponShobu,
                      ipponLimit: selectedIsIpponShobu ? 1 : 2,
                    );

                    final newMatch = MatchModel(
                      id: matchId,
                      tournamentId: dateId,
                      groupName: selectedGroupName,
                      matchType: '個人戦',
                      redName: redPlayer,
                      whiteName: whitePlayer,
                      matchTimeMinutes: selectedMatchTime,
                      hasExtension:
                          baseRule.enchoTimeMinutes > 0 ||
                          baseRule.isEnchoUnlimited,
                      extensionTimeMinutes: baseRule.enchoTimeMinutes,
                      status: 'in_progress',
                      order: DateTime.now().millisecondsSinceEpoch.toDouble(),
                      rule: matchRule,
                      note: '$selectedCourt\n$selectedGroupName',
                    );

                    await ref
                        .read(matchApplicationServiceProvider)
                        .saveMatch(newMatch);

                    if (context.mounted) {
                      context.push(
                        '/match/${newMatch.id}?tournamentId=$dateId&dojoId=$dojoId',
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text(
                    '試合スタート',
                    style: TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColors.primaryAccent,
                    foregroundColor: AppKendoColors.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.modernValue,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.large,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _selectSinglePlayerSheet(
    BuildContext context,
    WidgetRef ref,
    String sideName,
    Color accentColor,
  ) {
    return BunaiksenSinglePlayerSelectSheet.show(
      context,
      ref,
      sideName: sideName,
      accentColor: accentColor,
    );
  }
}
