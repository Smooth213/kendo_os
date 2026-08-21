import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_expedition_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_kachinuki_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_league_section.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_score_table_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';

final isExportingProvider = StateProvider.autoDispose<bool>((ref) => false);

class OfficialRecordScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const OfficialRecordScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<OfficialRecordScreen> createState() =>
      _OfficialRecordScreenState();
}

class _OfficialRecordScreenState extends ConsumerState<OfficialRecordScreen> {
  @override
  Widget build(BuildContext context) {
    final tournamentId = widget.tournamentId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExporting = ref.watch(isExportingProvider);

    final permissions = ref.watch(permissionProvider);
    final String screenTitle = permissions.isReadOnly ? '全試合スコア' : '大会 公式記録';

    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));
    final tName = tournamentAsync.value?.name;
    final tDate = tournamentAsync.value != null
        ? DateFormat('yyyy年MM月dd日').format(tournamentAsync.value!.date)
        : null;
    final tVenue = tournamentAsync.value?.venue;

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;
    final headerTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : context.appColors.primaryAccent;

    final registeredTeamsAsync = ref.watch(
      registeredTeamsProvider(tournamentId),
    );
    final registeredTeams = registeredTeamsAsync.value ?? [];
    final registeredTeamNames = registeredTeams
        .map((t) => t.teamName.trim())
        .where((n) => n.isNotEmpty)
        .toSet();
    final registeredPlayerNames = registeredTeams
        .expand((t) => t.playerNames)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet();

    final matchesForThisTournament = ref.watch(
      matchListProvider.select(
        (list) => list.where((m) => m.tournamentId == tournamentId).toList(),
      ),
    );

    final categoryGroups = <String, Map<String, List<MatchModel>>>{};
    for (var m in matchesForThisTournament) {
      if (m.groupName == null || m.groupName!.isEmpty) continue;
      final cat = (m.category != null && m.category!.isNotEmpty)
          ? m.category!
          : '一般';
      categoryGroups.putIfAbsent(cat, () => {});
      categoryGroups[cat]!.putIfAbsent(m.groupName!, () => []).add(m);
    }

    if (categoryGroups.isEmpty) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            title: screenTitle,
            backgroundColor: cardColor,
            actions: [
              ManualHelpButton(
                manualPath: 'docs/manuals/operator/official_record.md',
                color: headerTextColor,
              ),
            ],
          ),
          body: Center(
            child: Text(
              '記録データがありません',
              style: TextStyle(color: context.appColors.textColor),
            ),
          ),
        ),
      );
    }

    final categories = categoryGroups.keys.toList();

    return DefaultTabController(
      length: categories.length,
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            title: screenTitle,
            backgroundColor: cardColor,
            actions: [
              ManualHelpButton(
                manualPath: 'docs/manuals/operator/official_record.md',
                color: headerTextColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.sm,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: Icon(
                    Icons.home,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : context.appColors.primaryAccent,
                    size: 16,
                  ),
                  label: Text(
                    'トップへ',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : context.appColors.primaryAccent,
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.small,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? context.appColors.textColor.withValues(alpha: 0.15)
                        : themeColors.softAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.round,
                    ),
                  ),
                ),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              labelColor: headerTextColor,
              unselectedLabelColor: isDark
                  ? const Color(0xFFFFFFFF)
                  : const Color(0x8A000000),
              indicatorColor: const Color(0xFF3F51B5),
              tabs: categories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),
          body: TabBarView(
            children: categories.map((cat) {
              final groupsMap = categoryGroups[cat]!;

              // 個人戦グループを統合するためのマップ
              final mergedGroups = <String, List<MatchModel>>{};
              final List<MatchModel> individualMergedList = [];
              final uuidRegex = RegExp(
                r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
              );

              groupsMap.forEach((key, matches) {
                final isIndiv = matches.any(
                  (m) =>
                      m.matchType == 'individual' ||
                      m.matchType == '選手' ||
                      m.matchType.contains('個人戦'),
                );
                final isLeague = matches.any((m) => m.note.contains('[リーグ戦]'));

                // 通常の個人戦（リーグ戦以外）かつ、ID形式のグループ名を統合対象とする
                if (isIndiv &&
                    !isLeague &&
                    (uuidRegex.hasMatch(key) || key.length > 20)) {
                  individualMergedList.addAll(matches);
                } else {
                  mergedGroups[key] = matches;
                }
              });

              if (individualMergedList.isNotEmpty) {
                individualMergedList.sort((a, b) => a.order.compareTo(b.order));
                mergedGroups['__merged_individual__'] = individualMergedList;
              }

              final sortedGroupKeys = mergedGroups.keys.toList()
                ..sort((a, b) {
                  final aLast = _getLastTimestamp(mergedGroups[a]!);
                  final bLast = _getLastTimestamp(mergedGroups[b]!);
                  return aLast.compareTo(bLast);
                });

              final categoryMatches = matchesForThisTournament.where((m) {
                final cName = (m.category != null && m.category!.isNotEmpty)
                    ? m.category!
                    : '一般';
                return cName == cat;
              }).toList();

              final categoryRegisteredTeams = registeredTeams
                  .where((t) => t.category == cat)
                  .toList();

              final Set<String> categoryRegisteredTeamNames;
              if (categoryRegisteredTeams.isNotEmpty) {
                categoryRegisteredTeamNames = categoryRegisteredTeams
                    .map((t) => t.teamName.trim())
                    .where((n) => n.isNotEmpty)
                    .toSet();
              } else if (registeredTeamNames.isNotEmpty) {
                final matchedInCat = registeredTeamNames.where((tName) {
                  return categoryMatches.any((m) {
                    final r = m.redName.contains(':')
                        ? m.redName.split(':').first.trim()
                        : m.redName.trim();
                    final w = m.whiteName.contains(':')
                        ? m.whiteName.split(':').first.trim()
                        : m.whiteName.trim();
                    return r == tName || w == tName;
                  });
                }).toSet();
                categoryRegisteredTeamNames = matchedInCat;
              } else {
                categoryRegisteredTeamNames = <String>{};
              }

              final Set<String> categoryRegisteredPlayerNames;
              if (categoryRegisteredTeams.isNotEmpty) {
                categoryRegisteredPlayerNames = categoryRegisteredTeams
                    .expand((t) => t.playerNames)
                    .map((p) => p.trim())
                    .where((p) => p.isNotEmpty)
                    .toSet();
              } else if (registeredPlayerNames.isNotEmpty) {
                categoryRegisteredPlayerNames = registeredPlayerNames;
              } else {
                categoryRegisteredPlayerNames = <String>{};
              }

              return Column(
                children: [
                  OfficialRecordExpeditionSummaryCard(
                    matches: categoryMatches,
                    isDark: isDark,
                    registeredTeamNames: categoryRegisteredTeamNames,
                    registeredPlayerNames: categoryRegisteredPlayerNames,
                  ),
                  OfficialRecordExportBar(
                    isExporting: isExporting,
                    isDark: isDark,
                    onPdfPressed: () => OfficialRecordExportHelper.handleExport(
                      context: context,
                      ref: ref,
                      isExportingController: ref.read(
                        isExportingProvider.notifier,
                      ),
                      sortedGroupKeys: sortedGroupKeys,
                      mergedGroups: mergedGroups,
                      cat: cat,
                      type: 'pdf',
                      tName: tName,
                      tDate: tDate,
                      tVenue: tVenue,
                    ),
                    onImagePressed: () =>
                        OfficialRecordExportHelper.handleExport(
                          context: context,
                          ref: ref,
                          isExportingController: ref.read(
                            isExportingProvider.notifier,
                          ),
                          sortedGroupKeys: sortedGroupKeys,
                          mergedGroups: mergedGroups,
                          cat: cat,
                          type: 'image',
                          tName: tName,
                          tDate: tDate,
                          tVenue: tVenue,
                        ),
                    onCsvPressed: () => OfficialRecordExportHelper.handleExport(
                      context: context,
                      ref: ref,
                      isExportingController: ref.read(
                        isExportingProvider.notifier,
                      ),
                      sortedGroupKeys: sortedGroupKeys,
                      mergedGroups: mergedGroups,
                      cat: cat,
                      type: 'csv',
                      tName: tName,
                      tDate: tDate,
                      tVenue: tVenue,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: sortedGroupKeys.length,
                      itemBuilder: (context, index) {
                        final groupName = sortedGroupKeys[index];
                        final matches = mergedGroups[groupName]!
                          ..sort((a, b) => a.order.compareTo(b.order));

                        if (matches.isNotEmpty && matches.first.isKachinuki) {
                          return OfficialRecordKachinukiCard(
                            matches: matches,
                            isDark: isDark,
                            ref: ref,
                          );
                        } else if (matches.isNotEmpty &&
                            matches.any((m) => m.note.contains('[リーグ戦]'))) {
                          final ownTeams =
                              ref.watch(customTeamNamesProvider).value ?? [];
                          return OfficialRecordLeagueSection(
                            groupName: groupName,
                            matches: matches,
                            cardColor: cardColor,
                            isDark: isDark,
                            ownTeams: ownTeams,
                            scoreTableBuilder:
                                (name, bouts, {cardColor, isDark = false}) =>
                                    OfficialRecordScoreTableBuilder.buildScoreTable(
                                      name,
                                      bouts,
                                      cardColor: cardColor,
                                      isDark: isDark,
                                    ),
                          );
                        } else if (matches.isNotEmpty &&
                            matches.any(
                              (m) =>
                                  m.matchType == 'individual' ||
                                  m.matchType == '選手' ||
                                  m.matchType.contains('個人戦'),
                            )) {
                          return OfficialRecordIndividualMatchesList(
                            groupName: groupName,
                            matches: matches,
                            cardColor: cardColor,
                            isDark: isDark,
                            applySort: true,
                          );
                        } else {
                          return OfficialRecordScoreTableBuilder.buildScoreTable(
                            groupName,
                            matches,
                            cardColor: cardColor,
                            isDark: isDark,
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  DateTime _getLastTimestamp(List<MatchModel> ms) {
    DateTime last = DateTime.fromMillisecondsSinceEpoch(0);
    for (var m in ms) {
      if (m.events.isNotEmpty && m.events.last.timestamp.isAfter(last)) {
        last = m.events.last.timestamp;
      }
    }
    return last;
  }
}
