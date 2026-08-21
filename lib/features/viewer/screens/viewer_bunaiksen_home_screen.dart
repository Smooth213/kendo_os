import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_match_card.dart';

import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_share_dialog.dart';
import 'package:kendo_os/features/viewer/presentation/viewer_home_screen.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/infinite_streak_leaderboard.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

class ViewerBunaiksenHomeScreen extends ConsumerWidget {
  final String tournamentId;

  const ViewerBunaiksenHomeScreen({super.key, required this.tournamentId});

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
    final dojoId = ref.watch(currentDojoIdProvider);

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
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            backgroundColor: enableLiquidGlass
                ? AppKendoColors.transparent
                : (isDark
                      ? themeColors.cardBackground
                      : themeColors.primaryAccent),
            foregroundColor: (enableLiquidGlass || isDark)
                ? themeColors.primaryAccent
                : const Color(0xFFFFFFFF),
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
                      ref.read(bunaiksenViewDateProvider.notifier).state =
                          picked;
                      final nextTournamentId =
                          'bunaiksen_${DateFormat('yyyyMMdd').format(picked)}';
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
                onPressed: () => ViewerBunaiksenShareDialog.show(
                  context,
                  ref,
                  tournamentId: tournamentId,
                  dateDisplay: dateDisplay,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.leaderboard_outlined),
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
                        color: AppKendoColors.grey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'この日の記録はありません',
                        style: TextStyle(color: AppKendoColors.grey),
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
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFFFFFFFF),
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
                                        color: AppKendoColors.deepOrange,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        '無限勝ち抜き 連勝ランキング',
                                        style: TextStyle(
                                          fontSize: AppFontSize.subhead,
                                          fontWeight: AppFontWeight.bold,
                                          color: context.appColors.textColor,
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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ViewerBunaiksenMatchCard(
                          match: matches[index],
                          index: index,
                          tournamentId: tournamentId,
                          dojoId: dojoId,
                        ),
                        childCount: matches.length,
                      ),
                    ),
                  ],
                ),
          floatingActionButton: null,
        ),
      ),
    );
  }
}
