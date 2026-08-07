import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import '../providers/viewer_view_state_provider.dart';
import 'package:kendo_os/features/pdf/pdf_service.dart' deferred as pdf_service;
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/time/time_source.dart'; // ★ 追加
import 'package:kendo_os/shared/widgets/match_tables/score_table_card.dart';
import 'package:kendo_os/shared/widgets/match_tables/league_grid_card.dart';
import 'package:kendo_os/shared/widgets/match_tables/individual_list_card.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

final isExportingProvider = StateProvider.autoDispose<bool>((ref) => false);

class ViewerOfficialRecordScreen extends ConsumerWidget {
  final String tournamentId;
  const ViewerOfficialRecordScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExporting = ref.watch(isExportingProvider);

    const String screenTitle = '大会 公式記録';

    final bgColor = isDark ? AppKendoColors.pureBlack : const Color(0xFFF2F2F7);
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;
    final headerTextColor = isDark
        ? AppKendoColors.pureWhite
        : AppKendoColors.indigo.shade900;

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
                      ? AppKendoColors.grey.shade600
                      : AppKendoColors.grey.shade500,
                  indicatorColor: AppKendoColors.indigo.shade600,
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
                              color: context.appColors.separatorColor,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                // ★ STEP 2：テストコード側から、ボタン内のテキストや配置に依存せず一撃で Finder 捕捉可能にする不変 Key
                                key: const Key('viewer_export_pdf_button'),
                                onPressed: isExporting
                                    ? null
                                    : () async {
                                        if (ref.read(isExportingProvider)) {
                                          return;
                                        }
                                        ref
                                                .read(
                                                  isExportingProvider.notifier,
                                                )
                                                .state =
                                            true;
                                        final groupDataList = sortedGroupKeys
                                            .map(
                                              (key) => {
                                                'groupName': key,
                                                'matches':
                                                    List<
                                                        MatchListProjection
                                                      >.from(
                                                        proj
                                                            .teamMatches[key]!
                                                            .matches,
                                                      )
                                                      ..sort(
                                                        (a, b) => a.order
                                                            .compareTo(b.order),
                                                      ),
                                              },
                                            )
                                            .toList();

                                        BuildContext? dialogContext;
                                        showAppDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (ctx) {
                                            dialogContext = ctx;
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                        );

                                        try {
                                          final now = ref
                                              .read(timeSourceProvider)
                                              .now();
                                          await pdf_service.loadLibrary();
                                          await pdf_service
                                              .PdfService.printOfficialRecord(
                                            cat,
                                            groupDataList,
                                            tournamentName: tName,
                                            tournamentDate: tDate,
                                            tournamentVenue: tVenue,
                                            outputTime: now,
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            AppSnackBar.showError(
                                              context,
                                              '出力に失敗しました: $e',
                                            );
                                          }
                                        } finally {
                                          ref
                                                  .read(
                                                    isExportingProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              false;
                                          if (dialogContext != null &&
                                              dialogContext!.mounted) {
                                            Navigator.pop(dialogContext!);
                                          } else if (context.mounted) {
                                            Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).pop();
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.print),
                                label: const Text(
                                  'PDF印刷',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppKendoColors.grey.shade800,
                                  foregroundColor: AppKendoColors.pureWhite,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.medium,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: ElevatedButton.icon(
                                key: const Key('viewer_export_image_button'),
                                onPressed: () async {
                                  final groupDataList = sortedGroupKeys
                                      .map(
                                        (key) => {
                                          'groupName': key,
                                          'matches':
                                              List<MatchListProjection>.from(
                                                proj.teamMatches[key]!.matches,
                                              )..sort(
                                                (a, b) =>
                                                    a.order.compareTo(b.order),
                                              ),
                                        },
                                      )
                                      .toList();

                                  BuildContext? dialogContext;
                                  showAppDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) {
                                      dialogContext = ctx;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );

                                  try {
                                    final now = ref
                                        .read(timeSourceProvider)
                                        .now();
                                    await pdf_service.loadLibrary();
                                    await pdf_service
                                        .PdfService.shareOfficialRecordAsImage(
                                      cat,
                                      groupDataList,
                                      tournamentName: tName,
                                      tournamentDate: tDate,
                                      tournamentVenue: tVenue,
                                      outputTime: now,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppSnackBar.showError(
                                        context,
                                        '出力に失敗しました: $e',
                                      );
                                    }
                                  } finally {
                                    if (dialogContext != null &&
                                        dialogContext!.mounted) {
                                      Navigator.pop(dialogContext!);
                                    } else if (context.mounted) {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                    }
                                  }
                                },
                                icon: const Icon(Icons.share),
                                label: const Text(
                                  '画像シェア',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF06C755),
                                  foregroundColor: AppKendoColors.pureWhite,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.medium,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                                          : AppKendoColors.grey.shade300,
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
                                            ? AppKendoColors.indigo.shade900
                                                  .withValues(alpha: 0.4)
                                            : AppKendoColors.indigo.shade50,
                                        width: double.infinity,
                                        child: Text(
                                          titleText,
                                          style: TextStyle(
                                            fontWeight: AppFontWeight.bold,
                                            color: isDark
                                                ? AppKendoColors.indigo.shade100
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
                                              ? AppKendoColors.pureBlack
                                              : AppKendoColors.pureWhite,
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
                                  ? AppKendoColors.pureWhite
                                  : AppKendoColors.indigo.shade900;

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

                                  _buildLeagueGridTableViewer(
                                    context,
                                    groupName,
                                    matches,
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
                                      child: _buildIndividualMatchesListViewer(
                                        '対戦スコア詳細',
                                        normalMatches,
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
                                        child: _buildScoreTableViewer(
                                          matchupName,
                                          bouts,
                                          cardColor: cardColor,
                                          isDark: isDark,
                                        ),
                                      );
                                    }),

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
                                        child:
                                            _buildIndividualMatchesListViewer(
                                              '順位決定戦',
                                              tieBouts,
                                              cardColor: isDark
                                                  ? AppKendoColors.orange
                                                        .withValues(alpha: 0.1)
                                                  : AppKendoColors
                                                        .orange
                                                        .shade50,
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
                                          child: _buildScoreTableViewer(
                                            matchupName,
                                            bouts,
                                            cardColor: isDark
                                                ? AppKendoColors.orange
                                                      .withValues(alpha: 0.1)
                                                : AppKendoColors.orange.shade50,
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
                              return _buildIndividualMatchesListViewer(
                                groupName,
                                matches,
                                cardColor: cardColor,
                                isDark: isDark,
                                applySort: true,
                              );
                            } else {
                              // 通常団体戦の描画
                              return _buildScoreTableViewer(
                                groupName,
                                matches,
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

  Widget _buildScoreTableViewer(
    String groupName,
    List<MatchListProjection> matches, {
    TeamMatchResult? result,
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

    String teamWinner = 'draw';
    int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
    bool allFinished = false;

    if (result != null) {
      teamWinner = result.teamWinner;
      rWins = result.redWins;
      wWins = result.whiteWins;
      rPts = result.redPoints;
      wPts = result.whitePoints;
      allFinished = result.allFinished;
    } else {
      allFinished = matches.every(
        (m) => m.status == 'approved' || m.status == 'finished',
      );
      MatchListProjection? daihyoMatch;
      for (var m in matches) {
        if (m.status == 'approved' || m.status == 'finished') {
          final rs = m.redScore;
          final ws = m.whiteScore;
          rPts += rs;
          wPts += ws;
          if (rs > ws) {
            rWins++;
          } else if (ws > rs) {
            wWins++;
          }
        }
        if (m.matchType == '代表戦') daihyoMatch = m;
      }
      if (allFinished) {
        if (rWins > wWins) {
          teamWinner = 'red';
        } else if (wWins > rWins) {
          teamWinner = 'white';
        } else if (rPts > wPts) {
          teamWinner = 'red';
        } else if (wPts > rPts) {
          teamWinner = 'white';
        } else if (daihyoMatch != null) {
          final rs = daihyoMatch.redScore;
          final ws = daihyoMatch.whiteScore;
          if (rs > ws) {
            teamWinner = 'red';
          } else if (ws > rs) {
            teamWinner = 'white';
          }
        }
      }
    }

    final bool isSummary = matches.any((m) => m.note.contains('[SUMMARY]'));

    final info = ScoreTableGroupInfo(
      groupName: groupName,
      headerTitle: headerTitle,
      sideLabelRed: redTeam,
      sideLabelWhite: whiteTeam,
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
      final ptsMap = MatchCalculatorHelper.extractPointsFromProjection(m);
      return ScoreTableMatchItem(
        id: m.id,
        matchType: m.matchType,
        redName: m.redName,
        whiteName: m.whiteName,
        redScore: m.redScore,
        whiteScore: m.whiteScore,
        isFinished: isFinished,
        isSummary: m.note.contains('[SUMMARY]'),
        isEncho: MatchCalculatorHelper.isEnchoFromProjection(m),
        redPoints: ptsMap['red'] ?? [],
        whitePoints: ptsMap['white'] ?? [],
        onTap: () {},
      );
    }).toList();

    return InkWell(
      key: Key('viewer_match_card_$groupName'),
      onTap: () {}, // Widget Test のタップイベント吸収用ダミー
      child: ScoreTableCard(
        info: info,
        matches: matchItems,
        cardColor: cardColor,
        isDark: isDark,
      ),
    );
  }

  Widget _buildLeagueGridTableViewer(
    BuildContext context,
    String groupName,
    List<MatchListProjection> matches, {
    Color? cardColor,
    required bool isDark,
    required List<dynamic> stats,
    required bool isLeagueRule,
  }) {
    final normalMatches = matches
        .where((m) => !m.note.contains('[順位決定戦]'))
        .toList();
    if (normalMatches.isEmpty) return const SizedBox();

    final isIndiv = normalMatches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );
    final allFinished = matches.every(
      (m) => m.status == 'approved' || m.status == 'finished',
    );
    final hasMatchPoints = isLeagueRule;

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

    final teamSet = <String>{};
    for (var m in normalMatches) {
      teamSet.add(getEntityName(m.redName));
      teamSet.add(getEntityName(m.whiteName));
    }
    final teamList = teamSet.toList()..sort();

    String getStatName(dynamic s) => s is Map ? s['name'] : (s?.name ?? '');
    int getStatMatchWins(dynamic s) =>
        s is Map ? (s['matchWins'] ?? 0) : (s?.matchWins ?? 0);
    int getStatIndivWinners(dynamic s) =>
        s is Map ? (s['individualWinners'] ?? 0) : (s?.individualWinners ?? 0);
    int getStatTotalPts(dynamic s) =>
        s is Map ? (s['totalPointsScored'] ?? 0) : (s?.totalPointsScored ?? 0);
    double getStatCustomPts(dynamic s) => s == null
        ? 0.0
        : (s is Map
              ? ((s['customPoints'] ?? 0.0) as num).toDouble()
              : (s.customPoints as num).toDouble());

    final leagueTeams = teamList.map((rowTeam) {
      final stat = stats.where((s) => getStatName(s) == rowTeam).firstOrNull;
      final rankStr = allFinished
          ? '${stats.indexWhere((s) => getStatName(s) == rowTeam) + 1}'
          : '-';
      final customPts = getStatCustomPts(stat);
      return LeagueGridTeamInfo(
        teamName: rowTeam,
        matchWins: '${getStatMatchWins(stat)}',
        individualWinners: '${getStatIndivWinners(stat)}',
        totalPoints: '${getStatTotalPts(stat)}',
        customPoints: stat != null
            ? customPts.toStringAsFixed(
                customPts.truncateToDouble() == customPts ? 0 : 1,
              )
            : '0',
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
          final rs = m.redScore;
          final ws = m.whiteScore;
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
            final extractedMap =
                MatchCalculatorHelper.extractPointsFromProjection(m);
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
                        color: context.appColors.cardBackground,
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
                                ? _buildIndividualMatchesListViewer(
                                    '$rowTeam vs $colTeam',
                                    bouts,
                                    cardColor: AppKendoColors.transparent,
                                    isDark: isDark,
                                    applySort: false,
                                  )
                                : _buildScoreTableViewer(
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
            );
          },
        );
      }
    }

    return InkWell(
      key: Key('viewer_match_card_$groupName'),
      onTap: () {},
      child: LeagueGridCard(
        teams: leagueTeams,
        matrix: matrix,
        hasMatchPoints: hasMatchPoints,
        cardColor: cardColor,
        isDark: isDark,
      ),
    );
  }

  // 👇 ここから追加：個人戦専用の縦並びリスト描画エンジン
  Widget _buildIndividualMatchesListViewer(
    String groupName,
    List<MatchListProjection> matches, {
    Color? cardColor,
    required bool isDark,
    required bool applySort,
  }) {
    List<MatchListProjection> displayMatches = List.from(matches);

    if (applySort) {
      displayMatches.sort((a, b) {
        return a.order.compareTo(b.order);
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
      final rScore = m.redScore;
      final wScore = m.whiteScore;
      final isDraw = isDone && rScore == wScore;
      final rWin = isDone && rScore > wScore;
      final wWin = isDone && wScore > rScore;

      final ptsMap = MatchCalculatorHelper.extractPointsFromProjection(m);

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
        hasOwnTeam: false,
        redPoints: ptsMap['red'] ?? [],
        whitePoints: ptsMap['white'] ?? [],
        onTap: () {},
      );
    }).toList();

    return InkWell(
      key: Key('viewer_match_card_$groupName'),
      onTap: () {}, // Widget Test のタップイベント吸収用ダミー
      child: IndividualListCard(
        headerTitle: headerTitle,
        matches: matchItems,
        cardColor: cardColor,
        isDark: isDark,
      ),
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
