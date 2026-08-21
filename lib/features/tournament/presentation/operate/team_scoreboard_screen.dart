import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_daihyo_handler.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_table_builder.dart';

import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/name_formatter.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

export 'components/team_scoreboard/team_scoreboard_table_builder.dart'
    show TeamPointDisplay;

class TeamScoreboardScreen extends ConsumerWidget {
  final String? groupName;
  final List<MatchModel>? matches;

  const TeamScoreboardScreen({super.key, this.groupName, this.matches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String safeDecodeComponent(String? input) {
      if (input == null) return '';
      try {
        return Uri.decodeComponent(input);
      } catch (_) {
        return input;
      }
    }

    final decodedGroupName = safeDecodeComponent(groupName);
    List<MatchModel> teamMatches = matches ?? [];
    final urlTournamentId = GoRouterState.of(
      context,
    ).uri.queryParameters['tournamentId'];

    final allMatches = ref.watch(matchListProvider);
    final asyncMatches = (urlTournamentId != null && urlTournamentId.isNotEmpty)
        ? ref.watch(matchListByTournamentProvider(urlTournamentId))
        : null;

    if (matches == null && decodedGroupName.isNotEmpty) {
      teamMatches = allMatches
          .where(
            (m) => m.groupName == decodedGroupName || m.id == decodedGroupName,
          )
          .toList();

      if (teamMatches.isEmpty && asyncMatches != null) {
        if (asyncMatches.isLoading &&
            (asyncMatches.valueOrNull == null ||
                asyncMatches.valueOrNull!.isEmpty)) {
          return Scaffold(
            backgroundColor: context.appColors.scaffoldBackground,
            appBar: const AppHeader(title: 'スコアボード'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        teamMatches = (asyncMatches.value ?? [])
            .where(
              (m) =>
                  m.groupName == decodedGroupName || m.id == decodedGroupName,
            )
            .toList();
      }
    }

    if (teamMatches.isEmpty) {
      return const Scaffold(body: Center(child: Text('データがありません')));
    }

    final firstMatch = teamMatches.first;
    if (firstMatch.isKachinuki || (firstMatch.rule?.isKachinuki ?? false)) {
      return KachinukiScoreboardScreen(groupName: firstMatch.groupName ?? '');
    }

    teamMatches.sort((a, b) => a.order.compareTo(b.order));

    final isDaihyoAllowed =
        teamMatches.first.rule?.hasRepresentativeMatch ?? true;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? const Color(0xFF1C1C1E)
        : context.appColors.cardBackground;
    final borderColor = isDark
        ? const Color(0xFF2C2C2E)
        : context.appColors.separatorColor;

    final redTeam = _cleanName(teamMatches.first.redName, true);
    final whiteTeam = _cleanName(teamMatches.first.whiteName, true);

    final result = TeamMatchCalculator.calculate(teamMatches);

    final matchNote = teamMatches
        .map((m) => m.note)
        .firstWhere(
          (n) => n.isNotEmpty && !n.contains('[SUMMARY]'),
          orElse: () => '',
        );

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          title: decodedGroupName.isNotEmpty ? decodedGroupName : '団体戦スコアボード',
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (matchNote.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3F51B5).withValues(alpha: 0.2)
                        : const Color(0xFF3F51B5),
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3F51B5)
                          : const Color(0xFF3F51B5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          matchNote,
                          style: TextStyle(
                            fontSize: AppFontSize.bodyMedium,
                            fontWeight: AppFontWeight.bold,
                            color: isDark
                                ? const Color(0xFF3F51B5)
                                : const Color(0xFF3F51B5),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: AppRadius.large,
                    border: isDark
                        ? null
                        : Border.all(color: borderColor, width: 1.0),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.large,
                    child: Stack(
                      children: [
                        Table(
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: borderColor, width: 0.5),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(2.0),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(1.2),
                            4: FlexColumnWidth(2.0),
                          },
                          children: [
                            TeamScoreboardTableBuilder.buildHeaderRow(
                              redTeam,
                              whiteTeam,
                              isDark,
                            ),
                            ...teamMatches.map(
                              (m) => TeamScoreboardTableBuilder.buildMatchRow(
                                m,
                                context,
                                isDark,
                                teamMatches
                                    .map(
                                      (x) => NameFormatter.parse(
                                        x.redName,
                                      )['last']!,
                                    )
                                    .where((s) => s.isNotEmpty)
                                    .toList(),
                                teamMatches
                                    .map(
                                      (x) => NameFormatter.parse(
                                        x.whiteName,
                                      )['last']!,
                                    )
                                    .where((s) => s.isNotEmpty)
                                    .toList(),
                              ),
                            ),
                            TeamScoreboardTableBuilder.buildTotalRow(
                              result,
                              isDark,
                            ),
                          ],
                        ),
                        if (teamMatches.any(
                          (m) => m.note.contains('[SUMMARY]'),
                        ))
                          Positioned.fill(
                            top: 40,
                            child: Container(
                              color: isDark
                                  ? AppKendoColors.pureBlack.withValues(
                                      alpha: 0.3,
                                    )
                                  : AppKendoColors.pureWhite.withValues(
                                      alpha: 0.6,
                                    ),

                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.appColors.cardBackground,
                                    borderRadius: AppRadius.small,
                                    border: Border.all(
                                      color: context.appColors.separatorColor,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppKendoColors.pureBlack
                                            .withValues(alpha: 0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '※簡易入力された結果です\n（詳細スコアはありません）',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: AppFontSize.bodySmall,
                                      fontWeight: AppFontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFFFFFFFF)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: (result.isTie && isDaihyoAllowed)
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          TeamScoreboardDaihyoHandler.handleAddDaihyo(
                            context: context,
                            ref: ref,
                            teamMatches: teamMatches,
                            redTeam: redTeam,
                            whiteTeam: whiteTeam,
                            isDark: isDark,
                          ),
                      icon: const Icon(
                        Icons.add,
                        color: AppKendoColors.pureWhite,
                      ),
                      label: const Text(
                        '代表戦を追加する',
                        style: TextStyle(
                          fontSize: AppFontSize.subhead,
                          fontWeight: AppFontWeight.bold,
                          color: AppKendoColors.pureWhite,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppKendoColors.hansokuRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.large,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _cleanName(String n, bool team) {
    if (!n.contains(':')) {
      return team ? 'チーム' : n;
    }
    return team
        ? n.split(':').first.trim()
        : n.split(':').last.replaceAll(')', '').trim();
  }
}
