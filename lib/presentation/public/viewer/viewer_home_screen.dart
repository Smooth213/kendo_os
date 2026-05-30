import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

// ドメイン・インフラ・リポジトリ層
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/entities/tournament_model.dart';
import 'package:kendo_os/infrastructure/repository/player_repository.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';

// プロバイダ層
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';

// 共通シェアUIコンポーネント・ウィジェット層（★ パスを正しい座標へ完全適合）
import 'package:kendo_os/presentation/shared/widgets/liquid_background.dart';
import 'package:kendo_os/presentation/shared/widgets/glass_button.dart';
import 'package:kendo_os/presentation/shared/widgets/manual_help_button.dart';
import 'package:kendo_os/presentation/shared/utils/match_calculator_helper.dart';

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
typedef _SafeViewerTimelineResult = ({List<MapEntry<String, List<MatchModel>>> entries, Set<String> matchedGroupNames, Set<String> matchedMatchIds, bool isLoading, bool hasError, String? errorMessage});

final safeViewerTimelineProvider = Provider.family.autoDispose<_SafeViewerTimelineResult, String>((ref, String tournamentId) {
  final asyncMatches = ref.watch(matchListByTournamentProvider(tournamentId));
  
  final bool hasError = asyncMatches.hasError;
  final String? errorMessage = asyncMatches.error?.toString();

  if (hasError) {
    debugPrint('🚨 [safeViewerTimelineProvider] エラーを検知しました: $errorMessage');
  } else if (!asyncMatches.isLoading) {
    debugPrint('📊 [safeViewerTimelineProvider] 試合リスト抽出完了: ${asyncMatches.value?.length ?? 0} 件');
    if ((asyncMatches.value?.length ?? 0) == 0) {
      debugPrint('🤔 [safeViewerTimelineProvider] 試合が0件です。クラウド側でデータが作成されていないか、検索クエリ・大会IDの不一致の可能性があります。');
    }
  }

  final matches = List<MatchModel>.from(asyncMatches.value ?? [])
    ..sort((a, b) => a.order.compareTo(b.order));
      
  final searchQuery = ref.watch(searchQueryProvider).replaceAll(RegExp(r'\s+'), '').toLowerCase();
  final isSortAscending = ref.watch(categorySortProvider);

  final matchedGroupNames = <String>{};
  final matchedMatchIds = <String>{};

  if (searchQuery.isNotEmpty) {
    for (var m in matches) {
      final rName = m.redName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final wName = m.whiteName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
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
      bool isMatch = matchedMatchIds.contains(m.id) || 
                     (m.groupName != null && matchedGroupNames.contains(m.groupName!));
      if (!isMatch) continue;
    }
    final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : '未分類';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color textColor = isDark ? Colors.white : Colors.black;

    try {
        // ★ 修正: activeMatchesProvider だとリーグ戦や勝ち抜き戦で最初の試合が終了すると
        // グループ全体がバナーから消えてしまう不具合があるため、専用の抽出ロジックに置き換え
        final asyncMatches = ref.watch(matchListByTournamentProvider(tournamentId));
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

        final sanitizedQuery = ref.watch(searchQueryProvider).replaceAll(RegExp(r'\s+'), '').toLowerCase();
        final timelineResult = ref.watch(safeViewerTimelineProvider(tournamentId));
        final matchedGroupNames = timelineResult.matchedGroupNames;
        final matchedMatchIds = timelineResult.matchedMatchIds;

        return PopScope(
          canPop: false, // 戻るスワイプをブロック
          child: LiquidBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                // ★ 修正1: 標準の戻るボタン（<）は消す
                automaticallyImplyLeading: false, 
          
          // ★ 修正2: 「管理者アプリから直接遷移してきた（戻る履歴がある）場合」のみ扉ボタンを出す
          // 従来の context.canPop() だとWebブラウザでQRから直接アクセスした際に
          // 暗黙の履歴によって true と誤判定されるため、GoRouterの canPop() を使用します。
          leading: GoRouter.of(context).canPop() 
              ? IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.deepOrange),
                  tooltip: '管理画面に戻る',
                  onPressed: () => context.pop(),
                )
              : null, // QRコードから直接来た一般客には何も表示しない（null）

          title: Text('大会ホーム (観客席)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          backgroundColor: enableLiquidGlass ? Colors.transparent : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          elevation: 0,
          actions: [
            ManualHelpButton(manualPath: 'docs/manuals/faq/viewer_faq.md', color: isDark ? Colors.white : Colors.indigo.shade900),
            IconButton(
              icon: Icon(Icons.settings, color: isDark ? Colors.white : Colors.indigo.shade900),
              tooltip: '表示設定',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const ViewerSettingsBottomSheet(),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.qr_code_2, color: isDark ? Colors.white : Colors.indigo.shade900),
              tooltip: '大会を共有する',
              onPressed: () => _showShareDialog(context, tournamentId),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            if (uniqueInProgress.isNotEmpty || uniqueWaiting.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade800, // 観客席らしい落ち着いた色に変更
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    if (uniqueInProgress.isNotEmpty)
                      _buildCallRow('進行中', uniqueInProgress.first, Colors.orangeAccent),
                    if (uniqueInProgress.isNotEmpty && uniqueWaiting.isNotEmpty) 
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white24, height: 1)),
                    if (uniqueWaiting.isNotEmpty)
                      _buildCallRow('次試合', uniqueWaiting.first, Colors.white),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  
                  // ==========================================
                  // ★ Phase 4-1, 4-3, 4-6: UI簡略化 & スリム化 (観客向け巨大ボタンの洗練)
                  // 観客が混乱しないよう、巨大ボタンは「試合結果一覧」の1つに絞る。
                  // 高齢補助員向けの押しやすさを維持しつつ、パディングを減らし、サブタイトルを削除。
                  // アイコンとフォントサイズを小さくして高さを抑え、下の試合リストの領域を広げます。
                  // ==========================================
                  _buildHugeMenuButton(context, enableLiquidGlass, Icons.print, '試合結果一覧 (PDF/CSV)', Colors.blueGrey, () => context.push('/official-record/$tournamentId')),
                  const SizedBox(height: 12), // 🌟 縦幅を節約するため12に微調整
                  
                  // ★ 修正: 観客・保護者用のホーム画面（ViewerHome）にも、大会プログラムを「見るだけ」で閲覧できる安全なボタンを追加
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      // 🌟 修正: 遷移先URLに ?role=viewer を確実に付与し、移動先での権限先祖返りを100%防止
                      onPressed: () => context.push('/tournament/$tournamentId/programs?role=viewer'),
                      icon: Icon(Icons.picture_as_pdf, size: 20, color: isDark ? Colors.redAccent.shade100 : Colors.red.shade600),
                      label: Text(
                        '大会プログラムを見る（閲覧専用）', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.grey.shade800),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300), 
                        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  
                  ref.watch(tournamentProvider(tournamentId)).when(
                    data: (tournament) => tournament != null 
                      ? _buildTournamentInfoCard(context, ref, tournament)
                      : const SizedBox.shrink(),
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                    error: (e, s) => Text('大会情報の読み込みに失敗しました: $e'),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!ref.watch(isSearchVisibleProvider))
                          Text('試合リスト', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                        
                        if (ref.watch(isSearchVisibleProvider))
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: SizedBox(
                                height: 32,
                                child: TextField(
                                  autofocus: true,
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: '選手名・チーム名で検索...',
                                    hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.blueGrey.shade400),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () {
                                        ref.read(searchQueryProvider.notifier).state = '';
                                        ref.read(isSearchVisibleProvider.notifier).state = false;
                                      },
                                    ),
                                  ),
                                  onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                                ),
                              ),
                            ),
                          ),
                        
                        if (!ref.watch(isSearchVisibleProvider))
                          const Spacer(),

                        if (!ref.watch(isSearchVisibleProvider))
                          IconButton(
                            icon: Icon(Icons.search, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => ref.read(isSearchVisibleProvider.notifier).state = true,
                          ),
                        
                        if (!ref.watch(isSearchVisibleProvider))
                          const SizedBox(width: 12),

                        OutlinedButton.icon(
                          onPressed: () => ref.read(categorySortProvider.notifier).state = !ref.read(categorySortProvider),
                          icon: Icon(ref.watch(categorySortProvider) ? Icons.arrow_downward : Icons.arrow_upward, size: 16),
                          label: Text(ref.watch(categorySortProvider) ? 'カテゴリ昇順' : 'カテゴリ降順', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
                            side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.blueGrey.shade200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (timelineResult.hasError)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text('データの取得に失敗しました', style: TextStyle(color: isDark ? Colors.red.shade300 : Colors.red, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(timelineResult.errorMessage ?? '通信状況を確認してください', style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),

                  if (timelineResult.entries.isEmpty && sanitizedQuery.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('該当する試合が見つかりません', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  
                  if (timelineResult.entries.isEmpty && timelineResult.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  
                  ...(() {
                    if (timelineResult.entries.isEmpty) return <Widget>[];
                    final sortedEntries = timelineResult.entries;
                    return sortedEntries.map<Widget>((catEntry) {
                      try {
                      final categoryName = catEntry.key;
                      final catMatches = catEntry.value;

                      final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
                      final matchesByTeam = <String, List<MatchModel>>{};
                      
                      final groupToOwnTeams = <String, Set<String>>{};
                      for (var m in catMatches) {
                        if (m.groupName != null && m.groupName!.isNotEmpty) {
                          String rTeam = m.redName.contains(':') ? m.redName.split(':').first.trim() : m.redName;
                          String wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first.trim() : m.whiteName;
                          if (ownTeams.contains(rTeam)) groupToOwnTeams.putIfAbsent(m.groupName!, () => {}).add(rTeam);
                          if (ownTeams.contains(wTeam)) groupToOwnTeams.putIfAbsent(m.groupName!, () => {}).add(wTeam);
                        }
                      }

                      for (var m in catMatches) {
                        String rTeam = m.redName.contains(':') ? m.redName.split(':').first.trim() : m.redName;
                        String wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first.trim() : m.whiteName;
                        
                        bool isRedOwn = ownTeams.contains(rTeam);
                        bool isWhiteOwn = ownTeams.contains(wTeam);

                        if (m.groupName != null && m.groupName!.isNotEmpty && groupToOwnTeams.containsKey(m.groupName!)) {
                          for (String team in groupToOwnTeams[m.groupName!]!) {
                            matchesByTeam.putIfAbsent(team, () => []).add(m);
                          }
                        } else {
                          if (isRedOwn) {
                            matchesByTeam.putIfAbsent(rTeam, () => []).add(m);
                          }
                          if (isWhiteOwn && wTeam != rTeam) {
                            matchesByTeam.putIfAbsent(wTeam, () => []).add(m);
                          }
                          // ★ 修正: 観客（どちらのチームにも属さない）場合、赤チーム名が空だとリストから消滅する不具合を修正
                          if (!isRedOwn && !isWhiteOwn) {
                             final keyTeam = rTeam.isNotEmpty && !rTeam.contains('代表') ? rTeam 
                                           : (wTeam.isNotEmpty && !wTeam.contains('代表') ? wTeam : '設定なし');
                             matchesByTeam.putIfAbsent(keyTeam, () => []).add(m);
                          }
                        }
                      }

                      final sortedTeams = matchesByTeam.entries.toList();
                      sortedTeams.sort((a, b) => a.key.compareTo(b.key));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
                            child: Text(categoryName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade800, letterSpacing: 1.2)),
                          ),
                          
                          ...sortedTeams.map((teamEntry) {
                            final teamName = teamEntry.key;
                            final teamMatchesList = teamEntry.value;

                            String getMatchLabel(MatchModel m) {
                              final bool isLeague = m.note.contains('[リーグ戦]'); 
                              final bool isKachinuki = m.isKachinuki;
                              final bool isIndividual = !isKachinuki && (m.matchType == 'individual' || m.matchType == '選手');

                              if (isLeague) return isIndividual ? '個人戦/リーグ戦' : '団体戦/リーグ戦';
                              if (isKachinuki) return '団体戦/勝ち抜き戦';
                              return isIndividual ? '個人戦' : '団体戦';
                            }

                            final catGroupedMatches = <String, List<MatchModel>>{};
                            final catIndividualMatches = <MatchModel>[];

                            for (var m in teamMatchesList) {
                              bool forceIndividual = sanitizedQuery.isNotEmpty && 
                                                     matchedMatchIds.contains(m.id) && 
                                                     (m.groupName == null || !matchedGroupNames.contains(m.groupName!));

                              if (!forceIndividual && m.groupName != null && m.groupName!.isNotEmpty) {
                                catGroupedMatches.putIfAbsent(m.groupName!, () => []).add(m);
                              } else {
                                catIndividualMatches.add(m);
                              }
                            }

                            final actualGroupedMatches = <String, List<MatchModel>>{};
                            for (var entry in catGroupedMatches.entries) {
                              if (entry.value.length > 1 || entry.value.first.isKachinuki) {
                                actualGroupedMatches[entry.key] = entry.value;
                              } else {
                                catIndividualMatches.addAll(entry.value);
                              }
                            }

                            final matchesByPlayer = <String, List<MatchModel>>{};
                            for (var m in catIndividualMatches) {
                              String playerName = '選手名不明';
                              
                              bool forceIndividual = sanitizedQuery.isNotEmpty && 
                                                     matchedMatchIds.contains(m.id) && 
                                                     (m.groupName == null || !matchedGroupNames.contains(m.groupName!));
                              if (forceIndividual) {
                                String rPlayer = m.redName.contains(':') ? m.redName.split(':').last.trim() : m.redName;
                                String wPlayer = m.whiteName.contains(':') ? m.whiteName.split(':').last.trim() : m.whiteName;
                                bool rHit = rPlayer.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(sanitizedQuery);
                                bool wHit = wPlayer.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(sanitizedQuery);
                                if (rHit) {
                                  playerName = rPlayer;
                                } else if (wHit) {
                                  playerName = wPlayer;
                                } else {
                                  playerName = m.redName.contains(teamName) ? rPlayer : wPlayer;
                                }
                              } else {
                                if (m.redName.contains(teamName)) {
                                  playerName = m.redName.contains(':') ? m.redName.split(':').last.trim() : m.redName;
                                } else if (m.whiteName.contains(teamName)) {
                                  playerName = m.whiteName.contains(':') ? m.whiteName.split(':').last.trim() : m.whiteName;
                                }
                              }
                              matchesByPlayer.putIfAbsent(playerName, () => []).add(m);
                            }

                            final sortedGroups = actualGroupedMatches.entries.toList()
                              ..sort((a, b) => a.value.first.order.compareTo(b.value.first.order));
                            final sortedPlayers = matchesByPlayer.entries.toList()
                              ..sort((a, b) => a.key.compareTo(b.key));

                            return Container(
                              margin: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161618) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 2),
                                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.blueGrey.shade900.withValues(alpha: 0.3) : Colors.blueGrey.shade50,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                      border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.blueGrey.shade100)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.business, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(teamName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.blueGrey.shade900))),
                                        // 編集ボタンは削除
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),

                                  ...(() {
                                    String lastGroupLabel = ''; 
                                    
                                    return sortedGroups.map((entry) {
                                      final groupList = entry.value;
                                      final firstMatch = groupList.first;
                                      final label = getMatchLabel(firstMatch); 
                                      
                                      Widget? headerWidget;
                                      if (label != lastGroupLabel) {
                                        headerWidget = Padding(
                                          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.groups, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700, size: 16),
                                              const SizedBox(width: 4),
                                              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700)),
                                            ],
                                          ),
                                        );
                                        lastGroupLabel = label;
                                      }
                                      
                                      final rTeam = firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName;
                                      final wTeam = firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName;
                                      
                                      final hasInProgress = groupList.any((m) => m.status == 'in_progress');
                                      final allFinished = groupList.every((m) => m.status == 'finished' || m.status == 'approved');
                                      
                                      final Color cardBg = allFinished 
                                          ? (isDark ? const Color(0xFF161618) : Colors.grey.shade100) 
                                          : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

                                      final Color titleColor = allFinished
                                          ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                                          : (isDark ? Colors.white : Colors.black87);

                                      final Color subTitleColor = allFinished
                                          ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500)
                                          : (isDark ? Colors.grey.shade500 : Colors.grey.shade600);

                                      final pairingsSet = <String>{};
                                      for (var m in groupList) { final t1 = m.redName.split(':').first.trim(); final t2 = m.whiteName.split(':').first.trim(); final pairKey = [t1, t2]..sort(); pairingsSet.add(pairKey.join(' vs ')); }
                                      final int displayMatchCount = pairingsSet.length;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ?headerWidget,
                                          GestureDetector(
                                            onLongPress: null,
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                // ★ 修正: color: cardBg, を削除
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 1),
                                                boxShadow: hasInProgress ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(11),
                                                child: ExpansionTile(
                                                  collapsedBackgroundColor: cardBg, backgroundColor: cardBg,
                                                  title: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // 🔼 【1行目】: 運営系ボタン・メモ一元化ライン
                                                      Row(
                                                        children: [
                                                          if (firstMatch.note.isNotEmpty)
                                                            Flexible(child: Padding(padding: const EdgeInsets.only(right: 6), child: Text(firstMatch.note, style: TextStyle(fontSize: 11, color: subTitleColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1))),
                                                          const Spacer(),
                                                          // 📊スコアボタン（観客閲覧専用リンクにアタッチ）
                                                          if (!label.contains('リーグ戦') && firstMatch.groupName != null && firstMatch.groupName!.isNotEmpty) ...[
                                                            SizedBox(
                                                              height: 26,
                                                              child: OutlinedButton(
                                                                onPressed: () {
                                                                  final encodedGroupName = Uri.encodeComponent(firstMatch.groupName ?? '');
                                                                  context.push(firstMatch.isKachinuki ? '/viewer-kachinuki/\u0000$encodedGroupName' : '/viewer-team/$encodedGroupName');
                                                                },
                                                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: BorderSide(color: titleColor.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                                                child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: titleColor)),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 6),
                                                          ],
                                                          // 状態バナー
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(color: hasInProgress ? Colors.blueGrey.shade600 : (allFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)), borderRadius: BorderRadius.circular(4)),
                                                            child: Text(hasInProgress ? '進行中' : (allFinished ? '終了' : '待機中'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasInProgress ? Colors.white : (allFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)))),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 10),
                                                      // 🔽 【2行目】: チーム合計スコア勝数(本数)ライン / またはリーグ戦タイトル（全自動加算による完全一瞥化）
                                                      Builder(builder: (context) {
                                                        if (label.contains('リーグ戦')) {
                                                          return Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  _generateDescriptiveLeagueTitle(groupList, ownTeams),
                                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor),
                                                                  textAlign: TextAlign.center,
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        }

                                                        int redWins = 0; int redPts = 0;
                                                        int whiteWins = 0; int whitePts = 0;
                                                        for (var m in groupList) {
                                                          final r = m.redScore; final w = m.whiteScore;
                                                          redPts += (r as num).toInt(); whitePts += (w as num).toInt();
                                                          final mFinished = m.status == 'finished' || m.status == 'approved';
                                                          if (mFinished) {
                                                            if (r > w) {
                                                              redWins++;
                                                            } else if (w > r) {
                                                              whiteWins++;
                                                            }
                                                          }
                                                        }
                                                        final isRedOwn = ownTeams.contains(rTeam);
                                                        final isWhiteOwn = ownTeams.contains(wTeam);

                                                        return Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Text(rTeam, style: TextStyle(fontSize: 15, fontWeight: isRedOwn ? FontWeight.w900 : FontWeight.bold, color: isRedOwn ? Colors.amber.shade600 : titleColor), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Text('$redWins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.red.shade300 : Colors.red.shade700)),
                                                                  Text('($redPts)', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                                                  Padding(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                                                    child: Text('ー', style: TextStyle(fontSize: 14, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                  Text('$whiteWins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                                                  Text('($whitePts)', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                                                ],
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Text(wTeam, style: TextStyle(fontSize: 15, fontWeight: isWhiteOwn ? FontWeight.w900 : FontWeight.bold, color: isWhiteOwn ? Colors.amber.shade600 : titleColor), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis),
                                                            ),
                                                          ],
                                                        );
                                                      }),
                                                    ],
                                                  ),
                                                    subtitle: Text('$displayMatchCount対戦', style: TextStyle(color: subTitleColor, fontSize: 12)),
                                                    children: (() {
                                                      final List<Widget> childrenWidgets = [];
                                                      final normalMatches = groupList.where((m) => !m.note.contains('[順位決定戦]')).toList();
                                                      final tieBreakMatches = groupList.where((m) => m.note.contains('[順位決定戦]')).toList();

                                                      // 決定戦作成ボタンは削除済み

                                                      if (label.contains('リーグ戦')) {
                                                        if (label.contains('個人戦')) {
                                                          // 🛡️ STEP 4-1 要件：一意な識別Key（viewer_match_card_xxx）を完全埋入
                                                          childrenWidgets.addAll(normalMatches.map((m) => ViewerMatchListTileCard(key: Key('viewer_match_card_${m.id}'), initialMatch: m)).toList());
                                                        } else {
                                                          // 【リーグ団体戦】中枠あり
                                                          final boutsByMatchup = <String, List<MatchModel>>{};
                                                          final matchupOrder = <String>[];
                                                          for (var m in normalMatches) {
                                                            final t1 = m.redName.split(':').first.trim();
                                                            final r2 = m.whiteName.split(':').first.trim();
                                                            final matchupName = '$t1 vs $r2';
                                                            if (!boutsByMatchup.containsKey(matchupName)) {
                                                              matchupOrder.add(matchupName);
                                                              boutsByMatchup[matchupName] = [];
                                                            }
                                                            boutsByMatchup[matchupName]!.add(m);
                                                          }

                                                          childrenWidgets.addAll(matchupOrder.map((name) {
                                                          final bouts = boutsByMatchup[name]!;
                                                          final bool boutsInProgress = bouts.any((m) => m.status == 'in_progress');
                                                          final bool boutsAllFinished = bouts.every((m) => m.status == 'finished' || m.status == 'approved');

                                                          final t1 = name.split(' vs ')[0];
                                                          final t2 = name.split(' vs ')[1];

                                                          final Color mCardBg = boutsAllFinished 
                                                              ? (isDark ? const Color(0xFF161618) : Colors.grey.shade100) 
                                                              : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
                                                              
                                                          final Color mTitleColor = boutsAllFinished 
                                                              ? (isDark ? Colors.grey.shade600 : Colors.grey.shade50) 
                                                              : (isDark ? Colors.white : Colors.black87);

                                                          return Container(
                                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 1),
                                                              boxShadow: boutsInProgress ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(7),
                                                              child: Theme(
                                                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                                                child: ExpansionTile(
                                                                  collapsedBackgroundColor: mCardBg, backgroundColor: mCardBg,
                                                                  title: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          Text('${bouts.length}ポジション', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                                          const Spacer(),
                                                                          if (bouts.isNotEmpty && bouts.first.groupName != null && bouts.first.groupName!.isNotEmpty)
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(right: 6),
                                                                              child: SizedBox(
                                                                                height: 24,
                                                                                child: OutlinedButton(
                                                                                  onPressed: () {
                                                                                    final encodedGroupName = Uri.encodeComponent(bouts.first.groupName ?? '');
                                                                                  context.push('/viewer-team/$encodedGroupName');
                                                                                  },
                                                                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: BorderSide(color: mTitleColor.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                                                                  child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mTitleColor)),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          Container(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                            decoration: BoxDecoration(color: boutsInProgress ? Colors.blueGrey.shade600 : (boutsAllFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)), borderRadius: BorderRadius.circular(4)),
                                                                            child: Text(boutsInProgress ? '進行中' : (boutsAllFinished ? '終了' : '待機中'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: boutsInProgress ? Colors.white : (boutsAllFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)))),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(height: 10),
                                                                      Builder(builder: (context) {
                                                                        int redWins = 0; int redPts = 0;
                                                                        int whiteWins = 0; int whitePts = 0;
                                                                        for (var m in bouts) {
                                                                          final r = m.redScore; final w = m.whiteScore;
                                                                          redPts += (r as num).toInt(); whitePts += (w as num).toInt();
                                                                          if (m.status == 'finished' || m.status == 'approved') {
                                                                            if (r > w) {
                                                                              redWins++;
                                                                            } else if (w > r) {
                                                                              whiteWins++;
                                                                            }
                                                                          }
                                                                        }
                                                                        final isRedOwn = ownTeams.contains(t1);
                                                                        final isWhiteOwn = ownTeams.contains(t2);

                                                                        return Row(
                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                          children: [
                                                                            Expanded(child: Text(t1, style: TextStyle(fontSize: 14, fontWeight: isRedOwn ? FontWeight.w900 : FontWeight.bold, color: isRedOwn ? Colors.amber.shade600 : mTitleColor), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                                                              child: Row(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Text('$redWins', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.red.shade300 : Colors.red.shade700)),
                                                                                  Text('($redPts)', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                                                                    child: Text('ー', style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                                                                                  ),
                                                                                  Text('$whiteWins', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                                                                  Text('($whitePts)', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            Expanded(child: Text(t2, style: TextStyle(fontSize: 14, fontWeight: isWhiteOwn ? FontWeight.w900 : FontWeight.bold, color: isWhiteOwn ? Colors.amber.shade600 : mTitleColor), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis)),
                                                                          ],
                                                                        );
                                                                      }),
                                                                    ],
                                                                  ),
                                                                  // ★ 適合置換②: リーグ内各ポジションの試合タイル置換（Key付与）
                                                                  children: bouts.map((m) => ViewerMatchListTileCard(key: Key('viewer_match_card_${m.id}'), initialMatch: m)).toList(),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }));
                                                        }
                                                      } else {
                                                        // ★ 適合置換③: 通常のトーナメント団体戦内ポジション置換（Key付与）
                                                        childrenWidgets.addAll(normalMatches.map((m) => ViewerMatchListTileCard(key: Key('viewer_match_card_${m.id}'), initialMatch: m)).toList());
                                                      }

                                                      if (tieBreakMatches.isNotEmpty) {
                                                        childrenWidgets.add(const Divider());
                                                        childrenWidgets.add(const Padding(padding: EdgeInsets.all(8), child: Text('【順位決定戦】', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange))));
                                                        // ★ 適合置換④: 順位決定戦置換（Key付与）
                                                        childrenWidgets.addAll(tieBreakMatches.map((m) => ViewerMatchListTileCard(key: Key('viewer_match_card_${m.id}'), initialMatch: m)));
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
                                    padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(sanitizedQuery.isNotEmpty ? Icons.manage_search : Icons.person, color: Colors.orange.shade700, size: 16),
                                        const SizedBox(width: 4),
                                        Text(sanitizedQuery.isNotEmpty ? '抽出された個別試合' : '個人戦', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                                      ],
                                    ),
                                  ),
                                  ...sortedPlayers.map((playerEntry) {
                                    final playerName = playerEntry.key;
                                    final playerMatches = playerEntry.value;
                                    final firstMatch = playerMatches.first;
                                    final label = getMatchLabel(firstMatch); 

                                    final bool pInProgress = playerMatches.any((m) => m.status == 'in_progress');
                                    final bool pAllFinished = playerMatches.every((m) => m.status == 'finished' || m.status == 'approved');

                                    final Color pCardBg = pAllFinished 
                                        ? (isDark ? const Color(0xFF161618) : Colors.grey.shade100) 
                                        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
                                        
                                    final Color pTitleColor = pAllFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (isDark ? Colors.white : Colors.black87);
                                    final Color pSubTitleColor = pAllFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500) : (isDark ? Colors.grey.shade500 : Colors.grey.shade600);

                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        // ★ 修正: color: pCardBg, を削除
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 1),
                                        boxShadow: pInProgress ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: ExpansionTile(
                                            collapsedBackgroundColor: pCardBg, backgroundColor: pCardBg, // ★ 修正: 色をここで指定
                                            leading: CircleAvatar(
                                              backgroundColor: pAllFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : Colors.orange.shade100, 
                                              child: Text(playerName[0], style: TextStyle(color: pAllFinished ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600) : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold))
                                            ),
                                            title: Text(playerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: pTitleColor)),
                                            subtitle: Row(
                                              children: [
                                                Text('$label • ${playerMatches.length}試合', style: TextStyle(fontSize: 12, color: pSubTitleColor)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: pInProgress ? Colors.blueGrey.shade600 : (pAllFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    pInProgress ? '進行中' : (pAllFinished ? '終了' : '待機中'),
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pInProgress ? Colors.white : (pAllFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700))),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // ★ 適合置換⑤: 独立個人戦内ポジション置換
                                            children: playerMatches.map((match) => ViewerMatchListTileCard(initialMatch: match)).toList(),
                                          ),
                                      ),
                                    );
                                  }),
                                ],
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                    } catch (e, stack) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('レンダリングエラー発生: $e\n$stack', style: const TextStyle(color: Colors.red)),
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
          child: Text('致命的なUIエラー: $e\n$stack', style: const TextStyle(color: Colors.red)),
        ),
      );
    }
  } // buildメソッドの終わり

  Widget _buildTournamentInfoCard(BuildContext context, WidgetRef ref, dynamic tournament) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade700;
    final iconBgColor = isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50;
    final noteBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor, width: isDark ? 0.5 : 1.0)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(tournament.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                ),
                // 編集用PopupMenuButtonは削除
              ],
            ),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: borderColor)),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('yyyy年MM月dd日').format(tournament.date), style: TextStyle(color: subTextColor, fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.location_on, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(tournament.venue, style: TextStyle(color: subTextColor, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
            if (tournament.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: noteBgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(tournament.notes, style: TextStyle(color: textColor, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
} // ★ ViewerHomeScreen クラスを一旦ここで安全にクローズします

// ============================================================================
// 🛡️ 観客席専用要塞: ViewerMatchListTileCard (独立型ConsumerWidget)
// Undoリアクティブ即時同期反映の防壁、および全3行縦積み文字切れ完全防止レイアウト
// ============================================================================
class ViewerMatchListTileCard extends ConsumerWidget {
  final MatchModel initialMatch;

  const ViewerMatchListTileCard({
    super.key,
    required this.initialMatch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ 観客席スマホのElementキャッシュをぶち破り、本部が Undo 実行した瞬間に0ミリ秒即時リビルドを緊縛
    final matches = ref.watch(matchListProvider);
    final match = matches.where((m) => m.id == initialMatch.id).firstOrNull ?? initialMatch;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinished = match.status == 'finished' || match.status == 'approved';
    final isPlaying = match.status == 'in_progress';
    final bool isIndividual = !match.isKachinuki && (match.matchType == '個人戦' || match.matchType == '選手');

    String displayNote = match.note;
    if (!isIndividual && match.groupName != null && match.groupName!.isNotEmpty) {
      final regExp = RegExp(r'\[.*?\]');
      final tagMatches = regExp.allMatches(match.note);
      if (tagMatches.isNotEmpty) {
        displayNote = tagMatches.map((m) => m.group(0)).join(' ');
      } else {
        displayNote = '';
      }
    }

    final Color bg = isFinished ? (isDark ? const Color(0xFF161618) : Colors.grey.shade50) : (isDark ? const Color(0xFF1E1E20) : Colors.white);
    final Color textC = isFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (isDark ? Colors.white : Colors.black87);
    final Color noteC = isFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500) : Colors.grey.shade600;

    Widget buildMarkItem(dynamic p, Color textColor) {
      final String mark = p.mark == '✕' ? '×' : p.mark;
      final bool isFirstOverall = p.isFirst;

      if (mark == '◯' || mark == '×') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(mark, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        );
      }

      if (isFirstOverall) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: textColor, width: 1.2)),
          alignment: Alignment.center,
          child: Text(mark, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor, height: 1.1)),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(mark, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300, width: 1.2),
        boxShadow: isPlaying ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔼 【1行目】: 運営ステータス＆観客専用「スコア」ボタン集約ライン
            Row(
              children: [
                if (displayNote.isNotEmpty || match.matchType.isNotEmpty)
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (displayNote.isNotEmpty) TextSpan(text: displayNote),
                          if (displayNote.isNotEmpty && (match.matchType.isNotEmpty && match.matchType != '選手')) const TextSpan(text: ' '),
                          if (match.matchType.isNotEmpty && match.matchType != '選手') TextSpan(text: '【${match.matchType}】'),
                        ],
                      ),
                      style: TextStyle(fontSize: 11, color: noteC, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                const Spacer(),
                // 観客専用スコア詳細ボタン（権限先祖返りの完全防壁）
                if ((isIndividual || match.note.contains('[順位決定戦]') || match.matchType == '代表戦') && match.groupName != null && match.groupName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      height: 26,
                      child: OutlinedButton(
                        onPressed: () {
                          final encodedGroupName = Uri.encodeComponent(match.groupName ?? '');
                          context.push('/viewer-team/$encodedGroupName');
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: BorderSide(color: textC.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                        child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textC)),
                      ),
                    ),
                  ),
                // 状態バナー
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: isPlaying ? Colors.blueGrey.shade600 : (isFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)), borderRadius: BorderRadius.circular(4)),
                  child: Text(isPlaying ? '進行中' : (isFinished ? '終了' : '待機中'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPlaying ? Colors.white : (isFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 🔽 【2行目〜3行目】: 掲示板式リアルタイムスコア＆対戦ライン
            Builder(builder: (context) {
              final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
              
              String getTeamPart(String raw) => raw.contains(':') ? raw.split(':').first.trim() : '';
              String getNamePart(String raw) => raw.contains(':') ? raw.split(':').last.trim() : raw.trim();

              final rTeam = getTeamPart(match.redName);
              final rName = getNamePart(match.redName);
              final wTeam = getTeamPart(match.whiteName);
              final wName = getNamePart(match.whiteName);

              final ptsMap = MatchCalculatorHelper.extractPointsFromModel(match);
              final redPoints = ptsMap['red'] ?? [];
              final whitePoints = ptsMap['white'] ?? [];
              final bool hasValidPoints = redPoints.isNotEmpty || whitePoints.isNotEmpty;

              final isRedOwn = ownTeams.contains(rTeam) || match.redName.contains('自チーム');
              final isWhiteOwn = ownTeams.contains(wTeam) || match.whiteName.contains('自チーム');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏢 【2行目】: 左右チーム名独立表示ライン
                  Row(
                    children: [
                      Expanded(
                        child: Text(rTeam.isNotEmpty ? rTeam : '（個人エントリー）', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontWeight: FontWeight.w500), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Text(wTeam.isNotEmpty ? wTeam : '（個人エントリー）', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontWeight: FontWeight.w500), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 🥋 【3行目】: 選手名＆真実の中央時系列スコア
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(rName, style: TextStyle(fontSize: 14, fontWeight: isRedOwn ? FontWeight.w900 : FontWeight.bold, color: isRedOwn ? Colors.amber.shade600 : (isDark ? Colors.white : Colors.black87)), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis),
                      ),
                      if (!hasValidPoints)
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 12))
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: redPoints.map((p) => buildMarkItem(p, isDark ? Colors.red.shade300 : Colors.red.shade700)).toList()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(isFinished && match.redScore == match.whiteScore ? '×' : 'ー', style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                              ),
                              Row(mainAxisSize: MainAxisSize.min, children: whitePoints.map((p) => buildMarkItem(p, isDark ? Colors.white : Colors.black87)).toList()),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Text(wName, style: TextStyle(fontSize: 14, fontWeight: isWhiteOwn ? FontWeight.w900 : FontWeight.bold, color: isWhiteOwn ? Colors.amber.shade600 : (isDark ? Colors.white : Colors.black87)), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
        onTap: () => context.push('/viewer/${match.id}'),
      ),
    );
  }
}

class ViewerHomeScreenUtils { // 元から存在していたトップレベル関数群を包むダミー、またはそのまま配置
}

  Widget _buildCallRow(String label, dynamic match, Color textColor) {
    return Column(
      children: [
        if (match.note.isNotEmpty)
          Text(match.note, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _getMatchTitle(match), 
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
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
    final isIndividual = match.matchType == 'individual' || match.matchType == '選手' || match.matchType.contains('個人戦');
    
    if (isGrouped && !isIndividual) {
      final rTeam = match.redName.contains(':') ? match.redName.split(':').first.trim() : match.redName;
      final wTeam = match.whiteName.contains(':') ? match.whiteName.split(':').first.trim() : match.whiteName;
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

  void _showShareDialog(BuildContext context, String tournamentId) {
    // ★ 修正：完全に分離された viewer-home の URL を生成する
    final String shareUrl = 'https://kendo-os.web.app/viewer-home/$tournamentId';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('大会観戦リンク', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('この大会の全試合・スコアを\n観客用に安全に共有できます。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: QrImageView(
                  data: shareUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                // ★ Phase 9最適化: 名称から「AI/OS」を排し、現場に寄り添った文言へブラッシュアップ
                onPressed: () => SharePlus.instance.share(ShareParams(text: 
                  '【剣道リアルタイムViewer共有】このリンクから今日の試合結果・スコアをリアルタイムにその場で観戦・確認できます！\n'
                  'アプリ名: 剣道リアルタイムViewer共有＋スコア記録 (kendo_os)\n'
                  'リンク: $shareUrl'
                )),
                icon: const Icon(Icons.share),
                label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade700, foregroundColor: Colors.white, elevation: 0),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  String _generateDescriptiveLeagueTitle(List<MatchModel> matches, List<String> ownTeams) {
    final participantsSet = <String>{};
    for (var m in matches) {
      participantsSet.add(m.redName.split(':').first.trim());
      participantsSet.add(m.whiteName.split(':').first.trim());
    }
    final int n = participantsSet.length;
    final int mCount = n * (n - 1) ~/ 2;
    final bool isIndiv = matches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'));

    String selfInfo = "";
    if (isIndiv) {
      final myMatch = matches.firstWhere((m) => ownTeams.any((ot) => m.redName.contains(ot) || m.whiteName.contains(ot)), orElse: () => matches.first);
      final isRedOwn = ownTeams.any((ot) => myMatch.redName.contains(ot));
      final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
      final team = rawName.split(':').first.trim();
      final name = rawName.contains(':') ? rawName.split(':').last.replaceAll(')', '').trim() : rawName;
      selfInfo = "$name（$team）";
    } else {
      selfInfo = participantsSet.firstWhere((p) => ownTeams.contains(p), orElse: () => participantsSet.first);
    }

    final suffix = isIndiv ? "$n人リーグ" : "$nチームリーグ";
    return "$selfInfo : $suffix（全$mCount試合）";
  }

  // ==========================================
  // ★ Phase 4-1, 4-3, 4-6: スリム化された巨大メニューボタン (観客向け)
  // 高齢補助員向けの押しやすさを維持しつつ、パディングを減らし、サブタイトルを削除.
  // アイコンとフォントサイズを小さくして高さを抑え、画面領域を効率的に使います。
  // ==========================================
  Widget _buildHugeMenuButton(BuildContext context, bool enableLiquidGlass, IconData icon, String title, MaterialColor color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassButton(
      onPressed: onTap,
      color: color,
      icon: icon,
      label: title,
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: enableLiquidGlass ? (isDark ? color.shade500 : color.shade300) : Colors.white70),
    );
  }

// ★ 追加: home_screen.dart に定義されている tournamentProvider を拝借するための定義
final tournamentProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTournamentStream(id);
});

// ============================================================================
// ★ 観客用 表示設定ボトムシート (Liquid Glass & テーマ切り替え)
// ============================================================================
class ViewerSettingsBottomSheet extends ConsumerWidget {
  const ViewerSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '表示設定',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Icon(Icons.palette_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'テーマの切り替え',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.themeMode,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('📱 システム設定に従う')),
                      DropdownMenuItem(value: 'light', child: Text('☀️ ライトモード')),
                      DropdownMenuItem(value: 'dark', child: Text('🌙 ダークモード')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                        notifier.state = notifier.state.copyWith(themeMode: value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '・システム: お使いの端末の設定に自動で連動します。\n'
                '・ライト: 明るく見やすい標準的なデザインです。\n'
                '・ダーク: 暗い背景で目に優しく、バッテリー消費も抑えます。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Icon(Icons.auto_awesome),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'すりガラス効果',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Switch(
                    value: settings.enableLiquidGlass,
                    onChanged: (value) {
                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                      notifier.state = notifier.state.copyWith(enableLiquidGlass: value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '・背景の試合状況が美しく透けて見えるモダンなデザインになります。\n'
                '・動作が重く感じる場合や、古い端末をお使いの場合は「OFF」にするとパフォーマンスが向上します。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}