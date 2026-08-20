import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
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
import 'package:kendo_os/shared/widgets/glass_button.dart';
import 'package:kendo_os/shared/widgets/manual_help_button.dart';
import 'components/viewer_match_list_tile_card.dart';
import 'components/viewer_settings_bottom_sheet.dart';
import 'components/viewer_share_dialog.dart';
import 'components/viewer_tournament_info_card.dart';

export 'components/viewer_match_list_tile_card.dart';
export 'components/viewer_settings_bottom_sheet.dart';
export 'components/viewer_share_dialog.dart';
export 'components/viewer_tournament_info_card.dart';
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
                if (uniqueInProgress.isNotEmpty || uniqueWaiting.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: const Color(0xFF607D8B), // 観客席らしい落ち着いた色に変更
                      borderRadius: AppRadius.large,
                      boxShadow: [
                        BoxShadow(
                          color: AppKendoColors.pureBlack.withValues(
                            alpha: 0.2,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (uniqueInProgress.isNotEmpty)
                          _buildCallRow(
                            '進行中',
                            uniqueInProgress.first,
                            AppKendoColors.orangeAccent,
                          ),
                        if (uniqueInProgress.isNotEmpty &&
                            uniqueWaiting.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: Divider(
                              color: AppKendoColors.pureWhite.withValues(
                                alpha: 0.24,
                              ),
                              height: 1,
                            ),
                          ),
                        if (uniqueWaiting.isNotEmpty)
                          _buildCallRow(
                            '次試合',
                            uniqueWaiting.first,
                            AppKendoColors.pureWhite,
                          ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      // ==========================================
                      // ★ Phase 4-1, 4-3, 4-6: UI簡略化 & スリム化 (観客向け巨大ボタンの洗練)
                      // 観客が混乱しないよう、巨大ボタンは「試合結果一覧」の1つに絞る。
                      // 高齢補助員向けの押しやすさを維持しつつ、パディングを減らし、サブタイトルを削除。
                      // アイコンとフォントサイズを小さくして高さを抑え、下の試合リストの領域を広げます。
                      // ==========================================
                      _buildHugeMenuButton(
                        context,
                        enableLiquidGlass,
                        Icons.print,
                        '試合結果一覧 (PDF/CSV)',
                        AppKendoColors.blueGrey,
                        () => context.push('/official-record/$tournamentId'),
                      ),
                      const SizedBox(
                        height: AppSpacing.md,
                      ), // 🌟 縦幅を節約するため12に微調整
                      // ★ 修正: 観客・保護者用のホーム画面（ViewerHome）にも、大会プログラムを「見るだけ」で閲覧できる安全なボタンを追加
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          // 🌟 修正: 遷移先URLに ?role=viewer を確実に付与し、移動先での権限先祖返りを100%防止
                          onPressed: () => context.push(
                            '/tournament/$tournamentId/programs?role=viewer',
                          ),
                          icon: Icon(
                            Icons.picture_as_pdf,
                            size: 20,
                            color: isDark
                                ? context.appColors.errorColor
                                : context.appColors.errorColor,
                          ),
                          label: Text(
                            '大会プログラムを見る（閲覧専用）',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.body,
                              color: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xDE000000),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : context.appColors.separatorColor,
                            ),
                            backgroundColor: context.appColors.cardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.medium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!ref.watch(isSearchVisibleProvider))
                              Text(
                                '試合リスト',
                                style: TextStyle(
                                  fontSize: AppFontSize.subhead,
                                  fontWeight: AppFontWeight.bold,
                                  color: context.appColors.subTextColor,
                                ),
                              ),

                            if (ref.watch(isSearchVisibleProvider))
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.sm,
                                  ),
                                  child: SizedBox(
                                    height: 32,
                                    child: AppTextField(
                                      autofocus: true,
                                      style: TextStyle(
                                        fontSize: AppFontSize.bodySmall,
                                        color: context.appColors.textColor,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '選手名・チーム名で検索...',
                                        hintStyle: TextStyle(
                                          fontSize: AppFontSize.small,
                                          color: isDark
                                              ? context.appColors.subTextColor
                                              : context.appColors.subTextColor,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md,
                                              vertical: 0,
                                            ),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF2C2C2E)
                                            : context.appColors.inputBackground,
                                        border: OutlineInputBorder(
                                          borderRadius: AppRadius.small,
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? const Color(0xFF38383A)
                                                : const Color(0x33000000),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: AppRadius.small,
                                          borderSide: BorderSide(
                                            color: AppKendoColors
                                                .blueGrey
                                                .shade400,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            ref
                                                    .read(
                                                      searchQueryProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                '';
                                            ref
                                                    .read(
                                                      isSearchVisibleProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                false;
                                          },
                                        ),
                                      ),
                                      onChanged: (val) =>
                                          ref
                                                  .read(
                                                    searchQueryProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              val,
                                    ),
                                  ),
                                ),
                              ),

                            if (!ref.watch(isSearchVisibleProvider))
                              const Spacer(),

                            if (!ref.watch(isSearchVisibleProvider))
                              IconButton(
                                icon: Icon(
                                  Icons.search,
                                  color: context.appColors.primaryAccent,
                                  size: 22,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    ref
                                            .read(
                                              isSearchVisibleProvider.notifier,
                                            )
                                            .state =
                                        true,
                              ),

                            if (!ref.watch(isSearchVisibleProvider))
                              const SizedBox(width: AppSpacing.md),

                            OutlinedButton.icon(
                              onPressed: () =>
                                  ref
                                      .read(categorySortProvider.notifier)
                                      .state = !ref.read(
                                    categorySortProvider,
                                  ),
                              icon: Icon(
                                ref.watch(categorySortProvider)
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                size: 16,
                              ),
                              label: Text(
                                ref.watch(categorySortProvider)
                                    ? 'カテゴリ昇順'
                                    : 'カテゴリ降順',
                                style: const TextStyle(
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: AppFontSize.small,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    context.appColors.primaryAccent,
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF38383A)
                                      : context.appColors.subTextColor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.small,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                  final teamName = teamEntry.key;
                                  final teamMatchesList = teamEntry.value;

                                  String getMatchLabel(MatchModel m) {
                                    final bool isLeague = m.note.contains(
                                      '[リーグ戦]',
                                    );
                                    final bool isKachinuki = m.isKachinuki;
                                    final bool isIndividual =
                                        !isKachinuki &&
                                        (m.matchType == 'individual' ||
                                            m.matchType == '選手');

                                    if (isLeague) {
                                      return isIndividual
                                          ? '個人戦/リーグ戦'
                                          : '団体戦/リーグ戦';
                                    }
                                    if (isKachinuki) return '団体戦/勝ち抜き戦';
                                    return isIndividual ? '個人戦' : '団体戦';
                                  }

                                  final catGroupedMatches =
                                      <String, List<MatchModel>>{};
                                  final catIndividualMatches = <MatchModel>[];

                                  for (var m in teamMatchesList) {
                                    bool forceIndividual =
                                        sanitizedQuery.isNotEmpty &&
                                        matchedMatchIds.contains(m.id) &&
                                        (m.groupName == null ||
                                            !matchedGroupNames.contains(
                                              m.groupName!,
                                            ));

                                    if (!forceIndividual &&
                                        m.groupName != null &&
                                        m.groupName!.isNotEmpty) {
                                      catGroupedMatches
                                          .putIfAbsent(m.groupName!, () => [])
                                          .add(m);
                                    } else {
                                      catIndividualMatches.add(m);
                                    }
                                  }

                                  final actualGroupedMatches =
                                      <String, List<MatchModel>>{};
                                  for (var entry in catGroupedMatches.entries) {
                                    final firstMatch = entry.value.first;
                                    final bool isLeagueMatch = firstMatch.note
                                        .contains('[リーグ戦]');
                                    final bool isPureIndividual =
                                        !firstMatch.isKachinuki &&
                                        (firstMatch.matchType == 'individual' ||
                                            firstMatch.matchType == '選手' ||
                                            firstMatch.matchType.contains(
                                              '個人戦',
                                            ));

                                    if (!isPureIndividual &&
                                        (entry.value.length > 1 ||
                                            firstMatch.isKachinuki)) {
                                      actualGroupedMatches[entry.key] =
                                          entry.value;
                                    } else if (isLeagueMatch) {
                                      actualGroupedMatches[entry.key] =
                                          entry.value;
                                    } else {
                                      catIndividualMatches.addAll(entry.value);
                                    }
                                  }

                                  final matchesByPlayer =
                                      <String, List<MatchModel>>{};
                                  for (var m in catIndividualMatches) {
                                    String playerName = '選手名不明';

                                    bool forceIndividual =
                                        sanitizedQuery.isNotEmpty &&
                                        matchedMatchIds.contains(m.id) &&
                                        (m.groupName == null ||
                                            !matchedGroupNames.contains(
                                              m.groupName!,
                                            ));
                                    if (forceIndividual) {
                                      String rPlayer = m.redName.contains(':')
                                          ? m.redName.split(':').last.trim()
                                          : m.redName;
                                      String wPlayer = m.whiteName.contains(':')
                                          ? m.whiteName.split(':').last.trim()
                                          : m.whiteName;
                                      bool rHit = rPlayer
                                          .replaceAll(RegExp(r'\s+'), '')
                                          .toLowerCase()
                                          .contains(sanitizedQuery);
                                      bool wHit = wPlayer
                                          .replaceAll(RegExp(r'\s+'), '')
                                          .toLowerCase()
                                          .contains(sanitizedQuery);
                                      if (rHit) {
                                        playerName = rPlayer;
                                      } else if (wHit) {
                                        playerName = wPlayer;
                                      } else {
                                        final rTeam = m.redName.contains(':')
                                            ? m.redName.split(':').first.trim()
                                            : m.redName;
                                        final wTeam = m.whiteName.contains(':')
                                            ? m.whiteName
                                                  .split(':')
                                                  .first
                                                  .trim()
                                            : m.whiteName;
                                        final isRedOwn =
                                            ownTeams.contains(rTeam) ||
                                            (m.rule?.teamName.isNotEmpty ==
                                                    true &&
                                                rTeam == m.rule!.teamName);
                                        final isWhiteOwn =
                                            ownTeams.contains(wTeam) ||
                                            (m.rule?.teamName.isNotEmpty ==
                                                    true &&
                                                wTeam == m.rule!.teamName);
                                        if (isWhiteOwn && !isRedOwn) {
                                          playerName = wPlayer;
                                        } else if (isRedOwn && !isWhiteOwn) {
                                          playerName = rPlayer;
                                        } else {
                                          playerName =
                                              m.redName.contains(teamName)
                                              ? rPlayer
                                              : wPlayer;
                                        }
                                      }
                                    } else {
                                      final rTeam = m.redName.contains(':')
                                          ? m.redName.split(':').first.trim()
                                          : m.redName;
                                      final wTeam = m.whiteName.contains(':')
                                          ? m.whiteName.split(':').first.trim()
                                          : m.whiteName;
                                      final isRedOwn =
                                          ownTeams.contains(rTeam) ||
                                          (m.rule?.teamName.isNotEmpty ==
                                                  true &&
                                              rTeam == m.rule!.teamName);
                                      final isWhiteOwn =
                                          ownTeams.contains(wTeam) ||
                                          (m.rule?.teamName.isNotEmpty ==
                                                  true &&
                                              wTeam == m.rule!.teamName);

                                      if (isWhiteOwn && !isRedOwn) {
                                        playerName = m.whiteName.contains(':')
                                            ? m.whiteName.split(':').last.trim()
                                            : m.whiteName;
                                      } else if (isRedOwn && !isWhiteOwn) {
                                        playerName = m.redName.contains(':')
                                            ? m.redName.split(':').last.trim()
                                            : m.redName;
                                      } else {
                                        if (m.redName.contains(teamName)) {
                                          playerName = m.redName.contains(':')
                                              ? m.redName.split(':').last.trim()
                                              : m.redName;
                                        } else if (m.whiteName.contains(
                                          teamName,
                                        )) {
                                          playerName = m.whiteName.contains(':')
                                              ? m.whiteName
                                                    .split(':')
                                                    .last
                                                    .trim()
                                              : m.whiteName;
                                        } else {
                                          playerName =
                                              m.redName.contains(teamName)
                                              ? (m.redName.contains(':')
                                                    ? m.redName
                                                          .split(':')
                                                          .last
                                                          .trim()
                                                    : m.redName)
                                              : (m.whiteName.contains(':')
                                                    ? m.whiteName
                                                          .split(':')
                                                          .last
                                                          .trim()
                                                    : m.whiteName);
                                        }
                                      }
                                    }
                                    matchesByPlayer
                                        .putIfAbsent(playerName, () => [])
                                        .add(m);
                                  }

                                  final sortedGroups =
                                      actualGroupedMatches.entries.toList()
                                        ..sort(
                                          (a, b) => a.value.first.order
                                              .compareTo(b.value.first.order),
                                        );
                                  final sortedPlayers =
                                      matchesByPlayer.entries.toList()..sort(
                                        (a, b) => a.key.compareTo(b.key),
                                      );

                                  return Container(
                                    margin: const EdgeInsets.only(
                                      left: AppSpacing.md,
                                      right: AppSpacing.md,
                                      bottom: AppSpacing.xl,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF161618)
                                          : const Color(0xFFFFFFFF),
                                      borderRadius: AppRadius.large,
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF38383A)
                                            : const Color(0x33000000),
                                        width: 2,
                                      ),
                                      boxShadow: isDark
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF000000,
                                                ).withValues(alpha: 0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.lg,
                                            vertical: AppSpacing.md,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppKendoColors
                                                      .blueGrey
                                                      .shade900
                                                      .withValues(alpha: 0.3)
                                                : AppKendoColors
                                                      .blueGrey
                                                      .shade50,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(
                                                    AppRadius.modernValue,
                                                  ),
                                                ),
                                            border: Border(
                                              bottom: BorderSide(
                                                color: isDark
                                                    ? const Color(0xFF38383A)
                                                    : AppKendoColors
                                                          .blueGrey
                                                          .shade100,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.business,
                                                color: context
                                                    .appColors
                                                    .primaryAccent,
                                                size: 20,
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  teamName,
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppFontSize.headline,
                                                    fontWeight:
                                                        AppFontWeight.bold,
                                                    color: isDark
                                                        ? AppKendoColors
                                                              .pureWhite
                                                        : Colors
                                                              .blueGrey
                                                              .shade900,
                                                  ),
                                                ),
                                              ),
                                              // 編集ボタンは削除
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: AppSpacing.sm),

                                        ...(() {
                                          String lastGroupLabel = '';

                                          return sortedGroups.map((entry) {
                                            final groupList = entry.value;
                                            final firstMatch = groupList.first;
                                            final label = getMatchLabel(
                                              firstMatch,
                                            );

                                            Widget? headerWidget;
                                            if (label != lastGroupLabel) {
                                              headerWidget = Padding(
                                                padding: const EdgeInsets.only(
                                                  left: AppSpacing.lg,
                                                  top: AppSpacing.md,
                                                  bottom: AppSpacing.xs,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.groups,
                                                      color: isDark
                                                          ? Colors
                                                                .blueGrey
                                                                .shade300
                                                          : Colors
                                                                .blueGrey
                                                                .shade700,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(
                                                      width: AppSpacing.xs,
                                                    ),
                                                    Text(
                                                      label,
                                                      style: TextStyle(
                                                        fontSize: AppFontSize
                                                            .bodySmall,
                                                        fontWeight:
                                                            AppFontWeight.bold,
                                                        color: isDark
                                                            ? Colors
                                                                  .blueGrey
                                                                  .shade300
                                                            : Colors
                                                                  .blueGrey
                                                                  .shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              lastGroupLabel = label;
                                            }

                                            final rTeam =
                                                firstMatch.redName.contains(':')
                                                ? firstMatch.redName
                                                      .split(':')
                                                      .first
                                                      .trim()
                                                : firstMatch.redName;
                                            final wTeam =
                                                firstMatch.whiteName.contains(
                                                  ':',
                                                )
                                                ? firstMatch.whiteName
                                                      .split(':')
                                                      .first
                                                      .trim()
                                                : firstMatch.whiteName;

                                            final hasInProgress = groupList.any(
                                              (m) => m.status == 'in_progress',
                                            );
                                            final allFinished = groupList.every(
                                              (m) =>
                                                  m.status == 'finished' ||
                                                  m.status == 'approved',
                                            );

                                            final Color cardBg = allFinished
                                                ? (isDark
                                                      ? const Color(0xFF161618)
                                                      : AppKendoColors
                                                            .grey
                                                            .shade100)
                                                : (context
                                                      .appColors
                                                      .cardBackground);

                                            final Color titleColor = allFinished
                                                ? (isDark
                                                      ? AppKendoColors
                                                            .grey
                                                            .shade600
                                                      : AppKendoColors
                                                            .grey
                                                            .shade500)
                                                : (context.appColors.textColor);

                                            final Color subTitleColor =
                                                allFinished
                                                ? (isDark
                                                      ? AppKendoColors
                                                            .grey
                                                            .shade700
                                                      : AppKendoColors
                                                            .grey
                                                            .shade500)
                                                : (isDark
                                                      ? AppKendoColors
                                                            .grey
                                                            .shade500
                                                      : AppKendoColors
                                                            .grey
                                                            .shade600);

                                            final pairingsSet = <String>{};
                                            for (var m in groupList) {
                                              final t1 = m.redName
                                                  .split(':')
                                                  .first
                                                  .trim();
                                              final t2 = m.whiteName
                                                  .split(':')
                                                  .first
                                                  .trim();
                                              final pairKey = [t1, t2]..sort();
                                              pairingsSet.add(
                                                pairKey.join(' vs '),
                                              );
                                            }
                                            final int displayMatchCount =
                                                pairingsSet.length;

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ?headerWidget,
                                                GestureDetector(
                                                  onLongPress: null,
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                              AppSpacing.md,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      // ★ 修正: color: cardBg, を削除
                                                      borderRadius:
                                                          AppRadius.medium,
                                                      border: Border.all(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF38383A,
                                                              )
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                        width: 1,
                                                      ),
                                                      boxShadow: hasInProgress
                                                          ? [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .blue
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                blurRadius: 8,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      4,
                                                                    ),
                                                              ),
                                                            ]
                                                          : [],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          AppRadius.smooth,
                                                      child: ExpansionTile(
                                                        key:
                                                            PageStorageKey<
                                                              String
                                                            >(
                                                              'group_${entry.key}',
                                                            ),
                                                        collapsedBackgroundColor:
                                                            cardBg,
                                                        backgroundColor: cardBg,
                                                        title: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            // 🔼 【1行目】: コントロール・ステータスライン（コントロール右寄せ）
                                                            Row(
                                                              children: [
                                                                const Spacer(),
                                                                // 📊スコアボタン（観客閲覧専用リンクにアタッチ）
                                                                if (!label
                                                                        .contains(
                                                                          'リーグ戦',
                                                                        ) &&
                                                                    firstMatch
                                                                            .groupName !=
                                                                        null &&
                                                                    firstMatch
                                                                        .groupName!
                                                                        .isNotEmpty) ...[
                                                                  SizedBox(
                                                                    height: 26,
                                                                    child: OutlinedButton(
                                                                      onPressed: () {
                                                                        final encodedGroupName = Uri.encodeComponent(
                                                                          firstMatch.groupName ??
                                                                              '',
                                                                        );
                                                                        context.push(
                                                                          firstMatch.isKachinuki
                                                                              ? '/viewer-kachinuki/\u0000$encodedGroupName'
                                                                              : '/viewer-team/$encodedGroupName',
                                                                        );
                                                                      },
                                                                      style: OutlinedButton.styleFrom(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              AppSpacing.sm,
                                                                        ),
                                                                        side: BorderSide(
                                                                          color: titleColor.withValues(
                                                                            alpha:
                                                                                0.2,
                                                                          ),
                                                                        ),
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              AppRadius.sub,
                                                                        ),
                                                                      ),
                                                                      child: Text(
                                                                        'スコア',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              AppFontSize.badge,
                                                                          fontWeight:
                                                                              AppFontWeight.bold,
                                                                          color:
                                                                              titleColor,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                ],
                                                                // 状態バナー
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        AppSpacing
                                                                            .subValue,
                                                                    vertical:
                                                                        AppSpacing
                                                                            .xxs,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        hasInProgress
                                                                        ? Colors
                                                                              .blueGrey
                                                                              .shade600
                                                                        : (allFinished
                                                                              ? (context.appColors.separatorColor)
                                                                              : (isDark
                                                                                    ? const Color(
                                                                                        0xFF2C2C2E,
                                                                                      )
                                                                                    : context.appColors.separatorColor)),
                                                                    borderRadius:
                                                                        AppRadius
                                                                            .tiny,
                                                                  ),
                                                                  child: Text(
                                                                    hasInProgress
                                                                        ? '進行中'
                                                                        : (allFinished
                                                                              ? '終了'
                                                                              : '待機中'),
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          AppFontSize
                                                                              .badge,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          hasInProgress
                                                                          ? AppKendoColors.pureWhite
                                                                          : (allFinished
                                                                                ? (isDark
                                                                                      ? context.appColors.subTextColor
                                                                                      : context.appColors.subTextColor)
                                                                                : (context.appColors.subTextColor)),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            if (firstMatch
                                                                .note
                                                                .isNotEmpty) ...[
                                                              const SizedBox(
                                                                height: 6,
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      AppSpacing
                                                                          .xxs,
                                                                ),
                                                                child: Text(
                                                                  firstMatch
                                                                      .note,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        AppFontSize
                                                                            .caption,
                                                                    color:
                                                                        subTitleColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            // 🔽 【3行目】: チーム合計スコア勝数(本数)ライン / またはリーグ戦タイトル（全自動加算による完全一瞥化）
                                                            Builder(
                                                              builder: (context) {
                                                                if (label
                                                                    .contains(
                                                                      'リーグ戦',
                                                                    )) {
                                                                  return Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: Text(
                                                                          _generateDescriptiveLeagueTitle(
                                                                            groupList,
                                                                            ownTeams,
                                                                          ),
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                AppFontSize.bodySmall,
                                                                            fontWeight:
                                                                                AppFontWeight.bold,
                                                                            color:
                                                                                titleColor,
                                                                          ),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                }

                                                                int redWins = 0;
                                                                int redPts = 0;
                                                                int whiteWins =
                                                                    0;
                                                                int whitePts =
                                                                    0;
                                                                for (var m
                                                                    in groupList) {
                                                                  final r = m
                                                                      .redScore;
                                                                  final w = m
                                                                      .whiteScore;
                                                                  redPts +=
                                                                      (r as num)
                                                                          .toInt();
                                                                  whitePts +=
                                                                      (w as num)
                                                                          .toInt();
                                                                  final mFinished =
                                                                      m.status ==
                                                                          'finished' ||
                                                                      m.status ==
                                                                          'approved';
                                                                  if (mFinished) {
                                                                    if (r > w) {
                                                                      redWins++;
                                                                    } else if (w >
                                                                        r) {
                                                                      whiteWins++;
                                                                    }
                                                                  }
                                                                }
                                                                final ruleTeamName =
                                                                    groupList
                                                                        .firstOrNull
                                                                        ?.rule
                                                                        ?.teamName;
                                                                final isRedOwn =
                                                                    ownTeams
                                                                        .contains(
                                                                          rTeam,
                                                                        ) ||
                                                                    (ruleTeamName?.isNotEmpty ==
                                                                            true &&
                                                                        rTeam ==
                                                                            ruleTeamName);
                                                                final isWhiteOwn =
                                                                    ownTeams
                                                                        .contains(
                                                                          wTeam,
                                                                        ) ||
                                                                    (ruleTeamName?.isNotEmpty ==
                                                                            true &&
                                                                        wTeam ==
                                                                            ruleTeamName);

                                                                final showLeftTeam =
                                                                    rTeam;
                                                                final showRightTeam =
                                                                    wTeam;
                                                                final showLeftWins =
                                                                    redWins;
                                                                final showLeftPts =
                                                                    redPts;
                                                                final showRightWins =
                                                                    whiteWins;
                                                                final showRightPts =
                                                                    whitePts;
                                                                final showLeftOwn =
                                                                    isRedOwn;
                                                                final showRightOwn =
                                                                    isWhiteOwn;

                                                                return Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Expanded(
                                                                      child: Text(
                                                                        showLeftTeam,
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              AppFontSize.bodyMedium,
                                                                          fontWeight:
                                                                              showLeftOwn
                                                                              ? AppFontWeight.black
                                                                              : AppFontWeight.bold,
                                                                          color:
                                                                              showLeftOwn
                                                                              ? const Color(
                                                                                  0xFFFFB300,
                                                                                )
                                                                              : titleColor,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.end,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            AppSpacing.lg,
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Text(
                                                                            '$showLeftWins',
                                                                            style: TextStyle(
                                                                              fontSize: AppFontSize.subhead,
                                                                              fontWeight: AppFontWeight.bold,
                                                                              color: isDark
                                                                                  ? const Color(
                                                                                      0xFFE53935,
                                                                                    )
                                                                                  : const Color(
                                                                                      0xFFE53935,
                                                                                    ),
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            '($showLeftPts)',
                                                                            style: TextStyle(
                                                                              fontSize: AppFontSize.caption,
                                                                              color: isDark
                                                                                  ? const Color(
                                                                                      0x8A000000,
                                                                                    )
                                                                                  : const Color(
                                                                                      0x8A000000,
                                                                                    ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal: AppSpacing.subValue,
                                                                            ),
                                                                            child: Text(
                                                                              'ー',
                                                                              style: TextStyle(
                                                                                fontSize: AppFontSize.body,
                                                                                color: const Color(
                                                                                  0x8A000000,
                                                                                ),
                                                                                fontWeight: AppFontWeight.bold,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            '$showRightWins',
                                                                            style: TextStyle(
                                                                              fontSize: AppFontSize.subhead,
                                                                              fontWeight: AppFontWeight.bold,
                                                                              color: context.appColors.textColor,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            '($showRightPts)',
                                                                            style: TextStyle(
                                                                              fontSize: AppFontSize.caption,
                                                                              color: isDark
                                                                                  ? context.appColors.subTextColor
                                                                                  : context.appColors.subTextColor,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        showRightTeam,
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              AppFontSize.bodyMedium,
                                                                          fontWeight:
                                                                              showRightOwn
                                                                              ? AppFontWeight.black
                                                                              : AppFontWeight.bold,
                                                                          color:
                                                                              showRightOwn
                                                                              ? const Color(
                                                                                  0xFFFFB300,
                                                                                )
                                                                              : titleColor,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.start,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        subtitle: Text(
                                                          '$displayMatchCount対戦',
                                                          style: TextStyle(
                                                            color:
                                                                subTitleColor,
                                                            fontSize:
                                                                AppFontSize
                                                                    .small,
                                                          ),
                                                        ),
                                                        children: (() {
                                                          final List<Widget>
                                                          childrenWidgets = [];
                                                          final normalMatches =
                                                              groupList
                                                                  .where(
                                                                    (m) => !m
                                                                        .note
                                                                        .contains(
                                                                          '[順位決定戦]',
                                                                        ),
                                                                  )
                                                                  .toList();
                                                          final tieBreakMatches =
                                                              groupList
                                                                  .where(
                                                                    (m) => m
                                                                        .note
                                                                        .contains(
                                                                          '[順位決定戦]',
                                                                        ),
                                                                  )
                                                                  .toList();

                                                          // 決定戦作成ボタンは削除済み

                                                          if (label.contains(
                                                            'リーグ戦',
                                                          )) {
                                                            if (label.contains(
                                                              '個人戦',
                                                            )) {
                                                              // 🛡️ STEP 4-1 要件：一意な識別Key（viewer_match_card_xxx）を完全埋入
                                                              childrenWidgets.addAll(
                                                                normalMatches
                                                                    .map(
                                                                      (
                                                                        m,
                                                                      ) => ViewerMatchListTileCard(
                                                                        key: Key(
                                                                          'viewer_match_card_${m.id}',
                                                                        ),
                                                                        initialMatch:
                                                                            m,
                                                                      ),
                                                                    )
                                                                    .toList(),
                                                              );
                                                            } else {
                                                              // 【リーグ団体戦】中枠あり
                                                              final boutsByMatchup =
                                                                  <
                                                                    String,
                                                                    List<
                                                                      MatchModel
                                                                    >
                                                                  >{};
                                                              final matchupOrder =
                                                                  <String>[];
                                                              for (var m
                                                                  in normalMatches) {
                                                                final t1 = m
                                                                    .redName
                                                                    .split(':')
                                                                    .first
                                                                    .trim();
                                                                final r2 = m
                                                                    .whiteName
                                                                    .split(':')
                                                                    .first
                                                                    .trim();
                                                                final matchupName =
                                                                    '$t1 vs $r2';
                                                                if (!boutsByMatchup
                                                                    .containsKey(
                                                                      matchupName,
                                                                    )) {
                                                                  matchupOrder.add(
                                                                    matchupName,
                                                                  );
                                                                  boutsByMatchup[matchupName] =
                                                                      [];
                                                                }
                                                                boutsByMatchup[matchupName]!
                                                                    .add(m);
                                                              }

                                                              childrenWidgets.addAll(
                                                                matchupOrder.map((
                                                                  name,
                                                                ) {
                                                                  final bouts =
                                                                      boutsByMatchup[name]!;
                                                                  final bool
                                                                  boutsInProgress =
                                                                      bouts.any(
                                                                        (m) =>
                                                                            m.status ==
                                                                            'in_progress',
                                                                      );
                                                                  final bool
                                                                  boutsAllFinished = bouts.every(
                                                                    (m) =>
                                                                        m.status ==
                                                                            'finished' ||
                                                                        m.status ==
                                                                            'approved',
                                                                  );

                                                                  final t1 = name
                                                                      .split(
                                                                        ' vs ',
                                                                      )[0];
                                                                  final t2 = name
                                                                      .split(
                                                                        ' vs ',
                                                                      )[1];

                                                                  final Color
                                                                  mCardBg =
                                                                      boutsAllFinished
                                                                      ? (isDark
                                                                            ? const Color(
                                                                                0xFF161618,
                                                                              )
                                                                            : const Color(
                                                                                0xFFF2F2F7,
                                                                              ))
                                                                      : (isDark
                                                                            ? const Color(
                                                                                0xFF1C1C1E,
                                                                              )
                                                                            : const Color(
                                                                                0xFFFFFFFF,
                                                                              ));

                                                                  final Color
                                                                  mTitleColor =
                                                                      boutsAllFinished
                                                                      ? (isDark
                                                                            ? context.appColors.subTextColor
                                                                            : context.appColors.subTextColor)
                                                                      : (context
                                                                            .appColors
                                                                            .textColor);

                                                                  return Container(
                                                                    margin: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          AppSpacing
                                                                              .sm,
                                                                      vertical:
                                                                          AppSpacing
                                                                              .xs,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          AppRadius
                                                                              .small,
                                                                      border: Border.all(
                                                                        color:
                                                                            isDark
                                                                            ? const Color(
                                                                                0xFF38383A,
                                                                              )
                                                                            : const Color(
                                                                                0x33000000,
                                                                              ),
                                                                        width:
                                                                            1,
                                                                      ),
                                                                      boxShadow:
                                                                          boutsInProgress
                                                                          ? [
                                                                              BoxShadow(
                                                                                color: AppKendoColors.blue.withValues(
                                                                                  alpha: 0.1,
                                                                                ),
                                                                                blurRadius: 4,
                                                                                offset: const Offset(
                                                                                  0,
                                                                                  2,
                                                                                ),
                                                                              ),
                                                                            ]
                                                                          : [],
                                                                    ),
                                                                    child: ClipRRect(
                                                                      borderRadius:
                                                                          AppRadius
                                                                              .sub,
                                                                      child: Theme(
                                                                        data:
                                                                            Theme.of(
                                                                              context,
                                                                            ).copyWith(
                                                                              dividerColor: AppKendoColors.transparent,
                                                                            ),
                                                                        child: ExpansionTile(
                                                                          collapsedBackgroundColor:
                                                                              mCardBg,
                                                                          backgroundColor:
                                                                              mCardBg,
                                                                          title: Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  Text(
                                                                                    '${bouts.length}ポジション',
                                                                                    style: const TextStyle(
                                                                                      fontSize: AppFontSize.caption,
                                                                                      color: AppKendoColors.grey,
                                                                                      fontWeight: AppFontWeight.bold,
                                                                                    ),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  if (bouts.isNotEmpty &&
                                                                                      bouts.first.groupName !=
                                                                                          null &&
                                                                                      bouts.first.groupName!.isNotEmpty)
                                                                                    Padding(
                                                                                      padding: const EdgeInsets.only(
                                                                                        right: AppSpacing.subValue,
                                                                                      ),
                                                                                      child: SizedBox(
                                                                                        height: 24,
                                                                                        child: OutlinedButton(
                                                                                          onPressed: () {
                                                                                            final encodedGroupName = Uri.encodeComponent(
                                                                                              bouts.first.groupName ??
                                                                                                  '',
                                                                                            );
                                                                                            context.push(
                                                                                              '/viewer-team/$encodedGroupName',
                                                                                            );
                                                                                          },
                                                                                          style: OutlinedButton.styleFrom(
                                                                                            padding: const EdgeInsets.symmetric(
                                                                                              horizontal: AppSpacing.sm,
                                                                                            ),
                                                                                            side: BorderSide(
                                                                                              color: mTitleColor.withValues(
                                                                                                alpha: 0.2,
                                                                                              ),
                                                                                            ),
                                                                                            shape: RoundedRectangleBorder(
                                                                                              borderRadius: AppRadius.sub,
                                                                                            ),
                                                                                          ),
                                                                                          child: Text(
                                                                                            'スコア',
                                                                                            style: TextStyle(
                                                                                              fontSize: AppFontSize.badge,
                                                                                              fontWeight: AppFontWeight.bold,
                                                                                              color: mTitleColor,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  Container(
                                                                                    padding: const EdgeInsets.symmetric(
                                                                                      horizontal: AppSpacing.subValue,
                                                                                      vertical: AppSpacing.xxs,
                                                                                    ),
                                                                                    decoration: BoxDecoration(
                                                                                      color: boutsInProgress
                                                                                          ? context.appColors.subTextColor
                                                                                          : (boutsAllFinished
                                                                                                ? (context.appColors.separatorColor)
                                                                                                : (isDark
                                                                                                      ? const Color(
                                                                                                          0xFF2C2C2E,
                                                                                                        )
                                                                                                      : context.appColors.separatorColor)),
                                                                                      borderRadius: AppRadius.tiny,
                                                                                    ),
                                                                                    child: Text(
                                                                                      boutsInProgress
                                                                                          ? '進行中'
                                                                                          : (boutsAllFinished
                                                                                                ? '終了'
                                                                                                : '待機中'),
                                                                                      style: TextStyle(
                                                                                        fontSize: AppFontSize.badge,
                                                                                        fontWeight: AppFontWeight.bold,
                                                                                        color: boutsInProgress
                                                                                            ? AppKendoColors.pureWhite
                                                                                            : (boutsAllFinished
                                                                                                  ? (isDark
                                                                                                        ? context.appColors.subTextColor
                                                                                                        : context.appColors.subTextColor)
                                                                                                  : (context.appColors.subTextColor)),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(
                                                                                height: 10,
                                                                              ),
                                                                              Builder(
                                                                                builder:
                                                                                    (
                                                                                      context,
                                                                                    ) {
                                                                                      int redWins = 0;
                                                                                      int redPts = 0;
                                                                                      int whiteWins = 0;
                                                                                      int whitePts = 0;
                                                                                      for (var m in bouts) {
                                                                                        if (m.matchType ==
                                                                                            '代表戦') {
                                                                                          continue; // ★ 代表戦は合計に含めない
                                                                                        }
                                                                                        final r = m.redScore;
                                                                                        final w = m.whiteScore;
                                                                                        redPts +=
                                                                                            (r
                                                                                                    as num)
                                                                                                .toInt();
                                                                                        whitePts +=
                                                                                            (w
                                                                                                    as num)
                                                                                                .toInt();
                                                                                        if (m.status ==
                                                                                                'finished' ||
                                                                                            m.status ==
                                                                                                'approved') {
                                                                                          if (r >
                                                                                              w) {
                                                                                            redWins++;
                                                                                          } else if (w >
                                                                                              r) {
                                                                                            whiteWins++;
                                                                                          }
                                                                                        }
                                                                                      }
                                                                                      final ruleTeamName = bouts.firstOrNull?.rule?.teamName;
                                                                                      final isRedOwn =
                                                                                          ownTeams.contains(
                                                                                            t1,
                                                                                          ) ||
                                                                                          (ruleTeamName?.isNotEmpty ==
                                                                                                  true &&
                                                                                              t1 ==
                                                                                                  ruleTeamName);
                                                                                      final isWhiteOwn =
                                                                                          ownTeams.contains(
                                                                                            t2,
                                                                                          ) ||
                                                                                          (ruleTeamName?.isNotEmpty ==
                                                                                                  true &&
                                                                                              t2 ==
                                                                                                  ruleTeamName);

                                                                                      final showLeftTeam = t1;
                                                                                      final showRightTeam = t2;
                                                                                      final showLeftWins = redWins;
                                                                                      final showLeftPts = redPts;
                                                                                      final showRightWins = whiteWins;
                                                                                      final showRightPts = whitePts;
                                                                                      final showLeftOwn = isRedOwn;
                                                                                      final showRightOwn = isWhiteOwn;

                                                                                      return Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                                        children: [
                                                                                          Expanded(
                                                                                            child: Text(
                                                                                              showLeftTeam,
                                                                                              style: TextStyle(
                                                                                                fontSize: AppFontSize.body,
                                                                                                fontWeight: showLeftOwn
                                                                                                    ? AppFontWeight.black
                                                                                                    : AppFontWeight.bold,
                                                                                                color: showLeftOwn
                                                                                                    ? const Color(
                                                                                                        0xFFFFB300,
                                                                                                      )
                                                                                                    : mTitleColor,
                                                                                              ),
                                                                                              textAlign: TextAlign.end,
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                            ),
                                                                                          ),
                                                                                          Padding(
                                                                                            padding: const EdgeInsets.symmetric(
                                                                                              horizontal: AppSpacing.md,
                                                                                            ),
                                                                                            child: Row(
                                                                                              mainAxisSize: MainAxisSize.min,
                                                                                              children: [
                                                                                                Text(
                                                                                                  '$showLeftWins',
                                                                                                  style: TextStyle(
                                                                                                    fontSize: AppFontSize.bodyMedium,
                                                                                                    fontWeight: AppFontWeight.bold,
                                                                                                    color: isDark
                                                                                                        ? const Color(
                                                                                                            0xFFE53935,
                                                                                                          )
                                                                                                        : const Color(
                                                                                                            0xFFE53935,
                                                                                                          ),
                                                                                                  ),
                                                                                                ),
                                                                                                Text(
                                                                                                  '($showLeftPts)',
                                                                                                  style: TextStyle(
                                                                                                    fontSize: AppFontSize.badge,
                                                                                                    color: context.appColors.subTextColor,
                                                                                                  ),
                                                                                                ),
                                                                                                Padding(
                                                                                                  padding: const EdgeInsets.symmetric(
                                                                                                    horizontal: AppSpacing.subValue,
                                                                                                  ),
                                                                                                  child: Text(
                                                                                                    'ー',
                                                                                                    style: TextStyle(
                                                                                                      fontSize: AppFontSize.bodySmall,
                                                                                                      color: context.appColors.subTextColor,
                                                                                                      fontWeight: AppFontWeight.bold,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                Text(
                                                                                                  '$showRightWins',
                                                                                                  style: TextStyle(
                                                                                                    fontSize: AppFontSize.bodyMedium,
                                                                                                    fontWeight: AppFontWeight.bold,
                                                                                                    color: context.appColors.textColor,
                                                                                                  ),
                                                                                                ),
                                                                                                Text(
                                                                                                  '($showRightPts)',
                                                                                                  style: TextStyle(
                                                                                                    fontSize: AppFontSize.badge,
                                                                                                    color: context.appColors.subTextColor,
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                          Expanded(
                                                                                            child: Text(
                                                                                              showRightTeam,
                                                                                              style: TextStyle(
                                                                                                fontSize: AppFontSize.body,
                                                                                                fontWeight: showRightOwn
                                                                                                    ? AppFontWeight.black
                                                                                                    : AppFontWeight.bold,
                                                                                                color: showRightOwn
                                                                                                    ? const Color(
                                                                                                        0xFFFFB300,
                                                                                                      )
                                                                                                    : mTitleColor,
                                                                                              ),
                                                                                              textAlign: TextAlign.start,
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    },
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          // ★ 適合置換②: リーグ内各ポジションの試合タイル置換（Key付与）
                                                                          children: bouts
                                                                              .map(
                                                                                (
                                                                                  m,
                                                                                ) => ViewerMatchListTileCard(
                                                                                  key: Key(
                                                                                    'viewer_match_card_${m.id}',
                                                                                  ),
                                                                                  initialMatch: m,
                                                                                ),
                                                                              )
                                                                              .toList(),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }),
                                                              );
                                                            }
                                                          } else {
                                                            // ★ 適合置換③: 通常のトーナメント団体戦内ポジション置換（Key付与）
                                                            childrenWidgets.addAll(
                                                              normalMatches
                                                                  .map(
                                                                    (
                                                                      m,
                                                                    ) => ViewerMatchListTileCard(
                                                                      key: Key(
                                                                        'viewer_match_card_${m.id}',
                                                                      ),
                                                                      initialMatch:
                                                                          m,
                                                                    ),
                                                                  )
                                                                  .toList(),
                                                            );
                                                          }

                                                          if (tieBreakMatches
                                                              .isNotEmpty) {
                                                            childrenWidgets.add(
                                                              const Divider(),
                                                            );
                                                            childrenWidgets.add(
                                                              const Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      AppSpacing
                                                                          .sm,
                                                                    ),
                                                                child: Text(
                                                                  '【順位決定戦】',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        AppFontSize
                                                                            .small,
                                                                    color: Colors
                                                                        .orange,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                            // ★ 適合置換④: 順位決定戦置換（Key付与）
                                                            childrenWidgets.addAll(
                                                              tieBreakMatches.map(
                                                                (
                                                                  m,
                                                                ) => ViewerMatchListTileCard(
                                                                  key: Key(
                                                                    'viewer_match_card_${m.id}',
                                                                  ),
                                                                  initialMatch:
                                                                      m,
                                                                ),
                                                              ),
                                                            );
                                                          }

                                                          return childrenWidgets;
                                                        })(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          });
                                        })(),

                                        if (sortedPlayers.isNotEmpty) ...[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: AppSpacing.lg,
                                              top: AppSpacing.xs,
                                              bottom: AppSpacing.sm,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  sanitizedQuery.isNotEmpty
                                                      ? Icons.manage_search
                                                      : Icons.person,
                                                  color: AppKendoColors
                                                      .orange
                                                      .shade700,
                                                  size: 16,
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.xs,
                                                ),
                                                Text(
                                                  sanitizedQuery.isNotEmpty
                                                      ? '抽出された個別試合'
                                                      : '個人戦',
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppFontSize.bodySmall,
                                                    fontWeight:
                                                        AppFontWeight.bold,
                                                    color: AppKendoColors
                                                        .orange
                                                        .shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ...sortedPlayers.map((playerEntry) {
                                            final playerName = playerEntry.key;
                                            final playerMatches =
                                                playerEntry.value;
                                            final firstMatch =
                                                playerMatches.first;
                                            final label = getMatchLabel(
                                              firstMatch,
                                            );

                                            final bool pInProgress =
                                                playerMatches.any(
                                                  (m) =>
                                                      m.status == 'in_progress',
                                                );
                                            final bool pAllFinished =
                                                playerMatches.every(
                                                  (m) =>
                                                      m.status == 'finished' ||
                                                      m.status == 'approved',
                                                );

                                            final Color pCardBg = pAllFinished
                                                ? (isDark
                                                      ? const Color(0xFF161618)
                                                      : AppKendoColors
                                                            .grey
                                                            .shade100)
                                                : (context
                                                      .appColors
                                                      .cardBackground);

                                            final Color pTitleColor =
                                                pAllFinished
                                                ? (isDark
                                                      ? AppKendoColors
                                                            .grey
                                                            .shade600
                                                      : AppKendoColors
                                                            .grey
                                                            .shade500)
                                                : (context.appColors.textColor);
                                            final Color pSubTitleColor =
                                                pAllFinished
                                                ? (isDark
                                                      ? AppKendoColors
                                                            .grey
                                                            .shade700
                                                      : AppKendoColors
                                                            .grey
                                                            .shade500)
                                                : (isDark
                                                      ? AppKendoColors
                                                            .grey
                                                            .shade500
                                                      : AppKendoColors
                                                            .grey
                                                            .shade600);

                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.md,
                                                    vertical: AppSpacing.xs,
                                                  ),
                                              decoration: BoxDecoration(
                                                // ★ 修正: color: pCardBg, を削除
                                                borderRadius: AppRadius.medium,
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0xFF38383A)
                                                      : AppKendoColors
                                                            .grey
                                                            .shade300,
                                                  width: 1,
                                                ),
                                                boxShadow: pInProgress
                                                    ? [
                                                        BoxShadow(
                                                          color: AppKendoColors
                                                              .blue
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ]
                                                    : [],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: AppRadius.smooth,
                                                child: ExpansionTile(
                                                  collapsedBackgroundColor:
                                                      pCardBg,
                                                  backgroundColor:
                                                      pCardBg, // ★ 修正: 色をここで指定
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        pAllFinished
                                                        ? (isDark
                                                              ? Colors
                                                                    .grey
                                                                    .shade800
                                                              : Colors
                                                                    .grey
                                                                    .shade300)
                                                        : Colors
                                                              .orange
                                                              .shade100,
                                                    child: Text(
                                                      playerName[0],
                                                      style: TextStyle(
                                                        color: pAllFinished
                                                            ? (isDark
                                                                  ? Colors
                                                                        .grey
                                                                        .shade500
                                                                  : Colors
                                                                        .grey
                                                                        .shade600)
                                                            : Colors
                                                                  .orange
                                                                  .shade800,
                                                        fontSize:
                                                            AppFontSize.small,
                                                        fontWeight:
                                                            AppFontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    playerName,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          AppFontWeight.bold,
                                                      fontSize: AppFontSize
                                                          .bodyMedium,
                                                      color: pTitleColor,
                                                    ),
                                                  ),
                                                  subtitle: Row(
                                                    children: [
                                                      Text(
                                                        '$label • ${playerMatches.length}試合',
                                                        style: TextStyle(
                                                          fontSize:
                                                              AppFontSize.small,
                                                          color: pSubTitleColor,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: AppSpacing.sm,
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal:
                                                                  AppSpacing
                                                                      .subValue,
                                                              vertical:
                                                                  AppSpacing
                                                                      .xxs,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: pInProgress
                                                              ? Colors
                                                                    .blueGrey
                                                                    .shade600
                                                              : (pAllFinished
                                                                    ? (context
                                                                          .appColors
                                                                          .separatorColor)
                                                                    : (isDark
                                                                          ? const Color(
                                                                              0xFF2C2C2E,
                                                                            )
                                                                          : context.appColors.separatorColor)),
                                                          borderRadius:
                                                              AppRadius.tiny,
                                                        ),
                                                        child: Text(
                                                          pInProgress
                                                              ? '進行中'
                                                              : (pAllFinished
                                                                    ? '終了'
                                                                    : '待機中'),
                                                          style: TextStyle(
                                                            fontSize:
                                                                AppFontSize
                                                                    .badge,
                                                            fontWeight:
                                                                AppFontWeight
                                                                    .bold,
                                                            color: pInProgress
                                                                ? AppKendoColors
                                                                      .pureWhite
                                                                : (pAllFinished
                                                                      ? (isDark
                                                                            ? context.appColors.subTextColor
                                                                            : context.appColors.subTextColor)
                                                                      : (context
                                                                            .appColors
                                                                            .subTextColor)),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  // ★ 適合置換⑤: 独立個人戦内ポジション置換
                                                  children: playerMatches
                                                      .map(
                                                        (match) =>
                                                            ViewerMatchListTileCard(
                                                              initialMatch:
                                                                  match,
                                                            ),
                                                      )
                                                      .toList(),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                        const SizedBox(height: AppSpacing.sm),
                                      ],
                                    ),
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

class ViewerHomeScreenUtils {
  // 元から存在していたトップレベル関数群を包むダミー、またはそのまま配置
}

Widget _buildCallRow(String label, dynamic match, Color textColor) {
  return Column(
    children: [
      if (match.note.isNotEmpty)
        Text(
          match.note,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.7),
            fontSize: AppFontSize.small,
            fontWeight: AppFontWeight.bold,
          ),
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: AppFontWeight.bold),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              _getMatchTitle(match),
              style: TextStyle(
                color: textColor,
                fontSize: AppFontSize.headline,
                fontWeight: AppFontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
  );
}

String _getMatchTitle(dynamic match) {
  final isGrouped = match.groupName != null && match.groupName!.isNotEmpty;
  final isIndividual =
      match.matchType == 'individual' ||
      match.matchType == '選手' ||
      match.matchType.contains('個人戦');

  if (isGrouped && !isIndividual) {
    final rTeam = match.redName.contains(':')
        ? match.redName.split(':').first.trim()
        : match.redName;
    final wTeam = match.whiteName.contains(':')
        ? match.whiteName.split(':').first.trim()
        : match.whiteName;
    return '$rTeam vs $wTeam';
  }

  return '${match.redName} vs ${_reverseWhiteName(match.whiteName)}';
}

String _reverseWhiteName(String whiteName) {
  if (!whiteName.contains(':')) return whiteName;
  final parts = whiteName.split(':');
  if (parts.length != 2) return whiteName;
  final teamName = parts[0].trim();
  final playerName = parts[1].trim();
  return '$playerName : $teamName';
}

String _generateDescriptiveLeagueTitle(
  List<MatchModel> matches,
  List<String> ownTeams,
) {
  final participantsSet = <String>{};
  for (var m in matches) {
    participantsSet.add(m.redName.split(':').first.trim());
    participantsSet.add(m.whiteName.split(':').first.trim());
  }
  final int n = participantsSet.length;
  final int mCount = n * (n - 1) ~/ 2;

  final ruleTeamName = matches.firstOrNull?.rule?.teamName;
  final hasRuleTeam = ruleTeamName?.isNotEmpty == true;

  final bool isIndiv = matches.any(
    (m) =>
        m.matchType == 'individual' ||
        m.matchType == '選手' ||
        m.matchType.contains('個人戦'),
  );

  String selfInfo = "";
  if (isIndiv) {
    final myMatch = matches.firstWhere(
      (m) =>
          ownTeams.any(
            (ot) => m.redName.contains(ot) || m.whiteName.contains(ot),
          ) ||
          (hasRuleTeam &&
              (m.redName.contains(ruleTeamName!) ||
                  m.whiteName.contains(ruleTeamName))),
      orElse: () => matches.first,
    );
    final isRedOwn =
        ownTeams.any((ot) => myMatch.redName.contains(ot)) ||
        (hasRuleTeam && myMatch.redName.contains(ruleTeamName!));
    final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
    final team = rawName.split(':').first.trim();
    final name = rawName.contains(':')
        ? rawName.split(':').last.replaceAll(')', '').trim()
        : rawName;
    selfInfo = "$name（$team）";
  } else {
    selfInfo = participantsSet.firstWhere(
      (p) => ownTeams.contains(p) || (hasRuleTeam && p == ruleTeamName),
      orElse: () => participantsSet.first,
    );
  }

  final suffix = isIndiv ? "$n人リーグ" : "$nチームリーグ";
  return "$selfInfo : $suffix（全$mCount試合）";
}

// ==========================================
// ★ Phase 4-1, 4-3, 4-6: スリム化された巨大メニューボタン (観客向け)
// 高齢補助員向けの押しやすさを維持しつつ、パディングを減らし、サブタイトルを削除.
// アイコンとフォントサイズを小さくして高さを抑え、画面領域を効率的に使います。
// ==========================================
Widget _buildHugeMenuButton(
  BuildContext context,
  bool enableLiquidGlass,
  IconData icon,
  String title,
  MaterialColor color,
  VoidCallback onTap,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GlassButton(
    onPressed: onTap,
    color: color,
    icon: icon,
    label: title,
    trailing: Icon(
      Icons.arrow_forward_ios,
      size: 14,
      color: enableLiquidGlass
          ? (isDark ? color.shade500 : color.shade300)
          : context.appColors.textColor.withValues(alpha: 0.7),
    ),
  );
}

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
