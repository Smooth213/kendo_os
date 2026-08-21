import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_score_summary.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_league_title_helper.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_league_matchup_tile.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_list_tile_card.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 観客席画面用 団体戦/リーグ戦 グループ単位カード（ExpansionTile）
class ViewerGroupMatchCard extends StatelessWidget {
  final String groupKey;
  final List<MatchModel> groupList;
  final String matchLabel;
  final Widget? headerWidget;
  final List<String> ownTeams;

  const ViewerGroupMatchCard({
    super.key,
    required this.groupKey,
    required this.groupList,
    required this.matchLabel,
    this.headerWidget,
    required this.ownTeams,
  });

  static String generateDescriptiveLeagueTitle(
    List<MatchModel> matches,
    List<String> ownTeams,
  ) {
    return ViewerLeagueTitleHelper.generateDescriptiveLeagueTitle(
      matches,
      ownTeams,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstMatch = groupList.first;

    final rTeam = firstMatch.redName.contains(':')
        ? firstMatch.redName.split(':').first.trim()
        : firstMatch.redName;
    final wTeam = firstMatch.whiteName.contains(':')
        ? firstMatch.whiteName.split(':').first.trim()
        : firstMatch.whiteName;

    final hasInProgress = groupList.any((m) => m.status == 'in_progress');
    final allFinished = groupList.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );

    final Color cardBg = allFinished
        ? (isDark ? const Color(0xFF161618) : context.appColors.inputBackground)
        : (context.appColors.cardBackground);

    final Color titleColor = allFinished
        ? context.appColors.subTextColor
        : (context.appColors.textColor);

    final Color subTitleColor = context.appColors.subTextColor;

    final pairingsSet = <String>{};
    for (var m in groupList) {
      final t1 = m.redName.split(':').first.trim();
      final t2 = m.whiteName.split(':').first.trim();
      final pairKey = [t1, t2]..sort();
      pairingsSet.add(pairKey.join(' vs '));
    }
    final int displayMatchCount = pairingsSet.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?headerWidget,
        GestureDetector(
          onLongPress: null,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.medium,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF38383A)
                    : context.appColors.separatorColor,
                width: 1,
              ),
              boxShadow: hasInProgress
                  ? [
                      BoxShadow(
                        color: AppKendoColors.blue.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.smooth,
              child: ExpansionTile(
                key: PageStorageKey<String>('group_$groupKey'),
                collapsedBackgroundColor: cardBg,
                backgroundColor: cardBg,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1行目: コントロール・ステータスライン
                    Row(
                      children: [
                        const Spacer(),
                        if (!matchLabel.contains('リーグ戦') &&
                            firstMatch.groupName != null &&
                            firstMatch.groupName!.isNotEmpty) ...[
                          SizedBox(
                            height: 26,
                            child: OutlinedButton(
                              onPressed: () {
                                final encodedGroupName = Uri.encodeComponent(
                                  firstMatch.groupName ?? '',
                                );
                                context.push(
                                  firstMatch.isKachinuki
                                      ? '/viewer-kachinuki/$encodedGroupName'
                                      : '/viewer-team/$encodedGroupName',
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                side: BorderSide(
                                  color: titleColor.withValues(alpha: 0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.sub,
                                ),
                              ),
                              child: Text(
                                'スコア',
                                style: TextStyle(
                                  fontSize: AppFontSize.badge,
                                  fontWeight: AppFontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.subValue,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: hasInProgress
                                ? const Color(0xFF546E7A)
                                : (allFinished
                                      ? context.appColors.separatorColor
                                      : (isDark
                                            ? const Color(0xFF2C2C2E)
                                            : context
                                                  .appColors
                                                  .separatorColor)),
                            borderRadius: AppRadius.tiny,
                          ),
                          child: Text(
                            hasInProgress
                                ? '進行中'
                                : (allFinished ? '終了' : '待機中'),
                            style: TextStyle(
                              fontSize: AppFontSize.badge,
                              fontWeight: AppFontWeight.bold,
                              color: hasInProgress
                                  ? AppKendoColors.pureWhite
                                  : context.appColors.subTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (firstMatch.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs,
                        ),
                        child: Text(
                          firstMatch.note,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: subTitleColor,
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // チーム合計スコアライン / リーグ戦タイトル
                    Builder(
                      builder: (context) {
                        if (matchLabel.contains('リーグ戦')) {
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  generateDescriptiveLeagueTitle(
                                    groupList,
                                    ownTeams,
                                  ),
                                  style: TextStyle(
                                    fontSize: AppFontSize.bodySmall,
                                    fontWeight: AppFontWeight.bold,
                                    color: titleColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }

                        return ViewerGroupMatchScoreSummary(
                          groupList: groupList,
                          rTeam: rTeam,
                          wTeam: wTeam,
                          ownTeams: ownTeams,
                          titleColor: titleColor,
                        );
                      },
                    ),
                  ],
                ),
                subtitle: Text(
                  '$displayMatchCount対戦',
                  style: TextStyle(
                    color: subTitleColor,
                    fontSize: AppFontSize.small,
                  ),
                ),
                children: (() {
                  final List<Widget> childrenWidgets = [];
                  final normalMatches = groupList
                      .where((m) => !m.note.contains('[順位決定戦]'))
                      .toList();
                  final tieBreakMatches = groupList
                      .where((m) => m.note.contains('[順位決定戦]'))
                      .toList();

                  if (matchLabel.contains('リーグ戦')) {
                    if (matchLabel.contains('個人戦')) {
                      childrenWidgets.addAll(
                        normalMatches
                            .map(
                              (m) => ViewerMatchListTileCard(
                                key: Key('viewer_match_card_${m.id}'),
                                initialMatch: m,
                              ),
                            )
                            .toList(),
                      );
                    } else {
                      final boutsByMatchup = <String, List<MatchModel>>{};
                      final matchupOrder = <String>[];
                      for (var m in normalMatches) {
                        final t1 = m.redName.split(':').first.trim();
                        final r2 = m.whiteName.split(':').first.trim();
                        final matchupName = '$t1 vs $r2';
                        if (!boutsByMatchup.containsKey(matchupName)) {
                          matchupOrder.add(matchupName);
                          boutsByMatchup[matchupName] = [];
                        }
                        boutsByMatchup[matchupName]!.add(m);
                      }

                      childrenWidgets.addAll(
                        matchupOrder.map((name) {
                          final bouts = boutsByMatchup[name]!;
                          return ViewerLeagueMatchupTile(
                            matchupName: name,
                            bouts: bouts,
                            ownTeams: ownTeams,
                            isDark: isDark,
                          );
                        }),
                      );
                    }
                  } else {
                    childrenWidgets.addAll(
                      normalMatches
                          .map(
                            (m) => ViewerMatchListTileCard(
                              key: Key('viewer_match_card_${m.id}'),
                              initialMatch: m,
                            ),
                          )
                          .toList(),
                    );
                  }

                  if (tieBreakMatches.isNotEmpty) {
                    childrenWidgets.add(const Divider());
                    childrenWidgets.add(
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Text(
                          '【順位決定戦】',
                          style: TextStyle(
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.small,
                            color: AppKendoColors.orangeAccent,
                          ),
                        ),
                      ),
                    );
                    childrenWidgets.addAll(
                      tieBreakMatches.map(
                        (m) => ViewerMatchListTileCard(
                          key: Key('viewer_match_card_${m.id}'),
                          initialMatch: m,
                        ),
                      ),
                    );
                  }

                  return childrenWidgets;
                })(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
