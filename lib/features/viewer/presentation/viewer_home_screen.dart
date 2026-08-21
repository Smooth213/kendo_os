import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kendo_os/features/match/presentation/components/announce_popup_manager.dart';
import 'package:kendo_os/features/match/presentation/components/announce_history_bottom_sheet.dart';

// ドメイン・インフラ・リポジトリ層
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/player_repository.dart';

// プロバイダ層
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';

// 共通シェアUIコンポーネント・ウィジェット層（★ パスを正しい座標へ完全適合）
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'components/viewer_settings_bottom_sheet.dart';
import 'components/viewer_share_dialog.dart';
import 'components/viewer_tournament_info_card.dart';
import 'components/viewer_call_banner.dart';
import 'components/viewer_quick_action_buttons.dart';
import 'components/viewer_match_list_search_bar.dart';
import 'components/viewer_team_card.dart';

export 'components/viewer_match_list_tile_card.dart';
export 'components/viewer_settings_bottom_sheet.dart';
export 'components/viewer_share_dialog.dart';
export 'components/viewer_tournament_info_card.dart';
export 'components/viewer_call_banner.dart';
export 'components/viewer_quick_action_buttons.dart';
export 'components/viewer_match_list_search_bar.dart';
export 'components/viewer_individual_player_card.dart';
export 'components/viewer_group_match_card.dart';
export 'components/viewer_team_card.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

// ★ 適合補正: 前回の位置リプレイスの際に一時的に消失していた、画面専用プロバイダ空間4点を完全復元
final categorySortProvider = StateProvider.autoDispose<bool>((ref) => true);
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final isSearchVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);

final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});

// =========================================================================
// 🛡️ Webアプリ・リスト消失バグ完全修正パッチ
// 全件取得(matchListProvider)に依存していた timelineMatchesByCategoryProvider が
// Web環境でフリーズ・空配列になる問題を回避するため、対象大会のみを直接取得する
// 安全な専用プロバイダーを定義し、UI側へ供給します。
// =========================================================================

// ★ 修正: Record 型に hasError と errorMessage を追加
typedef _SafeViewerTimelineResult = ({
  List<MapEntry<String, List<MatchModel>>> entries,
  Set<String> matchedGroupNames,
  Set<String> matchedMatchIds,
  bool isLoading,
  bool hasError,
  String? errorMessage,
});

final safeViewerTimelineProvider = Provider.family
    .autoDispose<_SafeViewerTimelineResult, String>((ref, String tournamentId) {
      final asyncMatches = ref.watch(
        matchListByTournamentProvider(tournamentId),
      );

      final bool hasError = asyncMatches.hasError;
      final String? errorMessage = asyncMatches.error?.toString();

      if (hasError) {
        debugPrint('🚨 [safeViewerTimelineProvider] エラーを検知しました: $errorMessage');
      } else if (!asyncMatches.isLoading) {
        // ★ 修正: 正常動作時に「0件です」のログが毎秒・毎描画スパム出力されるのを防ぐため、
        // エラー時（hasError == true）以外のデバッグプリントを静音化します。
      }

      final matches = List<MatchModel>.from(asyncMatches.value ?? [])
        ..sort((a, b) => a.order.compareTo(b.order));

      final searchQuery = ref
          .watch(searchQueryProvider)
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();
      final isSortAscending = ref.watch(categorySortProvider);

      final matchedGroupNames = <String>{};
      final matchedMatchIds = <String>{};

      if (searchQuery.isNotEmpty) {
        for (var m in matches) {
          final rName = m.redName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
          final wName = m.whiteName
              .replaceAll(RegExp(r'\s+'), '')
              .toLowerCase();
          if (rName.contains(searchQuery) || wName.contains(searchQuery)) {
            matchedMatchIds.add(m.id);
            if (m.groupName != null && m.groupName!.isNotEmpty) {
              matchedGroupNames.add(m.groupName!);
            }
          }
        }
      }

      final categoryMap = <String, List<MatchModel>>{};
      for (var m in matches) {
        if (searchQuery.isNotEmpty) {
          bool isMatch =
              matchedMatchIds.contains(m.id) ||
              (m.groupName != null && matchedGroupNames.contains(m.groupName!));
          if (!isMatch) continue;
        }
        final cat = (m.category != null && m.category!.isNotEmpty)
            ? m.category!
            : '未分類';
        categoryMap.putIfAbsent(cat, () => []).add(m);
      }

      final entries = categoryMap.entries.toList();
      entries.sort((a, b) {
        if (isSortAscending) {
          return a.key.compareTo(b.key);
        } else {
          return b.key.compareTo(a.key);
        }
      });

      return (
        entries: entries,
        matchedGroupNames: matchedGroupNames,
        matchedMatchIds: matchedMatchIds,
        isLoading: asyncMatches.isLoading,
        hasError: hasError,
        errorMessage: errorMessage,
      );
    });

/// ★ Phase 5-1: Viewer導線単純化（クローズド固定仕様）
/// 客席の保護者やおじいちゃん先生が絶対に誤操作を起こさないよう、
/// 機能を【試合を観る( remove_red_eye )】【PDFを観る( picture_as_pdf )】の閲覧系だけに完全限定化した専用ホーム画面。
/// 編集、Undo、CSV出力、設定変更などの破壊的導線はコードレベルで100%存在しません。
class ViewerHomeScreen extends ConsumerWidget {
  final String tournamentId;
  const ViewerHomeScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌟 ステップ3：観客席側 一斉ポップアップ監視トリガーをアタッチ（一般観客用フラグ: false）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        listenGlobalAnnouncements(
          context,
          ref,
          tournamentId,
          isStaffRoom: false,
        );
      }
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal_viewer');
    final enableLiquidGlass = ref.watch(
      settingsProvider.select((s) => s.enableLiquidGlass),
    );
    final Color bgColor = themeColors.scaffoldBackground;

    try {
      // ★ 修正: activeMatchesProvider だとリーグ戦や勝ち抜き戦で最初の試合が終了すると
      // グループ全体がバナーから消えてしまう不具合があるため、専用の抽出ロジックに置き換え
      final asyncMatches = ref.watch(
        matchListByTournamentProvider(tournamentId),
      );
      final allMatchesList = List<MatchModel>.from(asyncMatches.value ?? [])
        ..sort((a, b) => a.order.compareTo(b.order));

      final uniqueInProgress = <MatchModel>[];
      final uniqueWaiting = <MatchModel>[];
      final seenMatchups = <String>{};

      for (var match in allMatchesList) {
        if (match.status == 'finished' || match.status == 'approved') continue;

        String key;
        if (match.note.contains('[リーグ戦]')) {
          final t1 = match.redName.split(':').first.trim();
          final t2 = match.whiteName.split(':').first.trim();
          final sortedTeams = [t1, t2]..sort();
          key = 'league_${match.groupName}_${sortedTeams.join("_")}';
        } else if (match.isKachinuki) {
          key = 'kachinuki_${match.groupName}';
        } else if (match.groupName != null && match.groupName!.isNotEmpty) {
          key = 'group_${match.groupName}';
        } else {
          key = 'match_${match.id}';
        }

        if (!seenMatchups.contains(key)) {
          seenMatchups.add(key);
          if (match.status == 'in_progress') {
            uniqueInProgress.add(match);
          } else if (match.status == 'waiting') {
            uniqueWaiting.add(match);
          }
        }
      }

      final sanitizedQuery = ref
          .watch(searchQueryProvider)
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();
      final timelineResult = ref.watch(
        safeViewerTimelineProvider(tournamentId),
      );
      final matchedGroupNames = timelineResult.matchedGroupNames;
      final matchedMatchIds = timelineResult.matchedMatchIds;

      return PopScope(
        canPop: false, // 戻るスワイプをブロック
        child: LiquidBackground(
          child: Scaffold(
            backgroundColor: AppKendoColors.transparent,
            appBar: AppHeader(
              leading: GoRouter.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(
                        Icons.exit_to_app,
                        color: AppKendoColors.deepOrange,
                      ),
                      tooltip: '管理画面に戻る',
                      onPressed: () => context.pop(),
                    )
                  : null,
              title: '大会ホーム (観客席)',
              backgroundColor: enableLiquidGlass
                  ? AppKendoColors.transparent
                  : (context.appColors.cardBackground),
              actions: [
                NotificationBellButton(
                  tournamentId: tournamentId,
                  isStaffRoom: false,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : themeColors.primaryAccent,
                ),
                ManualHelpButton(
                  manualPath: 'docs/manuals/faq/viewer_faq.md',
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : themeColors.primaryAccent,
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : themeColors.primaryAccent,
                  ),
                  tooltip: '表示設定',
                  onPressed: () {
                    showAppBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const ViewerSettingsBottomSheet(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.qr_code_2,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : themeColors.primaryAccent,
                  ),
                  tooltip: '大会を共有する',
                  onPressed: () => ViewerShareDialog.show(
                    context,
                    tournamentId: tournamentId,
                    dojoId: ref.read(currentDojoIdProvider),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: Column(
              children: [
                ViewerCallBanner(
                  inProgressMatches: uniqueInProgress,
                  waitingMatches: uniqueWaiting,
                ),

                ViewerQuickActionButtons(
                  tournamentId: tournamentId,
                  enableLiquidGlass: enableLiquidGlass,
                ),
                const SizedBox(height: AppSpacing.sm),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.giant * 2,
                    ),
                    children: [
                      ref
                          .watch(viewerTournamentProvider(tournamentId))
                          .when(
                            data: (tournament) {
                              if (tournament != null) {
                                return ViewerTournamentInfoCard(
                                  tournament: tournament,
                                );
                              }
                              // ★ デバッグ支援: 大会情報が見つからない場合は原因切り分け用の表示を出す
                              final dojoId = ref.watch(currentDojoIdProvider);
                              return Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF161618)
                                        : context.appColors.inputBackground,
                                    borderRadius: AppRadius.medium,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF38383A)
                                          : const Color(0x33000000),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '大会情報が見つかりません',
                                        style: TextStyle(
                                          fontWeight: AppFontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text('大会ID: $tournamentId'),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text('現在の dojoId: $dojoId'),
                                      const SizedBox(height: AppSpacing.sm),
                                      const Text(
                                        '原因候補: 道場IDが一致しない、または大会が他パスに存在します。管理者に確認してください。',
                                        style: TextStyle(
                                          color: AppKendoColors.grey,
                                          fontSize: AppFontSize.small,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.lg),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, s) => Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF161618)
                                      : const Color(0xFFFFFFFF),
                                  borderRadius: AppRadius.medium,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF38383A)
                                        : const Color(0x33000000),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '大会情報の読み込みに失敗しました',
                                      style: TextStyle(
                                        fontWeight: AppFontWeight.bold,
                                        color: AppKendoColors.red,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text('$e'),
                                  ],
                                ),
                              ),
                            ),
                          ),

                      ViewerMatchListSearchBar(
                        isSearchVisible: ref.watch(isSearchVisibleProvider),
                        searchQuery: ref.watch(searchQueryProvider),
                        isSortAscending: ref.watch(categorySortProvider),
                        onSearchQueryChanged: (val) {
                          ref.read(searchQueryProvider.notifier).state = val;
                        },
                        onOpenSearch: () {
                          ref.read(isSearchVisibleProvider.notifier).state =
                              true;
                        },
                        onCloseSearch: () {
                          ref.read(searchQueryProvider.notifier).state = '';
                          ref.read(isSearchVisibleProvider.notifier).state =
                              false;
                        },
                        onToggleSort: () {
                          ref.read(categorySortProvider.notifier).state = !ref
                              .read(categorySortProvider);
                        },
                      ),

                      if (timelineResult.hasError)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppKendoColors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'データの取得に失敗しました',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFE53935)
                                        : AppKendoColors.red,
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  timelineResult.errorMessage ??
                                      '通信状況を確認してください',
                                  style: const TextStyle(
                                    color: AppKendoColors.grey,
                                    fontSize: AppFontSize.small,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (timelineResult.entries.isEmpty &&
                          sanitizedQuery.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: Text(
                              '該当する試合が見つかりません',
                              style: TextStyle(color: AppKendoColors.grey),
                            ),
                          ),
                        ),

                      if (timelineResult.entries.isEmpty &&
                          timelineResult.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: Center(child: CircularProgressIndicator()),
                        ),

                      // ★ 修正: 試合データが 0件 の時に画面が真っ白になる欠陥を修正し、メッセージを表示させる
                      if (timelineResult.entries.isEmpty &&
                          !timelineResult.isLoading &&
                          sanitizedQuery.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: Text(
                              'まだ試合が登録されていません',
                              style: TextStyle(
                                color: AppKendoColors.grey,
                                fontWeight: AppFontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      ...(() {
                        if (timelineResult.entries.isEmpty) return <Widget>[];
                        final sortedEntries = timelineResult.entries;
                        return sortedEntries.map<Widget>((catEntry) {
                          try {
                            final categoryName = catEntry.key;
                            final catMatches = catEntry.value;

                            final ownTeams =
                                ref.watch(customTeamNamesProvider).value ?? [];
                            final matchesByTeam = <String, List<MatchModel>>{};

                            final groupToOwnTeams = <String, Set<String>>{};
                            final groupToRepresentativeTeam =
                                <String, String>{};

                            for (var m in catMatches) {
                              if (m.groupName != null &&
                                  m.groupName!.isNotEmpty) {
                                String rTeam = m.redName.contains(':')
                                    ? m.redName.split(':').first.trim()
                                    : m.redName;
                                String wTeam = m.whiteName.contains(':')
                                    ? m.whiteName.split(':').first.trim()
                                    : m.whiteName;
                                final isRedOwnForM =
                                    ownTeams.contains(rTeam) ||
                                    (m.rule?.teamName.isNotEmpty == true &&
                                        rTeam == m.rule!.teamName);
                                final isWhiteOwnForM =
                                    ownTeams.contains(wTeam) ||
                                    (m.rule?.teamName.isNotEmpty == true &&
                                        wTeam == m.rule!.teamName);
                                if (isRedOwnForM) {
                                  groupToOwnTeams
                                      .putIfAbsent(m.groupName!, () => {})
                                      .add(rTeam);
                                }
                                if (isWhiteOwnForM) {
                                  groupToOwnTeams
                                      .putIfAbsent(m.groupName!, () => {})
                                      .add(wTeam);
                                }

                                // 🌟 リーグ個人戦一極集中ガード: グループの代表チームを固定し、同じリーグが所属選手ごとに引き裂かれるのを100%防ぐ
                                if (!groupToRepresentativeTeam.containsKey(
                                  m.groupName!,
                                )) {
                                  groupToRepresentativeTeam[m.groupName!] =
                                      rTeam.isNotEmpty && !rTeam.contains('代表')
                                      ? rTeam
                                      : (wTeam.isNotEmpty &&
                                                !wTeam.contains('代表')
                                            ? wTeam
                                            : '設定なし');
                                }
                              }
                            }

                            for (var m in catMatches) {
                              String rTeam = m.redName.contains(':')
                                  ? m.redName.split(':').first.trim()
                                  : m.redName;
                              String wTeam = m.whiteName.contains(':')
                                  ? m.whiteName.split(':').first.trim()
                                  : m.whiteName;

                              bool isRedOwn =
                                  ownTeams.contains(rTeam) ||
                                  (m.rule?.teamName.isNotEmpty == true &&
                                      rTeam == m.rule!.teamName);
                              bool isWhiteOwn =
                                  ownTeams.contains(wTeam) ||
                                  (m.rule?.teamName.isNotEmpty == true &&
                                      wTeam == m.rule!.teamName);

                              if (m.groupName != null &&
                                  m.groupName!.isNotEmpty) {
                                if (groupToOwnTeams.containsKey(m.groupName!)) {
                                  for (String team
                                      in groupToOwnTeams[m.groupName!]!) {
                                    matchesByTeam
                                        .putIfAbsent(team, () => [])
                                        .add(m);
                                  }
                                } else {
                                  // 🌟 観客・他チーム視点時もリーグ個人戦がバラバラに解体されないよう、代表キーへ全試合を完全に集約ホールドする
                                  final repTeam =
                                      groupToRepresentativeTeam[m.groupName!] ??
                                      '設定なし';
                                  matchesByTeam
                                      .putIfAbsent(repTeam, () => [])
                                      .add(m);
                                }
                              } else {
                                if (isRedOwn) {
                                  matchesByTeam
                                      .putIfAbsent(rTeam, () => [])
                                      .add(m);
                                }
                                if (isWhiteOwn && wTeam != rTeam) {
                                  matchesByTeam
                                      .putIfAbsent(wTeam, () => [])
                                      .add(m);
                                }
                                if (!isRedOwn && !isWhiteOwn) {
                                  final keyTeam =
                                      rTeam.isNotEmpty && !rTeam.contains('代表')
                                      ? rTeam
                                      : (wTeam.isNotEmpty &&
                                                !wTeam.contains('代表')
                                            ? wTeam
                                            : '設定なし');
                                  matchesByTeam
                                      .putIfAbsent(keyTeam, () => [])
                                      .add(m);
                                }
                              }
                            }

                            final sortedTeams = matchesByTeam.entries.toList();
                            sortedTeams.sort((a, b) => a.key.compareTo(b.key));

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.xl,
                                    AppSpacing.xl,
                                    AppSpacing.lg,
                                    AppSpacing.md,
                                  ),
                                  child: Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize: AppFontSize.subhead,
                                      fontWeight: AppFontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF607D8B)
                                          : const Color(0xFF607D8B),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),

                                ...sortedTeams.map((teamEntry) {
                                  return ViewerTeamCard(
                                    teamName: teamEntry.key,
                                    teamMatchesList: teamEntry.value,
                                    ownTeams: ownTeams,
                                    sanitizedQuery: sanitizedQuery,
                                    matchedMatchIds: matchedMatchIds,
                                    matchedGroupNames: matchedGroupNames,
                                  );
                                }),
                              ],
                            );
                          } catch (e, stack) {
                            return Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Text(
                                'レンダリングエラー発生: $e\n$stack',
                                style: const TextStyle(
                                  color: AppKendoColors.red,
                                ),
                              ),
                            );
                          }
                        }).toList();
                      })(),
                    ],
                  ),
                ),
              ],
            ),
          ), // Scaffoldの終わり
        ), // LiquidBackgroundの終わり
      ); // PopScopeの終わり
    } catch (e, stack) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            '致命的なUIエラー: $e\n$stack',
            style: const TextStyle(color: AppKendoColors.red),
          ),
        ),
      );
    }
  } // buildメソッドの終わり
} // ★ ViewerHomeScreen クラスを一旦ここで安全にクローズします

// ★ 修正: Web版のViewerでは currentDojoId が取得できないため、
// 確実に大会情報を引っ張り出せる専用のプロバイダに変更し、表示されない不具合を解消。
final viewerTournamentProvider = StreamProvider.family.autoDispose<TournamentModel?, String>((
  ref,
  id,
) async* {
  final firestore = FirebaseFirestore.instance;
  final currentDojoId = ref.watch(currentDojoIdProvider);

  debugPrint(
    '🔎 [viewerTournamentProvider] start - id: $id, currentDojoId: $currentDojoId',
  );

  try {
    if (currentDojoId.isNotEmpty) {
      final orgTournamentDoc = await firestore
          .collection('organizations')
          .doc(currentDojoId)
          .collection('tournaments')
          .doc(id)
          .get();

      if (orgTournamentDoc.exists) {
        debugPrint(
          '🔎 [viewerTournamentProvider] found in organizations/$currentDojoId/tournaments',
        );
        yield* firestore
            .collection('organizations')
            .doc(currentDojoId)
            .collection('tournaments')
            .doc(id)
            .snapshots()
            .map((doc) {
              if (!doc.exists) return null;
              return TournamentModel.fromJson({...doc.data()!, 'id': doc.id});
            });
        return;
      }

      debugPrint(
        '⚠️ [viewerTournamentProvider] currentDojoId($currentDojoId) の大会が見つかりませんでした。フォールバック検索を継続します。',
      );
    }

    final rootTournamentDoc = await firestore
        .collection('tournaments')
        .doc(id)
        .get();
    debugPrint(
      '🔎 [viewerTournamentProvider] root doc exists: ${rootTournamentDoc.exists}',
    );
    if (rootTournamentDoc.exists) {
      debugPrint('🔎 [viewerTournamentProvider] found in tournaments/$id');
      yield* firestore.collection('tournaments').doc(id).snapshots().map((doc) {
        if (!doc.exists) return null;
        return TournamentModel.fromJson({...doc.data()!, 'id': doc.id});
      });
      return;
    }

    final groupTournamentQuery = await firestore
        .collectionGroup('tournaments')
        .where(FieldPath.documentId, isEqualTo: id)
        .limit(1)
        .get();

    debugPrint(
      '🔎 [viewerTournamentProvider] collectionGroup tournaments found: ${groupTournamentQuery.docs.length}',
    );

    if (groupTournamentQuery.docs.isNotEmpty) {
      final docRef = groupTournamentQuery.docs.first.reference;
      debugPrint(
        '🔎 [viewerTournamentProvider] found in collectionGroup at path: ${docRef.path}',
      );
      yield* docRef.snapshots().map((doc) {
        if (!doc.exists) return null;
        return TournamentModel.fromJson({...doc.data()!, 'id': doc.id});
      });
      return;
    }

    final matchQuery = await firestore
        .collectionGroup('matches')
        .where('tournamentId', isEqualTo: id)
        .limit(1)
        .get();

    if (matchQuery.docs.isNotEmpty) {
      final matchRef = matchQuery.docs.first.reference;
      final pathSegments = matchRef.path.split('/');
      final orgIndex = pathSegments.indexOf('organizations');

      if (orgIndex != -1 && pathSegments.length > orgIndex + 1) {
        final orgId = pathSegments[orgIndex + 1];
        yield* firestore
            .collection('organizations')
            .doc(orgId)
            .collection('tournaments')
            .doc(id)
            .snapshots()
            .map((doc) {
              if (!doc.exists) return null;
              return TournamentModel.fromJson({...doc.data()!, 'id': doc.id});
            });
        return;
      }
    }

    yield null;
  } catch (e, st) {
    debugPrint('🚨 [viewerTournamentProvider] エラー: $e\n$st');
    yield null;
  }
});
