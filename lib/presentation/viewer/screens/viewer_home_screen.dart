import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kendo_os/infrastructure/repository/player_repository.dart';
import '../../shared/widgets/manual_help_button.dart'; // ★ ファイル上部に追加
import '../../operate/providers/match_list_provider.dart'; // ★ 追加
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/tournament_model.dart';
import 'package:kendo_os/infrastructure/repository/tournament_repository.dart';

final categorySortProvider = StateProvider.autoDispose<bool>((ref) => true);
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final isSearchVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);

final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});

class ViewerHomeScreen extends ConsumerWidget {
  final String tournamentId;
  const ViewerHomeScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color textColor = isDark ? Colors.white : Colors.black;

    // ★ デバッグ: フィルタリング前後の試合数を確認
    final allMatches = ref.watch(matchListProvider);
    debugPrint('🔍 [Viewer Debug] tournamentId param: "$tournamentId"');
    debugPrint('🔍 [Viewer Debug] Total matches from provider: ${allMatches.length}');
    for (int i = 0; i < allMatches.length && i < 5; i++) {
      final m = allMatches[i];
      debugPrint('  [$i] ID: ${m.id}, TID: "${m.tournamentId}", Match: ${m.redName} vs ${m.whiteName}');
    }

    // ★ 修正: Viewer用のProjectionの更新遅延をバイパスし、最新のFirestoreストリーム(MatchModel)を直接描画する
    final matches = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.tournamentId == tournamentId).toList()
    ));
    debugPrint('🔍 [Viewer Debug] Filtered matches (tournamentId=$tournamentId): ${matches.length}');
    
    matches.sort((a, b) => a.order.compareTo(b.order));

    try {
        final uniqueInProgress = <MatchModel>[];
        final uniqueWaiting = <MatchModel>[];
        final seenGroups = <String>{};

        for (var m in matches) {
          final isGrouped = m.groupName != null && m.groupName!.isNotEmpty;

          if (isGrouped) {
            if (seenGroups.contains(m.groupName)) continue; 
            seenGroups.add(m.groupName!);

            final groupMatches = matches.where((gm) => gm.groupName == m.groupName).toList();
            final allWaiting = groupMatches.every((gm) => gm.status == 'waiting');
            final allDone = groupMatches.every((gm) => gm.status == 'finished' || gm.status == 'approved');

            if (!allWaiting && !allDone) {
              uniqueInProgress.add(m);
            } else if (allWaiting) {
              uniqueWaiting.add(m);
            }
          } else {
            if (m.status == 'in_progress') {
              uniqueInProgress.add(m);
            } else if (m.status == 'waiting') {
              uniqueWaiting.add(m);
            }
          }
        }

        final sanitizedQuery = ref.watch(searchQueryProvider).replaceAll(RegExp(r'\s+'), '').toLowerCase();
        final matchedGroupNames = <String>{};
        final matchedMatchIds = <String>{};

        if (sanitizedQuery.isNotEmpty) {
          for (var m in matches) {
            String rTeam = m.redName.contains(':') ? m.redName.split(':').first : m.redName;
            String wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first : m.whiteName;
            String rPlayer = m.redName.contains(':') ? m.redName.split(':').last : m.redName;
            String wPlayer = m.whiteName.contains(':') ? m.whiteName.split(':').last : m.whiteName;

            bool teamHit = rTeam.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(sanitizedQuery) ||
                           wTeam.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(sanitizedQuery);
            
            bool playerHit = rPlayer.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(sanitizedQuery) ||
                             wPlayer.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(sanitizedQuery);

            if (teamHit) {
              if (m.groupName != null && m.groupName!.isNotEmpty) {
                matchedGroupNames.add(m.groupName!);
              } else {
                matchedMatchIds.add(m.id);
              }
            }
            if (playerHit) {
              matchedMatchIds.add(m.id);
            }
          }
        }

        final matchesByCategory = <String, List<MatchModel>>{};
        for (var m in matches) {
          if (sanitizedQuery.isNotEmpty) {
            final isMatchedGroup = m.groupName != null && matchedGroupNames.contains(m.groupName!);
            final isMatchedMatch = matchedMatchIds.contains(m.id);
            if (!isMatchedMatch && !isMatchedGroup) continue;
          }
          final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : 'カテゴリ未設定（全体）';
          matchesByCategory.putIfAbsent(cat, () => []).add(m);
        }

        return PopScope(
      canPop: false, // 戻るスワイプをブロック
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          // ★ 修正1: 標準の戻るボタン（<）は消す
          automaticallyImplyLeading: false, 
          
          // ★ 修正2: 「管理者アプリから直接遷移してきた（戻る履歴がある）場合」のみ扉ボタンを出す
          leading: context.canPop() 
              ? IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.deepOrange),
                  tooltip: '管理画面に戻る',
                  onPressed: () => context.pop(),
                )
              : null, // QRコードから直接来た一般客には何も表示しない（null）

          title: Text('大会ホーム (観客席)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            ManualHelpButton(manualPath: 'docs/manuals/faq/viewer_faq.md', color: isDark ? Colors.white : Colors.indigo.shade900),
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
                  _buildHugeMenuButton(context, Icons.print, '試合結果一覧 (PDF/CSV)', Colors.blueGrey, () => context.push('/official-record/$tournamentId')),
                  const SizedBox(height: 16),
                  
                  const SizedBox(height: 20),
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

                  if (matchesByCategory.isEmpty && sanitizedQuery.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('該当する試合が見つかりません', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  
                  ...(() {
                    if (matchesByCategory.isEmpty) return <Widget>[];
                    final sortedEntries = matchesByCategory.entries.toList();
                    final isAscending = ref.watch(categorySortProvider);
                    
                    int getWeight(String cat) {
                      if (cat.contains('初心者')) return 10;
                      if (cat.contains('幼年')) return 20;
                      if (cat.contains('小学生')) {
                        if (cat.contains('1年')) return 31;
                        if (cat.contains('2年')) return 32;
                        if (cat.contains('3年')) return 33;
                        if (cat.contains('4年')) return 34;
                        if (cat.contains('5年')) return 35;
                        if (cat.contains('6年')) return 36;
                        if (cat.contains('低学年')) return 38;
                        if (cat.contains('高学年')) return 39;
                        return 30;
                      }
                      if (cat.contains('中学生')) return 40;
                      if (cat.contains('高校生')) return 50;
                      if (cat.contains('大学') || cat.contains('一般') || cat.contains('シニア')) return 60;
                      return 999;
                    }

                    sortedEntries.sort((a, b) {
                      final weightA = getWeight(a.key);
                      final weightB = getWeight(b.key);
                      if (weightA != weightB) {
                        return isAscending ? weightA.compareTo(weightB) : weightB.compareTo(weightA);
                      }
                      return isAscending ? a.key.compareTo(b.key) : b.key.compareTo(a.key);
                    });

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
                              ..sort((a, b) => b.value.first.order.compareTo(a.value.first.order));
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
                                          // ignore: use_null_aware_elements
                                          if (headerWidget != null) headerWidget,
                                          GestureDetector(
                                            onLongPress: null,
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: cardBg,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 1),
                                                boxShadow: hasInProgress ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(11),
                                                child: ExpansionTile(
                                                    collapsedBackgroundColor: Colors.transparent,
                                                    backgroundColor: Colors.transparent,
                                                    title: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(children: [
                                                          if (firstMatch.note.isNotEmpty)
                                                            Flexible(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(
                                                                    right: 6, bottom: 4),
                                                                child: Text(firstMatch.note,
                                                                    style: TextStyle(
                                                                        fontSize: 11,
                                                                        color: subTitleColor,
                                                                        fontWeight: FontWeight.bold),
                                                                    overflow: TextOverflow.ellipsis,
                                                                    maxLines: 1),
                                                              ),
                                                            ),
                                                          const Spacer(),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: hasInProgress ? Colors.blueGrey.shade600 : (allFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)),
                                                                  borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: Text(
                                                                  hasInProgress ? '進行中' : (allFinished ? '終了' : '待機中'),
                                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasInProgress ? Colors.white : (allFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700))),
                                                                ),
                                                              ),
                                                        ]),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: label.contains('リーグ戦') 
                                                                ? Text(_generateDescriptiveLeagueTitle(groupList, ownTeams), style: TextStyle(fontWeight: FontWeight.bold, color: titleColor))
                                                                : Wrap(
                                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                                  children: [
                                                                    _buildTeamHighlight(rTeam, true, ownTeams.contains(rTeam) || rTeam.contains('自チーム'), isDark, titleColor, isFinished: allFinished),
                                                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('vs', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontWeight: FontWeight.bold))),
                                                                    _buildTeamHighlight(wTeam, false, ownTeams.contains(wTeam) || wTeam.contains('自チーム'), isDark, titleColor, isFinished: allFinished),
                                                                  ],
                                                                )
                                                            ),
                                                            
                                                            if (ownTeams.contains(rTeam) && ownTeams.contains(wTeam))
                                                              Container(
                                                                margin: const EdgeInsets.only(left: 8),
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(color: Colors.pink.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.pink.shade300)),
                                                                child: Text('⚔️ 同門', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pink.shade800)),
                                                              ),

                                                            // ★ Viewer専用のスコアボードへの遷移に変更
                                                            if (!label.contains('リーグ戦') && firstMatch.groupName != null && firstMatch.groupName!.isNotEmpty) ...[
                                                              const SizedBox(width: 8),
                                                              SizedBox(
                                                                height: 28,
                                                                child: OutlinedButton(
                                                                  onPressed: () {
                                                                    context.push(firstMatch.isKachinuki ? '/viewer-kachinuki/${firstMatch.groupName}' : '/viewer-team/${firstMatch.groupName}');
                                                                  },
                                                                  style: OutlinedButton.styleFrom(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                    side: BorderSide(color: titleColor.withValues(alpha: 0.3), width: 1),
                                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                                                                  ),
                                                                  child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: titleColor)),
                                                                ),
                                                              ),
                                                            ],
                                                            // 簡易入力ボタンは削除済み
                                                          ],
                                                        ),
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
                                                          // 【リーグ個人戦】中枠を省き、直接試合リストを表示
                                                          childrenWidgets.addAll(normalMatches.map((m) => _buildMatchListTile(context, ref, m)).toList());
                                                        } else {
                                                          // 【リーグ団体戦】中枠あり
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
                                                              ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) 
                                                              : (isDark ? Colors.white : Colors.black87);

                                                          return Container(
                                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: mCardBg,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 1),
                                                              boxShadow: boutsInProgress ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(7),
                                                              child: Theme(
                                                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                                                child: ExpansionTile(
                                                                  title: Wrap(
                                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                                    children: [
                                                                      _buildTeamHighlight(t1, true, ownTeams.contains(t1) || t1.contains('自チーム'), isDark, mTitleColor, isFinished: boutsAllFinished),
                                                                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('vs', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontWeight: FontWeight.bold))),
                                                                      _buildTeamHighlight(t2, false, ownTeams.contains(t2) || t2.contains('自チーム'), isDark, mTitleColor, isFinished: boutsAllFinished),
                                                                    ],
                                                                  ),
                                                                  subtitle: Padding(
                                                                    padding: const EdgeInsets.only(top: 4.0),
                                                                    child: Wrap(
                                                                      crossAxisAlignment: WrapCrossAlignment.center,
                                                                      spacing: 8,
                                                                      runSpacing: 4,
                                                                      children: [
                                                                        Text('${bouts.length}ポジション', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                          decoration: BoxDecoration(
                                                                            color: boutsInProgress ? Colors.blueGrey.shade600 : (boutsAllFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)),
                                                                            borderRadius: BorderRadius.circular(4),
                                                                          ),
                                                                          child: Text(
                                                                            boutsInProgress ? '進行中' : (boutsAllFinished ? '終了' : '待機中'),
                                                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: boutsInProgress ? Colors.white : (boutsAllFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700))),
                                                                          ),
                                                                        ),
                                                                        if (bouts.isNotEmpty && bouts.first.groupName != null && bouts.first.groupName!.isNotEmpty)
                                                                          SizedBox(
                                                                            height: 24,
                                                                            child: OutlinedButton(
                                                                              onPressed: () {
                                                                                context.push('/viewer-team/${bouts.first.groupName}');
                                                                              },
                                                                              style: OutlinedButton.styleFrom(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                                side: BorderSide(color: mTitleColor.withValues(alpha: 0.3), width: 1),
                                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                                                                              ),
                                                                              child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mTitleColor)),
                                                                            ),
                                                                          ),
                                                                        // 簡易入力ボタンは削除済み
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  children: bouts.map((m) => _buildMatchListTile(context, ref, m)).toList(),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }));
                                                        }
                                                      } else {
                                                        childrenWidgets.addAll(normalMatches.map((m) => _buildMatchListTile(context, ref, m)).toList());
                                                      }

                                                      if (tieBreakMatches.isNotEmpty) {
                                                        childrenWidgets.add(const Divider());
                                                        childrenWidgets.add(const Padding(padding: EdgeInsets.all(8), child: Text('【順位決定戦】', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange))));
                                                        childrenWidgets.addAll(tieBreakMatches.map((m) => _buildMatchListTile(context, ref, m)));
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
                                        color: pCardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 1),
                                        boxShadow: pInProgress ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: ExpansionTile(
                                            collapsedBackgroundColor: Colors.transparent, backgroundColor: Colors.transparent,
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
                                            children: playerMatches.map((match) => _buildMatchListTile(context, ref, match)).toList(),
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

  Widget _buildMatchListTile(BuildContext context, WidgetRef ref, MatchModel match) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinished = match.status == 'finished' || match.status == 'approved';
    final isPlaying = match.status == 'in_progress';

    final bool isIndividual = !match.isKachinuki && (match.matchType == '個人戦' || match.matchType == '選手');

    final Color bg = isFinished ? (isDark ? const Color(0xFF161618) : Colors.grey.shade50) : Colors.transparent;
    final Color textC = isFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (isDark ? Colors.white : Colors.black87);
    final Color noteC = isFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500) : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (match.note.isNotEmpty) TextSpan(text: match.note),
                        if (match.note.isNotEmpty && (match.matchType.isNotEmpty && match.matchType != '選手'))
                          const TextSpan(text: ' '),
                        if (match.matchType.isNotEmpty && match.matchType != '選手')
                          TextSpan(text: '【${match.matchType}】'),
                      ],
                    ),
                    style: TextStyle(fontSize: 11, color: noteC, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    maxLines: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPlaying ? Colors.blueGrey.shade600 : (isFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPlaying ? '進行中' : (isFinished ? '終了' : '待機中'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPlaying ? Colors.white : (isFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                    ),
                  ),
                ),
              ]
            ),
            const SizedBox(height: 6),
            Builder(builder: (context) {
              final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
              String rTeam = match.redName.contains(':') ? match.redName.split(':').first.trim() : match.redName;
              String wTeam = match.whiteName.contains(':') ? match.whiteName.split(':').first.trim() : match.whiteName;
              bool isRedOwn = ownTeams.contains(rTeam) || match.redName.contains('自チーム');
              bool isWhiteOwn = ownTeams.contains(wTeam) || match.whiteName.contains('自チーム');

              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6, runSpacing: 4,
                children: [
                  _buildTeamHighlight(match.redName, true, isRedOwn, isDark, textC, isFinished: isFinished),
                  Text('vs', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontWeight: FontWeight.bold)),
                  _buildTeamHighlight(_reverseWhiteName(match.whiteName), false, isWhiteOwn, isDark, textC, isFinished: isFinished),
                ],
              );
            }),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Viewerの個人戦・代表戦単発スコアボードへの遷移
            if ((isIndividual || match.note.contains('[順位決定戦]') || match.matchType == '代表戦') && match.groupName != null && match.groupName!.isNotEmpty)
              SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: () {
                     context.push('/viewer-team/${match.groupName}');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: BorderSide(color: textC.withValues(alpha: 0.3), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                  ),
                  child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textC)),
                ),
              ),
            // ゴミ箱アイコンは完全削除
          ],
        ),
        // ★ 遷移先を ViewerMatchScreen に向ける
        onTap: () => context.push('/viewer/${match.id}'),
        onLongPress: null, // ルール詳細はドメイン依存のため、ビューワーでは無効化
      ),
    );
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

  Widget _buildTeamHighlight(String name, bool isRed, bool isOwn, bool isDark, Color titleColor, {bool isFinished = false}) {
    Color tColor = isOwn ? Colors.amber.shade700 : titleColor;
    Color darkTColor = isOwn ? Colors.amber.shade400 : titleColor;

    if (isFinished) {
      tColor = isDark ? Colors.grey.shade600 : Colors.grey.shade500;
      darkTColor = tColor;
    }

    if (isOwn) {
      final boxColor = isFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade400) : (isRed ? Colors.red.shade600 : Colors.white);
      final borderColor = isFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500) : (isRed ? Colors.red.shade800 : Colors.grey.shade400);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color: boxColor,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(3),
              boxShadow: isFinished ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1))],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? darkTColor : tColor), overflow: TextOverflow.ellipsis)),
        ],
      );
    }
    return Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: titleColor));
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
                onPressed: () => SharePlus.instance.share(ShareParams(text: '【剣道OS】大会の進行状況をリアルタイムで観戦できます！\n$shareUrl')),
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
  Widget _buildHugeMenuButton(BuildContext context, IconData icon, String title, MaterialColor color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        // パディングをsymmetricに減らす (20 -> horizontal: 16, vertical: 12)
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? color.shade900.withValues(alpha: 0.3) : color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? color.shade700 : color.shade200, width: 2),
        ),
        child: Row(
          children: [
            // アイコンサイズを小さくする (36 -> 24)
            Icon(icon, size: 24, color: isDark ? color.shade300 : color.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトルのフォントサイズを小さくする (18 -> 16)
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  // ★ サブタイトル(subtitle)を削除
                ],
              ),
            ),
            // 右側の矢印も小さくする (16 -> 14)
            Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? color.shade500 : color.shade300),
          ],
        ),
      ),
    );
  }
}

// ★ 追加: home_screen.dart に定義されている tournamentProvider を拝借するための定義
final tournamentProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTournamentStream(id);
});