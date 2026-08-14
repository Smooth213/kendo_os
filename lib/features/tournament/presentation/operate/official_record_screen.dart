import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/pdf/pdf_service.dart' deferred as pdf_service;
// ★ 追加：先ほど作成した勝ち抜き戦の最強描画エンジンを呼び出す
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
// ★ Phase 7: 権限プロバイダのインポート
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/application/services/csv_service.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart'; // ★ 追加: 分離したヘルパー
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart'; // ★ ファイル上部に追加
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加
import 'package:kendo_os/shared/widgets/match_tables/score_table_card.dart';
import 'package:kendo_os/shared/widgets/match_tables/league_grid_card.dart';
import 'package:kendo_os/shared/widgets/match_tables/individual_list_card.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

final isExportingProvider = StateProvider.autoDispose<bool>((ref) => false);

class OfficialRecordScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const OfficialRecordScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<OfficialRecordScreen> createState() =>
      _OfficialRecordScreenState();
}

class _OfficialRecordScreenState extends ConsumerState<OfficialRecordScreen> {
  String _selectedSummaryTeam = '全体';

  @override
  Widget build(BuildContext context) {
    final tournamentId = widget.tournamentId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExporting = ref.watch(isExportingProvider);

    // ★ Phase 7: 権限プロバイダから取得
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

    // ★ Step 3-2: selectによる最適化
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
              // ★ 記録の間違いに気づいた時のために「公式記録の直し方」へ直行
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

              // 統合された個人戦がある場合、特殊なキーで登録
              if (individualMergedList.isNotEmpty) {
                // ★ 修正: match_screenでの並び替え順(order)を公式記録画面とPDFに100%反映するソートを強制
                individualMergedList.sort((a, b) => a.order.compareTo(b.order));
                mergedGroups['__merged_individual__'] = individualMergedList;
              }

              // ソート対象を mergedGroups に変更
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
                // 大会全体の登録チームから現在の部門の試合に合致するものがあるか確認
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
                  _buildExpeditionSummaryWidget(
                    categoryMatches,
                    isDark,
                    categoryRegisteredTeamNames,
                    categoryRegisteredPlayerNames,
                  ),
                  // ★ Phase 3: 三位一体の出力ボタン（PDF・画像・CSV）
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0x33000000),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 1. PDF出力
                        _buildHeaderActionButton(
                          icon: Icons.print,
                          label: 'PDF',
                          color: context.appColors.errorColor,
                          onPressed: isExporting
                              ? null
                              : () => _handleExport(
                                  context,
                                  ref,
                                  sortedGroupKeys,
                                  mergedGroups,
                                  cat,
                                  'pdf',
                                  tName: tName,
                                  tDate: tDate,
                                  tVenue: tVenue,
                                ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // 2. 画像出力
                        _buildHeaderActionButton(
                          icon: Icons.share,
                          label: '画像',
                          color: const Color(0xFF06C755),
                          onPressed: isExporting
                              ? null
                              : () => _handleExport(
                                  context,
                                  ref,
                                  sortedGroupKeys,
                                  mergedGroups,
                                  cat,
                                  'image',
                                  tName: tName,
                                  tDate: tDate,
                                  tVenue: tVenue,
                                ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // 3. ★新規: CSV出力
                        _buildHeaderActionButton(
                          icon: Icons.table_chart,
                          label: 'CSV',
                          color: context.appColors.primaryAccent,
                          onPressed: isExporting
                              ? null
                              : () => _handleExport(
                                  context,
                                  ref,
                                  sortedGroupKeys,
                                  mergedGroups,
                                  cat,
                                  'csv',
                                  tName: tName,
                                  tDate: tDate,
                                  tVenue: tVenue,
                                ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true, // ★ 追加
                      physics: const ClampingScrollPhysics(), // ★ 追加
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: sortedGroupKeys.length,
                      itemBuilder: (context, index) {
                        final groupName = sortedGroupKeys[index];
                        // 取得先を統合済みの mergedGroups に変更
                        final matches = mergedGroups[groupName]!
                          ..sort((a, b) => a.order.compareTo(b.order));

                        if (matches.isNotEmpty && matches.first.isKachinuki) {
                          // 勝ち抜き戦の描画
                          final firstMatch = matches.first;
                          final note = firstMatch.note;
                          final cleanNote = note
                              .replaceAll('[', '')
                              .replaceAll(']', '')
                              .trim();
                          final rTeam = firstMatch.redName.contains(':')
                              ? firstMatch.redName.split(':').first.trim()
                              : firstMatch.redName;
                          final wTeam = firstMatch.whiteName.contains(':')
                              ? firstMatch.whiteName.split(':').first.trim()
                              : firstMatch.whiteName;

                          // ヘッダーを【勝ち抜き戦】チーム名 vs チーム名 の形式に統一
                          String titleText = '【勝ち抜き戦】 $rTeam vs $wTeam';
                          if (cleanNote.isNotEmpty &&
                              !cleanNote.contains('勝ち抜き戦')) {
                            titleText += ' ($cleanNote)';
                          }

                          int redRem = matches.last.redRemaining.length;
                          int whiteRem = matches.last.whiteRemaining.length;
                          int maxRem = redRem > whiteRem ? redRem : whiteRem;
                          int totalCols = matches.length + maxRem;

                          // ★ 修正：画面幅以上の試合数がある場合に広がるよう余裕を持たせる
                          final canvasWidth = 60.0 + (totalCols * 60.0) + 120.0;

                          final engine = KendoRuleEngine();
                          final projections = matches.map((m) {
                            final analysis = engine.analyzeHistory(
                              m.events,
                              m,
                              m.rule,
                            );
                            return MatchProjectionMapper.toProjection(
                              m,
                              analysis,
                            );
                          }).toList();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.xs,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.large,
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF38383A)
                                    : const Color(0x33000000),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  color: isDark
                                      ? const Color(
                                          0xFF3F51B5,
                                        ).withValues(alpha: 0.4)
                                      : const Color(0xFF3F51B5),
                                  width: double.infinity,
                                  child: Text(
                                    titleText,
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF3F51B5)
                                          : const Color(0xFF3F51B5),
                                    ),
                                  ),
                                ),
                                // ★ 修正：InteractiveViewer を廃止し、確実に横に滑る SingleChildScrollView に変更
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    color: isDark
                                        ? context.appColors.cardBackground
                                        : context.appColors.textColor,
                                    width:
                                        canvasWidth <
                                            MediaQuery.of(context).size.width
                                        ? MediaQuery.of(context).size.width
                                        : canvasWidth,
                                    height: 520, // 描画高さに固定
                                    child: CustomPaint(
                                      painter: KachinukiBracketPainter(
                                        matches: projections,
                                        isDark: isDark,
                                        ref: ref, // ★ 最新のPainterに合わせて引数を修正
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (matches.isNotEmpty &&
                            matches.any((m) => m.note.contains('[リーグ戦]'))) {
                          final ownTeams =
                              ref.watch(customTeamNamesProvider).value ?? [];
                          final String leagueTitle =
                              BunaiksenHelper.generateDescriptiveLeagueTitle(
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
                          final tieBouts = matches
                              .where((m) => m.note.contains('[順位決定戦]'))
                              .toList();

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

                          // ★ 追加：対戦カードごとのグルーピング（順位決定戦用）
                          final tieBoutsByMatchup =
                              <String, List<MatchModel>>{};
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

                              // 1. ブラッシュアップされた星取表（マトリックス）
                              _buildLeagueGridTable(
                                context,
                                groupName,
                                matches,
                                cardColor: cardColor,
                                isDark: isDark,
                                ref: ref,
                              ),

                              const SizedBox(height: AppSpacing.xxl),
                              const Padding(
                                padding: EdgeInsets.only(
                                  left: AppSpacing.sm,
                                  bottom: AppSpacing.md,
                                ),
                                child: Text(
                                  '▼ 対戦カード別 スコア詳細',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: AppFontSize.body,
                                    color: AppKendoColors.grey,
                                  ),
                                ),
                              ),

                              // 2. 詳細スコアの表示（個人戦なら中枠なしの一括リスト）
                              if (isIndiv)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xl,
                                  ),
                                  child: _buildIndividualMatchesList(
                                    '対戦スコア詳細',
                                    normalMatches,
                                    cardColor: cardColor,
                                    isDark: isDark,
                                    ref: ref,
                                    applySort: false,
                                  ),
                                )
                              else
                                ...matchupOrder.map((matchupName) {
                                  final bouts = boutsByMatchup[matchupName]!;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.xl,
                                    ),
                                    child: _buildScoreTable(
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
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.lg,
                                    ),
                                    child: _buildIndividualMatchesList(
                                      '順位決定戦',
                                      tieBouts,
                                      cardColor: isDark
                                          ? const Color(
                                              0xFFFF9800,
                                            ).withValues(alpha: 0.1)
                                          : const Color(0xFFFF9800),
                                      isDark: isDark,
                                      ref: ref,
                                      applySort: false,
                                    ),
                                  )
                                else
                                  ...tieMatchupOrder.map((matchupName) {
                                    final bouts =
                                        tieBoutsByMatchup[matchupName]!;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.lg,
                                      ),
                                      child: _buildScoreTable(
                                        matchupName,
                                        bouts,
                                        cardColor: isDark
                                            ? const Color(
                                                0xFFFF9800,
                                              ).withValues(alpha: 0.1)
                                            : const Color(0xFFFF9800),
                                        isDark: isDark,
                                      ),
                                    );
                                  }),
                              ],
                              const SizedBox(height: 48),
                            ],
                          );
                        } else if (matches.isNotEmpty &&
                            matches.any(
                              (m) =>
                                  m.matchType == 'individual' ||
                                  m.matchType == '選手' ||
                                  m.matchType.contains('個人戦'),
                            )) {
                          // 👇 追加: 個人戦の場合は、専用の縦並びリスト形式で描画する
                          return _buildIndividualMatchesList(
                            groupName,
                            matches,
                            cardColor: cardColor,
                            isDark: isDark,
                            ref: ref,
                            applySort: true,
                          );
                        } else {
                          // 通常団体戦の描画
                          return _buildScoreTable(
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
        ), // Scaffold
      ),
    ); // LiquidBackground
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

  // 出力ボタンの共通デザイン
  Widget _buildHeaderActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.small,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppKendoColors.pureWhite,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
      ),
    );
  }

  // 出力処理の共通ハンドラ
  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    List<String> sortedGroupKeys,
    Map<String, List<MatchModel>> mergedGroups,
    String cat,
    String type, {
    String? tName,
    String? tDate,
    String? tVenue,
  }) async {
    if (ref.read(isExportingProvider)) return;
    ref.read(isExportingProvider.notifier).state = true;
    final groupDataList = sortedGroupKeys
        .map(
          (key) => {
            'groupName': key,
            'matches': mergedGroups[key]!
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
      if (type == 'pdf') {
        await pdf_service.loadLibrary();
        await pdf_service.PdfService.printOfficialRecord(
          cat,
          groupDataList,
          tournamentName: tName,
          tournamentDate: tDate,
          tournamentVenue: tVenue,
          outputTime: now,
        );
      }
      if (type == 'image') {
        await pdf_service.loadLibrary();
        await pdf_service.PdfService.shareOfficialRecordAsImage(
          cat,
          groupDataList,
          tournamentName: tName,
          tournamentDate: tDate,
          tournamentVenue: tVenue,
          outputTime: now,
        );
      }
      // ★ CSVサービスを呼び出し
      if (type == 'csv') {
        await CsvService.shareOfficialRecordAsCsv(cat, groupDataList);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '出力に失敗しました: $e');
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

  Widget _buildScoreTable(
    String groupName,
    List<MatchModel> matches, {
    Color? cardColor,
    bool isDark = false,
  }) {
    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    final redTeam = matches.first.redName.contains(':')
        ? matches.first.redName.split(':').first.trim()
        : matches.first.redName;
    final whiteTeam = matches.first.whiteName.contains(':')
        ? matches.first.whiteName.split(':').first.trim()
        : matches.first.whiteName;

    // 「赤」「白」ではなく実際のチーム名を表示するように変更
    final String sideLabelRed = redTeam;
    final String sideLabelWhite = whiteTeam;

    // 試合形式に合わせてヘッダーテキストを生成
    String matchTypeStr = '団体戦';
    if (matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    )) {
      matchTypeStr = '個人戦';
    } else if (matches.first.isKachinuki) {
      matchTypeStr = '勝ち抜き戦';
    } else if (matches.any((m) => m.note.contains('リーグ戦'))) {
      matchTypeStr = 'リーグ戦';
    }

    String headerTitle = '【$matchTypeStr】 $redTeam vs $whiteTeam';
    if (cleanNote.isNotEmpty && !cleanNote.contains(matchTypeStr)) {
      headerTitle += ' ($cleanNote)';
    }

    bool allFinished = matches.every(
      (m) => m.status == 'approved' || m.status == 'finished',
    );

    String teamWinner = 'draw';
    int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
    MatchModel? daihyoMatch;

    for (var m in matches) {
      if (m.matchType == '代表戦') {
        daihyoMatch = m;
        continue; // ★ 代表戦のスコアは本戦の計算から除外する
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

    final info = ScoreTableGroupInfo(
      groupName: groupName,
      headerTitle: headerTitle,
      sideLabelRed: sideLabelRed,
      sideLabelWhite: sideLabelWhite,
      isSummary: isSummary,
      teamWinner: teamWinner,
      redWins: rWins,
      whiteWins: wWins,
      redTotalPoints: rPts,
      whiteTotalPoints: wPts,
      allFinished: allFinished,
    );

    final matchItems = matches.map((m) {
      final isFinished = m.status == 'approved' || m.status == 'finished';
      final ptsMap = MatchCalculatorHelper.extractPointsFromModel(m);
      return ScoreTableMatchItem(
        id: m.id,
        matchType: m.matchType,
        redName: m.redName,
        whiteName: m.whiteName,
        redScore: (m.redScore as num).toInt(),
        whiteScore: (m.whiteScore as num).toInt(),
        isFinished: isFinished,
        isSummary: m.note.contains('[SUMMARY]'),
        isEncho: MatchCalculatorHelper.isEnchoFromModel(m),
        redPoints: ptsMap['red'] ?? [],
        whitePoints: ptsMap['white'] ?? [],
      );
    }).toList();

    return ScoreTableCard(
      info: info,
      matches: matchItems,
      cardColor: cardColor,
      isDark: isDark,
    );
  }

  // ★ 追加：印刷画面用のリーグ星取表描画メソッド
  Widget _buildLeagueGridTable(
    BuildContext context,
    String groupName,
    List<MatchModel> matches, {
    Color? cardColor,
    required bool isDark,
    required WidgetRef ref,
  }) {
    final normalMatches = matches
        .where((m) => !m.note.contains('[順位決定戦]'))
        .toList();
    if (normalMatches.isEmpty) return const SizedBox();

    final rule = normalMatches.first.rule ?? ref.read(matchRuleProvider);
    final nonNullRule = rule!;
    final stats = KendoRuleEngine.calculateLeagueStandings(
      normalMatches,
      nonNullRule,
    );
    final isIndiv = normalMatches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );
    final allFinished = matches.every(
      (m) => m.status == 'approved' || m.status == 'finished',
    );
    final hasMatchPoints = nonNullRule.isLeague;

    String getEntityName(String fullName) {
      if (isIndiv) {
        return fullName.contains(':')
            ? fullName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
            : fullName.trim();
      }
      return fullName.contains(':')
          ? fullName.split(':').first.trim()
          : fullName.trim();
    }

    final teams = <String>{};
    for (var m in normalMatches) {
      teams.add(getEntityName(m.redName));
      teams.add(getEntityName(m.whiteName));
    }
    final teamList = teams.toList()..sort();

    final leagueTeams = teamList.map((rowTeam) {
      final stat = stats.firstWhere(
        (s) => s.name == rowTeam,
        orElse: () => stats.first,
      );
      final rankStr = allFinished
          ? '${stats.indexWhere((s) => s.name == rowTeam) + 1}'
          : '-';
      return LeagueGridTeamInfo(
        teamName: rowTeam,
        matchWins: '${stat.matchWins}',
        individualWinners: '${stat.individualWinners}',
        totalPoints: '${stat.totalPointsScored}',
        customPoints: stat.customPoints.toStringAsFixed(
          stat.customPoints.truncateToDouble() == stat.customPoints ? 0 : 1,
        ),
        rank: rankStr,
      );
    }).toList();

    final matrix = <String, Map<String, LeagueGridCellData>>{};
    for (var rowTeam in teamList) {
      matrix[rowTeam] = {};
      for (var colTeam in teamList) {
        if (rowTeam == colTeam) continue;

        final bouts = normalMatches.where((m) {
          final r = getEntityName(m.redName);
          final w = getEntityName(m.whiteName);
          return (r == rowTeam && w == colTeam) ||
              (r == colTeam && w == rowTeam);
        }).toList();

        if (bouts.isEmpty) continue;

        int rWins = 0,
            cWins = 0,
            rPoints = 0,
            cPoints = 0,
            rWinners = 0,
            cWinners = 0;
        List<PointMark> techs = [];
        for (var m in bouts) {
          final isRowRed = getEntityName(m.redName) == rowTeam;
          final rs = (m.redScore as num).toInt();
          final ws = (m.whiteScore as num).toInt();
          if (rs > ws) {
            isRowRed ? rWins++ : cWins++;
            isRowRed ? rWinners++ : cWinners++;
          } else if (ws > rs) {
            isRowRed ? cWins++ : rWins++;
            isRowRed ? cWinners++ : rWinners++;
          }
          isRowRed ? rPoints += rs : cPoints += rs;
          isRowRed ? cPoints += ws : rPoints += ws;
          if (isIndiv) {
            final extractedMap = MatchCalculatorHelper.extractPointsFromModel(
              m,
            );
            final extracted = List<PointMark>.from(
              isRowRed ? extractedMap['red']! : extractedMap['white']!,
            );

            final bool isSummary = m.note.contains('[SUMMARY]');
            if (isSummary || extracted.isEmpty) {
              extracted.clear();
              for (int k = 0; k < (isRowRed ? rs : ws); k++) {
                extracted.add(const PointMark(mark: '◯', isFirst: false));
              }
            }
            techs.addAll(extracted);
          }
        }

        String result = 'draw';
        if (rWins > cWins) {
          result = 'win';
        } else if (cWins > rWins) {
          result = 'loss';
        }

        if (!bouts.every(
          (m) => m.status == 'approved' || m.status == 'finished',
        )) {
          continue;
        }

        matrix[rowTeam]![colTeam] = LeagueGridCellData(
          result: result,
          isIndiv: isIndiv,
          techMarks: techs,
          rPoints: rPoints,
          rWinners: rWinners,
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: '閉じる',
              barrierColor: AppKendoColors.pureBlack.withValues(alpha: 0.7),
              transitionDuration: const Duration(milliseconds: 350),
              pageBuilder: (ctx, anim1, anim2) {
                return Center(
                  child: Dialog(
                    backgroundColor: AppKendoColors.transparent,
                    elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.roundValue,
                      vertical: AppSpacing.giant,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 550),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFFFFFFFF),
                        borderRadius: AppRadius.round,
                        boxShadow: [
                          BoxShadow(
                            color: AppKendoColors.pureBlack.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.roundValue),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: isIndiv
                                ? _buildIndividualMatchesList(
                                    '$rowTeam vs $colTeam',
                                    bouts,
                                    cardColor: AppKendoColors.transparent,
                                    isDark: isDark,
                                    ref: ref,
                                    applySort: false,
                                  )
                                : _buildScoreTable(
                                    '$rowTeam vs $colTeam',
                                    bouts,
                                    cardColor: AppKendoColors.transparent,
                                    isDark: isDark,
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appColors.separatorColor,
                              foregroundColor: context.appColors.textColor,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: AppSpacing.md,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '閉じる',
                              style: TextStyle(fontWeight: AppFontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              transitionBuilder: (ctx, anim1, anim2, child) {
                return FadeTransition(
                  opacity: anim1,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: anim1,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
            );
          },
        );
      }
    }

    return LeagueGridCard(
      teams: leagueTeams,
      matrix: matrix,
      hasMatchPoints: hasMatchPoints,
      cardColor: cardColor,
      isDark: isDark,
    );
  }

  // 👇 ここから追加：個人戦専用の縦並びリスト描画エンジン
  Widget _buildIndividualMatchesList(
    String groupName,
    List<MatchModel> matches, {
    Color? cardColor,
    required bool isDark,
    required WidgetRef ref,
    required bool applySort,
  }) {
    List<MatchModel> displayMatches = List.from(matches);

    if (applySort) {
      final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];

      int getTeamPriority(MatchModel m) {
        final rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : '';
        final wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : '';
        final ruleTeamName = m.rule?.teamName;
        bool rOwn =
            ownTeams.contains(rTeam) ||
            m.redName.contains('自チーム') ||
            (ruleTeamName?.isNotEmpty == true && rTeam == ruleTeamName);
        bool wOwn =
            ownTeams.contains(wTeam) ||
            m.whiteName.contains('自チーム') ||
            (ruleTeamName?.isNotEmpty == true && wTeam == ruleTeamName);
        if (rOwn && wOwn) return 1; // 同門
        if (rOwn || wOwn) return 2; // 自チーム vs 他チーム
        return 3; // 他チーム同士
      }

      String getSortName(MatchModel m) {
        final rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : '';
        final wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : '';
        final rName = m.redName.contains(':')
            ? m.redName.split(':').last.trim()
            : m.redName;
        final wName = m.whiteName.contains(':')
            ? m.whiteName.split(':').last.trim()
            : m.whiteName;
        final ruleTeamName = m.rule?.teamName;

        bool rOwn =
            ownTeams.contains(rTeam) ||
            m.redName.contains('自チーム') ||
            (ruleTeamName?.isNotEmpty == true && rTeam == ruleTeamName);
        bool wOwn =
            ownTeams.contains(wTeam) ||
            m.whiteName.contains('自チーム') ||
            (ruleTeamName?.isNotEmpty == true && wTeam == ruleTeamName);

        if (rOwn && wOwn) return rName; // 同門は赤優先
        if (rOwn) return rName;
        if (wOwn) return wName;
        return rName;
      }

      displayMatches.sort((a, b) {
        int pA = getTeamPriority(a);
        int pB = getTeamPriority(b);
        if (pA != pB) return pA.compareTo(pB);

        String nameA = getSortName(a);
        String nameB = getSortName(b);
        int nameCompare = nameA.compareTo(nameB);
        if (nameCompare != 0) return nameCompare;

        return a.order.compareTo(b.order); // 同じ選手なら試合順
      });
    }

    // ヘッダー名からシステムID（英数字とハイフンの羅列）を隠す処理
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    String displayGroupName = groupName;
    if (uuidRegex.hasMatch(groupName) ||
        groupName.length > 20 ||
        groupName == '__default__' ||
        groupName.contains(' vs ')) {
      displayGroupName = '';
    }

    String headerTitle = '【個人戦】';
    if (displayGroupName.isNotEmpty) {
      headerTitle += ' $displayGroupName';
    }

    final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];

    final matchItems = displayMatches.map((m) {
      final rTeam = m.redName.contains(':')
          ? m.redName.split(':').first.trim()
          : '';
      final wTeam = m.whiteName.contains(':')
          ? m.whiteName.split(':').first.trim()
          : '';
      final rName = m.redName.contains(':')
          ? m.redName.split(':').last.replaceAll(')', '').trim()
          : m.redName;
      final wName = m.whiteName.contains(':')
          ? m.whiteName.split(':').last.replaceAll(')', '').trim()
          : m.whiteName;

      final isDone = m.status == 'finished' || m.status == 'approved';
      final rScore = (m.redScore as num).toInt();
      final wScore = (m.whiteScore as num).toInt();
      final isDraw = isDone && rScore == wScore;
      final rWin = isDone && rScore > wScore;
      final wWin = isDone && wScore > rScore;

      final ptsMap = MatchCalculatorHelper.extractPointsFromModel(m);

      final ruleTeamName = m.rule?.teamName;
      final bool rOwn =
          ownTeams.contains(rTeam) ||
          m.redName.contains('自チーム') ||
          (ruleTeamName?.isNotEmpty == true && rTeam == ruleTeamName);
      final bool wOwn =
          ownTeams.contains(wTeam) ||
          m.whiteName.contains('自チーム') ||
          (ruleTeamName?.isNotEmpty == true && wTeam == ruleTeamName);
      final bool hasOwnTeam = rOwn || wOwn;

      return IndividualMatchItem(
        id: m.id,
        note: m.note,
        redTeam: rTeam,
        whiteTeam: wTeam,
        redName: rName,
        whiteName: wName,
        redScore: rScore,
        whiteScore: wScore,
        isFinished: isDone,
        isSummary: m.note.contains('[SUMMARY]'),
        isDraw: isDraw,
        rWin: rWin,
        wWin: wWin,
        hasOwnTeam: hasOwnTeam,
        redPoints: ptsMap['red'] ?? [],
        whitePoints: ptsMap['white'] ?? [],
      );
    }).toList();

    return IndividualListCard(
      headerTitle: headerTitle,
      matches: matchItems,
      cardColor: cardColor,
      isDark: isDark,
    );
  }

  Widget _buildExpeditionSummaryWidget(
    List<MatchModel> matches,
    bool isDark,
    Set<String> registeredTeamNames,
    Set<String> registeredPlayerNames,
  ) {
    if (matches.isEmpty) return const SizedBox.shrink();

    // 1. 自チーム名の確定
    final List<String> teamsList;
    if (registeredTeamNames.isNotEmpty) {
      teamsList = registeredTeamNames.toList()..sort();
    } else {
      final teamsSet = <String>{};
      for (final m in matches) {
        if (m.redName.isNotEmpty) {
          final rTeam = m.redName.contains(':')
              ? m.redName.split(':').first.trim()
              : m.redName.trim();
          if (rTeam.isNotEmpty) teamsSet.add(rTeam);
        }
        if (m.whiteName.isNotEmpty) {
          final wTeam = m.whiteName.contains(':')
              ? m.whiteName.split(':').first.trim()
              : m.whiteName.trim();
          if (wTeam.isNotEmpty) teamsSet.add(wTeam);
        }
      }
      teamsList = teamsSet.toList()..sort();
    }

    // 自チーム判定ヘルパー
    bool isMyTeam(String teamName) {
      if (registeredTeamNames.isNotEmpty) {
        return registeredTeamNames.contains(teamName);
      }
      return teamsList.isNotEmpty && teamsList.first == teamName;
    }

    bool isMyPlayer(String playerName, String teamName) {
      if (registeredPlayerNames.isNotEmpty) {
        return registeredPlayerNames.contains(playerName);
      }
      return isMyTeam(teamName);
    }

    bool isMatchPlayed(MatchModel m) {
      return m.status == 'finished' || m.status == 'approved';
    }

    int renseikaiWin = 0, renseikaiLoss = 0, renseikaiDraw = 0;
    int honsenWin = 0, honsenLoss = 0, honsenDraw = 0;
    int moushiawaseWin = 0, moushiawaseLoss = 0, moushiawaseDraw = 0;

    // 技別集計（チーム全体）
    int teamMen = 0,
        teamKote = 0,
        teamDou = 0,
        teamTsuki = 0,
        teamHansoku = 0,
        teamOther = 0;
    int teamTotalScored = 0;
    int teamTotalConceded = 0;

    final Map<String, _DetailedPlayerStats> playerStatsMap = {};
    final List<_ExpeditionCardResult> cardResults = [];

    // 団体戦・勝ち抜き戦（groupNameごと）
    final Map<String, List<MatchModel>> groupMap = {};
    for (final m in matches) {
      final key = (m.groupName != null && m.groupName!.isNotEmpty)
          ? m.groupName!
          : m.id;
      groupMap.putIfAbsent(key, () => []).add(m);
    }

    for (final entry in groupMap.entries) {
      final bouts = entry.value;
      if (bouts.isEmpty) continue;

      final firstMatch = bouts.first;
      final bool isTeamMatch =
          bouts.length > 1 ||
          firstMatch.isKachinuki ||
          firstMatch.matchType.contains('団体') ||
          firstMatch.matchType == '先鋒' ||
          firstMatch.matchType == '次鋒' ||
          firstMatch.matchType == '中堅' ||
          firstMatch.matchType == '副将' ||
          firstMatch.matchType == '大将' ||
          firstMatch.matchType == '代表戦';

      if (isTeamMatch) {
        // ★ 団体戦 / 勝ち抜き戦: 全試合が決着済みの場合のみサマリーに集計（試合途中は除外）
        final allBoutsFinished = bouts.every(
          (b) => b.status == 'finished' || b.status == 'approved',
        );
        if (!firstMatch.isKachinuki && !allBoutsFinished) continue;
        if (firstMatch.isKachinuki && !isMatchPlayed(bouts.last)) continue;

        final rTeam = firstMatch.redName.contains(':')
            ? firstMatch.redName.split(':').first.trim()
            : firstMatch.redName.trim();
        final wTeam = firstMatch.whiteName.contains(':')
            ? firstMatch.whiteName.split(':').first.trim()
            : firstMatch.whiteName.trim();

        final bool rIsMine = isMyTeam(rTeam);
        final bool wIsMine = isMyTeam(wTeam);

        if (!rIsMine && !wIsMine) continue;

        final bool isTargetRed =
            (_selectedSummaryTeam == '全体' && rIsMine) ||
            (_selectedSummaryTeam == rTeam);
        final bool isTargetWhite =
            (_selectedSummaryTeam == '全体' && wIsMine) ||
            (_selectedSummaryTeam == wTeam);

        if (!isTargetRed && !isTargetWhite) continue;

        final playedBouts = bouts.where((b) => isMatchPlayed(b)).toList();
        if (playedBouts.isEmpty) continue;

        int myWins = 0;
        int oppWins = 0;
        int myPoints = 0;
        int oppPoints = 0;
        bool hasDaihyo = false;
        bool? daihyoIsMyWin;

        if (firstMatch.isKachinuki) {
          final lastMatch = bouts.last;
          if (isMatchPlayed(lastMatch)) {
            if (lastMatch.redRemaining.length >
                lastMatch.whiteRemaining.length) {
              if (isTargetRed) {
                myWins = 1;
              } else {
                oppWins = 1;
              }
            } else if (lastMatch.whiteRemaining.length >
                lastMatch.redRemaining.length) {
              if (isTargetWhite) {
                myWins = 1;
              } else {
                oppWins = 1;
              }
            }
          } else {
            for (final b in playedBouts) {
              if (isTargetRed) {
                if (b.redScore > b.whiteScore) {
                  myWins++;
                } else if (b.whiteScore > b.redScore) {
                  oppWins++;
                }
              } else {
                if (b.whiteScore > b.redScore) {
                  myWins++;
                } else if (b.redScore > b.whiteScore) {
                  oppWins++;
                }
              }
            }
          }
        } else {
          for (final b in playedBouts) {
            final int rScore = (b.redScore as num).toInt();
            final int wScore = (b.whiteScore as num).toInt();

            if (b.matchType == '代表戦') {
              hasDaihyo = true;
              if (rScore > wScore) {
                daihyoIsMyWin = isTargetRed;
              } else if (wScore > rScore) {
                daihyoIsMyWin = isTargetWhite;
              }
            } else {
              if (isTargetRed) {
                myPoints += rScore;
                oppPoints += wScore;
                if (rScore > wScore) {
                  myWins++;
                } else if (wScore > rScore) {
                  oppWins++;
                }
              } else {
                myPoints += wScore;
                oppPoints += rScore;
                if (wScore > rScore) {
                  myWins++;
                } else if (rScore > wScore) {
                  oppWins++;
                }
              }
            }

            // 団体戦内の各選手個人戦績＆打突集計
            final rPlayer = b.redName.contains(':')
                ? b.redName.split(':').last.trim()
                : b.redName.trim();
            final wPlayer = b.whiteName.contains(':')
                ? b.whiteName.split(':').last.trim()
                : b.whiteName.trim();

            if (isTargetRed &&
                rPlayer.isNotEmpty &&
                isMyPlayer(rPlayer, rTeam)) {
              final stats = playerStatsMap.putIfAbsent(
                rPlayer,
                () => _DetailedPlayerStats(),
              );
              if (rScore == wScore) {
                stats.draw++;
              } else if (rScore > wScore) {
                stats.win++;
              } else {
                stats.loss++;
              }
            }
            if (isTargetWhite &&
                wPlayer.isNotEmpty &&
                isMyPlayer(wPlayer, wTeam)) {
              final stats = playerStatsMap.putIfAbsent(
                wPlayer,
                () => _DetailedPlayerStats(),
              );
              if (wScore == rScore) {
                stats.draw++;
              } else if (wScore > rScore) {
                stats.win++;
              } else {
                stats.loss++;
              }
            }
          }
        }

        // 全剣連 勝敗判定ロジック
        bool isWin = false;
        bool isDraw = false;
        String resultType = '引き分け';

        if (myWins > oppWins) {
          isWin = true;
          resultType = '勝数勝ち';
        } else if (oppWins > myWins) {
          isWin = false;
          resultType = '敗戦';
        } else {
          // 勝数同数 ➔ 総取得本数（本数差勝ち）の比較
          if (myPoints > oppPoints) {
            isWin = true;
            resultType = '本数差勝ち';
          } else if (oppPoints > myPoints) {
            isWin = false;
            resultType = '本数差負け';
          } else {
            // 勝数・本数ともに同数 ➔ 代表戦判定
            if (hasDaihyo && daihyoIsMyWin != null) {
              if (daihyoIsMyWin == true) {
                isWin = true;
                resultType = '代表戦勝ち';
              } else {
                isWin = false;
                resultType = '代表戦負け';
              }
            } else {
              isDraw = true;
              resultType = '引き分け';
            }
          }
        }

        final opponentTeam = isTargetRed ? wTeam : rTeam;
        final scene = firstMatch.matchScene;

        // ★ 案C: 試合時刻・シーン名（「10:15 錬成会」など）の自動生成
        final DateTime? matchTime =
            firstMatch.lastUpdatedAt ??
            firstMatch.timerStartedAt ??
            (firstMatch.events.isNotEmpty
                ? firstMatch.events.first.timestamp
                : null);
        final String timeStr = matchTime != null
            ? DateFormat('HH:mm').format(matchTime)
            : '';

        final String sceneLabel = scene == 'renseikai'
            ? '錬成会'
            : (scene == 'moushiawase'
                  ? '申し合わせ'
                  : (scene == 'honsen' ? '本戦' : '団体戦'));
        final String timeSceneLabel = timeStr.isNotEmpty
            ? '$timeStr $sceneLabel'
            : sceneLabel;

        // UUIDやシステム文字列（英数字の羅列）を安全に検知・排除
        final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        final rawGroupName = (firstMatch.groupName ?? '').trim();
        final isUuid =
            uuidRegex.hasMatch(rawGroupName) ||
            rawGroupName.length > 25 ||
            rawGroupName == '__default__' ||
            rawGroupName.contains(' vs ');

        final String cardTitle;
        if (!isUuid && rawGroupName.isNotEmpty && rawGroupName != '団体戦') {
          cardTitle = '$rawGroupName ($timeSceneLabel)';
        } else {
          cardTitle = timeSceneLabel;
        }

        cardResults.add(
          _ExpeditionCardResult(
            cardTitle: cardTitle,
            opponentTeamName: opponentTeam,
            myWins: myWins,
            oppWins: oppWins,
            myPoints: myPoints,
            oppPoints: oppPoints,
            resultType: resultType,
            isWin: isWin,
            isDraw: isDraw,
            scene: scene,
          ),
        );

        if (scene == 'renseikai') {
          if (isDraw) {
            renseikaiDraw++;
          } else if (isWin) {
            renseikaiWin++;
          } else {
            renseikaiLoss++;
          }
        } else if (scene == 'moushiawase') {
          if (isDraw) {
            moushiawaseDraw++;
          } else if (isWin) {
            moushiawaseWin++;
          } else {
            moushiawaseLoss++;
          }
        } else {
          if (isDraw) {
            honsenDraw++;
          } else if (isWin) {
            honsenWin++;
          } else {
            honsenLoss++;
          }
        }
      } else {
        // ★ 個人戦: 個人成績にのみ反映（上段チーム成績には含めない）
        for (final m in bouts) {
          if (!isMatchPlayed(m)) continue;

          final rTeam = m.redName.contains(':')
              ? m.redName.split(':').first.trim()
              : m.redName.trim();
          final wTeam = m.whiteName.contains(':')
              ? m.whiteName.split(':').first.trim()
              : m.whiteName.trim();
          final rPlayer = m.redName.contains(':')
              ? m.redName.split(':').last.trim()
              : m.redName.trim();
          final wPlayer = m.whiteName.contains(':')
              ? m.whiteName.split(':').last.trim()
              : m.whiteName.trim();

          final bool rIsMine = isMyTeam(rTeam) || isMyPlayer(rPlayer, rTeam);
          final bool wIsMine = isMyTeam(wTeam) || isMyPlayer(wPlayer, wTeam);
          if (!rIsMine && !wIsMine) continue;

          final bool isTargetRed =
              (_selectedSummaryTeam == '全体' && rIsMine) ||
              (_selectedSummaryTeam == rTeam);
          final bool isTargetWhite =
              (_selectedSummaryTeam == '全体' && wIsMine) ||
              (_selectedSummaryTeam == wTeam);
          if (!isTargetRed && !isTargetWhite) continue;

          final isDraw = m.redScore == m.whiteScore;

          if (isTargetRed && rPlayer.isNotEmpty && isMyPlayer(rPlayer, rTeam)) {
            final stats = playerStatsMap.putIfAbsent(
              rPlayer,
              () => _DetailedPlayerStats(),
            );
            if (isDraw) {
              stats.draw++;
            } else if (m.redScore > m.whiteScore) {
              stats.win++;
            } else {
              stats.loss++;
            }
          }
          if (isTargetWhite &&
              wPlayer.isNotEmpty &&
              isMyPlayer(wPlayer, wTeam)) {
            final stats = playerStatsMap.putIfAbsent(
              wPlayer,
              () => _DetailedPlayerStats(),
            );
            if (isDraw) {
              stats.draw++;
            } else if (m.whiteScore > m.redScore) {
              stats.win++;
            } else {
              stats.loss++;
            }
          }
        }
      }
    }

    // ★ 技別（有効打突）および相手反則による取得の精緻な計測
    for (final m in matches) {
      if (!isMatchPlayed(m)) continue;

      final rTeam = m.redName.contains(':')
          ? m.redName.split(':').first.trim()
          : m.redName.trim();
      final wTeam = m.whiteName.contains(':')
          ? m.whiteName.split(':').first.trim()
          : m.whiteName.trim();
      final rPlayer = m.redName.contains(':')
          ? m.redName.split(':').last.trim()
          : m.redName.trim();
      final wPlayer = m.whiteName.contains(':')
          ? m.whiteName.split(':').last.trim()
          : m.whiteName.trim();

      final bool rIsMine = isMyTeam(rTeam) || isMyPlayer(rPlayer, rTeam);
      final bool wIsMine = isMyTeam(wTeam) || isMyPlayer(wPlayer, wTeam);
      if (!rIsMine && !wIsMine) continue;

      final bool isTargetRed =
          (_selectedSummaryTeam == '全体' && rIsMine) ||
          (_selectedSummaryTeam == rTeam);
      final bool isTargetWhite =
          (_selectedSummaryTeam == '全体' && wIsMine) ||
          (_selectedSummaryTeam == wTeam);
      if (!isTargetRed && !isTargetWhite) continue;

      for (final ev in m.events) {
        if (ev.isCanceled) continue;
        if (!ev.isIppon) continue;

        final bool evIsMine =
            (ev.side == Side.red && isTargetRed) ||
            (ev.side == Side.white && isTargetWhite);
        final bool evIsOpp =
            (ev.side == Side.red && isTargetWhite) ||
            (ev.side == Side.white && isTargetRed);

        if (evIsMine) {
          teamTotalScored++;
          final String myPlayer = ev.side == Side.red ? rPlayer : wPlayer;
          final pStats = playerStatsMap.putIfAbsent(
            myPlayer,
            () => _DetailedPlayerStats(),
          );
          pStats.totalPoints++;

          if (ev.isHansoku) {
            teamHansoku++;
            pStats.hansoku++;
          } else {
            switch (ev.strikeType) {
              case StrikeType.men:
                teamMen++;
                pStats.men++;
                break;
              case StrikeType.kote:
                teamKote++;
                pStats.kote++;
                break;
              case StrikeType.dou:
                teamDou++;
                pStats.dou++;
                break;
              case StrikeType.tsuki:
                teamTsuki++;
                pStats.tsuki++;
                break;
              default:
                teamOther++;
                pStats.other++;
                break;
            }
          }
        } else if (evIsOpp) {
          teamTotalConceded++;
          final String myPlayer = ev.side == Side.red ? wPlayer : rPlayer;
          if (myPlayer.isNotEmpty) {
            final pStats = playerStatsMap.putIfAbsent(
              myPlayer,
              () => _DetailedPlayerStats(),
            );
            pStats.concededPoints++;
          }
        }
      }
    }

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.analytics_outlined,
                    color: AppKendoColors.indigo,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '成績サマリー',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.bodyMedium,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ★ 詳細分析ボトムシートを開くボタン
                  InkWell(
                    onTap: () {
                      _showExpeditionDetailBottomSheet(
                        context: context,
                        isDark: isDark,
                        teamName: _selectedSummaryTeam,
                        teamMen: teamMen,
                        teamKote: teamKote,
                        teamDou: teamDou,
                        teamTsuki: teamTsuki,
                        teamHansoku: teamHansoku,
                        teamOther: teamOther,
                        totalScored: teamTotalScored,
                        totalConceded: teamTotalConceded,
                        cardResults: cardResults,
                      );
                    },
                    borderRadius: AppRadius.round,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : themeColors.softAccent,
                        borderRadius: AppRadius.round,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 14,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '詳細分析 ›',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : context.appColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (teamsList.length > 1) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.compact,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3F51B5).withValues(alpha: 0.3)
                            : const Color(0xFFEEF2FF),
                        borderRadius: AppRadius.round,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3F51B5)
                              : context.appColors.primaryAccent.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: teamsList.contains(_selectedSummaryTeam)
                              ? _selectedSummaryTeam
                              : '全体',
                          isDense: true,
                          dropdownColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFFFFFFF),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.primaryAccent,
                            size: 20,
                          ),
                          style: TextStyle(
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.bodySmall,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.primaryAccent,
                          ),
                          items: ['全体', ...teamsList].map((t) {
                            return DropdownMenuItem<String>(
                              value: t,
                              child: Text(
                                t == '全体' ? '全チーム合計' : t,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFFFFFFF)
                                      : context.appColors.textColor,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSummaryTeam = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '⚔️ 錬成会',
                renseikaiWin,
                renseikaiLoss,
                renseikaiDraw,
                const Color(0xFFD97706),
              ),
              _buildSummaryItem(
                '🏆 本戦',
                honsenWin,
                honsenLoss,
                honsenDraw,
                const Color(0xFF3F51B5),
              ),
              _buildSummaryItem(
                '🤝 申し合わせ',
                moushiawaseWin,
                moushiawaseLoss,
                moushiawaseDraw,
                const Color(0xFF009688),
              ),
            ],
          ),
          if (playerStatsMap.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '👤 選手別成績（タップでカルテ表示）',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.bodySmall,
                    color: AppKendoColors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: playerStatsMap.entries.map((entry) {
                final pName = entry.key;
                final st = entry.value;
                return InkWell(
                  onTap: () {
                    _showPlayerDetailBottomSheet(
                      context: context,
                      isDark: isDark,
                      playerName: pName,
                      stats: st,
                    );
                  },
                  borderRadius: AppRadius.medium,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
                            : const Color(0xFF000000).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pName: ${st.win}勝${st.loss}敗${st.draw > 0 ? "${st.draw}分" : ""}',
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            fontWeight: AppFontWeight.bold,
                            color: context.appColors.textColor,
                          ),
                        ),
                        if (st.totalPoints > 0) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '(${st.totalPoints}本)',
                            style: const TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: AppKendoColors.indigo,
                            ),
                          ),
                        ],
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: AppKendoColors.grey.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ★ チーム遠征詳細分析ボトムシート
  void _showExpeditionDetailBottomSheet({
    required BuildContext context,
    required bool isDark,
    required String teamName,
    required int teamMen,
    required int teamKote,
    required int teamDou,
    required int teamTsuki,
    required int teamHansoku,
    required int teamOther,
    required int totalScored,
    required int totalConceded,
    required List<_ExpeditionCardResult> cardResults,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final totalStrikes =
            teamMen + teamKote + teamDou + teamTsuki + teamHansoku + teamOther;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insights,
                          color: AppKendoColors.indigo,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '成績 詳細分析 ($teamName)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    // セクション 1: 🎯 有効打突・技別決定数メーター
                    Text(
                      '🎯 有効打突・取得技内訳',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF9FAFB),
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                              : const Color(0xFF000000).withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '面 (メ)',
                                  teamMen,
                                  totalStrikes,
                                  AppKendoColors.teal,
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '小手 (コ)',
                                  teamKote,
                                  totalStrikes,
                                  AppKendoColors.indigo,
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '胴 (ド)',
                                  teamDou,
                                  totalStrikes,
                                  const Color(0xFFD97706),
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '突き (ツ)',
                                  teamTsuki,
                                  totalStrikes,
                                  const Color(0xFF8B5CF6),
                                ),
                              ),
                              Expanded(
                                child: _buildStrikeStatBadge(
                                  '反則 (反)',
                                  teamHansoku,
                                  totalStrikes,
                                  AppKendoColors.hansokuRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Text(
                                '総取得本数: $totalScored本',
                                style: const TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.teal,
                                ),
                              ),
                              Text(
                                '総失本数: $totalConceded本',
                                style: const TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.caption,
                                  color: AppKendoColors.hansokuRed,
                                ),
                              ),
                              Text(
                                '得失差: ${totalScored - totalConceded >= 0 ? "+${totalScored - totalConceded}" : "${totalScored - totalConceded}"}',
                                style: TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.caption,
                                  color: (totalScored - totalConceded) >= 0
                                      ? AppKendoColors.teal
                                      : AppKendoColors.hansokuRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // セクション 2: ⚖️ 全剣連基準 対戦カード一覧
                    Text(
                      '⚖️ 団体戦 対戦カード履歴 (全剣連基準)',
                      style: TextStyle(
                        fontSize: AppFontSize.subhead,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (cardResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Center(
                          child: Text(
                            '団体戦の対戦履歴はありません',
                            style: TextStyle(color: AppKendoColors.grey),
                          ),
                        ),
                      )
                    else
                      ...cardResults.map((res) {
                        final Color badgeBg = res.isWin
                            ? AppKendoColors.teal.withValues(alpha: 0.15)
                            : (res.isDraw
                                  ? AppKendoColors.grey.withValues(alpha: 0.15)
                                  : AppKendoColors.hansokuRed.withValues(
                                      alpha: 0.15,
                                    ));
                        final Color badgeText = res.isWin
                            ? AppKendoColors.teal
                            : (res.isDraw
                                  ? AppKendoColors.grey
                                  : AppKendoColors.hansokuRed);

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFFFFFFF),
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: isDark
                                  ? const Color(
                                      0xFFFFFFFF,
                                    ).withValues(alpha: 0.1)
                                  : const Color(
                                      0xFF000000,
                                    ).withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.cardTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: AppFontSize.caption,
                                        color: AppKendoColors.grey,
                                        fontWeight: AppFontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'vs ${res.opponentTeamName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: AppFontSize.body,
                                        fontWeight: AppFontWeight.bold,
                                        color: context.appColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${res.myWins}(${res.myPoints}) - ${res.oppWins}(${res.oppPoints})',
                                    style: TextStyle(
                                      fontSize: AppFontSize.bodyMedium,
                                      fontWeight: AppFontWeight.bold,
                                      color: context.appColors.textColor,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: AppRadius.round,
                                    ),
                                    child: Text(
                                      res.resultType,
                                      style: TextStyle(
                                        fontSize: AppFontSize.caption,
                                        fontWeight: AppFontWeight.bold,
                                        color: badgeText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ★ 選手個人カルテ ボトムシート
  void _showPlayerDetailBottomSheet({
    required BuildContext context,
    required bool isDark,
    required String playerName,
    required _DetailedPlayerStats stats,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        final totalMatches = stats.win + stats.loss + stats.draw;
        final winRate = totalMatches > 0
            ? (stats.win / totalMatches * 100).toStringAsFixed(1)
            : '0.0';
        final totalStrikes =
            stats.men +
            stats.kote +
            stats.dou +
            stats.tsuki +
            stats.hansoku +
            stats.other;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: AppKendoColors.indigo,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '$playerName 選手の個人カルテ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: AppFontWeight.bold,
                              color: context.appColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatPill(
                    '総試合数',
                    '$totalMatches 試合',
                    AppKendoColors.grey,
                  ),
                  _buildStatPill(
                    '勝敗',
                    '${stats.win}勝 ${stats.loss}敗 ${stats.draw > 0 ? "${stats.draw}分" : ""}',
                    AppKendoColors.indigo,
                  ),
                  _buildStatPill('勝率', '$winRate %', AppKendoColors.teal),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '🎯 取得技の内訳',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF9FAFB),
                  borderRadius: AppRadius.large,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFFFFFFF).withValues(alpha: 0.1)
                        : const Color(0xFF000000).withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '面 (メ)',
                        stats.men,
                        totalStrikes,
                        AppKendoColors.teal,
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '小手 (コ)',
                        stats.kote,
                        totalStrikes,
                        AppKendoColors.indigo,
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '胴 (ド)',
                        stats.dou,
                        totalStrikes,
                        const Color(0xFFD97706),
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '突き (ツ)',
                        stats.tsuki,
                        totalStrikes,
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                    Expanded(
                      child: _buildStrikeStatBadge(
                        '反則 (反)',
                        stats.hansoku,
                        totalStrikes,
                        AppKendoColors.hansokuRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStrikeStatBadge(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count本',
          style: const TextStyle(
            fontSize: AppFontSize.bodyMedium,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        Text(
          '$pct%',
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppKendoColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppKendoColors.grey,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: AppFontSize.bodyMedium,
            fontWeight: AppFontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String title,
    int win,
    int loss,
    int draw,
    Color color,
  ) {
    final total = win + loss + draw;
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.bodySmall,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          total > 0 ? '$win勝 $loss敗 ${draw > 0 ? "$draw分" : ""}' : '未実施',
          style: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
        if (total > 0)
          Text(
            '（計$total試合）',
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              color: AppKendoColors.grey,
            ),
          ),
      ],
    );
  }
}

class _DetailedPlayerStats {
  int win = 0;
  int loss = 0;
  int draw = 0;
  int men = 0;
  int kote = 0;
  int dou = 0;
  int tsuki = 0;
  int hansoku = 0;
  int other = 0;
  int totalPoints = 0;
  int concededPoints = 0;
}

class _ExpeditionCardResult {
  final String cardTitle;
  final String opponentTeamName;
  final int myWins;
  final int oppWins;
  final int myPoints;
  final int oppPoints;
  final String resultType;
  final bool isWin;
  final bool isDraw;
  final String scene;

  _ExpeditionCardResult({
    required this.cardTitle,
    required this.opponentTeamName,
    required this.myWins,
    required this.oppWins,
    required this.myPoints,
    required this.oppPoints,
    required this.resultType,
    required this.isWin,
    required this.isDraw,
    required this.scene,
  });
}
