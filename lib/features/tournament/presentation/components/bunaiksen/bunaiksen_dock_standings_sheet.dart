import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_matches_provider.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 部内戦ドック：成績一覧・星取表・連勝数リーダーボード
class BunaiksenDockStandingsSheet extends ConsumerWidget {
  final String tournamentId;

  const BunaiksenDockStandingsSheet({super.key, required this.tournamentId});

  static void show(BuildContext context, {required String tournamentId}) {
    FloatingDockSheetManager.show(
      context: context,
      builder: (_) => BunaiksenDockStandingsSheet(tournamentId: tournamentId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveTournamentId = tournamentId.isNotEmpty
        ? tournamentId
        : () {
            final date = ref.watch(bunaiksenViewDateProvider);
            final dateStr = DateFormat('yyyyMMdd').format(date);
            return 'bunaiksen_$dateStr';
          }();

    final matchesAsync = ref.watch(
      bunaiksenMatchesStreamProvider(effectiveTournamentId),
    );
    final streaks = ref.watch(bunaiksenInfiniteStreakProvider);

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
                title: '部内戦成績・リーダーボード',
                icon: Icons.leaderboard_rounded,
                iconColor: AppKendoColors.ipponGold,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  // 1. 無限勝ち抜き連勝ランキング
                  if (streaks.isNotEmpty) ...[
                    _buildSectionHeader(
                      '勝ち抜き連勝ランキング',
                      AppKendoColors.ipponGold,
                    ),
                    ..._buildStreakList(streaks, themeColors),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // 2. 本日の対戦成績集計（勝敗・本数）
                  _buildSectionHeader('本日の個人勝敗・獲得本数', AppKendoColors.indigo),
                  matchesAsync.when(
                    data: (matches) {
                      final stats = _computePlayerStats(matches);
                      if (stats.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            '完了した試合の成績データはまだありません',
                            style: TextStyle(
                              color: themeColors.subTextColor,
                              fontSize: AppFontSize.small,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: stats
                            .map((s) => _buildStatRow(s, themeColors))
                            .toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text('成績の集計エラー: $e'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.tiny,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStreakList(
    Map<String, int> streaks,
    AppThemeColors themeColors,
  ) {
    final sorted = streaks.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Text(
            '現在連勝中の選手はいません',
            style: TextStyle(
              fontSize: AppFontSize.small,
              color: themeColors.subTextColor,
            ),
          ),
        ),
      ];
    }

    return sorted.map((entry) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: themeColors.cardBackground,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: AppKendoColors.ipponGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.military_tech_rounded,
              color: AppKendoColors.ipponGold,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.textColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppKendoColors.amber.withValues(alpha: 0.16),
                borderRadius: AppRadius.small,
              ),
              child: Text(
                '${entry.value} 連勝中',
                style: TextStyle(
                  fontSize: AppFontSize.badge,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.textColor,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<_PlayerStat> _computePlayerStats(List<MatchModel> matches) {
    final map = <String, _PlayerStat>{};

    for (final m in matches) {
      if (m.status != 'finished') continue;
      final red = m.redName.trim();
      final white = m.whiteName.trim();

      if (red.isNotEmpty) {
        final stat = map.putIfAbsent(red, () => _PlayerStat(name: red));
        stat.matches += 1;
        stat.pointsFor += m.redScore;
        stat.pointsAgainst += m.whiteScore;
        if (m.redScore > m.whiteScore) {
          stat.wins += 1;
        } else if (m.redScore == m.whiteScore) {
          stat.draws += 1;
        } else {
          stat.losses += 1;
        }
      }

      if (white.isNotEmpty) {
        final stat = map.putIfAbsent(white, () => _PlayerStat(name: white));
        stat.matches += 1;
        stat.pointsFor += m.whiteScore;
        stat.pointsAgainst += m.redScore;
        if (m.whiteScore > m.redScore) {
          stat.wins += 1;
        } else if (m.redScore == m.whiteScore) {
          stat.draws += 1;
        } else {
          stat.losses += 1;
        }
      }
    }

    final list = map.values.toList();
    list.sort((a, b) {
      if (b.wins != a.wins) return b.wins.compareTo(a.wins);
      final diffB = b.pointsFor - b.pointsAgainst;
      final diffA = a.pointsFor - a.pointsAgainst;
      if (diffB != diffA) return diffB.compareTo(diffA);
      return b.pointsFor.compareTo(a.pointsFor);
    });
    return list;
  }

  Widget _buildStatRow(_PlayerStat stat, AppThemeColors themeColors) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: themeColors.cardBackground,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: themeColors.separatorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stat.name,
              style: TextStyle(
                fontSize: AppFontSize.body,
                fontWeight: AppFontWeight.bold,
                color: themeColors.textColor,
              ),
            ),
          ),
          Text(
            '${stat.wins}勝 ${stat.losses}敗 ${stat.draws}分',
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: AppFontWeight.bold,
              color: themeColors.subTextColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppKendoColors.indigo.withValues(alpha: 0.12),
              borderRadius: AppRadius.tiny,
            ),
            child: Text(
              '${stat.pointsFor}本',
              style: const TextStyle(
                fontSize: AppFontSize.badge,
                fontWeight: AppFontWeight.bold,
                color: AppKendoColors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerStat {
  final String name;
  int matches = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;

  _PlayerStat({required this.name});
}
