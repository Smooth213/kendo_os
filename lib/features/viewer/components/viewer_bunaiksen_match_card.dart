import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_status_badge.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 部内戦観客用 試合カードコンポーネント
class ViewerBunaiksenMatchCard extends StatelessWidget {
  final MatchModel match;
  final int index;
  final String tournamentId;
  final String dojoId;

  const ViewerBunaiksenMatchCard({
    super.key,
    required this.match,
    required this.index,
    required this.tournamentId,
    required this.dojoId,
  });

  static Widget buildScoreMarks(
    MatchModel match,
    bool isDark, {
    bool isFinished = true,
  }) {
    final textColor = isFinished
        ? (isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000))
        : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000));
    final iconColor = isFinished
        ? (isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000))
        : (isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000));

    if (match.redScore == 0 && match.whiteScore == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Icon(Icons.close, size: 18, color: iconColor),
      );
    }

    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(match.events, match, match.rule);

    final rDisplays = analysis.displays[Side.red] ?? [];
    final wDisplays = analysis.displays[Side.white] ?? [];

    String rMarksStr = rDisplays
        .map((d) {
          if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
          if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
          if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
          if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
          if (d.mark == '反') return '反';
          if (d.mark == '判定') return '判';
          if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
          return d.mark;
        })
        .join('');

    String wMarksStr = wDisplays
        .map((d) {
          if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
          if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
          if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
          if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
          if (d.mark == '反') return '反';
          if (d.mark == '判定') return '判';
          if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
          return d.mark;
        })
        .join('');

    final bool isDraw = match.redScore == match.whiteScore;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rMarksStr,
          style: TextStyle(
            fontSize: AppFontSize.header,
            fontWeight: AppFontWeight.bold,
            color: textColor,
            height: 1.1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(
            isDraw ? Icons.close : Icons.remove,
            size: 16,
            color: iconColor,
          ),
        ),
        Text(
          wMarksStr,
          style: TextStyle(
            fontSize: AppFontSize.header,
            fontWeight: AppFontWeight.bold,
            color: textColor,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasScore =
        match.redScore > 0 || match.whiteScore > 0 || match.events.isNotEmpty;
    final isPlaying = match.status == 'in_progress';
    final isFinished =
        (match.status == 'finished' ||
            match.status == 'approved' ||
            hasScore) &&
        !isPlaying;

    final Color bg = isFinished
        ? (isDark ? const Color(0xFF161618) : context.appColors.cardBackground)
        : (context.appColors.cardBackground);
    final Color textC = isFinished
        ? (isDark
              ? context.appColors.subTextColor
              : context.appColors.subTextColor)
        : (context.appColors.textColor);
    final Color noteC = isFinished
        ? (isDark ? const Color(0xFFFFFFFF) : context.appColors.subTextColor)
        : AppKendoColors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(
            color: isDark
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                : const Color(0xFF000000).withValues(alpha: 0.05),
          ),
        ),
        child: InkWell(
          key: Key('viewer_match_card_${match.id}'),
          borderRadius: AppRadius.large,
          onTap: () {
            context.push(
              '/viewer/${match.id}?role=viewer&tournamentId=$tournamentId&dojoId=$dojoId',
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        match.note.isNotEmpty ? match.note : '部内稽古',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: noteC,
                          fontWeight: AppFontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: MatchStatusBadge(
                        isPlaying: isPlaying,
                        isFinished: isFinished,
                        isDark: isDark,
                      ),
                    ),
                    Text(
                      '第${index + 1}試合',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: noteC,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.redName,
                        style: TextStyle(
                          fontSize: AppFontSize.subhead,
                          fontWeight: AppFontWeight.bold,
                          color: textC,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: isFinished
                          ? buildScoreMarks(
                              match,
                              isDark,
                              isFinished: isFinished,
                            )
                          : Text(
                              'VS',
                              style: TextStyle(
                                fontSize: AppFontSize.subhead,
                                fontWeight: AppFontWeight.bold,
                                color: textC,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Text(
                        match.whiteName,
                        style: TextStyle(
                          fontSize: AppFontSize.subhead,
                          fontWeight: AppFontWeight.bold,
                          color: textC,
                        ),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
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
