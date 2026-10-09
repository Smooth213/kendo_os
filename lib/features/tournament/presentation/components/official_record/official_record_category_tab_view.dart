import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_expedition_summary_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_export_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_kachinuki_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_league_section.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_score_table_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 公式記録画面のカテゴリ別タブ内コンテンツビュー
class OfficialRecordCategoryTabView extends StatelessWidget {
  final String cat;
  final List<MatchModel> categoryMatches;
  final Map<String, List<MatchModel>> mergedGroups;
  final List<String> sortedGroupKeys;
  final Set<String> categoryRegisteredTeamNames;
  final Set<String> categoryRegisteredPlayerNames;
  final List<({String categoryName, List<Map<String, dynamic>> groupDataList})>
  allCategoryData;
  final bool isExporting;
  final String? exportingType;
  final bool isDark;
  final Color cardColor;
  final bool hasMultipleCategories;
  final OfficialRecordExportScope exportScope;
  final ValueChanged<OfficialRecordExportScope> onScopeChanged;
  final String? tName;
  final String? tDate;
  final String? tVenue;
  final bool isBottomSheet;
  final bool isReadOnly;
  final WidgetRef ref;
  final String highlightQuery;

  const OfficialRecordCategoryTabView({
    super.key,
    required this.cat,
    required this.categoryMatches,
    required this.mergedGroups,
    required this.sortedGroupKeys,
    required this.categoryRegisteredTeamNames,
    required this.categoryRegisteredPlayerNames,
    required this.allCategoryData,
    required this.isExporting,
    required this.exportingType,
    required this.isDark,
    required this.cardColor,
    required this.hasMultipleCategories,
    required this.exportScope,
    required this.onScopeChanged,
    required this.tName,
    required this.tDate,
    required this.tVenue,
    required this.isBottomSheet,
    required this.isReadOnly,
    required this.ref,
    this.highlightQuery = '',
  });

  void _handleExport(BuildContext context, String type) {
    if (exportScope == OfficialRecordExportScope.all) {
      OfficialRecordExportHelper.handleExportAll(
        context: context,
        ref: ref,
        isExportingController: ref.read(isExportingProvider.notifier),
        exportingTypeController: ref.read(exportingTypeProvider.notifier),
        allCategoryData: allCategoryData,
        type: type,
        tName: tName,
        tDate: tDate,
        tVenue: tVenue,
        isBottomSheet: isBottomSheet,
      );
    } else {
      OfficialRecordExportHelper.handleExport(
        context: context,
        ref: ref,
        isExportingController: ref.read(isExportingProvider.notifier),
        exportingTypeController: ref.read(exportingTypeProvider.notifier),
        sortedGroupKeys: sortedGroupKeys,
        mergedGroups: mergedGroups,
        cat: cat,
        type: type,
        tName: tName,
        tDate: tDate,
        tVenue: tVenue,
        isBottomSheet: isBottomSheet,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OfficialRecordExportBar(
          isExporting: isExporting,
          exportingType: exportingType,
          isDark: isDark,
          hasMultipleCategories: hasMultipleCategories,
          categoryName: cat,
          exportScope: exportScope,
          onScopeChanged: onScopeChanged,
          onPdfPressed: () => _handleExport(context, 'pdf'),
          onImagePressed: () => _handleExport(context, 'image'),
          onCsvPressed: () => _handleExport(context, 'csv'),
        ),
        if (!isReadOnly && !isBottomSheet)
          OfficialRecordExpeditionSummaryCard(
            matches: categoryMatches,
            isDark: isDark,
            registeredTeamNames: categoryRegisteredTeamNames,
            registeredPlayerNames: categoryRegisteredPlayerNames,
          ),
        Expanded(
          child: ListView.builder(
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
                final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
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
                            highlightQuery: highlightQuery,
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
                  highlightQuery: highlightQuery,
                );
              } else {
                return OfficialRecordScoreTableBuilder.buildScoreTable(
                  groupName,
                  matches,
                  cardColor: cardColor,
                  isDark: isDark,
                  highlightQuery: highlightQuery,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

final isExportingProvider = StateProvider.autoDispose<bool>((ref) => false);
final exportingTypeProvider = StateProvider.autoDispose<String?>((ref) => null);
