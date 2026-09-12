import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_score_marks.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_matches_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 部内戦ドック：対戦ホーム一覧（ホーム画面と完全同期した並び順・技マーク付きミニカード）
class BunaiksenDockMatchesSheet extends ConsumerWidget {
  final String tournamentId;

  const BunaiksenDockMatchesSheet({super.key, required this.tournamentId});

  static void show(BuildContext context, {required String tournamentId}) {
    FloatingDockSheetManager.show(
      context: context,
      builder: (_) => BunaiksenDockMatchesSheet(tournamentId: tournamentId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    // トーナメントIDが未指定の場合は現在表示中の日付から解決
    final effectiveTournamentId = tournamentId.isNotEmpty
        ? tournamentId
        : () {
            final date = ref.watch(bunaiksenViewDateProvider);
            final dateStr = DateFormat('yyyyMMdd').format(date);
            return 'bunaiksen_$dateStr';
          }();

    // ★ 部内戦ホーム画面と完全に同一のプロバイダーを購読（同じソート順序）
    final matches = ref.watch(bunaiksenMatchesProvider(effectiveTournamentId));

    return DockDraggableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: DockBottomSheetHeader(
                title: '本日の対戦一覧・進行状況',
                icon: Icons.format_list_bulleted_rounded,
                iconColor: AppKendoColors.indigo,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          '本日の対戦カードはまだ登録されていません',
                          style: TextStyle(
                            color: themeColors.subTextColor,
                            fontSize: AppFontSize.small,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        return _buildMatchMiniCard(
                          context,
                          ref,
                          match,
                          index,
                          themeColors,
                          isDark,
                          effectiveTournamentId,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchMiniCard(
    BuildContext context,
    WidgetRef ref,
    MatchModel match,
    int index,
    AppThemeColors themeColors,
    bool isDark,
    String tournamentId,
  ) {
    final redName = match.redName.isNotEmpty ? match.redName : '未定';
    final whiteName = match.whiteName.isNotEmpty ? match.whiteName : '未定';

    final hasScore =
        match.redScore > 0 || match.whiteScore > 0 || match.events.isNotEmpty;
    final isPlaying = match.status == 'in_progress';
    final isFinished =
        (match.status == 'finished' ||
            match.status == 'approved' ||
            hasScore) &&
        !isPlaying;

    final Color badgeBg = isPlaying
        ? const Color(0xFF2196F3)
        : (isFinished
              ? (isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0))
              : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEEEE)));

    final Color badgeText = isPlaying
        ? AppKendoColors.pureWhite
        : (isFinished
              ? (isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575))
              : (isDark ? const Color(0xFFBDBDBD) : const Color(0xFF616161)));

    final statusText = isPlaying
        ? '試合中'
        : (isFinished ? (match.status == 'approved' ? '確定' : '終了') : '待機中');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isFinished
            ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
            : themeColors.cardBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isPlaying
              ? AppKendoColors.indigo.withValues(alpha: 0.6)
              : themeColors.separatorColor.withValues(alpha: 0.3),
          width: isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: AppKendoColors.transparent,
        child: InkWell(
          borderRadius: AppRadius.medium,
          onTap: () {
            FloatingDockSheetManager.close(immediate: true);
            final dojoId = ref.read(currentDojoIdProvider);
            context.push(
              '/match/${match.id}?tournamentId=$tournamentId&dojoId=$dojoId',
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上段：第N試合 ＆ ステータスバッジ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '第${index + 1}試合${(match.category != null && match.category!.isNotEmpty) ? ' (${match.category})' : ''}',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.bold,
                        color: themeColors.subTextColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: AppRadius.tiny,
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: AppFontSize.badge,
                          fontWeight: AppFontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // 下段：赤選手 - スコアマーク（㋙ - 等） - 白選手
                Row(
                  children: [
                    // 赤選手名
                    Expanded(
                      child: Text(
                        redName,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: redName == '未定'
                              ? themeColors.subTextColor
                              : AppKendoColors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // ★ 部内戦ホーム画面と同じ丸囲み技マーク（BunaiksenScoreMarks）
                    BunaiksenScoreMarks(
                      match: match,
                      isDark: isDark,
                      isFinished: isFinished,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // 白選手名
                    Expanded(
                      child: Text(
                        whiteName,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: whiteName == '未定'
                              ? themeColors.subTextColor
                              : (isDark
                                    ? const Color(0xFFFFFFFF)
                                    : themeColors.textColor),
                        ),
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
  }
}
