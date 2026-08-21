import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/presentation/providers/match_view_model_provider.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_kachinuki_record_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_league_grid_table.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_record_action_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_record_export_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_team_score_table.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';

final isExportingProvider = StateProvider.autoDispose<bool>((ref) => false);

class BunaiksenOfficialRecordScreen extends ConsumerWidget {
  const BunaiksenOfficialRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExporting = ref.watch(isExportingProvider);
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final viewDate = ref.watch(bunaiksenViewDateProvider);
    final tournamentId = 'bunaiksen_${DateFormat('yyyyMMdd').format(viewDate)}';
    final tName = '部内戦';
    final tDate = DateFormat('yyyy年MM月dd日').format(viewDate);

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');
    final cardColor = themeColors.cardBackground;
    final headerTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : themeColors.primaryAccent;

    final categoryGroups = ref.watch(
      bunaiksenRecordCategoryGroupsProvider(tournamentId),
    );

    if (categoryGroups.isEmpty) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: AppKendoColors.transparent,
          appBar: AppHeader(
            backgroundColor: enableLiquidGlass
                ? AppKendoColors.transparent
                : cardColor,
            foregroundColor: headerTextColor,
            title: '成績一覧',
            elevation: 0,
            centerTitle: true,
          ),
          body: const Center(
            child: Text(
              'この日の記録データはありません',
              style: TextStyle(color: AppKendoColors.grey),
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
            backgroundColor: enableLiquidGlass
                ? AppKendoColors.transparent
                : cardColor,
            foregroundColor: headerTextColor,
            title: '${DateFormat('yyyy/MM/dd').format(viewDate)} 成績',
            elevation: 0,
            centerTitle: true,
            bottom: TabBar(
              isScrollable: true,
              labelColor: headerTextColor,
              unselectedLabelColor: AppKendoColors.grey,
              indicatorColor: themeColors.primaryAccent,
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

              // 統合された個人戦がある場合、特殊なキーで登録
              if (individualMergedList.isNotEmpty) {
                individualMergedList.sort((a, b) => a.order.compareTo(b.order));
                mergedGroups['__merged_individual__'] = individualMergedList;
              }

              final sortedGroupKeys = mergedGroups.keys.toList()..sort();

              return Column(
                children: [
                  // 共有・印刷アクションバー
                  BunaiksenRecordActionBar(
                    cardColor: cardColor,
                    isDark: isDark,
                    isExporting: isExporting,
                    onPrintPdf: () => BunaiksenRecordExportHelper.handleExport(
                      context: context,
                      ref: ref,
                      isExportingController: ref.read(
                        isExportingProvider.notifier,
                      ),
                      cat: cat,
                      groupsMap: mergedGroups,
                      sortedGroupKeys: sortedGroupKeys,
                      isPdf: true,
                      tName: tName,
                      tDate: tDate,
                    ),
                    onShareImage: () =>
                        BunaiksenRecordExportHelper.handleExport(
                          context: context,
                          ref: ref,
                          isExportingController: ref.read(
                            isExportingProvider.notifier,
                          ),
                          cat: cat,
                          groupsMap: mergedGroups,
                          sortedGroupKeys: sortedGroupKeys,
                          isPdf: false,
                          tName: tName,
                          tDate: tDate,
                        ),
                  ),
                  // 記録コンテンツ
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: sortedGroupKeys.length,
                      itemBuilder: (context, index) {
                        final groupName = sortedGroupKeys[index];
                        final bouts = mergedGroups[groupName]!
                          ..sort((a, b) => a.order.compareTo(b.order));

                        // 1. 勝ち抜き戦の描画
                        if (bouts.isNotEmpty && bouts.first.isKachinuki) {
                          return BunaiksenKachinukiRecordCard(
                            matches: bouts,
                            isDark: isDark,
                            ref: ref,
                          );
                        }

                        // 2. リーグ戦の描画
                        if (bouts.isNotEmpty &&
                            bouts.any((m) => m.note.contains('[リーグ戦]'))) {
                          return _buildLeagueSection(
                            context,
                            ref,
                            groupName,
                            bouts,
                            cardColor,
                            isDark,
                          );
                        }

                        // 3. 通常の団体戦・個人戦の描画
                        if (bouts.isNotEmpty &&
                            bouts.any(
                              (m) =>
                                  m.matchType == 'individual' ||
                                  m.matchType == '選手' ||
                                  m.matchType.contains('個人戦'),
                            )) {
                          return BunaiksenIndividualMatchesList(
                            groupName: groupName,
                            matches: bouts,
                            cardColor: cardColor,
                            isDark: isDark,
                          );
                        } else {
                          return BunaiksenTeamScoreTable(
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
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ★ リーグ戦セクションの描画（公式仕様：個人戦リスト対応版）
  Widget _buildLeagueSection(
    BuildContext context,
    WidgetRef ref,
    String groupName,
    List<MatchModel> matches,
    Color cardColor,
    bool isDark,
  ) {
    final isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦') ||
          (!m.redName.contains(':') && !m.whiteName.contains(':')),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        BunaiksenLeagueGridTable(
          groupName: groupName,
          matches: matches,
          cardColor: cardColor,
          isDark: isDark,
          buildScoreTableCallback: (matchupName, bouts) =>
              BunaiksenTeamScoreTable(
                groupName: matchupName,
                matches: bouts,
                cardColor: AppKendoColors.transparent,
                isDark: isDark,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._groupMatchesByMatchup(matches).entries.map((e) {
          return isIndiv
              ? BunaiksenIndividualMatchesList(
                  groupName: e.key,
                  matches: e.value,
                  cardColor: cardColor,
                  isDark: isDark,
                )
              : BunaiksenTeamScoreTable(
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
