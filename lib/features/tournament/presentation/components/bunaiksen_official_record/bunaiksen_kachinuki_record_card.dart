import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 部内戦公式記録画面 勝ち抜き戦対戦カード
class BunaiksenKachinukiRecordCard extends StatelessWidget {
  final List<MatchModel> matches;
  final bool isDark;
  final WidgetRef ref;

  const BunaiksenKachinukiRecordCard({
    super.key,
    required this.matches,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    final first = matches.first;
    final rTeam = first.redName.split(':').first.trim();
    final wTeam = first.whiteName.split(':').first.trim();
    final canvasWidth = 60.0 + ((matches.length + 5) * 60.0);

    final engine = KendoRuleEngine();
    final projections = matches.map((m) {
      final analysis = engine.analyzeHistory(m.events, m, m.rule);
      return MatchProjectionMapper.toProjection(m, analysis);
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(
          color: isDark
              ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
              : const Color(0x33000000),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: isDark
                ? const Color(0xFF3F51B5).withValues(alpha: 0.4)
                : const Color(0xFF3F51B5),
            width: double.infinity,
            child: Text(
              '勝ち抜き戦：$rTeam vs $wTeam',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                color: isDark
                    ? const Color(0xFF3F51B5)
                    : const Color(0xFF3F51B5),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              width: canvasWidth,
              height: 480,
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
