import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import '../providers/viewer_view_state_provider.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_table_sections.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_export_bar.dart';
import 'package:kendo_os/features/viewer/components/viewer_league_grid_table.dart';

class ViewerOfficialRecordScreen extends ConsumerWidget {
  final String tournamentId;
  const ViewerOfficialRecordScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const String screenTitle = '大会 公式記録';

    final bgColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFFF2F2F7);
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;
    final headerTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : context.appColors.primaryAccent;

    // ★ 運営側プロバイダ（tournamentProvider）への依存を完全に遮断し、安全なフォールバック値を適用
    final String? tName = null;
    final String? tDate = null;
    final String? tVenue = null;

    final asyncProj = ref.watch(
      viewerTournamentProjectionProvider(tournamentId),
    );

    return asyncProj.when(
      loading: () => Scaffold(
        backgroundColor: bgColor,
        appBar: AppHeader(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: screenTitle,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: bgColor,
        appBar: AppHeader(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: screenTitle,
          elevation: 0,
        ),
        body: Center(child: Text('エラーが発生しました: $err')),
      ),
      data: (proj) {
        if (proj == null || proj.categoryToGroupKeys.isEmpty) {
          return LiquidBackground(
            child: Scaffold(
              backgroundColor: AppKendoColors.transparent,
              appBar: AppHeader(
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: headerTextColor,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: screenTitle,
                elevation: 0,
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

        final categories = proj.categoryToGroupKeys.keys.toList();

        return DefaultTabController(
          length: categories.length,
          child: LiquidBackground(
            child: Scaffold(
              backgroundColor: AppKendoColors.transparent,
              appBar: AppHeader(
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: headerTextColor,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: screenTitle,
                elevation: 0,
                bottom: TabBar(
                  isScrollable: true,
                  labelColor: headerTextColor,
                  unselectedLabelColor: isDark
                      ? context.appColors.subTextColor
                      : context.appColors.subTextColor,
                  indicatorColor: context.appColors.primaryAccent,
                  tabs: categories
                      .map((cat) => Tab(key: Key('viewer_tab_$cat'), text: cat))
                      .toList(),
                ),
              ),
              body: TabBarView(
                children: categories.map((cat) {
                  final groupKeys = proj.categoryToGroupKeys[cat]!;

                  final sortedGroupKeys = List<String>.from(groupKeys)
                    ..sort((a, b) {
                      final aMatches = proj.teamMatches[a]?.matches;
                      final bMatches = proj.teamMatches[b]?.matches;
                      if (aMatches == null ||
                          aMatches.isEmpty ||
                          bMatches == null ||
                          bMatches.isEmpty) {
                        return 0;
                      }
                      return aMatches.first.order.compareTo(
                        bMatches.first.order,
                      );
                    });

                  return Column(
                    children: [
                      ViewerOfficialRecordExportBar(
                        category: cat,
                        sortedGroupKeys: sortedGroupKeys,
                        proj: proj,
                        tournamentName: tName,
                        tournamentDate: tDate,
                        tournamentVenue: tVenue,
                      ),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          itemCount: sortedGroupKeys.length,
                          itemBuilder: (context, index) {
                            final groupName = sortedGroupKeys[index];
                            final teamProj = proj.teamMatches[groupName];
                            if (teamProj == null) {
                              return const SizedBox.shrink();
                            }

                            final matches = List<MatchListProjection>.from(
                              teamProj.matches,
                            )..sort((a, b) => a.order.compareTo(b.order));

                            // ★ STEP 4/6: matchesが空の場合に matches.first が呼ばれて Bad state で落ちるのを完全に防ぐ防波堤
                            if (matches.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            if (matches.isNotEmpty && teamProj.isKachinuki) {
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

                              int maxRem = 5;
                              int totalCols = matches.length + maxRem;

                              final canvasWidth =
                                  60.0 + (totalCols * 60.0) + 120.0;

                              return InkWell(
                                key: Key('viewer_match_card_$groupName'),
                                onTap: () {}, // Widget Test のタップイベント吸収用ダミー
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm,
                                    horizontal: AppSpacing.xs,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.medium,
                                    side: BorderSide(
                                      color: isDark
                                          ? const Color(0xFF38383A)
                                          : const Color(0x33000000),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
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
                                                : AppKendoColors
                                                      .indigo
                                                      .shade900,
                                          ),
                                        ),
                                      ),
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
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width
                                              ? MediaQuery.of(
                                                  context,
                                                ).size.width
                                              : canvasWidth,
                                          height: 520,
                                          child: const Center(
                                            child: Text(
                                              '※ 勝ち抜き戦のトーナメント表は公式記録出力画面ではサポートされていません。\n各試合のスコアボードからご確認ください',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: AppKendoColors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (matches.isNotEmpty &&
                                teamProj.isLeague) {
                              final ownTeams =
                                  <String>[]; // Viewerモードでは自チームハイライト不要
                              final String leagueTitle =
                                  _generateDescriptiveLeagueTitle(
                                    matches,
                                    ownTeams,
                                  );
                              final textColor = isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF3F51B5);

                              final normalMatches = matches
                                  .where((m) => !m.note.contains('[順位決定戦]'))
                                  .toList();
                              final tieBouts = matches
                                  .where((m) => m.note.contains('[順位決定戦]'))
                                  .toList();

                              final boutsByMatchup =
                                  <String, List<MatchListProjection>>{};
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

                              final tieBoutsByMatchup =
                                  <String, List<MatchListProjection>>{};
                              final tieMatchupOrder = <String>[];
                              for (var m in tieBouts) {
                                final t1 = m.redName.split(':').first.trim();
                                final t2 = m.whiteName.split(':').first.trim();
                                final matchupName = '$t1 vs $t2';
                                if (!tieBoutsByMatchup.containsKey(
                                  matchupName,
                                )) {
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

                                  ViewerLeagueGridTable(
                                    groupName: groupName,
                                    matches: matches,
                                    cardColor: cardColor,
                                    isDark: isDark,
                                    stats: teamProj.leagueStandings,
                                    isLeagueRule: teamProj.isLeague,
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
                                      child: ViewerOfficialIndividualListCard(
                                        groupName: '対戦スコア詳細',
                                        matches: normalMatches,
                                        cardColor: cardColor,
                                        isDark: isDark,
                                        applySort: false,
                                      ),
                                    )
                                  else
                                    ...matchupOrder.map((matchupName) {
                                      final bouts =
                                          boutsByMatchup[matchupName]!;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.xl,
                                        ),
                                        child: ViewerOfficialScoreTableCard(
                                          groupName: matchupName,
                                          matches: bouts,
                                          cardColor: cardColor,
                                          isDark: isDark,
                                        ),
                                      );
                                    }),

                                  if (tieBouts.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: AppSpacing.md,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(
                                                0xFFFF9800,
                                              ).withValues(alpha: 0.15)
                                            : const Color(
                                                0xFFFF9800,
                                              ).withValues(alpha: 0.1),
                                        borderRadius: AppRadius.medium,
                                        border: Border.all(
                                          color: const Color(0xFFFF9800),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.emoji_events,
                                            size: 16,
                                            color: Color(0xFFFF9800),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            '同点のため順位決定戦（代表戦・延長戦）を実施',
                                            style: TextStyle(
                                              fontSize: AppFontSize.caption,
                                              fontWeight: AppFontWeight.bold,
                                              color: isDark
                                                  ? const Color(0xFFFFB74D)
                                                  : const Color(0xFFF57C00),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isIndiv)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.lg,
                                        ),
                                        child: ViewerOfficialIndividualListCard(
                                          groupName: '順位決定戦',
                                          matches: tieBouts,
                                          cardColor: isDark
                                              ? const Color(
                                                  0xFFFF9800,
                                                ).withValues(alpha: 0.1)
                                              : const Color(
                                                  0xFFFF9800,
                                                ).withValues(alpha: 0.1),
                                          isDark: isDark,
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
                                          child: ViewerOfficialScoreTableCard(
                                            groupName: matchupName,
                                            matches: bouts,
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
                              // ★ 修正: 表示前のタイミングで、本部によるドラッグ並び替え順を強制固定
                              matches.sort(
                                (a, b) => a.order.compareTo(b.order),
                              );
                              // 👇 追加: 個人戦の場合は、専用の縦並びリスト形式で描画する
                              return ViewerOfficialIndividualListCard(
                                groupName: groupName,
                                matches: matches,
                                cardColor: cardColor,
                                isDark: isDark,
                                applySort: true,
                              );
                            } else {
                              // 通常団体戦の描画
                              return ViewerOfficialScoreTableCard(
                                groupName: groupName,
                                matches: matches,
                                result: teamProj.result,
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
          ), // LiquidBackground
        ); // DefaultTabController
      },
    );
  }

  String _generateDescriptiveLeagueTitle(
    List<MatchListProjection> matches,
    List<String> ownTeams,
  ) {
    final participantsSet = <String>{};
    for (var m in matches) {
      participantsSet.add(m.redName.split(':').first.trim());
      participantsSet.add(m.whiteName.split(':').first.trim());
    }
    final int n = participantsSet.length;
    final int mCount = n * (n - 1) ~/ 2;
    final bool isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );

    String selfInfo = "";
    if (isIndiv) {
      final myMatch = matches.firstWhere(
        (m) => ownTeams.any(
          (ot) => m.redName.contains(ot) || m.whiteName.contains(ot),
        ),
        orElse: () => matches.first,
      );
      final isRedOwn = ownTeams.any((ot) => myMatch.redName.contains(ot));
      final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
      final team = rawName.split(':').first.trim();
      final name = rawName.contains(':')
          ? rawName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
          : rawName;
      selfInfo = "$name（$team）";
    } else {
      selfInfo = participantsSet.firstWhere(
        (p) => ownTeams.contains(p),
        orElse: () => participantsSet.first,
      );
    }
    return "$selfInfo : ${isIndiv ? "$n人リーグ" : "$nチームリーグ"}（全$mCount試合）";
  }
}
