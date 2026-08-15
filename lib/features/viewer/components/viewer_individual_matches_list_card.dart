import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/viewer/components/viewer_point_box_cell.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 観戦・公式記録画面における個人戦スコア一覧カード（純粋UIコンポーネント）
class ViewerIndividualMatchesListCard extends StatelessWidget {
  final String groupName;
  final List<MatchModel> matches;
  final Color? cardColor;
  final bool isDark;

  const ViewerIndividualMatchesListCard({
    super.key,
    required this.groupName,
    required this.matches,
    this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0x33000000);
    final headerBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFF2F2F7);
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    String displayGroupName = groupName;
    if (uuidRegex.hasMatch(groupName) ||
        groupName.length > 20 ||
        groupName == '__default__' ||
        groupName.contains(' vs ')) {
      displayGroupName = '';
    }

    String headerTitle = '【個人戦】';
    if (displayGroupName.isNotEmpty) {
      headerTitle += ' $displayGroupName';
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: headerBgColor,
            width: double.infinity,
            child: Text(
              headerTitle,
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xDE000000),
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            separatorBuilder: (context, index) => Divider(
              color: borderColor,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final m = matches[index];
              final rName = m.redName.contains(':')
                  ? m.redName.split(':').last.replaceAll(')', '').trim()
                  : m.redName;
              final wName = m.whiteName.contains(':')
                  ? m.whiteName.split(':').last.replaceAll(')', '').trim()
                  : m.whiteName;
              final rTeam = m.redName.contains(':')
                  ? m.redName.split(':').first.trim()
                  : '';
              final wTeam = m.whiteName.contains(':')
                  ? m.whiteName.split(':').first.trim()
                  : '';

              final isDone =
                  m.status == 'finished' ||
                  m.status == 'approved' ||
                  (m.redScore as num).toInt() > 0 ||
                  (m.whiteScore as num).toInt() > 0;
              final rScore = (m.redScore as num).toInt();
              final wScore = (m.whiteScore as num).toInt();
              final isDraw = isDone && rScore == wScore;
              final rWin = isDone && rScore > wScore;
              final wWin = isDone && wScore > rScore;

              final engine = KendoRuleEngine();
              final analysis = engine.analyzeHistory(m.events, m, m.rule);
              final proj = MatchProjectionMapper.toProjection(m, analysis);
              final bool rIsFirst = proj.firstPointSide == 'red';
              final bool wIsFirst = proj.firstPointSide == 'white';

              final rDisplays = analysis.displays[Side.red] ?? [];
              final wDisplays = analysis.displays[Side.white] ?? [];

              final redPts = <OfficialPointDisplay>[];
              for (int i = 0; i < rDisplays.length; i++) {
                redPts.add(
                  OfficialPointDisplay(rDisplays[i].mark, i == 0 && rIsFirst),
                );
              }

              final whitePts = <OfficialPointDisplay>[];
              for (int i = 0; i < wDisplays.length; i++) {
                whitePts.add(
                  OfficialPointDisplay(wDisplays[i].mark, i == 0 && wIsFirst),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 55,
                      child: Text(
                        m.note.isNotEmpty ? m.note : '第${index + 1}試合',
                        style: TextStyle(
                          fontSize: AppFontSize.badge,
                          color: const Color(0x8A000000),
                          fontWeight: AppFontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (rTeam.isNotEmpty)
                            Text(
                              rTeam,
                              style: TextStyle(
                                fontSize: AppFontSize.nano,
                                color: const Color(0x8A000000),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            rName,
                            style: TextStyle(
                              fontWeight: rWin
                                  ? AppFontWeight.black
                                  : AppFontWeight.bold,
                              color: rWin
                                  ? AppKendoColors.hansokuRed
                                  : textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ViewerPointBoxCell(
                      pts: redPts,
                      isWinner: rWin,
                      isRed: true,
                      isDark: isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        isDraw ? '✕' : '-',
                        style: TextStyle(
                          color: context.appColors.subTextColor,
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.subhead,
                        ),
                      ),
                    ),
                    ViewerPointBoxCell(
                      pts: whitePts,
                      isWinner: wWin,
                      isRed: false,
                      isDark: isDark,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (wTeam.isNotEmpty)
                            Text(
                              wTeam,
                              style: TextStyle(
                                fontSize: AppFontSize.nano,
                                color: const Color(0x8A000000),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            wName,
                            style: TextStyle(
                              fontWeight: wWin
                                  ? AppFontWeight.black
                                  : AppFontWeight.bold,
                              color: wWin
                                  ? AppKendoColors.hansokuRed
                                  : textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
