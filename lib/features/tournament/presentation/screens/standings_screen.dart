import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

class PlayerStats {
  final String name;
  int matches = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;
  int pointsScored = 0;
  double matchPoints = 0.0; // ★ 追加：勝ち点

  PlayerStats(this.name);
}

class StandingsScreen extends ConsumerWidget {
  final String tournamentId;
  const StandingsScreen({super.key, required this.tournamentId});

  String _formatWinRate(double rate) {
    if (rate >= 1.0) {
      return '10割';
    }
    if (rate <= 0.0) {
      return '0割';
    }

    int wari = (rate * 10).floor() % 10;
    int bu = (rate * 100).floor() % 10;
    int rin = (rate * 1000).floor() % 10;

    if (bu == 0 && rin == 0) {
      return '$wari割';
    }
    if (rin == 0) {
      return '$wari割$bu分';
    }
    return '$wari割$bu分$rin厘';
  }

  // ★ 追加：所属名などを取り除き、純粋な「選手名」だけを抽出するヘルパー
  String _extractPlayerName(String rawName) {
    if (rawName.contains('欠員') || rawName.contains('未定')) {
      return '';
    }
    String clean = rawName.contains(':')
        ? rawName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : rawName.trim();
    return clean;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ Step 3-2: selectを使い、計算に必要なこの大会の試合データのみを監視
    final matches = ref.watch(
      matchListProvider.select(
        (list) => list.where((m) => m.tournamentId == tournamentId).toList(),
      ),
    );

    // iOS Native: True Black & Elevation
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;
    final textColor = isDark
        ? AppKendoColors.pureWhite
        : AppKendoColors.pureBlack;
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : AppKendoColors.grey.shade700;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : AppKendoColors.grey.shade200;
    final headerTextColor = isDark
        ? AppKendoColors.pureWhite
        : AppKendoColors.indigo.shade900;

    final playerListAsync = ref.watch(playerListProvider);

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: '成績・順位表',
          backgroundColor: enableLiquidGlass
              ? AppKendoColors.transparent
              : cardColor,
          elevation: 0,
        ),
        body: playerListAsync.when(
          data: (players) {
            // ★ 追加：自チーム（選手マスタ）に登録されている選手名のリストを作成
            final masterPlayerNames = players.map((p) => p.name).toSet();

            final statsMap = <String, PlayerStats>{};
            for (var match in matches) {
              if (match.status != 'approved' && match.status != 'finished') {
                continue;
              }

              final rScore = (match.redScore as num).toInt();
              final wScore = (match.whiteScore as num).toInt();
              final r = match.rule;

              final rNameClean = _extractPlayerName(match.redName);
              final wNameClean = _extractPlayerName(match.whiteName);

              // ★ 赤側の集計（マスタに登録されている場合のみ）
              if (rNameClean.isNotEmpty &&
                  masterPlayerNames.contains(rNameClean)) {
                statsMap.putIfAbsent(rNameClean, () => PlayerStats(rNameClean));
                final stats = statsMap[rNameClean]!;
                stats.matches++;
                stats.pointsScored += rScore;
                if (rScore > wScore) {
                  stats.wins++;
                  if (r != null && r.isLeague) stats.matchPoints += r.winPoint;
                } else if (wScore > rScore) {
                  stats.losses++;
                  if (r != null && r.isLeague) stats.matchPoints += r.lossPoint;
                } else {
                  stats.draws++;
                  if (r != null && r.isLeague) stats.matchPoints += r.drawPoint;
                }
              }

              // ★ 白側の集計（マスタに登録されている場合のみ）
              if (wNameClean.isNotEmpty &&
                  masterPlayerNames.contains(wNameClean)) {
                statsMap.putIfAbsent(wNameClean, () => PlayerStats(wNameClean));
                final stats = statsMap[wNameClean]!;
                stats.matches++;
                stats.pointsScored += wScore;
                if (wScore > rScore) {
                  stats.wins++;
                  if (r != null && r.isLeague) stats.matchPoints += r.winPoint;
                } else if (rScore > wScore) {
                  stats.losses++;
                  if (r != null && r.isLeague) stats.matchPoints += r.lossPoint;
                } else {
                  stats.draws++;
                  if (r != null && r.isLeague) stats.matchPoints += r.drawPoint;
                }
              }
            }

            final sortedStats = statsMap.values
                .where((s) => s.matches > 0)
                .toList();
            sortedStats.sort((a, b) {
              // ★ 修正：最優先を「勝ち点」にする
              if (b.matchPoints != a.matchPoints) {
                return b.matchPoints.compareTo(a.matchPoints);
              }
              if (b.wins != a.wins) {
                return b.wins.compareTo(a.wins);
              }
              if (a.losses != b.losses) {
                return a.losses.compareTo(b.losses);
              }
              return b.pointsScored.compareTo(a.pointsScored);
            });

            if (sortedStats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/kendo_icon.png',
                      width: 80,
                      height: 80,
                      color: isDark
                          ? const Color(0xFF38383A)
                          : AppKendoColors.grey.shade300,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'まだ承認済みの試合結果がありません',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ★ 修正：3チーム以上の完全同点に対応（勝ち点誤差対策込）
            final tieGroups = <List<PlayerStats>>[];
            if (sortedStats.length > 1) {
              List<PlayerStats> currentTie = [sortedStats.first];
              const double epsilon = 0.001;

              for (int i = 1; i < sortedStats.length; i++) {
                final prev = sortedStats[i - 1];
                final curr = sortedStats[i];

                bool isTie =
                    (prev.matchPoints - curr.matchPoints).abs() < epsilon &&
                    prev.wins == curr.wins &&
                    prev.pointsScored == curr.pointsScored;

                if (isTie) {
                  currentTie.add(curr);
                } else {
                  if (currentTie.length > 1) {
                    tieGroups.add(List.from(currentTie));
                  }
                  currentTie = [curr];
                }
              }
              if (currentTie.length > 1) {
                tieGroups.add(currentTie);
              }
            }

            return Column(
              children: [
                // 元々の順位表リスト
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: sortedStats.length,
                    itemExtent: 92.0,
                    itemBuilder: (context, index) {
                      final stat = sortedStats[index];
                      final winRate = stat.matches > 0
                          ? (stat.wins / stat.matches)
                          : 0.0;
                      final rateStr = _formatWinRate(winRate);

                      Color avatarColor = isDark
                          ? const Color(0xFF2C2C2E)
                          : AppKendoColors.grey.shade200;
                      Color iconColor = isDark
                          ? AppKendoColors.grey.shade400
                          : AppKendoColors.grey.shade700;

                      if (index == 0) {
                        avatarColor = isDark
                            ? AppKendoColors.ipponGold.withValues(alpha: 0.3)
                            : AppKendoColors.ipponGold;
                        iconColor = isDark
                            ? AppKendoColors.ipponGold
                            : AppKendoColors.ipponGold;
                      } else if (index == 1) {
                        avatarColor = isDark
                            ? AppKendoColors.grey.shade800
                            : AppKendoColors.grey.shade300;
                        iconColor = isDark
                            ? AppKendoColors.grey.shade300
                            : AppKendoColors.grey.shade600;
                      } else if (index == 2) {
                        avatarColor = isDark
                            ? AppKendoColors.brown.shade900.withValues(
                                alpha: 0.5,
                              )
                            : AppKendoColors.orange.shade100;
                        iconColor = isDark
                            ? AppKendoColors.orange.shade300
                            : AppKendoColors.brown.shade400;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        elevation: 0,
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.large, // iOS角丸
                          side: isDark
                              ? BorderSide.none
                              : BorderSide(color: borderColor),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: avatarColor,
                            radius: 24,
                            child: index < 3
                                ? Icon(
                                    Icons.military_tech,
                                    color: iconColor,
                                    size: 28,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                      color: iconColor,
                                      fontSize: AppFontSize.headline,
                                    ),
                                  ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stat.name,
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: AppFontSize.headline,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Text(
                                '勝率: $rateStr',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  color: isDark
                                      ? AppKendoColors.indigo.shade300
                                      : AppKendoColors.indigo.shade600,
                                  fontSize: AppFontSize.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.subValue,
                            ),
                            child: Text(
                              '${stat.matches}試合: ${stat.wins}勝 ${stat.losses}敗 ${stat.draws}分 / 取得: ${stat.pointsScored}本',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: AppFontSize.bodySmall,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Text(
              'エラーが発生しました: $e',
              style: TextStyle(
                color: isDark
                    ? AppKendoColors.pureWhite
                    : AppKendoColors.pureBlack,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
