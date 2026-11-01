import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
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

    final canvasWidth = 70.0 + (totalCols * 50.0) + 40.0;

    final engine = KendoRuleEngine();
    final projections = matches.map((m) {
      final analysis = engine.analyzeHistory(m.events, m, m.rule);
      return MatchProjectionMapper.toProjection(m, analysis);
    }).toList();

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: themeColors.separatorColor),
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
                Builder(
                  builder: (context) {
                    final scene = KendoSceneHelper.detectScene(firstMatch);
                    if (scene == KendoMatchScene.honsen) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: KendoSceneBadge(scene: scene),
                    );
                  },
                ),
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
              color: cardColor,
              width: canvasWidth < MediaQuery.of(context).size.width
                  ? MediaQuery.of(context).size.width
                  : canvasWidth,
              height: 250,
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
