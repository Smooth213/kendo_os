import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 公式記録画面の勝ち抜き戦ブラケットカード
class OfficialRecordKachinukiCard extends StatelessWidget {
  final List<MatchModel> matches;
  final bool isDark;
  final WidgetRef ref;

  const OfficialRecordKachinukiCard({
    super.key,
    required this.matches,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    final firstMatch = matches.first;
    final note = firstMatch.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();
    final rTeam = firstMatch.redName.contains(':')
        ? firstMatch.redName.split(':').first.trim()
        : firstMatch.redName;
    final wTeam = firstMatch.whiteName.contains(':')
        ? firstMatch.whiteName.split(':').first.trim()
        : firstMatch.whiteName;

    String titleText = '【勝ち抜き戦】 $rTeam vs $wTeam';
    if (cleanNote.isNotEmpty && !cleanNote.contains('勝ち抜き戦')) {
      titleText += ' ($cleanNote)';
    }

    final int redRem = matches.last.redRemaining.length;
    final int whiteRem = matches.last.whiteRemaining.length;
    final int maxRem = redRem > whiteRem ? redRem : whiteRem;
    final int totalCols = matches.length + maxRem;

    final canvasWidth = 60.0 + (totalCols * 60.0) + 120.0;

    final engine = KendoRuleEngine();
    final projections = matches.map((m) {
      final analysis = engine.analyzeHistory(m.events, m, m.rule);
      return MatchProjectionMapper.toProjection(m, analysis);
    }).toList();

    final scenePrefix = TeamProgressHelper.getScenePrefix(firstMatch);

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(
          color: isDark ? const Color(0xFF38383A) : const Color(0x33000000),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: isDark
                ? const Color(0xFF3F51B5).withValues(alpha: 0.4)
                : const Color(0xFF3F51B5),
            width: double.infinity,
            child: Row(
              children: [
                if (scenePrefix.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final isMoushiawase = scenePrefix.contains('申合せ');
                      final badgeColor = isMoushiawase
                          ? context.appColors.warningColor
                          : AppKendoColors.pureWhite;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.subValue,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.2),
                            borderRadius: AppRadius.sub,
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            scenePrefix,
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                Expanded(
                  child: Text(
                    titleText,
                    style: const TextStyle(
                      fontWeight: AppFontWeight.bold,
                      color: AppKendoColors.pureWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: isDark
                  ? context.appColors.cardBackground
                  : context.appColors.textColor,
              width: canvasWidth < MediaQuery.of(context).size.width
                  ? MediaQuery.of(context).size.width
                  : canvasWidth,
              height: 520,
              child: CustomPaint(
                painter: KachinukiBracketPainter(
                  matches: projections,
                  isDark: isDark,
                  ref: ref,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
