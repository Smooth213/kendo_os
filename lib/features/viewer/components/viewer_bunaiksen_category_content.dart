import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/components/official_record_action_button.dart';
import 'package:kendo_os/features/viewer/components/viewer_bunaiksen_score_table_card.dart';
import 'package:kendo_os/features/viewer/components/viewer_individual_matches_list_card.dart';
import 'package:kendo_os/features/viewer/components/viewer_kachinuki_record_card.dart';
import 'package:kendo_os/features/viewer/components/viewer_league_grid_table_card.dart';
import 'package:kendo_os/features/viewer/services/viewer_bunaiksen_export_service.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 観客用 部内戦 カテゴリ別記録コンテンツ（純粋UIコンポーネント）
class ViewerBunaiksenCategoryContent extends ConsumerWidget {
  final String category;
  final Map<String, List<MatchModel>> groupsMap;
  final Color cardColor;
  final AppThemeColors themeColors;
  final bool isDark;
  final bool isExporting;
  final StateController<bool> isExportingController;
  final String tDate;
  final ViewerBunaiksenExportService exportService;

  const ViewerBunaiksenCategoryContent({
    super.key,
    required this.category,
    required this.groupsMap,
    required this.cardColor,
    required this.themeColors,
    required this.isDark,
    required this.isExporting,
    required this.isExportingController,
    required this.tDate,
    required this.exportService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final sortedGroupKeys = mergedGroups.keys.toList()..sort();

    return Column(
      children: [
        // 共有・印刷アクションバー
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border(
              bottom: BorderSide(color: context.appColors.separatorColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OfficialRecordActionButton(
                  icon: Icons.print,
                  label: 'PDF印刷',
                  color: context.appColors.textColor,
                  onTap: isExporting
                      ? null
                      : () => exportService.exportOfficialRecord(
                          context: context,
                          ref: ref,
                          category: category,
                          groupsMap: mergedGroups,
                          sortedGroupKeys: sortedGroupKeys,
                          isPdf: true,
                          isExportingController: isExportingController,
                          tournamentName: '部内戦',
                          tournamentDate: tDate,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OfficialRecordActionButton(
                  icon: Icons.ios_share,
                  label: '画像シェア',
                  color: themeColors.primaryAccent,
                  onTap: isExporting
                      ? null
                      : () => exportService.exportOfficialRecord(
                          context: context,
                          ref: ref,
                          category: category,
                          groupsMap: mergedGroups,
                          sortedGroupKeys: sortedGroupKeys,
                          isPdf: false,
                          isExportingController: isExportingController,
                          tournamentName: '部内戦',
                          tournamentDate: tDate,
                        ),
                ),
              ),
            ],
          ),
        ),
        // 記録コンテンツリスト
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: sortedGroupKeys.length,
            itemBuilder: (context, index) {
              final groupName = sortedGroupKeys[index];
              final bouts = mergedGroups[groupName]!
                ..sort((a, b) => a.order.compareTo(b.order));

              if (bouts.isNotEmpty && bouts.first.isKachinuki) {
                return ViewerKachinukiRecordCard(
                  matches: bouts,
                  isDark: isDark,
                  ref: ref,
                );
              }

              if (bouts.isNotEmpty &&
                  bouts.any((m) => m.note.contains('[リーグ戦]'))) {
                return _buildLeagueSection(context, groupName, bouts);
              }

              if (bouts.isNotEmpty &&
                  bouts.any(
                    (m) =>
                        m.matchType == 'individual' ||
                        m.matchType == '選手' ||
                        m.matchType.contains('個人戦'),
                  )) {
                return ViewerIndividualMatchesListCard(
                  groupName: groupName,
                  matches: bouts,
                  cardColor: cardColor,
                  isDark: isDark,
                );
              } else {
                return ViewerBunaiksenScoreTableCard(
                  groupName: groupName,
                  matches: bouts,
                  cardColor: cardColor,
                  isDark: isDark,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueSection(
    BuildContext context,
    String groupName,
    List<MatchModel> matches,
  ) {
    final isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦') ||
          (!m.redName.contains(':') && !m.whiteName.contains(':')),
    );

    final groupedMap = _groupMatchesByMatchup(matches);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        ViewerLeagueGridTableCard(
          groupName: groupName,
          matches: matches,
          cardColor: cardColor,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.lg),
        ...groupedMap.entries.map((e) {
          return isIndiv
              ? ViewerIndividualMatchesListCard(
                  groupName: e.key,
                  matches: e.value,
                  cardColor: cardColor,
                  isDark: isDark,
                )
              : ViewerBunaiksenScoreTableCard(
                  groupName: e.key,
                  matches: e.value,
                  cardColor: cardColor,
                  isDark: isDark,
                );
        }),
      ],
    );
  }

  Map<String, List<MatchModel>> _groupMatchesByMatchup(
    List<MatchModel> matches,
  ) {
    final Map<String, List<MatchModel>> res = {};
    for (var m in matches) {
      final t1 = m.redName.split(':').first.trim();
      final t2 = m.whiteName.split(':').first.trim();
      final key = '$t1 vs $t2';
      res.putIfAbsent(key, () => []).add(m);
    }
    return res;
  }
}
