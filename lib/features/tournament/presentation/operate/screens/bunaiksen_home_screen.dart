import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_leaderboard_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_match_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_match_list_header_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_home_action_helper.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import '../components/bulk_rule_edit_sheet.dart';
import '../providers/match_list_provider.dart';
import '../providers/permission_provider.dart';

class BunaiksenHomeScreen extends ConsumerStatefulWidget {
  const BunaiksenHomeScreen({super.key});

  @override
  ConsumerState<BunaiksenHomeScreen> createState() =>
      _BunaiksenHomeScreenState();
}

class _BunaiksenHomeScreenState extends ConsumerState<BunaiksenHomeScreen> {
  @override
  void dispose() {
    // 🥋 部内戦画面を抜ける際に開いているドックシートを確実に消去
    FloatingDockSheetManager.close(immediate: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final permissions = ref.watch(permissionProvider);

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

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        FloatingDockSheetManager.close(immediate: true);
      },
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            backgroundColor: enableLiquidGlass
                ? AppKendoColors.transparent
                : themeColors.cardBackground,
            foregroundColor: isDark
                ? const Color(0xFFFFFFFF)
                : themeColors.primaryAccent,
            title: '$dateDisplay 部内戦',
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.date_range),
                tooltip: '日付選択',
                onPressed: () => BunaiksenHomeActionHelper.handleDatePicker(
                  context: context,
                  ref: ref,
                  viewDate: viewDate,
                  availableDates: availableDates,
                  themeColors: themeColors,
                  isDark: isDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility),
                tooltip: '観戦プレビュー',
                onPressed: () {
                  final dojoId = ref.read(currentDojoIdProvider);
                  context.push('/bunaiksen-viewer-home/$dateId?dojoId=$dojoId');
                },
              ),
              IconButton(
                icon: const Icon(Icons.assessment_outlined),
                tooltip: '成績一覧',
                onPressed: () => context.push('/bunaiksen-record'),
              ),
            ],
          ),
          body: Stack(
            children: [
              matches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_kabaddi,
                            size: 64,
                            color: themeColors.subTextColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            isToday
                                ? '本日の試合はまだありません'
                                : '$dateDisplay の試合はありません',
                            style: TextStyle(
                              fontSize: AppFontSize.headline,
                              color: themeColors.subTextColor,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '右下の「試合作成」からリーグや個人戦を登録するか、\n下のボタンから手軽に対戦を開始できます。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppFontSize.small,
                                color: themeColors.subTextColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            ElevatedButton(
                              onPressed: () => BunaiksenQuickMatchSheet.show(
                                context,
                                ref,
                                dateId,
                              ),
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
                          const SliverToBoxAdapter(
                            child: BunaiksenLeaderboardCard(),
                          ),
                        ],
                        SliverToBoxAdapter(
                          child: BunaiksenMatchListHeaderBar(
                            themeColors: themeColors,
                            hasMatches: matches.isNotEmpty,
                            onQuickMatch: () => BunaiksenQuickMatchSheet.show(
                              context,
                              ref,
                              dateId,
                            ),
                            onBulkRuleEdit: () => showBulkRuleEditSheet(
                              context,
                              dateId,
                              matches,
                              isBunaiksen: true,
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final match = matches[index];
                            return BunaiksenMatchCard(
                              match: match,
                              index: index,
                              dateId: dateId,
                              isDark: isDark,
                              canEdit: !permissions.isReadOnly,
                              canDelete:
                                  permissions.canDeleteData ||
                                  permissions.canManageTournament,
                              onTap: () {
                                final dojoId = ref.read(currentDojoIdProvider);
                                context.push(
                                  '/match/${match.id}?tournamentId=$dateId&dojoId=$dojoId',
                                );
                              },
                              onEditNote: () =>
                                  BunaiksenHomeActionHelper.showEditNoteDialog(
                                    context: context,
                                    match: match,
                                    themeColors: themeColors,
                                  ),
                              onDelete: () =>
                                  BunaiksenHomeActionHelper.confirmDeleteMatch(
                                    context: context,
                                    ref: ref,
                                    matchId: match.id,
                                  ),
                            );
                          }, childCount: matches.length),
                        ),
                      ],
                    ),
              // 🥋 部内戦専用フローティングドック
              BunaiksenDockButton(
                tournamentId: dateId,
                isViewerMode: permissions.isReadOnly,
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
      ),
    );
  }
}
