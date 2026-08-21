import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';

import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';

import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import '../components/home/home_screen_call_banner.dart';
import '../components/home/home_screen_qr_dialog.dart';
import '../components/home/home_screen_setup_checklist_card.dart';
import '../components/home/match_timeline_list.dart';
import '../components/home/operator_action_buttons.dart';
import '../providers/match_list_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

export '../providers/safe_timeline_provider.dart';

final tournamentProvider = StreamProvider.family<TournamentModel?, String>((
  ref,
  id,
) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTournamentStream(id);
});

// 🌟 物理ネットワーク接続を監視するプロバイダ
final connectivityProvider = StreamProvider.autoDispose<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((result) {
    return result.contains(ConnectivityResult.none);
  });
});

class HomeScreen extends ConsumerWidget {
  final String tournamentId;
  const HomeScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌟 ステップ3：本部一斉ポップアップ監視トリガーをアタッチ（運営スタッフ用フラグ: true）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        listenGlobalAnnouncements(
          context,
          ref,
          tournamentId,
          isStaffRoom: true,
        );
        ref.read(currentTournamentIdProvider.notifier).state = tournamentId;
      }
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );
    final permissions = ref.watch(permissionProvider);
    final bool isReadOnly = permissions.isReadOnly;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final asyncMatches = ref.watch(matchListByTournamentProvider(tournamentId));
    final asyncTournament = ref.watch(tournamentProvider(tournamentId));
    final asyncTeams = ref.watch(registeredTeamsProvider(tournamentId));

    // =========================================================================
    // 🔍 【原因特定用】デバッグログ強制出力セクション
    // =========================================================================
    final isPhysicalOffline = ref.watch(connectivityProvider).value ?? false;
    debugPrint('╔═══════════════ kendo_os OFFLINE DEBUG ═══════════════╗');
    debugPrint('║ 📡 物理ネットワーク切断フラグ (isPhysicalOffline): $isPhysicalOffline');
    debugPrint('║ 📊 Firestoreストリーム状態 (matchState):');
    debugPrint('║    - isLoading: ${asyncMatches.isLoading}');
    debugPrint('║    - hasError: ${asyncMatches.hasError}');
    debugPrint('║    - hasValue: ${asyncMatches.hasValue}');
    debugPrint('║    - 件数: ${asyncMatches.value?.length ?? 0}件');
    debugPrint('╚══════════════════════════════════════════════════════╝');

    final allMatchesList = List<MatchModel>.from(asyncMatches.value ?? [])
      ..sort((a, b) => a.order.compareTo(b.order));

    final uniqueInProgress = <MatchModel>[];
    final uniqueWaiting = <MatchModel>[];
    final seenMatchups = <String>{};

    for (var match in allMatchesList) {
      if (match.status == 'finished' || match.status == 'approved') continue;

      String key;
      if (match.note.contains('[リーグ戦]')) {
        final t1 = match.redName.split(':').first.trim();
        final t2 = match.whiteName.split(':').first.trim();
        final sortedTeams = [t1, t2]..sort();
        key = 'league_${match.groupName}_${sortedTeams.join("_")}';
      } else if (match.isKachinuki) {
        key = 'kachinuki_${match.groupName}';
      } else if (match.groupName != null && match.groupName!.isNotEmpty) {
        key = 'group_${match.groupName}';
      } else {
        key = 'match_${match.id}';
      }

      if (!seenMatchups.contains(key)) {
        seenMatchups.add(key);
        if (match.status == 'in_progress') {
          uniqueInProgress.add(match);
        } else if (match.status == 'waiting') {
          uniqueWaiting.add(match);
        }
      }
    }

    return PopScope(
      canPop: !isReadOnly,
      child: LiquidBackground(
        child: Column(
          children: [
            // =========================================================================
            // 🛡️ Phase 3 - STEP 3-3 要件：オフライン画面防衛インジケータバナー
            // =========================================================================
            Builder(
              builder: (context) {
                // どのような条件であっても、ログに上がった状態を元にジャンプ判定を執行
                final isOfflineMode =
                    isPhysicalOffline ||
                    asyncMatches.hasError ||
                    asyncMatches.isLoading;

                if (!isOfflineMode) {
                  return const SizedBox.shrink();
                }

                return SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    color: (isDark
                        ? AppKendoColors.ipponGold
                        : const Color(0xFFD97706)),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: AppSpacing.lg,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: AppKendoColors.pureWhite,
                          size: 18,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            '⚠️ 体育館オフライン運営モード：ローカルDB（Isar）へ即時保存中',
                            style: TextStyle(
                              color: AppKendoColors.pureWhite,
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Scaffold(
                backgroundColor: AppKendoColors.transparent,
                appBar: AppHeader(
                  title: '大会ホーム',
                  backgroundColor: enableLiquidGlass
                      ? AppKendoColors.transparent
                      : themeColors.cardBackground,
                  actions: [
                    NotificationBellButton(
                      tournamentId: tournamentId,
                      isStaffRoom: true,
                    ),
                    if (!isReadOnly)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.sm,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/'),
                          icon: Icon(
                            Icons.home,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : themeColors.primaryAccent,
                            size: 18,
                          ),
                          label: Text(
                            'トップへ',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: isDark
                                      ? const Color(0xFFFFFFFF)
                                      : themeColors.primaryAccent,
                                  fontWeight: AppFontWeight.bold,
                                ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? context.appColors.textColor.withValues(
                                    alpha: 0.1,
                                  )
                                : themeColors.softAccent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.medium,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.qr_code_2,
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : themeColors.primaryAccent,
                      ),
                      tooltip: '大会を共有する',
                      onPressed: () =>
                          _showShareDialog(context, ref, tournamentId),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),
                body: Column(
                  children: [
                    if (!isReadOnly && allMatchesList.isEmpty)
                      asyncTournament.maybeWhen(
                        data: (tournament) {
                          if (tournament == null) {
                            return const SizedBox.shrink();
                          }
                          return asyncTeams.maybeWhen(
                            data: (teams) => HomeScreenSetupChecklistCard(
                              tournament: tournament,
                              teams: teams,
                              themeColors: themeColors,
                              isDark: isDark,
                              enableLiquidGlass: enableLiquidGlass,
                              tournamentId: tournamentId,
                            ),
                            orElse: () => const SizedBox.shrink(),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    HomeScreenCallBanner(
                      uniqueInProgress: uniqueInProgress,
                      uniqueWaiting: uniqueWaiting,
                      themeColors: themeColors,
                      isDark: isDark,
                      enableLiquidGlass: enableLiquidGlass,
                    ),
                    if (!isReadOnly)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 2.0,
                        ),
                        child: OperatorActionButtons(
                          tournamentId: tournamentId,
                        ),
                      ),
                    Expanded(
                      child: MatchTimelineList(tournamentId: tournamentId),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog(
    BuildContext context,
    WidgetRef ref,
    String tournamentId,
  ) {
    final dojoId = ref.read(currentDojoIdProvider);
    final String shareUrl =
        'https://kendo-os-beta.web.app/viewer-home/$tournamentId?role=viewer&dojoId=$dojoId';
    showAppDialog(
      context: context,
      builder: (ctx) => HomeScreenQrDialog(
        shareUrl: shareUrl,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }
}
