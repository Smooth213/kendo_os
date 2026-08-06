import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';

import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';

import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'dart:ui';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import '../components/home/match_timeline_list.dart';
import '../components/home/operator_action_buttons.dart';
import '../providers/match_list_provider.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

final tournamentProvider = StreamProvider.family<TournamentModel?, String>((
  ref,
  id,
) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTournamentStream(id);
});

final categorySortProvider = StateProvider.autoDispose<bool>((ref) => true);
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final isSearchVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);

final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
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
                    color: Colors.amber.shade900,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '⚠️ 体育館オフライン運営モード：ローカルDB（Isar）へ即時保存中',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                backgroundColor: Colors.transparent,
                appBar: AppHeader(
                  title: '大会ホーム',
                  backgroundColor: enableLiquidGlass
                      ? Colors.transparent
                      : themeColors.cardBackground,
                  actions: [
                    NotificationBellButton(
                      tournamentId: tournamentId,
                      isStaffRoom: true,
                    ),
                    if (!isReadOnly)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/'),
                          icon: Icon(
                            Icons.home,
                            color: isDark
                                ? Colors.white
                                : themeColors.primaryAccent,
                            size: 18,
                          ),
                          label: Text(
                            'トップへ',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : themeColors.primaryAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : themeColors.softAccent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.qr_code_2,
                        color: isDark
                            ? Colors.white
                            : themeColors.primaryAccent,
                      ),
                      tooltip: '大会を共有する',
                      onPressed: () =>
                          _showShareDialog(context, ref, tournamentId),
                    ),
                    const SizedBox(width: 8),
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
                            data: (teams) => _buildSetupChecklist(
                              context,
                              tournament,
                              teams,
                              themeColors,
                              isDark,
                              enableLiquidGlass,
                              tournamentId,
                            ),
                            orElse: () => const SizedBox.shrink(),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    if (uniqueInProgress.isNotEmpty || uniqueWaiting.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final bannerColor = enableLiquidGlass
                              ? themeColors.primaryAccent.withValues(
                                  alpha: isDark ? 0.35 : 0.65,
                                )
                              : themeColors.primaryAccent;

                          final bannerDecoration = BoxDecoration(
                            color: bannerColor,
                            borderRadius: BorderRadius.circular(16),
                            border: enableLiquidGlass
                                ? Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : Colors.black.withValues(alpha: 0.08),
                                    width: 0.5,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: themeColors.primaryAccent.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          );

                          final bannerContent = Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (uniqueInProgress.isNotEmpty)
                                _buildCallRow(
                                  context,
                                  '進行中',
                                  uniqueInProgress.first,
                                  Colors.orangeAccent,
                                ),
                              if (uniqueInProgress.isNotEmpty &&
                                  uniqueWaiting.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(
                                    color: Colors.white24,
                                    height: 1,
                                  ),
                                ),
                              if (uniqueWaiting.isNotEmpty)
                                _buildCallRow(
                                  context,
                                  '次試合',
                                  uniqueWaiting.first,
                                  Colors.white,
                                ),
                              if (uniqueWaiting.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '次々試合: ${uniqueWaiting[1].note.isNotEmpty ? "(${uniqueWaiting[1].note}) " : ""}${_getMatchTitle(uniqueWaiting[1])}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          );

                          if (enableLiquidGlass) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12.0,
                                    sigmaY: 12.0,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.zero,
                                    padding: const EdgeInsets.all(16),
                                    decoration: bannerDecoration,
                                    child: bannerContent,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            padding: const EdgeInsets.all(16),
                            decoration: bannerDecoration,
                            child: bannerContent,
                          );
                        },
                      ),
                    if (!isReadOnly)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
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
      builder: (ctx) => AppDialog(
        title: '大会観戦リンク',
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '離れた場所にいる保護者や仲間も、\n試合状況をリアルタイムで安心して見守れます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: QrImageView(
                  data: shareUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
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
                  backgroundColor: Colors.indigo,
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

  Widget _buildCallRow(
    BuildContext context,
    String label,
    dynamic match,
    Color textColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (match.note.isNotEmpty)
          Text(
            match.note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _getMatchTitle(match),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMatchTitle(dynamic match) {
    final isGrouped = match.groupName != null && match.groupName!.isNotEmpty;
    final isIndividual =
        match.matchType == 'individual' ||
        match.matchType == '選手' ||
        match.matchType.contains('個人戦');
    if (isGrouped && !isIndividual) {
      return '${match.redName.contains(':') ? match.redName.split(':').first.trim() : match.redName} vs ${match.whiteName.contains(':') ? match.whiteName.split(':').first.trim() : match.whiteName}';
    }
    return '${match.redName} vs ${match.whiteName.contains(':') ? '${match.whiteName.split(':')[1].trim()} : ${match.whiteName.split(':')[0].trim()}' : match.whiteName}';
  }

  Widget _buildSetupChecklist(
    BuildContext context,
    TournamentModel tournament,
    List<dynamic> teams,
    AppThemeColors themeColors,
    bool isDark,
    bool enableLiquidGlass,
    String tournamentId,
  ) {
    final hasTeams = teams.isNotEmpty;
    final hasRules = tournament.categoryRules.isNotEmpty;

    int completedSteps = 1; // 大会作成は常に完了
    if (hasTeams) completedSteps++;
    if (hasRules) completedSteps++;

    final progress = completedSteps / 4.0;

    final cardBgColor = enableLiquidGlass
        ? themeColors.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.08)
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

    final cardBorder = enableLiquidGlass
        ? Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          )
        : Border.all(
            color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200,
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.assignment_turned_in,
              color: themeColors.primaryAccent,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '大会準備ステップ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeColors.textColor,
                ),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}% 完了',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: themeColors.primaryAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(themeColors.primaryAccent),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 16),
        _buildChecklistItem(
          title: '大会基本情報の登録',
          isCompleted: true,
          themeColors: themeColors,
          isDark: isDark,
        ),
        _buildChecklistItem(
          title: '出場チーム・選手の登録',
          isCompleted: hasTeams,
          themeColors: themeColors,
          isDark: isDark,
          onTap: () => context.push('/team-registration/$tournamentId'),
        ),
        _buildChecklistItem(
          title: '部門別ルールの設定',
          isCompleted: hasRules,
          themeColors: themeColors,
          isDark: isDark,
          onTap: () => context.push('/tournament/$tournamentId/category-rules'),
        ),
        _buildChecklistItem(
          title: '最初の試合枠の作成',
          isCompleted: false,
          themeColors: themeColors,
          isDark: isDark,
          onTap: () => context.push('/setup-match/$tournamentId'),
        ),
      ],
    );

    if (enableLiquidGlass) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: cardBorder,
              ),
              child: content,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: cardBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required bool isCompleted,
    required AppThemeColors themeColors,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final activeTextColor = isDark ? Colors.white : Colors.black87;
    final inactiveTextColor = isDark ? Colors.white54 : Colors.black54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.green.shade600 : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCompleted ? FontWeight.w500 : FontWeight.bold,
                    color: isCompleted ? inactiveTextColor : activeTextColor,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (!isCompleted && onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  color: themeColors.primaryAccent,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
