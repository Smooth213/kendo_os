import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
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
    final headerTextColor = isDark ? Colors.white : Colors.indigo.shade900;

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
          backgroundColor: Colors.transparent,
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
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
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
          backgroundColor: Colors.transparent,
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
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/'),

                  icon: Icon(
                    Icons.home,
                    color: isDark ? Colors.white : Colors.indigo.shade700,
                    size: 16,
                  ),
                  label: Text(
                    'トップへ',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.indigo.shade700,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.indigo.shade50,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              labelColor: headerTextColor,
              unselectedLabelColor: isDark
                  ? Colors.grey.shade600
                  : Colors.grey.shade500,
              indicatorColor: Colors.indigo.shade600,
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 1. PDF出力
                        _buildHeaderActionButton(
                          icon: Icons.print,
                          label: 'PDF',
                          color: Colors.grey.shade800,
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
                          color: Colors.indigo.shade600,
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
                              vertical: 8,
                              horizontal: 4,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.large,
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF38383A)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  color: isDark
                                      ? Colors.indigo.shade900.withValues(
                                          alpha: 0.4,
                                        )
                                      : Colors.indigo.shade50,
                                  width: double.infinity,
                                  child: Text(
                                    titleText,
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                      color: isDark
                                          ? Colors.indigo.shade100
                                          : Colors.indigo.shade900,
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
                                    color: isDark ? Colors.black : Colors.white,
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
                              ? Colors.white
                              : Colors.indigo.shade900;

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
                                  top: 24,
                                  bottom: 12,
                                  left: 8,
                                ),
                                child: Text(
                                  '【リーグ戦】 $leagueTitle',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                    color: textColor,
                                    fontSize: 16,
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
                                padding: EdgeInsets.only(left: 8, bottom: 12),
                                child: Text(
                                  '▼ 対戦カード別 スコア詳細',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                              // 2. 詳細スコアの表示（個人戦なら中枠なしの一括リスト）
                              if (isIndiv)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
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
                                    padding: const EdgeInsets.only(bottom: 24),
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
                                  padding: EdgeInsets.only(left: 8, bottom: 8),
                                  child: Text(
                                    '▼ 順位決定戦',
                                    style: TextStyle(
                                      fontWeight: AppFontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                if (isIndiv)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildIndividualMatchesList(
                                      '順位決定戦',
                                      tieBouts,
                                      cardColor: isDark
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.orange.shade50,
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
                                        bottom: 16,
                                      ),
                                      child: _buildScoreTable(
                                        matchupName,
                                        bouts,
                                        cardColor: isDark
                                            ? Colors.orange.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.orange.shade50,
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
          style: const TextStyle(fontWeight: AppFontWeight.bold, fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              barrierColor: Colors.black.withValues(alpha: 0.7),
              transitionDuration: const Duration(milliseconds: 350),
              pageBuilder: (ctx, anim1, anim2) {
                return Center(
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 40,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 550),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: isIndiv
                                ? _buildIndividualMatchesList(
                                    '$rowTeam vs $colTeam',
                                    bouts,
                                    cardColor: Colors.transparent,
                                    isDark: isDark,
                                    ref: ref,
                                    applySort: false,
                                  )
                                : _buildScoreTable(
                                    '$rowTeam vs $colTeam',
                                    bouts,
                                    cardColor: Colors.transparent,
                                    isDark: isDark,
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              foregroundColor: isDark
                                  ? Colors.white
                                  : Colors.black87,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
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

    // 1. 自チーム名の確定（登録されている自チームのみをリスト化）
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

    // 自チーム判定
    bool isMyTeam(String teamName) {
      if (registeredTeamNames.isNotEmpty) {
        return registeredTeamNames.contains(teamName);
      }
      // 登録がない場合は一覧の最初のチームをメイン自チームとして扱う
      return teamsList.isNotEmpty && teamsList.first == teamName;
    }

    // 自チーム選手判定
    bool isMyPlayer(String playerName, String teamName) {
      if (registeredPlayerNames.isNotEmpty) {
        return registeredPlayerNames.contains(playerName);
      }
      return isMyTeam(teamName);
    }

    int renseikaiWin = 0, renseikaiLoss = 0, renseikaiDraw = 0;
    int honsenWin = 0, honsenLoss = 0, honsenDraw = 0;
    int moushiawaseWin = 0, moushiawaseLoss = 0, moushiawaseDraw = 0;

    final Map<String, _PlayerStats> playerStatsMap = {};

    // groupName ごとに試合をまとめる（団体戦・勝ち抜き戦・リーグ団体戦のチーム単位集計）
    final Map<String, List<MatchModel>> groupMap = {};
    for (final m in matches) {
      final key = (m.groupName != null && m.groupName!.isNotEmpty)
          ? m.groupName!
          : m.id;
      groupMap.putIfAbsent(key, () => []).add(m);
    }

    // ★ 試合が実施済み（終了済み、スコア入力済み、または打突イベントあり）かを判定するヘルパー
    bool isMatchPlayed(MatchModel m) {
      if (m.status == 'finished') return true;
      if (m.redScore > 0 || m.whiteScore > 0) return true;
      if (m.events.isNotEmpty) return true;
      return false;
    }

    for (final entry in groupMap.entries) {
      final bouts = entry.value;
      if (bouts.isEmpty) continue;

      final firstMatch = bouts.first;
      final bool isTeamMatch =
          bouts.length > 1 ||
          firstMatch.isKachinuki ||
          firstMatch.matchType.contains('団体');

      if (isTeamMatch) {
        // ★ 団体戦 / 勝ち抜き戦 / リーグ団体戦: チーム対戦カード全体の勝敗を算出
        final rTeam = firstMatch.redName.contains(':')
            ? firstMatch.redName.split(':').first.trim()
            : firstMatch.redName.trim();
        final wTeam = firstMatch.whiteName.contains(':')
            ? firstMatch.whiteName.split(':').first.trim()
            : firstMatch.whiteName.trim();

        final bool rIsMine = isMyTeam(rTeam);
        final bool wIsMine = isMyTeam(wTeam);

        // 自チームがどちらにも含まれない対戦は集計対象外
        if (!rIsMine && !wIsMine) continue;

        final bool isTargetRed =
            (_selectedSummaryTeam == '全体' && rIsMine) ||
            (_selectedSummaryTeam == rTeam);
        final bool isTargetWhite =
            (_selectedSummaryTeam == '全体' && wIsMine) ||
            (_selectedSummaryTeam == wTeam);

        if (!isTargetRed && !isTargetWhite) continue;

        // 実施済みの試合（終了済み、またはスコア/イベントあり）を取得
        final playedBouts = bouts.where((b) => isMatchPlayed(b)).toList();

        // 1試合も実施されていない（全試合前）カードはサマリーから除外
        if (playedBouts.isEmpty) continue;

        int redWins = 0;
        int whiteWins = 0;

        if (firstMatch.isKachinuki) {
          final lastMatch = bouts.last;
          if (isMatchPlayed(lastMatch)) {
            if (lastMatch.redRemaining.length >
                lastMatch.whiteRemaining.length) {
              redWins = 1;
            } else if (lastMatch.whiteRemaining.length >
                lastMatch.redRemaining.length) {
              whiteWins = 1;
            }
          } else {
            // 途中経過の場合でも勝者数でカウント
            for (final b in playedBouts) {
              if (b.redScore > b.whiteScore) {
                redWins++;
              } else if (b.whiteScore > b.redScore) {
                whiteWins++;
              }
            }
          }
        } else {
          for (final b in playedBouts) {
            if (b.redScore > b.whiteScore) {
              redWins++;
            } else if (b.whiteScore > b.redScore) {
              whiteWins++;
            }
          }
        }

        bool isWin = false;
        final bool isCardFinished = bouts.every((b) => isMatchPlayed(b));
        bool isDraw = false;

        if (redWins > whiteWins) {
          if (isTargetRed) isWin = true;
        } else if (whiteWins > redWins) {
          if (isTargetWhite) isWin = true;
        } else {
          // 引き分け（または途中経過で同点）
          if (isCardFinished || playedBouts.length >= (bouts.length / 2)) {
            isDraw = true;
          } else {
            continue;
          }
        }

        final scene = firstMatch.matchScene;
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
        // ★ 個人戦 / リーグ個人戦: 実施済みの試合（isMatchPlayed）のみを集計
        for (final m in bouts) {
          if (!isMatchPlayed(m)) {
            continue;
          }

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
          bool isWin = false;

          if (!isDraw) {
            if (isTargetRed && m.redScore > m.whiteScore) {
              isWin = true;
            } else if (isTargetWhite && m.whiteScore > m.redScore) {
              isWin = true;
            }
          }

          // 自チームの選手のみを個人成績マップに記録
          if (isTargetRed && rPlayer.isNotEmpty && isMyPlayer(rPlayer, rTeam)) {
            final stats = playerStatsMap.putIfAbsent(
              rPlayer,
              () => _PlayerStats(),
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
              () => _PlayerStats(),
            );
            if (isDraw) {
              stats.draw++;
            } else if (m.whiteScore > m.redScore) {
              stats.win++;
            } else {
              stats.loss++;
            }
          }

          final scene = m.matchScene;
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
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.indigo,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '🏆 遠征成績サマリー',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (teamsList.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.indigo.shade900.withValues(alpha: 0.5)
                        : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: teamsList.contains(_selectedSummaryTeam)
                          ? _selectedSummaryTeam
                          : '全体',
                      isDense: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.indigo,
                        size: 20,
                      ),
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.indigo.shade900,
                      ),
                      items: ['全体', ...teamsList].map((t) {
                        return DropdownMenuItem<String>(
                          value: t,
                          child: Text(t == '全体' ? '全チーム合計' : t),
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
                Colors.amber.shade900,
              ),
              _buildSummaryItem(
                '🏆 本戦',
                honsenWin,
                honsenLoss,
                honsenDraw,
                Colors.indigo.shade900,
              ),
              _buildSummaryItem(
                '🤝 申し合わせ',
                moushiawaseWin,
                moushiawaseLoss,
                moushiawaseDraw,
                Colors.teal.shade900,
              ),
            ],
          ),
          if (playerStatsMap.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              '👤 個人戦・選手別成績',
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: playerStatsMap.entries.map((entry) {
                final pName = entry.key;
                final st = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '$pName: ${st.win}勝${st.loss}敗${st.draw > 0 ? "${st.draw}分" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: AppFontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
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
            fontSize: 13,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          total > 0 ? '$win勝 $loss敗 ${draw > 0 ? "$draw分" : ""}' : '未実施',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
        if (total > 0)
          Text(
            '（計$total試合）',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
      ],
    );
  }
}

class _PlayerStats {
  int win = 0;
  int loss = 0;
  int draw = 0;
}
