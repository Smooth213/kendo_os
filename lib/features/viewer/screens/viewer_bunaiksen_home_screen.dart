import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_match_card.dart';

import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_header_actions.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/infinite_streak_leaderboard.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

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
              ViewerBunaiksenHeaderActions(
                tournamentId: tournamentId,
                dateDisplay: dateDisplay,
                dojoId: dojoId,
                isDark: isDark,
                isQrAccess: isQrAccess,
                availableDates: availableDates,
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
