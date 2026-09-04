import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';
import 'package:kendo_os/features/match/presentation/providers/unread_announcement_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/presentation/screens/embedded_manual_screen.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 🥋 大会クイック機能ハブ（フローティングドックから立ち上がる総合コントロールパネル）
class TournamentQuickHubBottomSheet extends ConsumerWidget {
  final String tournamentId;
  final bool isViewerMode;

  const TournamentQuickHubBottomSheet({
    super.key,
    required this.tournamentId,
    this.isViewerMode = false,
  });

  /// ボトムシートを表示するエントリーポイント
  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
    bool isViewerMode = false,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppKendoColors.transparent,
      builder: (ctx) => TournamentQuickHubBottomSheet(
        tournamentId: tournamentId,
        isViewerMode: isViewerMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final permissions = ref.watch(permissionProvider);
    final isReadOnly = isViewerMode || permissions.isReadOnly;

    // 未読アナウンス件数のリアルタイム取得
    final unreadAsync = ref.watch(
      unreadAnnouncementCountProvider((
        tournamentId: tournamentId,
        isStaffRoom: !isReadOnly,
      )),
    );
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.40,
      maxChildSize: 0.90,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: themeColors.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.roundValue),
            ),
            boxShadow: [
              BoxShadow(
                color: AppKendoColors.pureBlack.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDragHandle(themeColors),
              _buildHeader(context, themeColors),
              Divider(
                height: 1,
                thickness: 0.8,
                color: themeColors.separatorColor,
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    // 1. 最重要プライマリ: 大会プログラム・進行表
                    _buildProgramBanner(context, themeColors, isDark),
                    const SizedBox(height: AppSpacing.md),

                    // 2. 機能グリッド (2列)
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.45,
                      children: [
                        _buildTile(
                          themeColors: themeColors,
                          icon: Icons.groups_rounded,
                          iconColor: AppKendoColors.indigo,
                          title: 'チーム試合状況',
                          subtitle: 'コート・進行確認',
                          onTap: () {
                            Navigator.pop(context);
                            context.push(
                              '/court-status?tournamentId=$tournamentId',
                            );
                          },
                        ),
                        _buildTile(
                          themeColors: themeColors,
                          icon: Icons.scoreboard_rounded,
                          iconColor: AppKendoColors.ipponGold,
                          title: '公式記録・対戦表',
                          subtitle: '全試合スコア詳細',
                          onTap: () {
                            Navigator.pop(context);
                            final path = isReadOnly
                                ? '/viewer-official-record?tournamentId=$tournamentId'
                                : '/official-record?tournamentId=$tournamentId';
                            context.push(path);
                          },
                        ),
                        _buildTile(
                          themeColors: themeColors,
                          icon: Icons.brush_rounded,
                          iconColor: AppKendoColors.pink,
                          title: 'クイックメモ',
                          subtitle: '全画面ペン書き込み',
                          onTap: () {
                            final programs = ref
                                .read(programListProvider(tournamentId))
                                .valueOrNull;
                            Navigator.pop(context);
                            if (programs != null && programs.isNotEmpty) {
                              context.push(
                                isReadOnly
                                    ? '/program-viewer?role=viewer'
                                    : '/program-viewer',
                                extra: {
                                  'programs': programs,
                                  'index': 0,
                                  'initialDrawingMode': true,
                                },
                              );
                            } else {
                              ProgramBottomSheet.show(
                                context,
                                tournamentId: tournamentId,
                                isViewerMode: isReadOnly,
                              );
                            }
                          },
                        ),
                        _buildTile(
                          themeColors: themeColors,
                          icon: Icons.notifications_rounded,
                          iconColor: AppKendoColors.deepOrange,
                          title: 'お知らせ・連絡',
                          subtitle: unreadCount > 0
                              ? '$unreadCount 件の新着あり'
                              : 'アナウンス履歴',
                          badgeCount: unreadCount,
                          onTap: () {
                            Navigator.pop(context);
                            AnnounceHistoryBottomSheet.show(
                              context,
                              tournamentId,
                              !isReadOnly,
                            );
                          },
                        ),
                        if (!isReadOnly)
                          _buildTile(
                            themeColors: themeColors,
                            icon: Icons.settings_rounded,
                            iconColor: AppKendoColors.grey,
                            title: '大会設定',
                            subtitle: '表示・タイマー設定',
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/settings');
                            },
                          ),
                        _buildTile(
                          themeColors: themeColors,
                          icon: Icons.help_outline_rounded,
                          iconColor: AppKendoColors.teal,
                          title: 'ヘルプ・手引',
                          subtitle: '使い方・公式ルール',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EmbeddedManualScreen(
                                      initialFilePath: 'manual/index.md',
                                    ),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(AppThemeColors themeColors) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: themeColors.separatorColor,
          borderRadius: AppRadius.full,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.dashboard_customize_rounded,
            size: 20,
            color: themeColors.primaryAccent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '大会クイック機能',
            style: TextStyle(
              fontSize: AppFontSize.subhead,
              fontWeight: AppFontWeight.bold,
              color: themeColors.textColor,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: '閉じる',
            color: themeColors.subTextColor,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramBanner(
    BuildContext context,
    AppThemeColors themeColors,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        Navigator.pop(context);
        ProgramBottomSheet.show(
          context,
          tournamentId: tournamentId,
          isViewerMode: isViewerMode,
        );
      },
      borderRadius: AppRadius.large,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                : [
                    themeColors.primaryAccent.withValues(alpha: 0.08),
                    themeColors.primaryAccent.withValues(alpha: 0.03),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.large,
          border: Border.all(
            color: themeColors.primaryAccent.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeColors.primaryAccent.withValues(alpha: 0.15),
                borderRadius: AppRadius.medium,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: themeColors.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '大会プログラム・進行表',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: themeColors.textColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.subValue),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.subValue,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppKendoColors.pink.withValues(alpha: 0.2),
                          borderRadius: AppRadius.full,
                        ),
                        child: const Text(
                          '手書きペン対応',
                          style: TextStyle(
                            fontSize: AppFontSize.badge,
                            fontWeight: AppFontWeight.bold,
                            color: AppKendoColors.pink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'タップして素早くプレビュー＆メモ記入',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: themeColors.subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: themeColors.subTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required AppThemeColors themeColors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      borderRadius: AppRadius.large,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: themeColors.inputBackground,
          borderRadius: AppRadius.large,
          border: Border.all(
            color: themeColors.separatorColor.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.small,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppFontSize.subhead,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: themeColors.subTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.subValue,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppKendoColors.redAccent,
                    borderRadius: AppRadius.full,
                    border: Border.all(
                      color: AppKendoColors.pureWhite,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: AppKendoColors.pureWhite,
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
