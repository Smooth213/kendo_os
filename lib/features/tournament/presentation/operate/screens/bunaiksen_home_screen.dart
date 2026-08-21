import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_leaderboard_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_match_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_match_list_header_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_share_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import '../components/bulk_rule_edit_sheet.dart';
import '../components/home/match_edit_sheet.dart';
import '../providers/match_command_provider.dart';
import '../providers/match_list_provider.dart';

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
            // ★ カレンダーボタン（日付を選択して過去の記録へ）
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: '日付を選択して過去の記録を見る',
              onPressed: () => _handleDatePicker(
                context,
                ref,
                viewDate,
                availableDates,
                themeColors,
                isDark,
              ),
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
                            BunaiksenQuickMatchSheet.show(context, ref, dateId),
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
                    child: BunaiksenMatchListHeaderBar(
                      themeColors: themeColors,
                      hasMatches: matches.isNotEmpty,
                      onQuickMatch: () =>
                          BunaiksenQuickMatchSheet.show(context, ref, dateId),
                      onBulkRuleEdit: () => showBulkRuleEditSheet(
                        context,
                        dateId,
                        matches,
                        isBunaiksen: true,
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final match = matches[index];
                      return BunaiksenMatchCard(
                        match: match,
                        index: index,
                        dateId: dateId,
                        isDark: isDark,
                        onTap: () {
                          final dojoId = ref.read(currentDojoIdProvider);
                          context.push(
                            '/match/${match.id}?tournamentId=$dateId&dojoId=$dojoId',
                          );
                        },
                        onEditNote: () =>
                            _showEditNoteDialog(context, ref, match),
                        onDelete: () =>
                            _confirmDeleteMatch(context, ref, match.id),
                      );
                    }, childCount: matches.length),
                  ),
                ],
              ),
        floatingActionButton: isToday
            ? FloatingActionButton.extended(
                backgroundColor: themeColors.primaryAccent,
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
            : null,
      ),
    );
  }

  Future<void> _handleDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTime viewDate,
    Set<String> availableDates,
    AppThemeColors themeColors,
    bool isDark,
  ) async {
    final todayStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final viewDateStr = DateFormat('yyyyMMdd').format(viewDate);
    final bool isViewDateSelectable =
        viewDateStr == todayStr || availableDates.contains(viewDateStr);
    final safeInitialDate = isViewDateSelectable ? viewDate : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      selectableDayPredicate: (DateTime date) {
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
}
