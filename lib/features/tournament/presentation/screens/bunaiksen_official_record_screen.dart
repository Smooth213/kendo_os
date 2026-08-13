import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/providers/bunaiksen_provider.dart';
import 'package:kendo_os/features/pdf/pdf_service.dart' deferred as pdf_service;
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart'; // 勝ち抜き戦描画用
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart'; // ★ 追加: 分離したヘルパー
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart'; // Sideなどを利用
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/features/match/presentation/providers/match_view_model_provider.dart';
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

class OfficialPointDisplay {
  final String mark;
  final bool isFirstMatchPoint;
  OfficialPointDisplay(this.mark, this.isFirstMatchPoint);
}

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
                // ★ 修正: 部内戦用の個人戦タイムライン並び替え順(order)を完全保持
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
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0x33000000),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.print,
                            'PDF印刷',
                            context.appColors.textColor,
                            isExporting
                                ? null
                                : () => _handleExport(
                                    context,
                                    ref,
                                    cat,
                                    mergedGroups,
                                    sortedGroupKeys,
                                    isPdf: true,
                                    tName: tName,
                                    tDate: tDate,
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.share,
                            '画像シェア',
                            const Color(0xFF06C755),
                            isExporting
                                ? null
                                : () => _handleExport(
                                    context,
                                    ref,
                                    cat,
                                    mergedGroups,
                                    sortedGroupKeys,
                                    isPdf: false,
                                    tName: tName,
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

                        // 1. 勝ち抜き戦の描画
                        if (bouts.isNotEmpty && bouts.first.isKachinuki) {
                          return _buildKachinukiCard(
                            context,
                            ref,
                            bouts,
                            isDark,
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
                          return _buildIndividualMatchesList(
                            groupName,
                            bouts,
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
        ), // Scaffold
      ),
    ); // LiquidBackground
  }

  // --- ヘルパーWidget ---

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: AppFontWeight.bold,
          fontSize: AppFontSize.bodySmall,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppKendoColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        elevation: 0,
      ),
    );
  }

  // ★ 勝ち抜き戦カードの描画（公式仕様）
  Widget _buildKachinukiCard(
    BuildContext context,
    WidgetRef ref,
    List<MatchModel> matches,
    bool isDark,
  ) {
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

  // ★ リーグ戦セクションの描画（公式仕様：個人戦リスト対応版）
  Widget _buildLeagueSection(
    BuildContext context,
    WidgetRef ref,
    String groupName,
    List<MatchModel> matches,
    Color cardColor,
    bool isDark,
  ) {
    // 判定ロジックを強化：部内戦ではmatchTypeが様々であるため、団体戦（:を含む名前）でない場合は個人戦とみなす、または既存のキーワードチェックを行う
    final isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦') ||
          (!m.redName.contains(':') &&
              !m.whiteName.contains(':')), // 名前形式からの判定を追加
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _buildLeagueGridTable(
          context,
          groupName,
          matches,
          cardColor: cardColor,
          isDark: isDark,
          ref: ref,
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._groupMatchesByMatchup(matches).entries.map((e) {
          // 詳細スコア部分も個人戦ならリスト形式、団体戦なら表形式に分岐
          return isIndiv
              ? _buildIndividualMatchesList(
                  e.key,
                  e.value,
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

  // --- 公式記録テーブルエンジン一式 (OfficialRecordScreenから移植) ---

  Widget _buildScoreTable(
    String groupName,
    List<MatchModel> matches, {
    Color? cardColor,
    bool isDark = false,
  }) {
    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    // ヘッダー用（個人戦・リーグ戦なら選手名、それ以外はチーム名）
    String headerRed, headerWhite;
    headerRed = matches.first.redName.contains(':')
        ? matches.first.redName.split(':').first.trim()
        : matches.first.redName;
    headerWhite = matches.first.whiteName.contains(':')
        ? matches.first.whiteName.split(':').first.trim()
        : matches.first.whiteName;

    // ★ 修正2：表の横ラベル（チーム名のところ）は、個人戦・リーグ戦・団体戦問わず「赤」「白」に固定
    String sideLabelRed = '赤';
    String sideLabelWhite = '白';

    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0x33000000);
    final headerTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xDE000000);
    final daihyoBgColor = isDark
        ? const Color(0xFFE53935).withValues(alpha: 0.15)
        : const Color(0xFFE53935);

    // ★ 修正：スコアが入力されている試合は、ステータスに関わらず「完了」として扱う
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
                  // ★ sideLabelRed ("赤") を使用
                  _buildTeamRow(matches, true, sideLabelRed, isDark),
                  TableRow(
                    children: [
                      const SizedBox.shrink(),
                      ...matches.map((m) => _scoreCell(m, isDark, isSummary)),
                      _teamResultCell(teamWinner, isDark, allFinished),
                    ],
                  ),
                  // ★ sideLabelWhite ("白") を使用
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
                            ? const Color(0xFFFFFFFF)
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
          // 勝負がついていても、試合途中なら境界線（Divider）だけは表示してレイアウトを保つ
          if (winner != 'draw' || !allFinished)
            Divider(color: dividerColor, thickness: 1, height: 0),

          // ★ すべての試合が終わっている場合のみテキストを表示
          if (allFinished) ...[
            if (winner == 'draw')
              Center(child: _buildVerticalName('引き分け', '', isDark))
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
          final teamLastNames = matches
              .map((x) {
                final xName = isRed ? x.redName : x.whiteName;
                return BunaiksenHelper.parseName(xName)['last']!;
              })
              .where((s) => s.isNotEmpty)
              .toList();

          return _nameCell(
            name,
            isDark,
            teamLastNames,
            isDaihyo: m.matchType == '代表戦',
          );
        }),
        _summaryCell(matches, isRed, isDark),
      ],
    );
  }

  Widget _nameCell(
    String rawName,
    bool isDark,
    List<String> teamLastNames, {
    bool isDaihyo = false,
  }) {
    if (rawName.contains('欠員')) {
      return Container(
        color: isDaihyo
            ? (isDark
                  ? const Color(0xFFE53935).withValues(alpha: 0.15)
                  : const Color(0xFFE53935))
            : Colors.transparent,
      );
    }

    final parsed = BunaiksenHelper.parseName(rawName);
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
          child: _buildVerticalName(
            parsed['last']!,
            showInitial ? parsed['first']!.substring(0, 1) : '',
            isDark,
          ),
        ),
      ),
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

    // KendoRuleEngineによる解析を使用
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
                child: _buildPointBox(
                  redPts,
                  isDone && rScore > wScore,
                  true,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildPointBox(
                  whitePts,
                  isDone && wScore > rScore,
                  false,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 公式記録風の技マークボックス（丸囲み等）
  Widget _buildPointBox(
    List<OfficialPointDisplay> pts,
    bool isWinner,
    bool isRed,
    bool isDark,
  ) {
    final color = isRed
        ? (isDark ? const Color(0xFFE53935) : const Color(0xFFE53935))
        : (isDark ? const Color(0xFF2196F3) : const Color(0xFF2196F3));
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isWinner)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
          if (pts.isNotEmpty)
            Positioned(
              top: AppSpacing.xs,
              left: 6,
              child: _renderMark(pts[0], color),
            ),
          if (pts.length > 1)
            Positioned(
              bottom: AppSpacing.xs,
              right: 6,
              child: _renderMark(pts[1], color),
            ),
        ],
      ),
    );
  }

  Widget _renderMark(OfficialPointDisplay p, Color color) {
    String displayMark = p.mark == '判定' ? '判' : p.mark;
    if (p.isFirstMatchPoint && displayMark != '反') {
      return Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 0.8),
        ),
        child: Text(
          displayMark,
          style: TextStyle(
            fontSize: AppFontSize.micro,
            color: color,
            fontWeight: AppFontWeight.bold,
            height: 1.1,
          ),
        ),
      );
    }
    return Text(
      displayMark,
      style: TextStyle(
        fontSize: AppFontSize.badge,
        color: color,
        fontWeight: AppFontWeight.bold,
        height: 1.1,
      ),
    );
  }

  // --- 共通ロジック & ヘルパー ---

  Widget _buildVerticalName(String text, String initial, bool isDark) {
    final style = TextStyle(
      fontSize: AppFontSize.caption,
      fontWeight: AppFontWeight.bold,
      color: isDark ? const Color(0xFFFFFFFF) : const Color(0xDE000000),
    );

    Widget nameCol = Column(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((char) {
        if (char == 'ー' || char == '-') {
          return RotatedBox(quarterTurns: 1, child: Text(char, style: style));
        }
        if (char == '(' || char == ')' || char == '（' || char == '）') {
          return RotatedBox(quarterTurns: 1, child: Text(char, style: style));
        }
        return Text(char, style: style.copyWith(height: 1.1));
      }).toList(),
    );

    if (initial.isEmpty) return nameCol;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        nameCol,
        Padding(
          padding: const EdgeInsets.only(left: 1, bottom: 0),
          child: Text(
            initial,
            style: style.copyWith(
              fontSize: AppFontSize.micro,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCell(List<MatchModel> ms, bool isRed, bool isDark) {
    int wins = 0, pts = 0;
    for (var m in ms) {
      if (m.matchType == '代表戦') continue; // ★ 代表戦のスコアはチームの本数・勝数に含めない
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
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xDE000000),
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

  // ★ 究極版：リーグ戦グリッド描画（公式の自動計算付きフルスペック版）
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

    // 🌟 修正：部内戦特有のデータ形式に対応するため、名前形式（:を含まない）での個人戦判定を追加
    final isIndiv = normalMatches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦') ||
          (!m.redName.contains(':') && !m.whiteName.contains(':')),
    );
    final allFinished = matches.every(
      (m) => m.status == 'approved' || m.status == 'finished',
    );
    final hasMatchPoints = nonNullRule.isLeague;

    final teams = <String>{};
    for (var m in normalMatches) {
      teams.add(m.redName.split(':').first.trim());
      teams.add(m.whiteName.split(':').first.trim());
    }
    final teamList = teams.toList()..sort();

    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0x8A000000);
    final headerColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFF3F51B5);
    final blankColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0x33000000);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.small,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Table(
          border: TableBorder.all(color: borderColor, width: 1),
          columnWidths: {
            0: const FixedColumnWidth(100),
            for (int i = 1; i <= teamList.length; i++)
              i: const FixedColumnWidth(65),
            teamList.length + 1: const FixedColumnWidth(45),
            teamList.length + 2: const FixedColumnWidth(45),
            teamList.length + 3: const FixedColumnWidth(45),
            if (hasMatchPoints) teamList.length + 4: const FixedColumnWidth(45),
            teamList.length + (hasMatchPoints ? 5 : 4): const FixedColumnWidth(
              45,
            ),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerColor),
              children: [
                const SizedBox(height: 50),
                ...teamList.map(
                  (t) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: _buildVerticalName(t, '', isDark),
                    ),
                  ),
                ),
                _buildHeaderCell('勝数', isDark),
                _buildHeaderCell('勝者', isDark),
                _buildHeaderCell('本数', isDark),
                if (hasMatchPoints) _buildHeaderCell('勝点', isDark),
                _buildHeaderCell('順位', isDark),
              ],
            ),
            ...teamList.map((rowTeam) {
              final stat = stats.firstWhere(
                (s) => s.name == rowTeam,
                orElse: () => stats.first,
              );
              final rankStr = allFinished
                  ? '${stats.indexWhere((s) => s.name == rowTeam) + 1}'
                  : '-';

              // ★ 修正：分離したヘルパーを使って勝点を計算する
              int customTeamPoints =
                  BunaiksenHelper.calculateCustomLeaguePoints(
                    rowTeam,
                    teamList,
                    normalMatches,
                  );

              return TableRow(
                children: [
                  Container(
                    height: 65,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: headerColor),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Text(
                        rowTeam,
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.caption,
                          color: isDark
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF000000),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  ...teamList.map((colTeam) {
                    if (rowTeam == colTeam) {
                      return Container(
                        height: 65,
                        color: blankColor,
                        child: CustomPaint(
                          painter: DiagonalLinePainter(color: borderColor),
                        ),
                      );
                    }
                    final bouts = normalMatches.where((m) {
                      final r = m.redName.split(':').first.trim();
                      final w = m.whiteName.split(':').first.trim();
                      return (r == rowTeam && w == colTeam) ||
                          (r == colTeam && w == rowTeam);
                    }).toList();

                    if (bouts.isEmpty) {
                      return const SizedBox(height: 65);
                    }

                    int rWins = 0,
                        cWins = 0,
                        rPoints = 0,
                        cPoints = 0,
                        rWinners = 0,
                        cWinners = 0;
                    List<OfficialPointDisplay> techs = [];
                    for (var m in bouts) {
                      final isRowRed =
                          m.redName.split(':').first.trim() == rowTeam;
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
                        final engine = KendoRuleEngine();
                        final analysis = engine.analyzeHistory(
                          m.events,
                          m,
                          m.rule,
                        );
                        final proj = MatchProjectionMapper.toProjection(
                          m,
                          analysis,
                        );
                        final bool isRowFirst =
                            (isRowRed && proj.firstPointSide == 'red') ||
                            (!isRowRed && proj.firstPointSide == 'white');
                        final displays = isRowRed
                            ? analysis.displays[Side.red]
                            : analysis.displays[Side.white];
                        List<OfficialPointDisplay> extracted = [];
                        if (displays != null) {
                          for (int k = 0; k < displays.length; k++) {
                            extracted.add(
                              OfficialPointDisplay(
                                displays[k].mark,
                                k == 0 && isRowFirst,
                              ),
                            );
                          }
                        }

                        final bool isSummary = m.note.contains('[SUMMARY]');
                        if (isSummary || extracted.isEmpty) {
                          extracted.clear();
                          for (int k = 0; k < (isRowRed ? rs : ws); k++) {
                            extracted.add(OfficialPointDisplay('◯', false));
                          }
                        }
                        techs.addAll(extracted);
                      }
                    }

                    String result = 'draw';
                    Color symbolColor = isDark
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFFD4AF37);
                    if (rWins > cWins) {
                      result = 'win';
                      symbolColor = isDark
                          ? const Color(0xFFE53935)
                          : const Color(0xFFE53935);
                    } else if (cWins > rWins) {
                      result = 'loss';
                      symbolColor = isDark
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF3F51B5);
                    } else if (rPoints != cPoints) {
                      if (rPoints > cPoints) {
                        result = 'win';
                        symbolColor = isDark
                            ? const Color(0xFFE53935)
                            : const Color(0xFFE53935);
                      } else {
                        result = 'loss';
                        symbolColor = isDark
                            ? const Color(0xFF2196F3)
                            : const Color(0xFF3F51B5);
                      }
                    }

                    if (!bouts.every(
                      (m) => m.status == 'approved' || m.status == 'finished',
                    )) {
                      return const SizedBox(height: 65);
                    }

                    final textColor = isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: '閉じる',
                          barrierColor: AppKendoColors.pureBlack.withValues(
                            alpha: 0.7,
                          ),
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
                                  constraints: const BoxConstraints(
                                    maxWidth: 550,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1C1C1E)
                                        : const Color(0xFFFFFFFF),
                                    borderRadius: AppRadius.round,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppKendoColors.pureBlack
                                            .withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(
                                    AppSpacing.roundValue,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: isIndiv
                                            // 🌟 修正：個人戦なら必ずリスト形式を呼び出し、ソートは不要(applySort: false)
                                            ? _buildIndividualMatchesList(
                                                '$rowTeam vs $colTeam',
                                                bouts,
                                                cardColor:
                                                    AppKendoColors.transparent,
                                                isDark: isDark,
                                              )
                                            : _buildScoreTable(
                                                '$rowTeam vs $colTeam',
                                                bouts,
                                                cardColor:
                                                    AppKendoColors.transparent,
                                                isDark: isDark,
                                              ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark
                                              ? const Color(0xFFFFFFFF)
                                              : const Color(0x33000000),
                                          foregroundColor: isDark
                                              ? const Color(0xFFFFFFFF)
                                              : const Color(0xFF000000),
                                          shape: const StadiumBorder(),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: AppSpacing.md,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          '閉じる',
                                          style: TextStyle(
                                            fontWeight: AppFontWeight.bold,
                                          ),
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
                                scale: Tween<double>(begin: 0.9, end: 1.0)
                                    .animate(
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
                      child: Container(
                        height: 65,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(45, 45),
                              painter: ResultShapePainter(
                                result: result,
                                color: symbolColor,
                              ),
                            ),
                            if (isIndiv)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  techs.isNotEmpty
                                      ? _buildTechMark(techs[0], textColor)
                                      : const SizedBox(height: AppSpacing.md),
                                  Container(
                                    height: 0.5,
                                    width: 18,
                                    color: textColor.withValues(alpha: 0.5),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xxs,
                                    ),
                                  ),
                                  techs.length > 1
                                      ? _buildTechMark(techs[1], textColor)
                                      : const SizedBox(height: AppSpacing.md),
                                ],
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$rPoints',
                                    style: TextStyle(
                                      fontSize: AppFontSize.small,
                                      fontWeight: AppFontWeight.bold,
                                      height: 1.1,
                                      color: textColor,
                                    ),
                                  ),
                                  Container(
                                    height: 0.5,
                                    width: 18,
                                    color: textColor.withValues(alpha: 0.5),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xxs,
                                    ),
                                  ),
                                  Text(
                                    '$rWinners',
                                    style: TextStyle(
                                      fontSize: AppFontSize.small,
                                      fontWeight: AppFontWeight.bold,
                                      height: 1.1,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  _buildStatCell('${stat.matchWins}', isDark),
                  _buildStatCell('${stat.individualWinners}', isDark),
                  _buildStatCell('${stat.totalPointsScored}', isDark),
                  // ★ 修正：システム計算の stat.customPoints ではなく、上で計算した customTeamPoints を表示する
                  if (hasMatchPoints)
                    _buildStatCell('$customTeamPoints', isDark),
                  _buildStatCell(rankStr, isDark, isRank: true),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          text,
          style: TextStyle(
            fontSize: AppFontSize.badge,
            color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCell(String text, bool isDark, {bool isRank = false}) {
    return Container(
      height: 65,
      alignment: Alignment.center,
      color: isRank
          ? (isDark
                ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                : const Color(0xFFFF9800))
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: AppFontWeight.bold,
          fontSize: isRank ? 16 : 13,
          color: isRank
              ? const Color(0xFFFF9800)
              : (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000)),
        ),
      ),
    );
  }

  // ★ 追加：個人戦専用の縦並びリスト描画エンジン（部内戦用：ソートなし・進行順）
  Widget _buildIndividualMatchesList(
    String groupName,
    List<MatchModel> matches, {
    Color? cardColor,
    required bool isDark,
  }) {
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0x33000000);
    final headerBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFF2F2F7);
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);

    // ヘッダー名からシステムID（英数字とハイフンの羅列）を隠す処理
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    String displayGroupName = groupName;
    // ★ 修正：__default__ グループと UUID、長い名前、対戦形式の文字列は表示しない
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
    // ★note抽出ロジックは削除完了

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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: headerBgColor,
            width: double.infinity,
            child: Text(
              headerTitle,
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                color: isDark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xDE000000),
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            separatorBuilder: (context, index) => Divider(
              color: borderColor,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final m = matches[index];
              final rName = m.redName.contains(':')
                  ? m.redName.split(':').last.replaceAll(')', '').trim()
                  : m.redName;
              final wName = m.whiteName.contains(':')
                  ? m.whiteName.split(':').last.replaceAll(')', '').trim()
                  : m.whiteName;
              final rTeam = m.redName.contains(':')
                  ? m.redName.split(':').first.trim()
                  : '';
              final wTeam = m.whiteName.contains(':')
                  ? m.whiteName.split(':').first.trim()
                  : '';

              final isDone =
                  m.status == 'finished' ||
                  m.status == 'approved' ||
                  (m.redScore as num).toInt() > 0 ||
                  (m.whiteScore as num).toInt() > 0;
              final rScore = (m.redScore as num).toInt();
              final wScore = (m.whiteScore as num).toInt();
              final isDraw = isDone && rScore == wScore;
              final rWin = isDone && rScore > wScore;
              final wWin = isDone && wScore > rScore;

              final engine = KendoRuleEngine();
              final analysis = engine.analyzeHistory(m.events, m, m.rule);
              final proj = MatchProjectionMapper.toProjection(m, analysis);
              final bool rIsFirst = proj.firstPointSide == 'red';
              final bool wIsFirst = proj.firstPointSide == 'white';

              final rDisplays = analysis.displays[Side.red] ?? [];
              final wDisplays = analysis.displays[Side.white] ?? [];

              final redPts = <OfficialPointDisplay>[];
              for (int i = 0; i < rDisplays.length; i++) {
                redPts.add(
                  OfficialPointDisplay(rDisplays[i].mark, i == 0 && rIsFirst),
                );
              }
              final whitePts = <OfficialPointDisplay>[];
              for (int i = 0; i < wDisplays.length; i++) {
                whitePts.add(
                  OfficialPointDisplay(wDisplays[i].mark, i == 0 && wIsFirst),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 55,
                      child: Text(
                        m.note.isNotEmpty ? m.note : '第${index + 1}試合',
                        style: TextStyle(
                          fontSize: AppFontSize.badge,
                          color: const Color(0x8A000000),
                          fontWeight: AppFontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (rTeam.isNotEmpty)
                            Text(
                              rTeam,
                              style: TextStyle(
                                fontSize: AppFontSize.nano,
                                color: const Color(0x8A000000),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            rName,
                            style: TextStyle(
                              fontWeight: rWin
                                  ? AppFontWeight.black
                                  : AppFontWeight.bold,
                              color: rWin
                                  ? AppKendoColors.hansokuRed
                                  : textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _buildPointBox(redPts, rWin, true, isDark),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        isDraw ? '✕' : '-',
                        style: TextStyle(
                          color: const Color(0x8A000000),
                          fontWeight: AppFontWeight.light,
                          fontSize: AppFontSize.subhead,
                        ),
                      ),
                    ),
                    _buildPointBox(whitePts, wWin, false, isDark),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (wTeam.isNotEmpty)
                            Text(
                              wTeam,
                              style: TextStyle(
                                fontSize: AppFontSize.nano,
                                color: const Color(0x8A000000),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            wName,
                            style: TextStyle(
                              fontWeight: wWin
                                  ? AppFontWeight.black
                                  : AppFontWeight.bold,
                              color: wWin
                                  ? AppKendoColors.hansokuRed
                                  : textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // エクスポート処理
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

  Widget _buildTechMark(OfficialPointDisplay p, Color color) {
    final displayTech = p.mark == '判定' ? '判' : p.mark;
    if (p.isFirstMatchPoint && displayTech != '◯' && displayTech != '反') {
      return Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 0.8),
        ),
        child: Text(
          displayTech,
          style: TextStyle(
            fontSize: AppFontSize.micro,
            color: color,
            fontWeight: AppFontWeight.bold,
            height: 1.1,
          ),
        ),
      );
    }
    return Text(
      displayTech,
      style: TextStyle(
        fontSize: AppFontSize.badge,
        color: color,
        fontWeight: AppFontWeight.bold,
        height: 1.1,
      ),
    );
  }
}

// ★ 追加：表の「自分自身」のセルに斜め線を引くためのクラス
class DiagonalLinePainter extends CustomPainter {
  final Color color;
  DiagonalLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ★ ◯・△・□ を描画する究極のペインター
class ResultShapePainter extends CustomPainter {
  final String result; // 'win', 'loss', 'draw'
  final Color color;
  ResultShapePainter({required this.result, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    if (result == 'win') {
      canvas.drawCircle(center, radius, bgPaint);
      canvas.drawCircle(center, radius, strokePaint);
    } else if (result == 'loss') {
      final path = Path();
      path.moveTo(center.dx, center.dy - radius);
      path.lineTo(center.dx + radius * 1.1, center.dy + radius * 0.8);
      path.lineTo(center.dx - radius * 1.1, center.dy + radius * 0.8);
      path.close();
      canvas.drawPath(path, bgPaint);
      canvas.drawPath(path, strokePaint);
    } else {
      // PDFと同様に四角形(□)を描画する (円と同じくらいの視覚サイズにする)
      final rectSize = radius * 1.8;
      final rect = Rect.fromCenter(
        center: center,
        width: rectSize,
        height: rectSize,
      );
      canvas.drawRect(rect, bgPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
