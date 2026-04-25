import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart'; // ★ 追加: 触覚フィードバック(ブルッとする振動)用
import '../models/match_model.dart';
import '../providers/match_list_provider.dart';
import '../providers/match_command_provider.dart';
import 'standings_screen.dart';
import 'official_record_screen.dart';
import 'team_scoreboard_screen.dart'; 
import '../models/tournament_model.dart';
import '../repositories/tournament_repository.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/player_repository.dart';
import '../providers/permission_provider.dart';
import '../domain/kendo_rule_engine.dart';
import '../providers/match_rule_provider.dart';

final tournamentProvider = StreamProvider.family<TournamentModel?, String>((ref, id) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTournamentStream(id);
});

final categorySortProvider = StateProvider.autoDispose<bool>((ref) => true);

final customTeamNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref.watch(playerRepositoryProvider).watchCustomTeamNames();
});

class HomeScreen extends ConsumerWidget {
  final String tournamentId;
  const HomeScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permissions = ref.watch(permissionProvider);
    final Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final Color textColor = isDark ? Colors.white : Colors.black;

    final matches = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.tournamentId == tournamentId).toList()
    ));

    matches.sort((a, b) => a.order.compareTo(b.order));

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

    final matchesByCategory = <String, List<MatchModel>>{};
    for (var m in matches) {
      final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : 'カテゴリ未設定（全体）';
      matchesByCategory.putIfAbsent(cat, () => []).add(m);
    }

    return PopScope(
      canPop: !permissions.isReadOnly,
      child: Scaffold(
        backgroundColor: bgColor, 
        appBar: AppBar(
          automaticallyImplyLeading: !permissions.isReadOnly, 
          title: Text('大会ホーム', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
          backgroundColor: Colors.transparent, 
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          actions: [
            if (!permissions.isReadOnly)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/'), 
                  icon: Icon(Icons.home, color: isDark ? Colors.white : Colors.indigo.shade700, size: 18),
                  label: Text('トップへ', style: TextStyle(color: isDark ? Colors.white : Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.indigo.shade50, 
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
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
                  color: Colors.indigo.shade800,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    if (uniqueInProgress.isNotEmpty)
                      _buildCallRow('進行中', uniqueInProgress.first, Colors.orangeAccent),
                    if (uniqueInProgress.isNotEmpty && uniqueWaiting.isNotEmpty) 
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white24, height: 1)),
                    if (uniqueWaiting.isNotEmpty)
                      _buildCallRow('次試合', uniqueWaiting.first, Colors.white),
                    if (uniqueWaiting.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '次々試合: ${uniqueWaiting[1].note.isNotEmpty ? "(${uniqueWaiting[1].note}) " : ""}${_getMatchTitle(uniqueWaiting[1])}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Column(
                children: [
                  if (permissions.canCreateMatch) ...[
                    Container(
                      width: double.infinity,
                      height: 60, 
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade600, 
                        borderRadius: BorderRadius.circular(16), 
                        boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))], 
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/setup-match/$tournamentId'),
                        icon: const Icon(Icons.add_circle, color: Colors.white, size: 24),
                        label: const Text('この大会に試合を追加する', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  Container(
                    width: double.infinity,
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/tournament/$tournamentId/programs'),
                      icon: Icon(
                        Icons.picture_as_pdf, 
                        size: 20, 
                        color: isDark ? Colors.redAccent.shade100 : Colors.red.shade600
                      ),
                      label: Text(
                        permissions.isReadOnly ? '大会プログラムを見る' : '大会プログラムの管理', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.grey.shade800)
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
                        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!permissions.isReadOnly) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StandingsScreen(tournamentId: tournamentId))),
                            icon: Icon(Icons.emoji_events, size: 18, color: Colors.amber.shade600),
                            label: Text('自チーム成績', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.grey.shade800)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
                              backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OfficialRecordScreen(tournamentId: tournamentId))),
                          icon: Icon(Icons.print, size: 18, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600),
                          label: Text(
                            permissions.isReadOnly ? '全試合スコア' : '出力用スコア', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.grey.shade800)
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
                            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
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
                  
                  if (matchesByCategory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('試合リスト', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                          OutlinedButton.icon(
                            onPressed: () => ref.read(categorySortProvider.notifier).state = !ref.read(categorySortProvider),
                            icon: Icon(ref.watch(categorySortProvider) ? Icons.arrow_downward : Icons.arrow_upward, size: 16),
                            label: Text(ref.watch(categorySortProvider) ? 'カテゴリ昇順' : 'カテゴリ降順', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700,
                              side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.indigo.shade200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  ...(() {
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

                    return sortedEntries.map((catEntry) {
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
                          if (isRedOwn) matchesByTeam.putIfAbsent(rTeam, () => []).add(m);
                          if (isWhiteOwn && wTeam != rTeam) matchesByTeam.putIfAbsent(wTeam, () => []).add(m);
                          
                          if (!isRedOwn && !isWhiteOwn && rTeam.isNotEmpty && !rTeam.contains('代表')) {
                             matchesByTeam.putIfAbsent(rTeam, () => []).add(m);
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
                            child: Text(categoryName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade800, letterSpacing: 1.2)),
                          ),
                          
                          ...sortedTeams.map((teamEntry) {
                            final teamName = teamEntry.key;
                            final teamMatchesList = teamEntry.value;

                            String getMatchLabel(MatchModel m) {
                              final bool isLeague = m.note.contains('[リーグ戦]'); 
                              final bool isKachinuki = m.isKachinuki;
                              // ★ 修正：勝ち抜き戦の場合は、絶対に個人戦扱いしないように厳格化
                              final bool isIndividual = !isKachinuki && (m.matchType == 'individual' || m.matchType == '選手');

                              if (isLeague) return isIndividual ? '個人戦/リーグ戦' : '団体戦/リーグ戦';
                              if (isKachinuki) return '団体戦/勝ち抜き戦';
                              return isIndividual ? '個人戦' : '団体戦';
                            }

                            final catGroupedMatches = <String, List<MatchModel>>{};
                            final catIndividualMatches = <MatchModel>[];

                            for (var m in teamMatchesList) {
                              if (m.groupName != null && m.groupName!.isNotEmpty) {
                                catGroupedMatches.putIfAbsent(m.groupName!, () => []).add(m);
                              } else {
                                catIndividualMatches.add(m);
                              }
                            }

                            final actualGroupedMatches = <String, List<MatchModel>>{};
                            for (var entry in catGroupedMatches.entries) {
                              // ★ 修正：勝ち抜き戦は、試合データが1つだけでも「団体戦のグループ」として独立させる！
                              if (entry.value.length > 1 || entry.value.first.isKachinuki) {
                                actualGroupedMatches[entry.key] = entry.value;
                              } else {
                                catIndividualMatches.addAll(entry.value);
                              }
                            }

                            final matchesByPlayer = <String, List<MatchModel>>{};
                            for (var m in catIndividualMatches) {
                              String playerName = '選手名不明';
                              if (m.redName.contains(teamName)) {
                                playerName = m.redName.contains(':') ? m.redName.split(':').last.trim() : m.redName;
                              } else if (m.whiteName.contains(teamName)) {
                                playerName = m.whiteName.contains(':') ? m.whiteName.split(':').last.trim() : m.whiteName;
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
                                      color: isDark ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade50,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                      border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.indigo.shade100)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.business, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(teamName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.indigo.shade900))),
                                        
                                        if (!permissions.isReadOnly)
                                          IconButton(
                                            icon: Icon(Icons.edit_note, color: isDark ? Colors.indigo.shade400 : Colors.indigo.shade300, size: 20),
                                            tooltip: 'チーム名を修正して統合',
                                            onPressed: () => _showRenameTeamSheet(context, ref, tournamentId, teamName),
                                          ),
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
                                              Icon(Icons.groups, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700, size: 16),
                                              const SizedBox(width: 4),
                                              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700)),
                                            ],
                                          ),
                                        );
                                        lastGroupLabel = label;
                                      }
                                      
                                      final rTeam = firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName;
                                      final wTeam = firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName;
                                      
                                      final hasInProgress = groupList.any((m) => m.status == 'in_progress');
                                      final allFinished = groupList.every((m) => m.status == 'finished' || m.status == 'approved');
                                      
                                      // ★ 修正：大枠（リーグ・団体）の背景は常に「白かグレー」に固定。青色は個別アイテムにのみ適用！
                                      final Color cardBg = allFinished 
                                          ? (isDark ? const Color(0xFF161618) : Colors.grey.shade100) 
                                          : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

                                      final Color cardAccent = hasInProgress ? (isDark ? Colors.blue.shade400 : Colors.blue.shade600) : Colors.transparent;

                                      final Color titleColor = allFinished
                                          ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                                          : (hasInProgress ? (isDark ? Colors.blue.shade200 : Colors.blue.shade900) : textColor);

                                      final Color subTitleColor = allFinished
                                          ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500)
                                          : (hasInProgress ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700) : (isDark ? Colors.grey.shade500 : Colors.grey.shade600));

                                      final String statusText = hasInProgress ? '進行中' : (allFinished ? '終了' : '待機中');

                                      final pairingsSet = <String>{};
                                      for (var m in groupList) { final t1 = m.redName.split(':').first.trim(); final t2 = m.whiteName.split(':').first.trim(); final pairKey = [t1, t2]..sort(); pairingsSet.add(pairKey.join(' vs ')); }
                                      final int displayMatchCount = pairingsSet.length;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ?headerWidget,
                                          // ★ 追加：団体戦のヘッダー全体を長押しでルール表示可能に
                                          GestureDetector(
                                            onLongPress: () => _showRuleInfoSheet(context, firstMatch),
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
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border(left: BorderSide(color: cardAccent, width: 5)),
                                                  ),
                                                  child: ExpansionTile(
                                                    collapsedBackgroundColor: Colors.transparent,
                                                    backgroundColor: Colors.transparent,
                                                    title: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            if (firstMatch.note.isNotEmpty)
                                                              Padding(
                                                                padding: const EdgeInsets.only(right: 6, bottom: 4),
                                                                child: Text(firstMatch.note, style: TextStyle(fontSize: 11, color: subTitleColor, fontWeight: FontWeight.bold)),
                                                              ),
                                                            const Spacer(),
                                                            Text(statusText, style: TextStyle(fontSize: 11, color: subTitleColor, fontWeight: FontWeight.bold)),
                                                          ]
                                                        ),
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
                                                          
                                                          // ★ 追加：団体戦の時のみ、ヘッダーにiアイコンを表示し、タップでルール確認可能に
                                                          if (!allFinished)
                                                            Padding(
                                                              padding: const EdgeInsets.only(left: 8),
                                                              child: InkWell(
                                                                onTap: () => _showRuleInfoSheet(context, firstMatch),
                                                                borderRadius: BorderRadius.circular(12),
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(4.0),
                                                                  child: Icon(Icons.info_outline, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 16),
                                                                ),
                                                              ),
                                                            ),
                                                          
                                                          if (ownTeams.contains(rTeam) && ownTeams.contains(wTeam))
                                                            Container(
                                                              margin: const EdgeInsets.only(left: 8),
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(color: Colors.pink.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.pink.shade300)),
                                                              child: Text('⚔️ 同門', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pink.shade800)),
                                                            ),

                                                          // 通常団体戦のスコアボタン
                                                          if (!label.contains('リーグ戦')) ...[
                                                            const SizedBox(width: 8),
                                                            SizedBox(
                                                              height: 28,
                                                              child: OutlinedButton(
                                                                onPressed: () {
                                                                  Navigator.push(context, MaterialPageRoute(
                                                                    builder: (context) => TeamScoreboardScreen(groupName: firstMatch.groupName, matches: groupList),
                                                                  ));
                                                                },
                                                                style: OutlinedButton.styleFrom(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                  side: BorderSide(color: titleColor.withValues(alpha: 0.3), width: 1),
                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                                                                ),
                                                                child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: titleColor)),
                                                              ),
                                                            ),
                                                          ]
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: Text('$displayMatchCount対戦 • $statusText', style: TextStyle(color: subTitleColor, fontSize: 12)),
                                                  children: (() {
                                                    final List<Widget> childrenWidgets = [];
                                                    
                                                    // 1. 試合リストを「通常」と「決定戦」に分離
                                                    final normalMatches = groupList.where((m) => !m.note.contains('[順位決定戦]')).toList();
                                                    final tieBreakMatches = groupList.where((m) => m.note.contains('[順位決定戦]')).toList();

                                                    // 2. リーグが終了しており、かつ決定戦が未作成の場合のみボタンを表示
                                                    if (label.contains('リーグ戦') && allFinished && !label.contains('個人戦') && tieBreakMatches.isEmpty) {
                                                      final rule = firstMatch.rule ?? ref.read(matchRuleProvider);
                                                      final stats = KendoRuleEngine.calculateLeagueStandings(normalMatches, rule!);
                                                      
                                                      final tieGroups = <List<dynamic>>[];
                                                      if (stats.length > 1) {
                                                        List<dynamic> currentTie = [stats.first];
                                                        for (int i = 1; i < stats.length; i++) {
                                                          final prev = stats[i - 1];
                                                          final curr = stats[i];
                                                          bool isTie = (prev.customPoints - curr.customPoints).abs() < 0.001 && 
                                                                       prev.matchWins == curr.matchWins && 
                                                                       prev.individualWinners == curr.individualWinners && 
                                                                       prev.totalPointsScored == curr.totalPointsScored;
                                                          if (isTie) {
                                                            currentTie.add(curr);
                                                          } else {
                                                            if (currentTie.length > 1) tieGroups.add(List.from(currentTie));
                                                            currentTie = [curr];
                                                          }
                                                        }
                                                        if (currentTie.length > 1) tieGroups.add(currentTie);
                                                      }

                                                      if (tieGroups.isNotEmpty) {
                                                        childrenWidgets.add(
                                                          Container(
                                                            margin: const EdgeInsets.all(12),
                                                            padding: const EdgeInsets.all(12),
                                                            decoration: BoxDecoration(
                                                              color: isDark ? Colors.orange.shade900.withValues(alpha: 0.2) : Colors.orange.shade50,
                                                              border: Border.all(color: Colors.orange.shade300),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Column(
                                                              children: tieGroups.map((group) {
                                                                return ElevatedButton.icon(
                                                                  onPressed: () => _showTieBreakDialog(context, ref, firstMatch, group, rule),
                                                                  icon: const Icon(Icons.add_circle),
                                                                  label: const Text('順位決定戦を作成'),
                                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                                                                );
                                                              }).toList(),
                                                            ),
                                                          )
                                                        );
                                                      }
                                                    }

                                                    // 3. 通常試合のグルーピング表示（ここでアコーディオンを復活させる）
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
                                                      return Theme(
                                                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                                        child: ExpansionTile(
                                                          title: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                                                          subtitle: Text('${bouts.length}ポジション', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                          children: bouts.map((m) => _buildMatchListTile(context, ref, m)).toList(),
                                                        ),
                                                      );
                                                    }));

                                                    // 4. 順位決定戦があれば一番下に表示
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
                                          ),
                                        ],
                                      );
                                    });
                                  })(),

                                // --- 👤 個人戦セクション ---
                                if (sortedPlayers.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.person, color: Colors.orange.shade700, size: 16),
                                        const SizedBox(width: 4),
                                        Text('個人戦', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
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
                                    final String pStatusText = pInProgress ? '進行中' : (pAllFinished ? '終了' : '待機中');

                                    // ★ 修正：個人戦の大枠も、透けないように完全に背景を固定
                                    final Color pCardBg = pAllFinished 
                                        ? (isDark ? const Color(0xFF161618) : Colors.grey.shade100) 
                                        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
                                        
                                    final Color pCardAccent = pInProgress ? (isDark ? Colors.blue.shade400 : Colors.blue.shade600) : Colors.transparent;
                                    final Color pTitleColor = pAllFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (pInProgress ? (isDark ? Colors.blue.shade200 : Colors.blue.shade900) : textColor);
                                    final Color pSubTitleColor = pAllFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500) : (pInProgress ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700) : (isDark ? Colors.grey.shade500 : Colors.grey.shade600));

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
                                        child: Container(
                                          decoration: BoxDecoration(border: Border(left: BorderSide(color: pCardAccent, width: 5))),
                                          child: ExpansionTile(
                                            collapsedBackgroundColor: Colors.transparent, backgroundColor: Colors.transparent,
                                            leading: CircleAvatar(
                                              backgroundColor: pAllFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : Colors.orange.shade100, 
                                              child: Text(playerName[0], style: TextStyle(color: pAllFinished ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600) : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold))
                                            ),
                                            title: Text(playerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: pTitleColor)),
                                            subtitle: Text('$label • ${playerMatches.length}試合 • $pStatusText', style: TextStyle(fontSize: 12, color: pSubTitleColor)),
                                            children: playerMatches.map((match) => _buildMatchListTile(context, ref, match)).toList(),
                                          ),
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
                  });
                })(), 
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildTournamentInfoCard(BuildContext context, WidgetRef ref, TournamentModel tournament) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade700;
    final iconBgColor = isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50;
    final popupIconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
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
                if (ref.watch(permissionProvider).canManageTournament)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: popupIconColor),
                    color: cardColor,
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final nameController = TextEditingController(text: tournament.name);
                        final venueController = TextEditingController(text: tournament.venue);
                        final notesController = TextEditingController(text: tournament.notes);
                        DateTime selectedDate = tournament.date;

                        showDialog(
                          context: context,
                          builder: (ctx) => StatefulBuilder( 
                            builder: (context, setState) {
                              return AlertDialog(
                                backgroundColor: cardColor,
                                title: Text('大会情報の編集', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: SingleChildScrollView( 
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(controller: nameController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: '大会名', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)))),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () async {
                                          final DateTime? picked = await showDatePicker(
                                            context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030),
                                          );
                                          if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
                                        },
                                        child: InputDecorator(
                                          decoration: InputDecoration(labelText: '開催年月日', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor))),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(DateFormat('yyyy年MM月dd日').format(selectedDate), style: TextStyle(color: textColor)),
                                              Icon(Icons.calendar_today, size: 20, color: isDark ? Colors.indigo.shade400 : Colors.indigo.shade600),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(controller: venueController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: '会場・住所', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)))),
                                      const SizedBox(height: 12),
                                      TextField(controller: notesController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: '大会メモ（任意）', labelStyle: TextStyle(color: subTextColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor))), maxLines: 3),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white, elevation: 0),
                                    onPressed: () async {
                                      await ref.read(tournamentRepositoryProvider).updateTournamentDetails(
                                        tournament.id, name: nameController.text, venue: venueController.text, notes: notesController.text, date: selectedDate,
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    },
                                    child: const Text('保存'),
                                  ),
                                ],
                              );
                            }
                          ),
                        );
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: cardColor,
                            title: Text('大会の削除', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                            content: Text('この大会を削除しますか？', style: TextStyle(color: textColor)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(tournamentRepositoryProvider).deleteTournament(tournament.id);
                          if (context.mounted) context.go('/');
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: textColor), const SizedBox(width: 8), Text('編集', style: TextStyle(color: textColor))])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('削除', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
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

    // ★ 修正：勝ち抜き戦の場合は、matchTypeが「選手」でも絶対に個人戦扱いしない
    final bool isIndividual = !match.isKachinuki && (match.matchType == '個人戦' || match.matchType == '選手');
    // ★ 修正：1試合ずつの色も、待機中は完全に白（またはダークモードの黒）に固定
    final Color bg = isPlaying 
        ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.15) : Colors.blue.shade50) 
        : (isFinished ? (isDark ? const Color(0xFF161618) : Colors.grey.shade100) : (isDark ? const Color(0xFF1C1C1E) : Colors.white));
        
    final Color accent = isPlaying ? (isDark ? Colors.blue.shade400 : Colors.blue.shade600) : Colors.transparent;
    final Color textC = isFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (isPlaying ? (isDark ? Colors.blue.shade200 : Colors.blue.shade900) : (isDark ? Colors.white : Colors.black87));
    final Color noteC = isFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500) : (isPlaying ? (isDark ? Colors.blue.shade300 : Colors.blue.shade600) : Colors.grey);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: accent, width: 4),
          bottom: BorderSide(color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (match.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(match.note, style: TextStyle(fontSize: 10, color: noteC, fontWeight: FontWeight.bold)),
                  ),
                if (match.matchType.isNotEmpty && match.matchType != '選手')
                  Text('【${match.matchType}】', style: TextStyle(fontSize: 10, color: noteC, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(isPlaying ? '進行中' : (isFinished ? '終了' : '待機中'), style: TextStyle(fontSize: 10, color: noteC, fontWeight: FontWeight.bold)),
              ]
            ),
            const SizedBox(height: 4),
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
                  Text('vs', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontWeight: FontWeight.bold)),
                  _buildTeamHighlight(_reverseWhiteName(match.whiteName), false, isWhiteOwn, isDark, textC, isFinished: isFinished),
                ],
              );
            }),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ★ 修正：個人戦（独立した試合）の場合のみアイコンを表示。団体戦の子要素（先鋒など）では非表示。
            if (!isPlaying && !isFinished && isIndividual)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _showRuleInfoSheet(context, match),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.info_outline, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 18),
                  ),
                ),
              ),

            SizedBox(
              height: 28,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => TeamScoreboardScreen(matches: [match]), 
                  ));
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: BorderSide(color: textC.withValues(alpha: 0.3), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                ),
                child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textC)),
              ),
            ),
            if (!ref.watch(permissionProvider).isReadOnly)
              IconButton(
                icon: Icon(Icons.delete_outline, color: isFinished ? Colors.grey.withValues(alpha: 0.5) : Colors.grey, size: 20),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      title: Text('試合の削除', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      content: Text('削除しますか？', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                  if (confirm == true) await ref.read(matchCommandProvider).deleteMatch(match.id);
                },
              ),
          ],
        ),
        onTap: () => context.push('/match/${match.id}'),
        onLongPress: isIndividual ? () => _showRuleInfoSheet(context, match) : null, // ★ 修正：個人戦のみ長押し有効
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
    final String shareUrl = 'https://kendo-os.web.app/home/$tournamentId?role=viewer';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('大会観戦リンク', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('この大会の全試合・スコアを\nリアルタイムで共有できます。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
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
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: '【剣道OS】大会の進行状況をリアルタイムで観戦できます！\n$shareUrl'),
                ),
                icon: const Icon(Icons.share),
                label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 0),
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

  void _showRenameTeamSheet(BuildContext context, WidgetRef ref, String tournamentId, String oldName) {
    final controller = TextEditingController(text: oldName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.indigo.shade300 : Colors.indigo.shade700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(top: 16, left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text('チーム名の修正・統合', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('名前を修正すると、この大会内のすべての試合データが自動で書き換わり、同じ名前のチームと合流します。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '新しいチーム名',
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty || newName == oldName) {
                    Navigator.pop(ctx);
                    return;
                  }
                  
                  await ref.read(matchCommandProvider).renameTeamBulk(
                    tournamentId: tournamentId,
                    oldTeamName: oldName,
                    newTeamName: newName,
                  );
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('チーム名を一括更新しました ✨')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('一括修正して統合する', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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

  // ★ 修正：すべてのレギュレーション情報を網羅した完璧なシート
  void _showRuleInfoSheet(BuildContext context, MatchModel match) {
    HapticFeedback.mediumImpact(); 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 1. その試合が持っている「封印されたルール」を最優先で見る
    final rule = match.rule; 
    debugPrint('👀 [3. 読込センサー] 表示時のRuleがnullか?: ${rule == null}'); // ★ デバッグ用センサー

    // ★ 修正：備考欄の文字からも形式を推測する（古いデータ救済用）
    final bool isLegacyLeague = match.note.contains('[リーグ戦]');
    final bool isLeague = (rule?.isLeague ?? false) || isLegacyLeague;

    // 2. 形式の判定（勝ち抜き戦は個人戦判定から除外）
    final bool isIndividual = !match.isKachinuki && (match.matchType == 'individual' || match.matchType == '選手' || match.matchType.contains('個人戦') || (rule != null && rule.positions.length == 1 && (rule.positions.first == '選手' || rule.positions.first == '個人戦')));
    
    String formatText = isIndividual ? '個人戦' : '団体戦';
    if (rule?.isRenseikai ?? false) {
      formatText = '錬成会';
    } else if (match.isKachinuki || (rule?.isKachinuki ?? false)) {
      formatText = '勝ち抜き戦';
    } else if (isLeague) {
      formatText = 'リーグ戦（総当たり）';
    }

    // 3. 各種ルールの取得
    
    // 試合時間
    final double matchTime = rule?.matchTimeMinutes ?? match.matchTimeMinutes.toDouble();
    final isRunningTime = rule?.isRunningTime ?? match.isRunningTime;
    
    // ★ 修正：1.5 を「1分30秒」に綺麗にフォーマットする
    String timeStr = matchTime == matchTime.toInt() ? '${matchTime.toInt()}分' : '${matchTime.toInt()}分${((matchTime % 1) * 60).toInt()}秒';
    final String timeDesc = '$timeStr (${isRunningTime ? "通し/空回し" : "都度ストップ"})';

    // 延長
    final bool enchoUnlimited = rule?.isEnchoUnlimited ?? false;
    final double enchoMins = rule?.enchoTimeMinutes ?? match.extensionTimeMinutes?.toDouble() ?? 0.0;
    final int enchoCount = rule?.enchoCount ?? match.extensionCount ?? 1;
    final bool enchoEnabled = match.hasExtension || enchoUnlimited || enchoMins > 0;
    
    String enchoDesc = 'なし';
    if (enchoEnabled) {
      if (enchoUnlimited) {
        enchoDesc = 'あり (無制限)';
      } else {
        // ★ 修正：「1.5分・2回」を「1分30秒・2回」として表示する
        String extTimeStr = enchoMins == enchoMins.toInt() ? '${enchoMins.toInt()}分' : '${enchoMins.toInt()}分${((enchoMins % 1) * 60).toInt()}秒';
        enchoDesc = 'あり ($extTimeStr・$enchoCount回)';
      }
    }
    
    final bool hanteiEnabled = rule?.hasHantei ?? match.hasHantei;

    String daihyoDesc = 'なし';
    if (rule != null) {
      final bool hasRep = rule.hasRepresentativeMatch;
      final bool isIppon = rule.isDaihyoIpponShobu;
      daihyoDesc = hasRep ? (isIppon ? 'あり (一本勝負)' : 'あり (三本勝負)') : 'なし';
    } else {
      daihyoDesc = '不明（古いデータ）';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.gavel_rounded, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700, size: 22),
                const SizedBox(width: 8),
                Text('試合レギュレーション', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const Divider(height: 32),
            
            if (rule == null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade300)),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('この試合はアップデート前に作成されたため、詳細なルールが保存されていません。新しく作成した試合では正しく表示されます。', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

            _buildRuleRow('試合形式', formatText, isDark),
            _buildRuleRow('試合時間', timeDesc, isDark),

            if (rule?.isRenseikai ?? false) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('錬成会設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))),
              _buildRuleRow('進行方式', rule!.renseikaiType, isDark),
              if (rule.renseikaiType == '時間制') _buildRuleRow('制限時間', '${rule.overallTimeMinutes} 分', isDark),
            ] else ...[
              _buildRuleRow('延長戦', enchoDesc, isDark),
              _buildRuleRow('判定', hanteiEnabled ? 'あり' : 'なし', isDark),
            ],

            if (match.isKachinuki || (rule?.isKachinuki ?? false)) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('勝ち抜き戦設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))),
              _buildRuleRow('無制限条件', rule?.kachinukiUnlimitedType ?? '大将対大将', isDark),
              // ★ 修正：ポジション表示を勝ち抜き戦の枠組みの中に統合する
              if (rule != null && rule.positions.isNotEmpty) _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],

            // ★ 修正：予備判定(isLeague)を使って、古いデータでも確実に隠す
            if (!isIndividual && !(rule?.isRenseikai ?? false) && !match.isKachinuki && !(rule?.isKachinuki ?? false) && !isLeague) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('団体戦・チーム設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))),
              _buildRuleRow('代表戦', daihyoDesc, isDark),
              if (rule != null && rule.positions.isNotEmpty) _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],

            if (!isIndividual && (rule?.isRenseikai ?? false) && rule != null && rule.positions.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('ポジション設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal))),
              _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],

            if (rule != null && rule.isLeague) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('リーグ戦設定', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange))),
              // ★ 修正：リーグ戦のポジション表示を、リーグ戦専用枠の中に美しく統合する
              if (!isIndividual && rule.positions.isNotEmpty) _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
              _buildRuleRow('勝ち点設定', '勝: ${rule.winPoint} / 分: ${rule.drawPoint} / 負: ${rule.lossPoint}', isDark),
              _buildRuleRow('同点時代表戦', rule.hasLeagueDaihyo ? 'あり' : 'なし', isDark),
            ],

            if (match.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildRuleRow('備考・メモ', match.note, isDark),
            ],
              
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8), 
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }

  // ★ フェーズ3 最終調整：2ステップのシンプルで安全なダイアログ
  void _showTieBreakDialog(BuildContext parentContext, WidgetRef ref, MatchModel firstMatch, List<dynamic> tieTeams, dynamic baseRule) {
    String? selectedMode; // null = 未選択, 'daihyo' = 代表戦, 'rematch' = チーム再試合

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          if (selectedMode == null) {
            // 【ステップ1】形式の選択
            return AlertDialog(
              title: const Text('決定戦の形式を選択', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('同順位を解消するための形式を選んでください：', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  _buildTieOption(ctx, Icons.person, '代表戦（1名）', '1本勝負で順位を決定します', () {
                    if (tieTeams.length <= 2) {
                      Navigator.pop(ctx);
                      _createTieBreakMatch(parentContext, ref, firstMatch, tieTeams, baseRule, isAll: false, mode: 'daihyo');
                    } else {
                      setState(() => selectedMode = 'daihyo'); // 3チーム以上ならステップ2へ
                    }
                  }),
                  _buildTieOption(ctx, Icons.groups, 'チーム再試合', '全ポジションで再度対戦します', () {
                    if (tieTeams.length <= 2) {
                      Navigator.pop(ctx);
                      _createTieBreakMatch(parentContext, ref, firstMatch, tieTeams, baseRule, isAll: false, mode: 'rematch');
                    } else {
                      setState(() => selectedMode = 'rematch'); // 3チーム以上ならステップ2へ
                    }
                  }),
                  const Divider(height: 24),
                  _buildTieOption(ctx, Icons.close, '何もしない', '同点のままにします', () => Navigator.pop(ctx), isSub: true),
                ],
              ),
            );
          } else {
            // 【ステップ2】対戦カードの選択（3チーム以上の場合のみ表示される）
            final modeText = selectedMode == 'daihyo' ? '代表戦' : 'チーム再試合';
            return AlertDialog(
              title: Text('$modeTextの作成', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text('作成する組み合わせを選んでください：', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    _buildTieOption(ctx, Icons.auto_awesome, '三つ巴を一括作成', '総当たりの$modeTextをすべて作成します', () {
                      Navigator.pop(ctx);
                      _createTieBreakMatch(parentContext, ref, firstMatch, tieTeams, baseRule, isAll: true, mode: selectedMode!);
                    }),
                    const Divider(height: 24),
                    const Text('個別に対戦を作成：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...(() {
                      final combos = <Widget>[];
                      for (int i = 0; i < tieTeams.length; i++) {
                        for (int j = i + 1; j < tieTeams.length; j++) {
                          combos.add(_buildTieOption(ctx, Icons.compare_arrows, '${tieTeams[i].name} vs ${tieTeams[j].name}', '$modeTextを作成', () {
                            Navigator.pop(ctx);
                            _createTieBreakMatch(parentContext, ref, firstMatch, [tieTeams[i], tieTeams[j]], baseRule, isAll: false, mode: selectedMode!);
                          }, isSub: true));
                        }
                      }
                      return combos;
                    })(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() => selectedMode = null), 
                  child: const Text('形式選択に戻る')
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTieOption(BuildContext ctx, IconData icon, String title, String sub, VoidCallback onTap, {bool isSub = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: isSub ? Colors.transparent : Colors.orange.shade50,
      // ★ 修正：border ではなく side に変更
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSub ? Colors.grey.shade300 : Colors.orange.shade300)),
      child: ListTile(
        leading: Icon(icon, color: isSub ? Colors.grey.shade600 : Colors.orange.shade800),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSub ? Colors.black87 : Colors.orange.shade900)),
        subtitle: Text(sub, style: TextStyle(fontSize: 10, color: isSub ? Colors.grey.shade600 : Colors.orange.shade700)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _createTieBreakMatch(BuildContext context, WidgetRef ref, MatchModel firstMatch, List<dynamic> teams, dynamic baseRule, {required bool isAll, String mode = 'daihyo'}) async {
    try {
      final List<Map<String, String>> matchups = [];
      if (isAll) {
        for (int i = 0; i < teams.length; i++) {
          for (int j = i + 1; j < teams.length; j++) {
            matchups.add({'red': teams[i].name, 'white': teams[j].name});
          }
        }
      } else {
        matchups.add({'red': teams[0].name, 'white': teams[1].name});
      }

      String? firstMatchId;

      for (int i = 0; i < matchups.length; i++) {
        final bool isDaihyo = mode == 'daihyo';
        final List<String> positions = isDaihyo ? ['代表'] : List<String>.from(baseRule.positions);
        
        for (int p = 0; p < positions.length; p++) {
          final String mId = 'tiebreak_${DateTime.now().millisecondsSinceEpoch}_${i}_$p';
          firstMatchId ??= mId; // ★ 修正：Lint警告に対応した綺麗な書き方
          
          final newMatch = MatchModel(
            id: mId,
            tournamentId: firstMatch.tournamentId,
            category: firstMatch.category,
            groupName: firstMatch.groupName,
            redName: '${matchups[i]['red']} : 選手',
            whiteName: '${matchups[i]['white']} : 選手',
            matchType: isDaihyo ? '代表戦' : '順位決定戦',
            status: 'waiting',
            order: 999.0 + (i * 10) + p,
            note: '[順位決定戦] ${isDaihyo ? "代表戦" : "再試合"}',
            matchTimeMinutes: isDaihyo ? 0 : baseRule.matchTimeMinutes.toInt(),
            hasExtension: true,
            // ★ 修正：モデルに存在しない isEnchoUnlimited を削除
            remainingSeconds: isDaihyo ? 0 : (baseRule.matchTimeMinutes * 60).toInt(),
            rule: baseRule.copyWith(positions: [positions[p]], isKachinuki: false, isLeague: false),
          );
          // ★ 修正：Notifierではなく通常のProviderメソッドとして呼び出す（addMatchに変更）
          await ref.read(matchCommandProvider).addMatch(newMatch);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 4),
            content: Text(isAll ? '三つ巴の決定戦を一括作成しました' : '決定戦を作成しました'),
            action: firstMatchId != null ? SnackBarAction(
              label: '試合へ',
              textColor: Colors.white,
              onPressed: () => context.push('/match/$firstMatchId'),
            ) : null,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
    }
  }
} // ★ HomeScreenクラスの【真の】閉じ括弧です！これより下には何も書かないでください！