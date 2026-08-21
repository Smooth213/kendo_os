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
import 'package:kendo_os/features/viewer/components/viewer_official_record_card_item_builder.dart';

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
                              return ViewerOfficialRecordCardItemBuilder.buildKachinukiCard(
                                context: context,
                                groupName: groupName,
                                matches: matches,
                                isDark: isDark,
                              );
                            } else if (matches.isNotEmpty &&
                                teamProj.isLeague) {
                              return ViewerOfficialRecordCardItemBuilder.buildLeagueSection(
                                context: context,
                                groupName: groupName,
                                matches: matches,
                                teamProj: teamProj,
                                cardColor: cardColor,
                                isDark: isDark,
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
}
