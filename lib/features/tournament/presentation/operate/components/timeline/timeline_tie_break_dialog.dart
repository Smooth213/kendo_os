import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// タイムライン用 決定戦・代表戦・再試合作成ダイアログ
class TimelineTieBreakDialog {
  static void show(
    BuildContext parentContext,
    WidgetRef ref,
    MatchModel firstMatch,
    List<dynamic> tieTeams,
    dynamic baseRule,
  ) {
    String? selectedMode;
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;

    Widget buildTieOption(
      BuildContext ctx,
      IconData icon,
      String title,
      String sub,
      VoidCallback onTap, {
      bool isSub = false,
    }) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        color: isSub
            ? AppKendoColors.transparent
            : (isDark
                  ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                  : const Color(0xFFFF9800).withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.small,
          side: BorderSide(
            color: isSub
                ? (isDark
                      ? const Color(0xFFFFFFFF).withValues(alpha: 0.2)
                      : const Color(0x33000000))
                : const Color(0xFFFF9800),
          ),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSub
                ? (isDark ? AppKendoColors.grey : const Color(0x8A000000))
                : const Color(0xFFFF9800),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
              color: isSub ? ctx.appColors.textColor : const Color(0xFFFF9800),
            ),
          ),
          subtitle: Text(
            sub,
            style: TextStyle(
              fontSize: AppFontSize.badge,
              color: isSub
                  ? ctx.appColors.subTextColor
                  : const Color(0xFFFF9800),
            ),
          ),
          onTap: onTap,
        ),
      );
    }

    Future<void> createTieBreakMatch(
      BuildContext context,
      WidgetRef ref,
      MatchModel firstMatch,
      List<dynamic> teams,
      dynamic baseRule, {
      required bool isAll,
      String mode = 'daihyo',
    }) async {
      try {
        final List<Map<String, String>> matchups = [];
        if (isAll) {
          for (int i = 0; i < teams.length; i++) {
            for (int j = i + 1; j < teams.length; j++) {
              matchups.add({'red': teams[i].name, 'white': teams[j].name});
            }
          }
        } else {
          matchups.add({'red': teams[0].name, 'white': teams[1].name});
        }
        String? firstMatchId;

        for (int i = 0; i < matchups.length; i++) {
          final bool isDaihyo = mode == 'daihyo';
          final List<String> positions = isDaihyo
              ? ['代表']
              : List<String>.from(baseRule.positions);
          for (int p = 0; p < positions.length; p++) {
            final String mId =
                'tiebreak_${DateTime.now().millisecondsSinceEpoch}_${i}_$p';
            firstMatchId ??= mId;
            final newMatch = MatchModel(
              id: mId,
              tournamentId: firstMatch.tournamentId,
              category: firstMatch.category,
              groupName: firstMatch.groupName,
              redName: '${matchups[i]['red']} : 選手',
              whiteName: '${matchups[i]['white']} : 選手',
              matchType: isDaihyo ? '代表戦' : '順位決定戦',
              status: 'waiting',
              order: 999.0 + (i * 10) + p,
              note: '[順位決定戦] ${isDaihyo ? "代表戦" : "再試合"}',
              matchTimeMinutes: isDaihyo
                  ? (baseRule.isDaihyoIpponShobu
                        ? 0.0
                        : baseRule.matchTimeMinutes.toDouble())
                  : baseRule.matchTimeMinutes.toDouble(),
              hasExtension:
                  baseRule.isEnchoUnlimited || baseRule.enchoCount > 0,
              rule: baseRule.copyWith(
                positions: [positions[p]],
                isKachinuki: false,
                isLeague: false,
              ),
            );
            await ref.read(matchCommandProvider).addMatch(newMatch);
          }
        }
        if (context.mounted) {
          AppSnackBar.showSuccess(
            context,
            isAll ? '三つ巴の決定戦を一括作成しました' : '決定戦を作成しました',
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.showError(context, 'エラー: $e');
        }
      }
    }

    showAppDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          if (selectedMode == null) {
            return AppDialog(
              titleWidget: const Text(
                '決定戦の形式を選択',
                style: TextStyle(fontWeight: AppFontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '同順位を解消するための形式を選んでください：',
                    style: TextStyle(fontSize: AppFontSize.small),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  buildTieOption(
                    ctx,
                    Icons.person,
                    '代表戦（1名）',
                    '1本勝負で順位を決定します',
                    () {
                      if (tieTeams.length <= 2) {
                        Navigator.pop(ctx);
                        createTieBreakMatch(
                          parentContext,
                          ref,
                          firstMatch,
                          tieTeams,
                          baseRule,
                          isAll: false,
                          mode: 'daihyo',
                        );
                      } else {
                        setState(() => selectedMode = 'daihyo');
                      }
                    },
                  ),
                  buildTieOption(
                    ctx,
                    Icons.groups,
                    'チーム再試合',
                    '全ポジションで再度対戦します',
                    () {
                      if (tieTeams.length <= 2) {
                        Navigator.pop(ctx);
                        createTieBreakMatch(
                          parentContext,
                          ref,
                          firstMatch,
                          tieTeams,
                          baseRule,
                          isAll: false,
                          mode: 'rematch',
                        );
                      } else {
                        setState(() => selectedMode = 'rematch');
                      }
                    },
                  ),
                  const Divider(height: 24),
                  buildTieOption(
                    ctx,
                    Icons.close,
                    '何もしない',
                    '同点のままにします',
                    () => Navigator.pop(ctx),
                    isSub: true,
                  ),
                ],
              ),
            );
          } else {
            final modeText = selectedMode == 'daihyo' ? '代表戦' : 'チーム再試合';
            return AppDialog(
              titleWidget: Text(
                '$modeTextの作成',
                style: const TextStyle(fontWeight: AppFontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      '作成する組み合わせを選んでください：',
                      style: TextStyle(fontSize: AppFontSize.small),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildTieOption(
                      ctx,
                      Icons.auto_awesome,
                      '三つ巴を一括作成',
                      '総当たりの$modeTextをすべて作成します',
                      () {
                        Navigator.pop(ctx);
                        createTieBreakMatch(
                          parentContext,
                          ref,
                          firstMatch,
                          tieTeams,
                          baseRule,
                          isAll: true,
                          mode: selectedMode!,
                        );
                      },
                    ),
                    const Divider(height: 24),
                    const Text(
                      '個別に対戦を作成：',
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        fontWeight: AppFontWeight.bold,
                        color: AppKendoColors.grey,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...(() {
                      final combos = <Widget>[];
                      for (int i = 0; i < tieTeams.length; i++) {
                        for (int j = i + 1; j < tieTeams.length; j++) {
                          combos.add(
                            buildTieOption(
                              ctx,
                              Icons.compare_arrows,
                              '${tieTeams[i].name} vs ${tieTeams[j].name}',
                              '$modeTextを作成',
                              () {
                                Navigator.pop(ctx);
                                createTieBreakMatch(
                                  parentContext,
                                  ref,
                                  firstMatch,
                                  [tieTeams[i], tieTeams[j]],
                                  baseRule,
                                  isAll: false,
                                  mode: selectedMode!,
                                );
                              },
                              isSub: true,
                            ),
                          );
                        }
                      }
                      return combos;
                    })(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() => selectedMode = null),
                  child: const Text('形式選択に戻る'),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
