import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
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
    final participantsSet = <String>{};
    for (var m in matches) {
      participantsSet.add(m.redName.split(':').first.trim());
      participantsSet.add(m.whiteName.split(':').first.trim());
    }
    final int n = participantsSet.length;
    final int mCount = n * (n - 1) ~/ 2;

    final ruleTeamName = matches.firstOrNull?.rule?.teamName;
    final hasRuleTeam = ruleTeamName?.isNotEmpty == true;

    final bool isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );

    String selfInfo = "";
    if (isIndiv) {
      final myMatch = matches.firstWhere(
        (m) =>
            ownTeams.any(
              (ot) => m.redName.contains(ot) || m.whiteName.contains(ot),
            ) ||
            (hasRuleTeam &&
                (m.redName.contains(ruleTeamName!) ||
                    m.whiteName.contains(ruleTeamName))),
        orElse: () => matches.first,
      );
      final isRedOwn =
          ownTeams.any((ot) => myMatch.redName.contains(ot)) ||
          (hasRuleTeam && myMatch.redName.contains(ruleTeamName!));
      final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
      final team = rawName.split(':').first.trim();
      final name = rawName.contains(':')
          ? rawName.split(':').last.replaceAll(')', '').trim()
          : rawName;
      selfInfo = "$name（$team）";
    } else {
      selfInfo = participantsSet.firstWhere(
        (p) => ownTeams.contains(p) || (hasRuleTeam && p == ruleTeamName),
        orElse: () => participantsSet.first,
      );
    }

    final suffix = isIndiv ? "$n人リーグ" : "$nチームリーグ";
    return "$selfInfo : $suffix（全$mCount試合）";
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

                        int redWins = 0;
                        int redPts = 0;
                        int whiteWins = 0;
                        int whitePts = 0;
                        for (var m in groupList) {
                          final r = m.redScore;
                          final w = m.whiteScore;
                          redPts += (r as num).toInt();
                          whitePts += (w as num).toInt();
                          final mFinished =
                              m.status == 'finished' || m.status == 'approved';
                          if (mFinished) {
                            if (r > w) {
                              redWins++;
                            } else if (w > r) {
                              whiteWins++;
                            }
                          }
                        }
                        final ruleTeamName =
                            groupList.firstOrNull?.rule?.teamName;
                        final isRedOwn =
                            ownTeams.contains(rTeam) ||
                            (ruleTeamName?.isNotEmpty == true &&
                                rTeam == ruleTeamName);
                        final isWhiteOwn =
                            ownTeams.contains(wTeam) ||
                            (ruleTeamName?.isNotEmpty == true &&
                                wTeam == ruleTeamName);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                rTeam,
                                style: TextStyle(
                                  fontSize: AppFontSize.bodyMedium,
                                  fontWeight: isRedOwn
                                      ? AppFontWeight.black
                                      : AppFontWeight.bold,
                                  color: isRedOwn
                                      ? const Color(0xFFFFB300)
                                      : titleColor,
                                ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$redWins',
                                    style: const TextStyle(
                                      fontSize: AppFontSize.subhead,
                                      fontWeight: AppFontWeight.bold,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                  Text(
                                    '($redPts)',
                                    style: const TextStyle(
                                      fontSize: AppFontSize.caption,
                                      color: Color(0x8A000000),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.subValue,
                                    ),
                                    child: Text(
                                      'ー',
                                      style: TextStyle(
                                        fontSize: AppFontSize.body,
                                        color: Color(0x8A000000),
                                        fontWeight: AppFontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$whiteWins',
                                    style: TextStyle(
                                      fontSize: AppFontSize.subhead,
                                      fontWeight: AppFontWeight.bold,
                                      color: context.appColors.textColor,
                                    ),
                                  ),
                                  Text(
                                    '($whitePts)',
                                    style: TextStyle(
                                      fontSize: AppFontSize.caption,
                                      color: context.appColors.subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                wTeam,
                                style: TextStyle(
                                  fontSize: AppFontSize.bodyMedium,
                                  fontWeight: isWhiteOwn
                                      ? AppFontWeight.black
                                      : AppFontWeight.bold,
                                  color: isWhiteOwn
                                      ? const Color(0xFFFFB300)
                                      : titleColor,
                                ),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                          final bool boutsInProgress = bouts.any(
                            (m) => m.status == 'in_progress',
                          );
                          final bool boutsAllFinished = bouts.every(
                            (m) =>
                                m.status == 'finished' ||
                                m.status == 'approved',
                          );

                          final t1 = name.split(' vs ')[0];
                          final t2 = name.split(' vs ')[1];

                          final Color mCardBg = boutsAllFinished
                              ? (isDark
                                    ? const Color(0xFF161618)
                                    : const Color(0xFFF2F2F7))
                              : (isDark
                                    ? const Color(0xFF1C1C1E)
                                    : const Color(0xFFFFFFFF));

                          final Color mTitleColor = boutsAllFinished
                              ? context.appColors.subTextColor
                              : (context.appColors.textColor);

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.small,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF38383A)
                                    : const Color(0x33000000),
                                width: 1,
                              ),
                              boxShadow: boutsInProgress
                                  ? [
                                      BoxShadow(
                                        color: AppKendoColors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ClipRRect(
                              borderRadius: AppRadius.sub,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: AppKendoColors.transparent,
                                ),
                                child: ExpansionTile(
                                  collapsedBackgroundColor: mCardBg,
                                  backgroundColor: mCardBg,
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${bouts.length}ポジション',
                                            style: const TextStyle(
                                              fontSize: AppFontSize.caption,
                                              color: AppKendoColors.grey,
                                              fontWeight: AppFontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (bouts.isNotEmpty &&
                                              bouts.first.groupName != null &&
                                              bouts.first.groupName!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: AppSpacing.subValue,
                                              ),
                                              child: SizedBox(
                                                height: 24,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    final encodedGroupName =
                                                        Uri.encodeComponent(
                                                          bouts
                                                                  .first
                                                                  .groupName ??
                                                              '',
                                                        );
                                                    context.push(
                                                      '/viewer-team/$encodedGroupName',
                                                    );
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                              AppSpacing.sm,
                                                        ),
                                                    side: BorderSide(
                                                      color: mTitleColor
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                              AppRadius.sub,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'スコア',
                                                    style: TextStyle(
                                                      fontSize:
                                                          AppFontSize.badge,
                                                      fontWeight:
                                                          AppFontWeight.bold,
                                                      color: mTitleColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.subValue,
                                              vertical: AppSpacing.xxs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: boutsInProgress
                                                  ? context
                                                        .appColors
                                                        .subTextColor
                                                  : (boutsAllFinished
                                                        ? (context
                                                              .appColors
                                                              .separatorColor)
                                                        : (isDark
                                                              ? const Color(
                                                                  0xFF2C2C2E,
                                                                )
                                                              : context
                                                                    .appColors
                                                                    .separatorColor)),
                                              borderRadius: AppRadius.tiny,
                                            ),
                                            child: Text(
                                              boutsInProgress
                                                  ? '進行中'
                                                  : (boutsAllFinished
                                                        ? '終了'
                                                        : '待機中'),
                                              style: TextStyle(
                                                fontSize: AppFontSize.badge,
                                                fontWeight: AppFontWeight.bold,
                                                color: boutsInProgress
                                                    ? AppKendoColors.pureWhite
                                                    : context
                                                          .appColors
                                                          .subTextColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Builder(
                                        builder: (context) {
                                          int redWins = 0;
                                          int redPts = 0;
                                          int whiteWins = 0;
                                          int whitePts = 0;
                                          for (var m in bouts) {
                                            if (m.matchType == '代表戦') {
                                              continue;
                                            }
                                            final r = m.redScore;
                                            final w = m.whiteScore;
                                            redPts += (r as num).toInt();
                                            whitePts += (w as num).toInt();
                                            if (m.status == 'finished' ||
                                                m.status == 'approved') {
                                              if (r > w) {
                                                redWins++;
                                              } else if (w > r) {
                                                whiteWins++;
                                              }
                                            }
                                          }
                                          final ruleTeamName =
                                              bouts.firstOrNull?.rule?.teamName;
                                          final isRedOwn =
                                              ownTeams.contains(t1) ||
                                              (ruleTeamName?.isNotEmpty ==
                                                      true &&
                                                  t1 == ruleTeamName);
                                          final isWhiteOwn =
                                              ownTeams.contains(t2) ||
                                              (ruleTeamName?.isNotEmpty ==
                                                      true &&
                                                  t2 == ruleTeamName);

                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  t1,
                                                  style: TextStyle(
                                                    fontSize: AppFontSize.body,
                                                    fontWeight: isRedOwn
                                                        ? AppFontWeight.black
                                                        : AppFontWeight.bold,
                                                    color: isRedOwn
                                                        ? const Color(
                                                            0xFFFFB300,
                                                          )
                                                        : mTitleColor,
                                                  ),
                                                  textAlign: TextAlign.end,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.md,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '$redWins',
                                                      style: const TextStyle(
                                                        fontSize: AppFontSize
                                                            .bodyMedium,
                                                        fontWeight:
                                                            AppFontWeight.bold,
                                                        color: Color(
                                                          0xFFE53935,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '($redPts)',
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppFontSize.badge,
                                                        color: context
                                                            .appColors
                                                            .subTextColor,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal:
                                                                AppSpacing
                                                                    .subValue,
                                                          ),
                                                      child: Text(
                                                        'ー',
                                                        style: TextStyle(
                                                          fontSize: AppFontSize
                                                              .bodySmall,
                                                          color: context
                                                              .appColors
                                                              .subTextColor,
                                                          fontWeight:
                                                              AppFontWeight
                                                                  .bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '$whiteWins',
                                                      style: TextStyle(
                                                        fontSize: AppFontSize
                                                            .bodyMedium,
                                                        fontWeight:
                                                            AppFontWeight.bold,
                                                        color: context
                                                            .appColors
                                                            .textColor,
                                                      ),
                                                    ),
                                                    Text(
                                                      '($whitePts)',
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppFontSize.badge,
                                                        color: context
                                                            .appColors
                                                            .subTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  t2,
                                                  style: TextStyle(
                                                    fontSize: AppFontSize.body,
                                                    fontWeight: isWhiteOwn
                                                        ? AppFontWeight.black
                                                        : AppFontWeight.bold,
                                                    color: isWhiteOwn
                                                        ? const Color(
                                                            0xFFFFB300,
                                                          )
                                                        : mTitleColor,
                                                  ),
                                                  textAlign: TextAlign.start,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  children: bouts
                                      .map(
                                        (m) => ViewerMatchListTileCard(
                                          key: Key('viewer_match_card_${m.id}'),
                                          initialMatch: m,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
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
