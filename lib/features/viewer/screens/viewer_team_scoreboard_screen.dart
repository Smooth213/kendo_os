import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/components/viewer_team_scoreboard_table_builder.dart';

import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/name_formatter.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_loading_indicator.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import '../providers/viewer_view_state_provider.dart';
import 'viewer_kachinuki_scoreboard_screen.dart';

final _webTournamentIdSearchProvider = FutureProvider.family<String?, String>((
  ref,
  groupName,
) async {
  try {
    final localMatches = ref.read(matchListProvider);
    final match = localMatches
        .where((m) => m.groupName == groupName || m.id == groupName)
        .firstOrNull;
    if (match != null) {
      return match.tournamentId;
    }

    final firestore = FirebaseFirestore.instance;
    try {
      var rootGroupSnap = await firestore
          .collection('matches')
          .where('groupName', isEqualTo: groupName)
          .limit(1)
          .get();
      if (rootGroupSnap.docs.isNotEmpty) {
        return rootGroupSnap.docs.first.data()['tournamentId'] as String?;
      }

      var rootIdSnap = await firestore
          .collection('matches')
          .doc(groupName)
          .get();
      if (rootIdSnap.exists) {
        return rootIdSnap.data()?['tournamentId'] as String?;
      }
    } catch (e) {
      debugPrint('🚨 [Root Matches Query Error] $e');
    }

    final dojoId = ref.read(currentDojoIdProvider);
    if (dojoId.isNotEmpty) {
      var snapshot = await firestore
          .collection('organizations')
          .doc(dojoId)
          .collection('matches')
          .where('groupName', isEqualTo: groupName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        final docSnapshot = await firestore
            .collection('organizations')
            .doc(dojoId)
            .collection('matches')
            .doc(groupName)
            .get();
        if (docSnapshot.exists) {
          return docSnapshot.data()?['tournamentId'] as String?;
        }
      }

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['tournamentId'] as String?;
      }
    }

    final fallbackMatches = ref.read(matchListProvider);
    if (fallbackMatches.isNotEmpty) {
      return fallbackMatches.first.tournamentId;
    }

    return 'default_tournament';
  } catch (e) {
    debugPrint('🚨 [_webTournamentIdSearchProvider Error] $e');
    return 'default_tournament';
  }
});

class ViewerTeamScoreboardScreen extends ConsumerWidget {
  final String? groupName;

  const ViewerTeamScoreboardScreen({super.key, this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String safeDecodeComponent(String? input) {
      if (input == null) return '';
      try {
        return Uri.decodeComponent(input);
      } catch (_) {
        return input;
      }
    }

    final decodedGroupName = safeDecodeComponent(groupName);

    String? tournamentId = GoRouterState.of(
      context,
    ).uri.queryParameters['tournamentId'];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1E293B);

    final allMatches = ref.watch(matchListProvider);

    if (tournamentId == null && decodedGroupName.isNotEmpty) {
      final match = allMatches
          .where(
            (m) => m.groupName == decodedGroupName || m.id == decodedGroupName,
          )
          .firstOrNull;
      if (match != null) {
        tournamentId = match.tournamentId;
      }
    }

    if (tournamentId == null && decodedGroupName.isNotEmpty) {
      final asyncTournamentId = ref.watch(
        _webTournamentIdSearchProvider(decodedGroupName),
      );
      return asyncTournamentId.when(
        loading: () => _buildFallbackScaffold(
          context,
          ref,
          isDark,
          headerColor,
          const Center(child: AppLoadingIndicator()),
          null,
        ),
        error: (e, s) => _buildFallbackScaffold(
          context,
          ref,
          isDark,
          headerColor,
          Center(child: Text('大会情報の取得に失敗しました: $e')),
          null,
        ),
        data: (foundId) {
          if (foundId == null || foundId.isEmpty) {
            return _buildFallbackScaffold(
              context,
              ref,
              isDark,
              headerColor,
              const Center(child: Text('該当する大会が見つかりませんでした')),
              null,
            );
          }
          return _buildScoreboardScaffold(
            context,
            ref,
            foundId,
            decodedGroupName,
            isDark,
            headerColor,
          );
        },
      );
    }

    return _buildScoreboardScaffold(
      context,
      ref,
      tournamentId,
      decodedGroupName,
      isDark,
      headerColor,
    );
  }

  Widget _buildScoreboardScaffold(
    BuildContext context,
    WidgetRef ref,
    String? tournamentId,
    String decodedGroupName,
    bool isDark,
    Color headerColor,
  ) {
    final allMatches = ref.watch(matchListProvider);

    if (tournamentId == null && allMatches.isNotEmpty) {
      tournamentId = allMatches.first.tournamentId;
    }

    if (tournamentId == null) {
      return _buildFallbackScaffold(
        context,
        ref,
        isDark,
        headerColor,
        const Center(child: Text('大会情報がありません')),
        null,
      );
    }

    final asyncProj = ref.watch(
      viewerTournamentProjectionProvider(tournamentId),
    );

    return asyncProj.when(
      loading: () => _buildFallbackScaffold(
        context,
        ref,
        isDark,
        headerColor,
        const Center(child: AppLoadingIndicator()),
        tournamentId,
      ),
      error: (e, s) => _buildFallbackScaffold(
        context,
        ref,
        isDark,
        headerColor,
        Center(child: Text('エラー: $e')),
        tournamentId,
      ),
      data: (proj) {
        if (proj == null || proj.teamMatches.isEmpty) {
          return _buildFallbackScaffold(
            context,
            ref,
            isDark,
            headerColor,
            const Center(child: Text('試合データがまだ登録されていません')),
            tournamentId,
          );
        }

        dynamic foundProj = proj.teamMatches[decodedGroupName];

        if (foundProj == null) {
          for (final val in proj.teamMatches.values) {
            final redTeam = val.redTeamName;
            if (decodedGroupName.contains(redTeam) ||
                redTeam.contains(decodedGroupName)) {
              foundProj = val;
              break;
            }
            if ((val.matches as Iterable<dynamic>).any(
              (m) =>
                  m.id == decodedGroupName ||
                  decodedGroupName.contains(m.id as String),
            )) {
              foundProj = val;
              break;
            }
          }
        }

        final teamProj = foundProj ?? proj.teamMatches.values.first;

        if (teamProj.isKachinuki) {
          return ViewerKachinukiScoreboardScreen(groupName: decodedGroupName);
        }

        final themeColors =
            Theme.of(context).extension<AppThemeColors>() ??
            AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
        final cardColor = themeColors.cardBackground;
        final borderColor = context.appColors.separatorColor;

        return LiquidBackground(
          child: Scaffold(
            backgroundColor: AppKendoColors.transparent,
            appBar: AppHeader(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: headerColor,
                  size: 20,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    final dojoId =
                        GoRouterState.of(
                          context,
                        ).uri.queryParameters['dojoId'] ??
                        ref.read(currentDojoIdProvider);
                    context.go(
                      '/viewer-home/$tournamentId?role=viewer&dojoId=$dojoId',
                    );
                  }
                },
              ),
              title: '団体戦 スコア (観戦)',
              backgroundColor: context.appColors.cardBackground,
              elevation: 0,
              actions: const [
                ManualHelpButton(manualPath: 'docs/manuals/faq/viewer_faq.md'),
                SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  if (teamProj.note.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3F51B5).withValues(alpha: 0.25)
                            : const Color(0xFF3F51B5),
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF5C6BC0)
                              : const Color(0xFF3949AB),
                        ),
                      ),
                      child: Text(
                        teamProj.note,
                        style: const TextStyle(
                          fontSize: AppFontSize.bodyMedium,
                          fontWeight: AppFontWeight.bold,
                          color: AppKendoColors.pureWhite,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: AppRadius.large,
                        border: isDark
                            ? null
                            : Border.all(color: borderColor, width: 1.0),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.large,
                        child: Table(
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: borderColor, width: 0.5),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(2.0),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(1.2),
                            4: FlexColumnWidth(2.0),
                          },
                          children: [
                            ViewerTeamScoreboardTableBuilder.buildHeaderRow(
                              teamProj.redTeamName,
                              teamProj.whiteTeamName,
                              isDark,
                            ),
                            ...teamProj.matches.map(
                              (m) =>
                                  ViewerTeamScoreboardTableBuilder.buildMatchRow(
                                    m,
                                    context,
                                    isDark,
                                    (teamProj.matches as Iterable<dynamic>)
                                        .map<String>(
                                          (x) =>
                                              NameFormatter.parse(
                                                x.redName,
                                              )['last'] ??
                                              '',
                                        )
                                        .where((String s) => s.isNotEmpty)
                                        .toList(),
                                    (teamProj.matches as Iterable<dynamic>)
                                        .map<String>(
                                          (x) =>
                                              NameFormatter.parse(
                                                x.whiteName,
                                              )['last'] ??
                                              '',
                                        )
                                        .where((String s) => s.isNotEmpty)
                                        .toList(),
                                  ),
                            ),
                            ViewerTeamScoreboardTableBuilder.buildTotalRow(
                              teamProj.result,
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackScaffold(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color headerColor,
    Widget body,
    String? tournamentId,
  ) {
    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: headerColor, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                final dojoId =
                    GoRouterState.of(context).uri.queryParameters['dojoId'] ??
                    ref.read(currentDojoIdProvider);
                context.go(
                  '/viewer-home/$tournamentId?role=viewer&dojoId=$dojoId',
                );
              }
            },
          ),
          title: '団体戦 スコア (観戦)',
          actions: const [
            ManualHelpButton(manualPath: 'docs/manuals/faq/viewer_faq.md'),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: body,
      ),
    );
  }
}
