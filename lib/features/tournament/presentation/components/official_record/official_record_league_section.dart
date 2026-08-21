import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_league_grid_table.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 公式記録画面のリーグ戦描画セクション（星取表＋対戦カード別スコア詳細＋順位決定戦）
class OfficialRecordLeagueSection extends StatelessWidget {
  final String groupName;
  final List<MatchModel> matches;
  final Color cardColor;
  final bool isDark;
  final List<String> ownTeams;
  final Widget Function(
    String matchupName,
    List<MatchModel> bouts, {
    Color? cardColor,
    bool isDark,
  })
  scoreTableBuilder;

  const OfficialRecordLeagueSection({
    super.key,
    required this.groupName,
    required this.matches,
    required this.cardColor,
    required this.isDark,
    required this.ownTeams,
    required this.scoreTableBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final String leagueTitle = BunaiksenHelper.generateDescriptiveLeagueTitle(
      matches,
      ownTeams,
    );
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF3F51B5);

    // 通常の試合と決定戦を分離
    final normalMatches = matches
        .where((m) => !m.note.contains('[順位決定戦]'))
        .toList();
    final tieBouts = matches.where((m) => m.note.contains('[順位決定戦]')).toList();

    // 対戦カードごとのグルーピング（通常用）
    final boutsByMatchup = <String, List<MatchModel>>{};
    final matchupOrder = <String>[];
    for (var m in normalMatches) {
      final t1 = m.redName.split(':').first.trim();
      final t2 = m.whiteName.split(':').first.trim();
      final matchupName = '$t1 vs $t2';
      if (!boutsByMatchup.containsKey(matchupName)) {
        matchupOrder.add(matchupName);
        boutsByMatchup[matchupName] = [];
      }
      boutsByMatchup[matchupName]!.add(m);
    }

    // 対戦カードごとのグルーピング（順位決定戦用）
    final tieBoutsByMatchup = <String, List<MatchModel>>{};
    final tieMatchupOrder = <String>[];
    for (var m in tieBouts) {
      final t1 = m.redName.split(':').first.trim();
      final t2 = m.whiteName.split(':').first.trim();
      final matchupName = '$t1 vs $t2';
      if (!tieBoutsByMatchup.containsKey(matchupName)) {
        tieMatchupOrder.add(matchupName);
        tieBoutsByMatchup[matchupName] = [];
      }
      tieBoutsByMatchup[matchupName]!.add(m);
    }

    final isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl,
            bottom: AppSpacing.md,
            left: AppSpacing.sm,
          ),
          child: Text(
            '【リーグ戦】 $leagueTitle',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              color: textColor,
              fontSize: AppFontSize.subhead,
            ),
          ),
        ),

        // 1. 星取表（マトリックス）
        OfficialRecordLeagueGridTable(
          groupName: groupName,
          matches: matches,
          cardColor: cardColor,
          isDark: isDark,
          scoreTableBuilder: (name, bouts) => scoreTableBuilder(
            name,
            bouts,
            cardColor: AppKendoColors.transparent,
            isDark: isDark,
          ),
          individualListBuilder: (name, bouts) =>
              OfficialRecordIndividualMatchesList(
                groupName: name,
                matches: bouts,
                cardColor: AppKendoColors.transparent,
                isDark: isDark,
                applySort: false,
              ),
        ),

        const SizedBox(height: AppSpacing.xxl),
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.md),
          child: Text(
            '▼ 対戦カード別 スコア詳細',
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.body,
              color: AppKendoColors.grey,
            ),
          ),
        ),

        // 2. 詳細スコアの表示
        if (isIndiv)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: OfficialRecordIndividualMatchesList(
              groupName: '対戦スコア詳細',
              matches: normalMatches,
              cardColor: cardColor,
              isDark: isDark,
              applySort: false,
            ),
          )
        else
          ...matchupOrder.map((matchupName) {
            final bouts = boutsByMatchup[matchupName]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: scoreTableBuilder(
                matchupName,
                bouts,
                cardColor: cardColor,
                isDark: isDark,
              ),
            );
          }),

        // 3. 順位決定戦
        if (tieBouts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              '▼ 順位決定戦',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.body,
                color: AppKendoColors.orange,
              ),
            ),
          ),
          if (isIndiv)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: OfficialRecordIndividualMatchesList(
                groupName: '順位決定戦',
                matches: tieBouts,
                cardColor: isDark
                    ? const Color(0xFFFF9800).withValues(alpha: 0.1)
                    : const Color(0xFFFF9800),
                isDark: isDark,
                applySort: false,
              ),
            )
          else
            ...tieMatchupOrder.map((matchupName) {
              final bouts = tieBoutsByMatchup[matchupName]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: scoreTableBuilder(
                  matchupName,
                  bouts,
                  cardColor: isDark
                      ? const Color(0xFFFF9800).withValues(alpha: 0.1)
                      : const Color(0xFFFF9800),
                  isDark: isDark,
                ),
              );
            }),
        ],
        const SizedBox(height: 48),
      ],
    );
  }
}
