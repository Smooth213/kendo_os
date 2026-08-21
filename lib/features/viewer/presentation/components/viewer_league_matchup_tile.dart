import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_match_list_tile_card.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 観客席画面用 団体リーグ戦の対戦カード別 ExpansionTile
class ViewerLeagueMatchupTile extends StatelessWidget {
  final String matchupName;
  final List<MatchModel> bouts;
  final List<String> ownTeams;
  final bool isDark;

  const ViewerLeagueMatchupTile({
    super.key,
    required this.matchupName,
    required this.bouts,
    required this.ownTeams,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool boutsInProgress = bouts.any((m) => m.status == 'in_progress');
    final bool boutsAllFinished = bouts.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );

    final t1 = matchupName.split(' vs ')[0];
    final t2 = matchupName.split(' vs ')[1];

    final Color mCardBg = boutsAllFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF));

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
          color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
          width: 1,
        ),
        boxShadow: boutsInProgress
            ? [
                BoxShadow(
                  color: AppKendoColors.blue.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.sub,
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(dividerColor: AppKendoColors.transparent),
          child: ExpansionTile(
            collapsedBackgroundColor: mCardBg,
            backgroundColor: mCardBg,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                              final encodedGroupName = Uri.encodeComponent(
                                bouts.first.groupName ?? '',
                              );
                              context.push('/viewer-team/$encodedGroupName');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              side: BorderSide(
                                color: mTitleColor.withValues(alpha: 0.2),
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
                            ? context.appColors.subTextColor
                            : (boutsAllFinished
                                  ? (context.appColors.separatorColor)
                                  : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : context.appColors.separatorColor)),
                        borderRadius: AppRadius.tiny,
                      ),
                      child: Text(
                        boutsInProgress
                            ? '進行中'
                            : (boutsAllFinished ? '終了' : '待機中'),
                        style: TextStyle(
                          fontSize: AppFontSize.badge,
                          fontWeight: AppFontWeight.bold,
                          color: boutsInProgress
                              ? AppKendoColors.pureWhite
                              : context.appColors.subTextColor,
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
                      if (m.status == 'finished' || m.status == 'approved') {
                        if (r > w) {
                          redWins++;
                        } else if (w > r) {
                          whiteWins++;
                        }
                      }
                    }
                    final ruleTeamName = bouts.firstOrNull?.rule?.teamName;
                    final isRedOwn =
                        ownTeams.contains(t1) ||
                        (ruleTeamName?.isNotEmpty == true &&
                            t1 == ruleTeamName);
                    final isWhiteOwn =
                        ownTeams.contains(t2) ||
                        (ruleTeamName?.isNotEmpty == true &&
                            t2 == ruleTeamName);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                  ? const Color(0xFFFFB300)
                                  : mTitleColor,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$redWins',
                                style: const TextStyle(
                                  fontSize: AppFontSize.bodyMedium,
                                  fontWeight: AppFontWeight.bold,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              Text(
                                '($redPts)',
                                style: TextStyle(
                                  fontSize: AppFontSize.badge,
                                  color: context.appColors.subTextColor,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.subValue,
                                ),
                                child: Text(
                                  'ー',
                                  style: TextStyle(
                                    fontSize: AppFontSize.bodySmall,
                                    color: context.appColors.subTextColor,
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '$whiteWins',
                                style: TextStyle(
                                  fontSize: AppFontSize.bodyMedium,
                                  fontWeight: AppFontWeight.bold,
                                  color: context.appColors.textColor,
                                ),
                              ),
                              Text(
                                '($whitePts)',
                                style: TextStyle(
                                  fontSize: AppFontSize.badge,
                                  color: context.appColors.subTextColor,
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
                                  ? const Color(0xFFFFB300)
                                  : mTitleColor,
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
  }
}
