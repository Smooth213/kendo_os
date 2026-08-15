import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/pdf/pdf_service.dart' deferred as pdf_service;
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_view_model_provider.dart';
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/features/viewer/components/official_record_action_button.dart';
import 'package:kendo_os/features/viewer/components/viewer_kachinuki_record_card.dart';
import 'package:kendo_os/features/viewer/components/viewer_vertical_player_name_cell.dart';
import 'package:kendo_os/features/viewer/components/viewer_point_box_cell.dart';
import 'package:kendo_os/features/viewer/components/viewer_league_grid_table_card.dart';
import 'package:kendo_os/features/viewer/components/viewer_individual_matches_list_card.dart';

final isExportingProvider = StateProvider.autoDispose<bool>((ref) => false);

class ViewerBunaiksenOfficialRecordScreen extends ConsumerWidget {
  final String tournamentId;

  const ViewerBunaiksenOfficialRecordScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExporting = ref.watch(isExportingProvider);
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;

    // tournamentId から日付をパース (例: bunaiksen_20241010)
    String dateDisplay = '部内戦';
    String tDate = '';
    if (tournamentId.startsWith('bunaiksen_') && tournamentId.length == 18) {
      final dateStr = tournamentId.substring(10);
      if (dateStr.length == 8) {
        dateDisplay =
            '${dateStr.substring(0, 4)}/${dateStr.substring(4, 6)}/${dateStr.substring(6, 8)}';
        tDate =
            '${dateStr.substring(0, 4)}年${dateStr.substring(4, 6)}月${dateStr.substring(6, 8)}日';
      }
    }

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen_viewer');
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
            title: '成績一覧 (観戦)',
            elevation: 0,
            centerTitle: true,
            leading: GoRouter.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => context.pop(),
                  )
                : null,
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

    return PopScope(
      canPop: false,
      child: DefaultTabController(
        length: categories.length,
        child: LiquidBackground(
          child: Scaffold(
            backgroundColor: AppKendoColors.transparent,
            appBar: AppHeader(
              backgroundColor: enableLiquidGlass
                  ? AppKendoColors.transparent
                  : cardColor,
              foregroundColor: headerTextColor,
              title: '$dateDisplay 成績 (観戦)',
              elevation: 0,
              centerTitle: true,
              leading: GoRouter.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => context.pop(),
                    )
                  : null,
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
                  final isLeague = matches.any(
                    (m) => m.note.contains('[リーグ戦]'),
                  );

                  if (isIndiv &&
                      !isLeague &&
                      (uuidRegex.hasMatch(key) || key.length > 20)) {
                    individualMergedList.addAll(matches);
                  } else {
                    mergedGroups[key] = matches;
                  }
                });

                if (individualMergedList.isNotEmpty) {
                  // ★ 修正: 観客席側でも本部での並び替え変更を即座にシミュレート反映
                  individualMergedList.sort(
                    (a, b) => a.order.compareTo(b.order),
                  );
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
                          bottom: BorderSide(
                            color: context.appColors.separatorColor,
                          ),
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
                                  : () => _handleExport(
                                      context,
                                      ref,
                                      cat,
                                      mergedGroups,
                                      sortedGroupKeys,
                                      isPdf: true,
                                      tName: '部内戦',
                                      tDate: tDate,
                                    ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: OfficialRecordActionButton(
                              icon: Icons.share,
                              label: '画像シェア',
                              color: themeColors.primaryAccent,
                              onTap: isExporting
                                  ? null
                                  : () => _handleExport(
                                      context,
                                      ref,
                                      cat,
                                      mergedGroups,
                                      sortedGroupKeys,
                                      isPdf: false,
                                      tName: '部内戦',
                                      tDate: tDate,
                                    ),
                            ),
                          ),
                        ],
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

                          if (bouts.isNotEmpty && bouts.first.isKachinuki) {
                            return ViewerKachinukiRecordCard(
                              matches: bouts,
                              isDark: isDark,
                              ref: ref,
                            );
                          }

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
                            return _buildScoreTable(
                              groupName,
                              bouts,
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
      ),
    );
  }

  // --- ヘルパーWidget ---

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
        ViewerLeagueGridTableCard(
          groupName: groupName,
          matches: matches,
          cardColor: cardColor,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._groupMatchesByMatchup(matches).entries.map((e) {
          return isIndiv
              ? ViewerIndividualMatchesListCard(
                  groupName: e.key,
                  matches: e.value,
                  cardColor: cardColor,
                  isDark: isDark,
                )
              : _buildScoreTable(
                  e.key,
                  e.value,
                  cardColor: cardColor,
                  isDark: isDark,
                );
        }),
      ],
    );
  }

  Widget _buildScoreTable(
    String groupName,
    List<MatchModel> matches, {
    Color? cardColor,
    bool isDark = false,
  }) {
    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    String headerRed, headerWhite;
    headerRed = matches.first.redName.contains(':')
        ? matches.first.redName.split(':').first.trim()
        : matches.first.redName;
    headerWhite = matches.first.whiteName.contains(':')
        ? matches.first.whiteName.split(':').first.trim()
        : matches.first.whiteName;

    String sideLabelRed = '赤';
    String sideLabelWhite = '白';

    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0x33000000);
    final headerTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0x8A000000);
    final daihyoBgColor = isDark
        ? const Color(0xFFE53935).withValues(alpha: 0.15)
        : const Color(0xFFE53935);

    bool allFinished = matches.every((m) {
      final hasScore =
          (m.redScore as num).toInt() > 0 || (m.whiteScore as num).toInt() > 0;
      final isOfficial = m.status == 'approved' || m.status == 'finished';
      return isOfficial || hasScore;
    });

    String teamWinner = 'draw';
    int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
    MatchModel? daihyoMatch;

    for (var m in matches) {
      if (m.matchType == '代表戦') {
        daihyoMatch = m;
        continue;
      }
      final rs = (m.redScore as num).toInt();
      final ws = (m.whiteScore as num).toInt();
      rPts += rs;
      wPts += ws;
      if (rs > ws) {
        rWins++;
      } else if (ws > rs) {
        wWins++;
      }
    }

    if (rWins > wWins) {
      teamWinner = 'red';
    } else if (wWins > rWins) {
      teamWinner = 'white';
    } else if (rPts > wPts) {
      teamWinner = 'red';
    } else if (wPts > rPts) {
      teamWinner = 'white';
    } else if (daihyoMatch != null) {
      final rs = (daihyoMatch.redScore as num).toInt();
      final ws = (daihyoMatch.whiteScore as num).toInt();
      if (rs > ws) {
        teamWinner = 'red';
      } else if (ws > rs) {
        teamWinner = 'white';
      }
    }

    final bool isSummary = matches.any((m) => m.note.contains('[SUMMARY]'));

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                width: double.infinity,
                child: Text(
                  cleanNote.isNotEmpty
                      ? '【$cleanNote】 $headerRed vs $headerWhite'
                      : '$headerRed vs $headerWhite',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xDE000000),
                  ),
                ),
              ),
              Table(
                border: TableBorder.all(color: borderColor, width: 1),
                columnWidths: {
                  0: const FlexColumnWidth(1.2),
                  for (int i = 1; i <= matches.length; i++)
                    i: const FlexColumnWidth(1.0),
                  matches.length + 1: const FlexColumnWidth(0.8),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                    ),
                    children: [
                      const SizedBox.shrink(),
                      ...matches.map(
                        (m) => Container(
                          color: m.matchType == '代表戦'
                              ? daihyoBgColor
                              : AppKendoColors.transparent,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Text(
                                m.matchType,
                                style: TextStyle(
                                  fontSize: AppFontSize.badge,
                                  fontWeight: AppFontWeight.bold,
                                  color: m.matchType == '代表戦'
                                      ? (isDark
                                            ? const Color(0xFFE53935)
                                            : const Color(0xFFE53935))
                                      : (isDark
                                            ? const Color(0xFFFFFFFF)
                                            : const Color(0xDE000000)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(
                            '本/勝',
                            style: TextStyle(
                              fontSize: AppFontSize.badge,
                              color: headerTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildTeamRow(matches, true, sideLabelRed, isDark),
                  TableRow(
                    children: [
                      const SizedBox.shrink(),
                      ...matches.map((m) => _scoreCell(m, isDark, isSummary)),
                      _teamResultCell(teamWinner, isDark, allFinished),
                    ],
                  ),
                  _buildTeamRow(matches, false, sideLabelWhite, isDark),
                ],
              ),
            ],
          ),
          if (isSummary)
            Positioned.fill(
              top: 40,
              child: Container(
                color: isDark
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.3)
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF475569),
                      borderRadius: AppRadius.small,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0x33000000),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppKendoColors.pureBlack.withValues(
                            alpha: 0.1,
                          ),
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
                            : const Color(0xDE000000),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _teamResultCell(String winner, bool isDark, bool allFinished) {
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    final dividerColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0x33000000);

    return Container(
      height: 70,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (winner != 'draw' || !allFinished)
            Divider(color: dividerColor, thickness: 1, height: 0),

          if (allFinished) ...[
            if (winner == 'draw')
              Center(
                child: ViewerVerticalPlayerNameCell(
                  text: '引き分け',
                  isDark: isDark,
                ),
              )
            else
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        winner == 'red' ? '勝' : '負',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: winner == 'red'
                              ? (isDark
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFFE53935))
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        winner == 'white' ? '勝' : '負',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: winner == 'white'
                              ? (isDark
                                    ? const Color(0xFF2196F3)
                                    : const Color(0xFF2196F3))
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  TableRow _buildTeamRow(
    List<MatchModel> matches,
    bool isRed,
    String teamName,
    bool isDark,
  ) {
    return TableRow(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              teamName,
              style: TextStyle(
                color: isRed
                    ? (isDark
                          ? const Color(0xFFE53935)
                          : const Color(0xFFE53935))
                    : (isDark
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF2196F3)),
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.caption,
              ),
            ),
          ),
        ),
        ...matches.map((m) {
          final name = isRed ? m.redName : m.whiteName;
          final isDaihyo = m.matchType == '代表戦';

          if (name.contains('欠員')) {
            return Container(
              color: isDaihyo
                  ? (isDark
                        ? const Color(0xFFE53935).withValues(alpha: 0.15)
                        : const Color(0xFFE53935))
                  : Colors.transparent,
            );
          }

          final teamLastNames = matches
              .map((x) {
                final xName = isRed ? x.redName : x.whiteName;
                return BunaiksenHelper.parseName(xName)['last']!;
              })
              .where((s) => s.isNotEmpty)
              .toList();

          final parsed = BunaiksenHelper.parseName(name);
          final showInitial =
              teamLastNames.where((n) => n == parsed['last']).length > 1 &&
              parsed['first']!.isNotEmpty;

          return Container(
            color: isDaihyo
                ? (isDark
                      ? const Color(0xFFE53935).withValues(alpha: 0.15)
                      : const Color(0xFFE53935))
                : Colors.transparent,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.xs,
                ),
                child: ViewerVerticalPlayerNameCell(
                  text: parsed['last']!,
                  initial: showInitial ? parsed['first']!.substring(0, 1) : '',
                  isDark: isDark,
                ),
              ),
            ),
          );
        }),
        _summaryCell(matches, isRed, isDark),
      ],
    );
  }

  Widget _scoreCell(MatchModel m, bool isDark, bool isSummary) {
    if (isSummary) {
      return Container(height: 70, color: Colors.transparent);
    }
    final isDone = m.status == 'finished' || m.status == 'approved';
    final rScore = (m.redScore as num).toInt();
    final wScore = (m.whiteScore as num).toInt();
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;

    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(m.events, m, m.rule);
    final proj = MatchProjectionMapper.toProjection(m, analysis);
    final bool rIsFirst = proj.firstPointSide == 'red';
    final bool wIsFirst = proj.firstPointSide == 'white';

    final rDisplays = analysis.displays[Side.red] ?? [];
    final wDisplays = analysis.displays[Side.white] ?? [];

    final redPts = <OfficialPointDisplay>[];
    for (int i = 0; i < rDisplays.length; i++) {
      redPts.add(OfficialPointDisplay(rDisplays[i].mark, i == 0 && rIsFirst));
    }

    final whitePts = <OfficialPointDisplay>[];
    for (int i = 0; i < wDisplays.length; i++) {
      whitePts.add(OfficialPointDisplay(wDisplays[i].mark, i == 0 && wIsFirst));
    }

    return Container(
      height: 70,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(
            color: isDark
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                : const Color(0x33000000),
            thickness: 1,
            height: 0,
          ),
          if (isDone && rScore == wScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              color: cardColor,
              child: Text(
                '✕',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.black,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0x8A000000),
                ),
              ),
            ),
          Column(
            children: [
              Expanded(
                child: ViewerPointBoxCell(
                  pts: redPts,
                  isWinner: isDone && rScore > wScore,
                  isRed: true,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: ViewerPointBoxCell(
                  pts: whitePts,
                  isWinner: isDone && wScore > rScore,
                  isRed: false,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(List<MatchModel> ms, bool isRed, bool isDark) {
    int wins = 0, pts = 0;
    for (var m in ms) {
      if (m.matchType == '代表戦') continue;
      final r = (m.redScore as num).toInt();
      final w = (m.whiteScore as num).toInt();
      pts += isRed ? r : w;
      if (isRed && r > w) {
        wins++;
      } else if (!isRed && w > r) {
        wins++;
      }
    }
    return Center(
      child: Text(
        '$pts\n--\n$wins',
        style: TextStyle(
          fontWeight: AppFontWeight.bold,
          fontSize: AppFontSize.small,
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
        ),
        textAlign: TextAlign.center,
      ),
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

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    String cat,
    Map<String, List<MatchModel>> groupsMap,
    List<String> sortedGroupKeys, {
    required bool isPdf,
    String? tName,
    String? tDate,
  }) async {
    if (ref.read(isExportingProvider)) return;
    ref.read(isExportingProvider.notifier).state = true;
    final groupDataList = sortedGroupKeys
        .map(
          (key) => {
            'groupName': key,
            'matches': groupsMap[key]!
              ..sort((a, b) => a.order.compareTo(b.order)),
          },
        )
        .toList();

    BuildContext? dialogContext;
    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final now = ref.read(timeSourceProvider).now();
      if (isPdf) {
        await pdf_service.loadLibrary();
        await pdf_service.PdfService.printOfficialRecord(
          cat,
          groupDataList,
          tournamentName: tName,
          tournamentDate: tDate,
          outputTime: now,
        );
      } else {
        await pdf_service.loadLibrary();
        await pdf_service.PdfService.shareOfficialRecordAsImage(
          cat,
          groupDataList,
          tournamentName: tName,
          tournamentDate: tDate,
          outputTime: now,
        );
      }
    } finally {
      ref.read(isExportingProvider.notifier).state = false;
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      } else if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}
