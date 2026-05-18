import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:uuid/uuid.dart';

import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';

import '../../providers/match_command_provider.dart';
import '../../providers/timeline_provider.dart';
import '../../providers/permission_provider.dart';
import '../../providers/match_rule_provider.dart';
import '../../providers/match_view_model_provider.dart';

import '../../screens/home_screen.dart'; // 検索プロバイダなどを参照するため
import '../../screens/team_scoreboard_screen.dart';

class MatchTimelineList extends ConsumerWidget {
  final String tournamentId;
  const MatchTimelineList({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final permissions = ref.watch(permissionProvider);

    final comments = ref.watch(commentStreamProvider(tournamentId)).value ?? [];

    final sanitizedQuery = ref.watch(searchQueryProvider).replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final timelineResult = ref.watch(timelineMatchesByCategoryProvider(tournamentId));
    final matchedGroupNames = timelineResult.matchedGroupNames;
    final matchedMatchIds = timelineResult.matchedMatchIds;

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.indigo.shade400)),
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
                  icon: Icon(Icons.search, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700, size: 22),
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

        if (timelineResult.entries.isEmpty && sanitizedQuery.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('該当する試合が見つかりません', style: TextStyle(color: Colors.grey))),
          ),
        
        ...(() {
          if (timelineResult.entries.isEmpty) return <Widget>[];
          final sortedEntries = timelineResult.entries;
          return sortedEntries.map<Widget>((catEntry) {
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
                  child: Text(categoryName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade800, letterSpacing: 1.2)),
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
                    bool forceIndividual = sanitizedQuery.isNotEmpty && matchedMatchIds.contains(m.id) && (m.groupName == null || !matchedGroupNames.contains(m.groupName!));
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
                    bool forceIndividual = sanitizedQuery.isNotEmpty && matchedMatchIds.contains(m.id) && (m.groupName == null || !matchedGroupNames.contains(m.groupName!));
                    if (forceIndividual) {
                      String rPlayer = m.redName.contains(':') ? m.redName.split(':').last.trim() : m.redName;
                      String wPlayer = m.whiteName.contains(':') ? m.whiteName.split(':').last.trim() : m.whiteName;
                      if (rPlayer.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(sanitizedQuery)) {
                        playerName = rPlayer;
                      } else if (wPlayer.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(sanitizedQuery)) {
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

                  final sortedGroups = actualGroupedMatches.entries.toList()..sort((a, b) => a.value.first.order.compareTo(b.value.first.order));
                  final sortedPlayers = matchesByPlayer.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

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
                              
                              if (!permissions.isReadOnly) ...[
                                IconButton(
                                  icon: Icon(Icons.add_comment, color: isDark ? Colors.indigo.shade400 : Colors.indigo.shade300, size: 20),
                                  tooltip: '見出し（コメント）を追加',
                                  onPressed: () => _showAddCommentDialog(context, ref, tournamentId, categoryName, teamName, sortedGroups.isEmpty ? 0.0 : sortedGroups.first.value.first.order - 100.0),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit_note, color: isDark ? Colors.indigo.shade400 : Colors.indigo.shade300, size: 20),
                                  tooltip: 'チーム名を修正して統合',
                                  onPressed: () => _showRenameTeamSheet(context, ref, tournamentId, teamName),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),

                        Builder(builder: (context) {
                          final timelineItems = <ReorderableTimelineItem>[];
                          for (var entry in sortedGroups) {
                            timelineItems.add(MatchGroupTimelineItem(entry.key, entry.value));
                          }
                          final teamComments = comments.where((c) => c.category == categoryName && c.groupName == teamName).toList();
                          for (var c in teamComments) {
                            timelineItems.add(CommentTimelineItem(c));
                          }
                          timelineItems.sort((a, b) => a.order.compareTo(b.order));

                          return ReorderableListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            onReorder: (oldIndex, newIndex) => _onReorderTimeline(timelineItems, oldIndex, newIndex, ref),
                            children: (() {
                              String lastGroupLabel = ''; 
                              return timelineItems.map((item) {
                                if (item is CommentTimelineItem) {
                                  final c = item.comment;
                                  return Container(
                                    key: ValueKey('comment_${c.id}'),
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.label_outline, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(c.text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800))),
                                      ],
                                    ),
                                  );
                                } else if (item is MatchGroupTimelineItem) {
                                  final entry = MapEntry(item.groupId, item.matches);
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
                                  
                                  final Color cardBg = allFinished ? (isDark ? const Color(0xFF161618) : Colors.grey.shade100) : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
                                  final Color titleColor = allFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (isDark ? Colors.white : Colors.black87);
                                  final Color subTitleColor = allFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500) : (isDark ? Colors.grey.shade500 : Colors.grey.shade600);

                                  final pairingsSet = <String>{};
                                  for (var m in groupList) { final t1 = m.redName.split(':').first.trim(); final t2 = m.whiteName.split(':').first.trim(); final pairKey = [t1, t2]..sort(); pairingsSet.add(pairKey.join(' vs ')); }
                                  final int displayMatchCount = pairingsSet.length;

                                  return Container(
                                    key: ValueKey(entry.key),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ?headerWidget,
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          child: Slidable(
                                            key: ValueKey('group_${entry.key}'),
                                            enabled: !permissions.isReadOnly,
                                            endActionPane: ActionPane(
                                              motion: const ScrollMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) => _showEditGroupNoteDialog(context, ref, groupList),
                                                  backgroundColor: Colors.blueAccent,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.edit,
                                                  label: '編集',
                                                ),
                                                SlidableAction(
                                                  onPressed: (context) async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                                        title: Text('試合グループの削除', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                                        content: Text('このグループに含まれる全試合を\n削除しますか？\n(取り消せません)', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
                                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除する', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      for (var m in groupList) { await ref.read(matchCommandProvider).deleteMatch(m.id); }
                                                    }
                                                  },
                                                  backgroundColor: Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.delete,
                                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                                  label: '削除',
                                                ),
                                              ],
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: cardBg,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 1),
                                                boxShadow: hasInProgress ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(11),
                                                child: ExpansionTile(
                                                  collapsedBackgroundColor: Colors.transparent, backgroundColor: Colors.transparent,
                                                  title: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(children: [
                                                        if (firstMatch.note.isNotEmpty)
                                                          Flexible(child: Padding(padding: const EdgeInsets.only(right: 6, bottom: 4), child: Text(firstMatch.note, style: TextStyle(fontSize: 11, color: subTitleColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1))),
                                                        const Spacer(),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: hasInProgress ? Colors.blue.shade600 : (allFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(hasInProgress ? '進行中' : (allFinished ? '終了' : '待機中'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasInProgress ? Colors.white : (allFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)))),
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
                                                          if (!allFinished)
                                                            Padding(
                                                              padding: const EdgeInsets.only(left: 8),
                                                              child: InkWell(
                                                                onTap: () => _showRuleInfoSheet(context, firstMatch),
                                                                borderRadius: BorderRadius.circular(12),
                                                                child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.info_outline, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 16)),
                                                              ),
                                                            ),
                                                          if (ownTeams.contains(rTeam) && ownTeams.contains(wTeam))
                                                            Container(
                                                              margin: const EdgeInsets.only(left: 8),
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(color: Colors.pink.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.pink.shade300)),
                                                              child: Text('⚔️ 同門', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pink.shade800)),
                                                            ),
                                                          if (!label.contains('リーグ戦')) ...[
                                                            const SizedBox(width: 8),
                                                            SizedBox(
                                                              height: 28,
                                                              child: OutlinedButton(
                                                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TeamScoreboardScreen(groupName: firstMatch.groupName, matches: groupList))),
                                                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: BorderSide(color: titleColor.withValues(alpha: 0.3), width: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                                                child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: titleColor)),
                                                              ),
                                                            ),
                                                          ],
                                                          if (!permissions.isReadOnly && !allFinished && !label.contains('個人戦') && !label.contains('勝ち抜き戦') && !label.contains('リーグ戦') &&
                                                              !(ref.read(customTeamNamesProvider).value ?? []).contains(groupList.first.redName.split(':').first.trim()) &&
                                                              !(ref.read(customTeamNamesProvider).value ?? []).contains(groupList.first.whiteName.split(':').first.trim())) ...[
                                                            const SizedBox(width: 8),
                                                            SizedBox(
                                                              height: 28,
                                                              child: OutlinedButton.icon(
                                                                onPressed: () => _showSummaryInputDialog(context, ref, groupList),
                                                                icon: Icon(Icons.flash_on, size: 14, color: Colors.amber.shade700),
                                                                label: Text('簡易入力', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: titleColor)),
                                                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: BorderSide(color: titleColor.withValues(alpha: 0.3), width: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                                              ),
                                                            ),
                                                          ]
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: Text('$displayMatchCount対戦', style: TextStyle(color: subTitleColor, fontSize: 12)),
                                                  children: (() {
                                                    final List<Widget> childrenWidgets = [];
                                                    final normalMatches = groupList.where((m) => !m.note.contains('[順位決定戦]')).toList();
                                                    final tieBreakMatches = groupList.where((m) => m.note.contains('[順位決定戦]')).toList();

                                                    if (label.contains('リーグ戦') && allFinished && !label.contains('個人戦') && tieBreakMatches.isEmpty) {
                                                      final rule = firstMatch.rule ?? ref.read(matchRuleProvider);
                                                      final stats = KendoRuleEngine.calculateLeagueStandings(normalMatches, rule!);
                                                      final tieGroups = <List<dynamic>>[];
                                                      if (stats.length > 1) {
                                                        List<dynamic> currentTie = [stats.first];
                                                        for (int i = 1; i < stats.length; i++) {
                                                          final prev = stats[i - 1];
                                                          final curr = stats[i];
                                                          bool isTie = (prev.customPoints - curr.customPoints).abs() < 0.001 && prev.matchWins == curr.matchWins && prev.individualWinners == curr.individualWinners && prev.totalPointsScored == curr.totalPointsScored;
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
                                                            decoration: BoxDecoration(color: isDark ? Colors.orange.shade900.withValues(alpha: 0.2) : Colors.orange.shade50, border: Border.all(color: Colors.orange.shade300), borderRadius: BorderRadius.circular(12)),
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

                                                    if (label.contains('リーグ戦')) {
                                                      if (label.contains('個人戦')) {
                                                        childrenWidgets.add(
                                                          ReorderableListView(
                                                            shrinkWrap: true,
                                                            physics: const NeverScrollableScrollPhysics(),
                                                            onReorder: (oldIndex, newIndex) => _onReorderMatches(normalMatches, oldIndex, newIndex, ref),
                                                            children: normalMatches.map((m) => Container(key: ValueKey(m.id), child: _buildMatchListTile(context, ref, m, isDeletable: true))).toList(),
                                                          )
                                                        );
                                                      } else {
                                                        final boutsByMatchup = <String, List<MatchModel>>{};
                                                        final matchupOrder = <String>[];
                                                        for (var m in normalMatches) {
                                                          final matchupName = '${m.redName.split(':').first.trim()} vs ${m.whiteName.split(':').first.trim()}';
                                                          if (!boutsByMatchup.containsKey(matchupName)) { matchupOrder.add(matchupName); boutsByMatchup[matchupName] = []; }
                                                          boutsByMatchup[matchupName]!.add(m);
                                                        }

                                                        childrenWidgets.addAll(matchupOrder.map((name) {
                                                        final bouts = boutsByMatchup[name]!;
                                                        final bool boutsInProgress = bouts.any((m) => m.status == 'in_progress');
                                                        final bool boutsAllFinished = bouts.every((m) => m.status == 'finished' || m.status == 'approved');
                                                        final t1 = name.split(' vs ')[0];
                                                        final t2 = name.split(' vs ')[1];
                                                        final Color mCardBg = boutsAllFinished ? (isDark ? const Color(0xFF161618) : Colors.grey.shade100) : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
                                                        final Color mTitleColor = boutsAllFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (isDark ? Colors.white : Colors.black87);

                                                        return Container(
                                                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(color: mCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, width: 1), boxShadow: boutsInProgress ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : []),
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
                                                                    spacing: 8, runSpacing: 4,
                                                                    children: [
                                                                      Text('${bouts.length}ポジション', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                        decoration: BoxDecoration(color: boutsInProgress ? Colors.blue.shade600 : (boutsAllFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)), borderRadius: BorderRadius.circular(4)),
                                                                        child: Text(boutsInProgress ? '進行中' : (boutsAllFinished ? '終了' : '待機中'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: boutsInProgress ? Colors.white : (boutsAllFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)))),
                                                                      ),
                                                                      SizedBox(
                                                                        height: 24,
                                                                        child: OutlinedButton(
                                                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TeamScoreboardScreen(groupName: bouts.first.groupName, matches: bouts))),
                                                                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: BorderSide(color: mTitleColor.withValues(alpha: 0.3), width: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                                                          child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mTitleColor)),
                                                                        ),
                                                                      ),
                                                                      Builder(builder: (context) {
                                                                        final ownT = ref.read(customTeamNamesProvider).value ?? [];
                                                                        final rT = bouts.first.redName.split(':').first.trim();
                                                                        final wT = bouts.first.whiteName.split(':').first.trim();
                                                                        if (!permissions.isReadOnly && !boutsAllFinished && !(ownT.contains(rT) || bouts.first.redName.contains('自チーム')) && !(ownT.contains(wT) || bouts.first.whiteName.contains('自チーム'))) {
                                                                          return SizedBox(
                                                                            height: 24,
                                                                            child: OutlinedButton.icon(
                                                                              onPressed: () => _showSummaryInputDialog(context, ref, bouts),
                                                                              icon: Icon(Icons.flash_on, size: 12, color: Colors.amber.shade700),
                                                                              label: Text('簡易入力', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mTitleColor)),
                                                                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: BorderSide(color: mTitleColor.withValues(alpha: 0.3), width: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                                                            ),
                                                                          );
                                                                        }
                                                                        return const SizedBox.shrink();
                                                                      }),
                                                                    ],
                                                                  ),
                                                                ),
                                                                children: bouts.map((m) => _buildMatchListTile(context, ref, m, isDeletable: false)).toList(),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                        }));
                                                      }
                                                    } else {
                                                      childrenWidgets.addAll(normalMatches.map((m) => _buildMatchListTile(context, ref, m, isDeletable: false)).toList());
                                                    }

                                                    if (tieBreakMatches.isNotEmpty) {
                                                      childrenWidgets.add(const Divider());
                                                      childrenWidgets.add(const Padding(padding: EdgeInsets.all(8), child: Text('【順位決定戦】', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange))));
                                                      if (label.contains('個人戦') || label.contains('選手')) {
                                                        childrenWidgets.add(
                                                          ReorderableListView(
                                                            shrinkWrap: true,
                                                            physics: const NeverScrollableScrollPhysics(),
                                                            onReorder: (oldIndex, newIndex) => _onReorderMatches(tieBreakMatches, oldIndex, newIndex, ref),
                                                            children: tieBreakMatches.map((m) => Container(key: ValueKey(m.id), child: _buildMatchListTile(context, ref, m, isDeletable: true))).toList(),
                                                          )
                                                        );
                                                      } else {
                                                        childrenWidgets.addAll(tieBreakMatches.map((m) => _buildMatchListTile(context, ref, m, isDeletable: false)).toList());
                                                      }
                                                    }
                                                    return childrenWidgets;
                                                  })(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }).toList();
                            })(),
                          );
                        }),

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
                            final label = (!firstMatch.isKachinuki && (firstMatch.matchType == 'individual' || firstMatch.matchType == '選手')) ? (firstMatch.note.contains('[リーグ戦]') ? '個人戦/リーグ戦' : '個人戦') : (firstMatch.isKachinuki ? '団体戦/勝ち抜き戦' : (firstMatch.note.contains('[リーグ戦]') ? '団体戦/リーグ戦' : '団体戦'));
                            final bool pInProgress = playerMatches.any((m) => m.status == 'in_progress');
                            final bool pAllFinished = playerMatches.every((m) => m.status == 'finished' || m.status == 'approved');
                            final Color pCardBg = pAllFinished ? (isDark ? const Color(0xFF161618) : Colors.grey.shade100) : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
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
                                  leading: CircleAvatar(backgroundColor: pAllFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : Colors.orange.shade100, child: Text(playerName[0], style: TextStyle(color: pAllFinished ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600) : Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold))),
                                  title: Text(playerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: pTitleColor)),
                                  subtitle: Row(
                                    children: [
                                      Text('$label • ${playerMatches.length}試合', style: TextStyle(fontSize: 12, color: pSubTitleColor)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: pInProgress ? Colors.blue.shade600 : (pAllFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)), borderRadius: BorderRadius.circular(4)),
                                        child: Text(pInProgress ? '進行中' : (pAllFinished ? '終了' : '待機中'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pInProgress ? Colors.white : (pAllFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)))),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    ReorderableListView(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      onReorder: (oldIndex, newIndex) => _onReorderMatches(playerMatches, oldIndex, newIndex, ref),
                                      children: playerMatches.map((match) => Container(key: ValueKey(match.id), child: _buildMatchListTile(context, ref, match))).toList(),
                                    )
                                  ],
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
          }).toList();
        })(), 
      ],
    );
  }

  Widget _buildMatchListTile(BuildContext context, WidgetRef ref, MatchModel match, {bool isDeletable = true}) {
    final permissions = ref.watch(permissionProvider);
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

    final Color bg = isFinished ? (isDark ? const Color(0xFF161618) : Colors.grey.shade50) : Colors.transparent;
    final Color textC = isFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (isDark ? Colors.white : Colors.black87);
    final Color noteC = isFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500) : Colors.grey.shade600;

    final tile = Container(
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200, width: 0.5))),
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
                        if (displayNote.isNotEmpty) TextSpan(text: displayNote),
                        if (displayNote.isNotEmpty && (match.matchType.isNotEmpty && match.matchType != '選手')) const TextSpan(text: ' '),
                        if (match.matchType.isNotEmpty && match.matchType != '選手') TextSpan(text: '【${match.matchType}】'),
                      ],
                    ),
                    style: TextStyle(fontSize: 11, color: noteC, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, softWrap: false, maxLines: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: isPlaying ? Colors.blue.shade600 : (isFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)), borderRadius: BorderRadius.circular(4)),
                  child: Text(isPlaying ? '進行中' : (isFinished ? '終了' : '待機中'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPlaying ? Colors.white : (isFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)))),
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
            if (isIndividual)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _showRuleInfoSheet(context, match),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.info_outline, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 18)),
                ),
              ),
            Builder(builder: (context) {
              final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
              final rT = match.redName.split(':').first.trim();
              final wT = match.whiteName.split(':').first.trim();
              if (!permissions.isReadOnly && !isFinished && !isPlaying && !(ownTeams.contains(rT) || match.redName.contains('自チーム')) && !(ownTeams.contains(wT) || match.whiteName.contains('自チーム')) && isIndividual) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    height: 28,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSummaryInputDialog(context, ref, [match]),
                      icon: Icon(Icons.flash_on, size: 12, color: Colors.amber.shade700),
                      label: Text('簡易', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textC)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), side: BorderSide(color: textC.withValues(alpha: 0.3), width: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            if (isIndividual || match.note.contains('[順位決定戦]') || match.matchType == '代表戦')
              SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: () => context.push('/team-scoreboard/${match.groupName ?? match.id}'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: BorderSide(color: textC.withValues(alpha: 0.3), width: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  child: Text('スコア', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textC)),
                ),
              ),
          ],
        ),
        onTap: () => context.push('/match/${match.id}'),
      ),
    );

    if (permissions.isReadOnly || !isDeletable) return tile;

    return Slidable(
      key: ValueKey(match.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(onPressed: (context) => _showEditNoteDialog(context, ref, match), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, icon: Icons.edit, label: '編集'),
          SlidableAction(
            onPressed: (context) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  title: Text('試合の削除', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  content: Text('削除しますか？\n(取り消せません)', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
              if (confirm == true) await ref.read(matchCommandProvider).deleteMatch(match.id);
            },
            backgroundColor: Colors.redAccent, foregroundColor: Colors.white, icon: Icons.delete, label: '削除',
          ),
        ],
      ),
      child: tile,
    );
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
            decoration: BoxDecoration(color: boxColor, border: Border.all(color: borderColor, width: 1.5), borderRadius: BorderRadius.circular(3), boxShadow: isFinished ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1))]),
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
    return '${parts[1].trim()} : ${parts[0].trim()}';
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
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
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
              controller: controller, autofocus: true,
              decoration: InputDecoration(labelText: '新しいチーム名', filled: true, fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty || newName == oldName) { Navigator.pop(ctx); return; }
                  await ref.read(matchCommandProvider).renameTeamBulk(tournamentId: tournamentId, oldTeamName: oldName, newTeamName: newName);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('チーム名を一括更新しました ✨')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
    for (var m in matches) { participantsSet.add(m.redName.split(':').first.trim()); participantsSet.add(m.whiteName.split(':').first.trim()); }
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
    return "$selfInfo : ${isIndiv ? "$n人リーグ" : "$nチームリーグ"}（全$mCount試合）";
  }

  void _showRuleInfoSheet(BuildContext context, MatchModel match) {
    HapticFeedback.mediumImpact(); 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rule = match.rule; 
    
    final bool isLegacyLeague = match.note.contains('[リーグ戦]');
    final bool isLeague = (rule?.isLeague ?? false) || isLegacyLeague;
    final bool isIndividual = !match.isKachinuki && (match.matchType == 'individual' || match.matchType == '選手' || match.matchType.contains('個人戦') || (rule != null && rule.positions.length == 1 && (rule.positions.first == '選手' || rule.positions.first == '個人戦')));
    
    String formatText = isIndividual ? '個人戦' : '団体戦';
    if (rule?.isRenseikai ?? false) { formatText = '錬成会'; } else if (match.isKachinuki || (rule?.isKachinuki ?? false)) { formatText = '勝ち抜き戦'; } else if (isLeague) { formatText = 'リーグ戦（総当たり）'; }

    final double matchTime = rule?.matchTimeMinutes ?? match.matchTimeMinutes.toDouble();
    final isRunningTime = rule?.isRunningTime ?? match.isRunningTime;
    String timeStr = matchTime == matchTime.toInt() ? '${matchTime.toInt()}分' : '${matchTime.toInt()}分${((matchTime % 1) * 60).toInt()}秒';
    final String timeDesc = '$timeStr (${isRunningTime ? "通し/空回し" : "都度ストップ"})';

    final bool enchoUnlimited = rule?.isEnchoUnlimited ?? false;
    final double enchoMins = rule?.enchoTimeMinutes ?? match.extensionTimeMinutes?.toDouble() ?? 0.0;
    final int enchoCount = rule?.enchoCount ?? match.extensionCount ?? 1;
    final bool enchoEnabled = match.hasExtension || enchoUnlimited || enchoMins > 0;
    
    String enchoDesc = 'なし';
    if (enchoEnabled) {
      if (enchoUnlimited) { enchoDesc = 'あり (無制限)'; } else {
        String extTimeStr = enchoMins == enchoMins.toInt() ? '${enchoMins.toInt()}分' : '${enchoMins.toInt()}分${((enchoMins % 1) * 60).toInt()}秒';
        enchoDesc = 'あり ($extTimeStr・$enchoCount回)';
      }
    }
    
    final bool hanteiEnabled = rule?.hasHantei ?? match.hasHantei;
    String daihyoDesc = rule != null ? (rule.hasRepresentativeMatch ? (rule.isDaihyoIpponShobu ? 'あり (一本勝負)' : 'あり (三本勝負)') : 'なし') : '不明（古いデータ）';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Row(children: [Icon(Icons.gavel_rounded, color: isDark ? Colors.teal.shade300 : Colors.teal.shade700, size: 22), const SizedBox(width: 8), Text('試合レギュレーション', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))]),
            const Divider(height: 32),
            if (rule == null)
              Container(
                margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade300)),
                child: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20), const SizedBox(width: 8), Expanded(child: Text('この試合はアップデート前に作成されたため、詳細なルールが保存されていません。新しく作成した試合では正しく表示されます。', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)))]),
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
              if (rule != null && rule.positions.isNotEmpty) _buildRuleRow('ポジション', rule.positions.join('、'), isDark),
            ],
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
                style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200, foregroundColor: isDark ? Colors.white : Colors.black87, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
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

  void _showTieBreakDialog(BuildContext parentContext, WidgetRef ref, MatchModel firstMatch, List<dynamic> tieTeams, dynamic baseRule) {
    String? selectedMode;
    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          if (selectedMode == null) {
            return AlertDialog(
              title: const Text('決定戦の形式を選択', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('同順位を解消するための形式を選んでください：', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  _buildTieOption(ctx, Icons.person, '代表戦（1名）', '1本勝負で順位を決定します', () {
                    if (tieTeams.length <= 2) { Navigator.pop(ctx); _createTieBreakMatch(parentContext, ref, firstMatch, tieTeams, baseRule, isAll: false, mode: 'daihyo'); } else { setState(() => selectedMode = 'daihyo'); }
                  }),
                  _buildTieOption(ctx, Icons.groups, 'チーム再試合', '全ポジションで再度対戦します', () {
                    if (tieTeams.length <= 2) { Navigator.pop(ctx); _createTieBreakMatch(parentContext, ref, firstMatch, tieTeams, baseRule, isAll: false, mode: 'rematch'); } else { setState(() => selectedMode = 'rematch'); }
                  }),
                  const Divider(height: 24),
                  _buildTieOption(ctx, Icons.close, '何もしない', '同点のままにします', () => Navigator.pop(ctx), isSub: true),
                ],
              ),
            );
          } else {
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
                    _buildTieOption(ctx, Icons.auto_awesome, '三つ巴を一括作成', '総当たりの$modeTextをすべて作成します', () { Navigator.pop(ctx); _createTieBreakMatch(parentContext, ref, firstMatch, tieTeams, baseRule, isAll: true, mode: selectedMode!); }),
                    const Divider(height: 24),
                    const Text('個別に対戦を作成：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...(() {
                      final combos = <Widget>[];
                      for (int i = 0; i < tieTeams.length; i++) {
                        for (int j = i + 1; j < tieTeams.length; j++) {
                          combos.add(_buildTieOption(ctx, Icons.compare_arrows, '${tieTeams[i].name} vs ${tieTeams[j].name}', '$modeTextを作成', () { Navigator.pop(ctx); _createTieBreakMatch(parentContext, ref, firstMatch, [tieTeams[i], tieTeams[j]], baseRule, isAll: false, mode: selectedMode!); }, isSub: true));
                        }
                      }
                      return combos;
                    })(),
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => setState(() => selectedMode = null), child: const Text('形式選択に戻る'))],
            );
          }
        },
      ),
    );
  }

  Widget _buildTieOption(BuildContext ctx, IconData icon, String title, String sub, VoidCallback onTap, {bool isSub = false}) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 8), color: isSub ? Colors.transparent : Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSub ? Colors.grey.shade300 : Colors.orange.shade300)),
      child: ListTile(leading: Icon(icon, color: isSub ? Colors.grey.shade600 : Colors.orange.shade800), title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSub ? Colors.black87 : Colors.orange.shade900)), subtitle: Text(sub, style: TextStyle(fontSize: 10, color: isSub ? Colors.grey.shade600 : Colors.orange.shade700)), onTap: onTap),
    );
  }

  Future<void> _createTieBreakMatch(BuildContext context, WidgetRef ref, MatchModel firstMatch, List<dynamic> teams, dynamic baseRule, {required bool isAll, String mode = 'daihyo'}) async {
    try {
      final List<Map<String, String>> matchups = [];
      if (isAll) {
        for (int i = 0; i < teams.length; i++) {
          for (int j = i + 1; j < teams.length; j++) { matchups.add({'red': teams[i].name, 'white': teams[j].name}); }
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
          firstMatchId ??= mId;
          final newMatch = MatchModel(
            id: mId, tournamentId: firstMatch.tournamentId, category: firstMatch.category, groupName: firstMatch.groupName, redName: '${matchups[i]['red']} : 選手', whiteName: '${matchups[i]['white']} : 選手', matchType: isDaihyo ? '代表戦' : '順位決定戦', status: 'waiting', order: 999.0 + (i * 10) + p, note: '[順位決定戦] ${isDaihyo ? "代表戦" : "再試合"}', matchTimeMinutes: isDaihyo ? 0 : baseRule.matchTimeMinutes.toInt(), hasExtension: true, rule: baseRule.copyWith(positions: [positions[p]], isKachinuki: false, isLeague: false),
          );
          await ref.read(matchCommandProvider).addMatch(newMatch);
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.teal, duration: const Duration(seconds: 4), content: Text(isAll ? '三つ巴の決定戦を一括作成しました' : '決定戦を作成しました'), action: firstMatchId != null ? SnackBarAction(label: '試合へ', textColor: Colors.white, onPressed: () => context.push('/match/$firstMatchId')) : null));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
    }
  }

  void _showSummaryInputDialog(BuildContext context, WidgetRef ref, List<MatchModel> matches) {
    final normalMatches = matches.where((m) => m.matchType != '代表戦' && m.matchType != '順位決定戦').toList();
    if (normalMatches.isEmpty) return;

    final int totalMatches = normalMatches.length;
    int rWins = 0, rPts = 0, wWins = 0, wPts = 0;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rTeam = normalMatches.first.redName.split(':').first.trim();
    final wTeam = normalMatches.first.whiteName.split(':').first.trim();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Widget buildCounter(String label, int value, VoidCallback onMinus, VoidCallback onPlus, Color color) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(icon: Icon(Icons.remove_circle_outline, color: color), onPressed: value > 0 ? () { onMinus(); setState((){}); } : null),
                    SizedBox(width: 30, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(icon: Icon(Icons.add_circle_outline, color: color), onPressed: () { onPlus(); setState((){}); }),
                  ],
                )
              ]
            );
          }

          bool isValid = (rWins + wWins <= totalMatches) && (rPts >= rWins && rPts <= rWins * 2) && (wPts >= wWins && wPts <= wWins * 2);
          String errorMsg = '';
          if (rWins + wWins > totalMatches) { errorMsg = '勝者数の合計が試合数($totalMatches)を超えています'; } else if (rPts < rWins) { errorMsg = '赤の本数が少なすぎます（1勝につき最低1本）'; } else if (rPts > rWins * 2) { errorMsg = '赤の本数が多すぎます（1勝につき最大2本）'; } else if (wPts < wWins) { errorMsg = '白の本数が少なすぎます'; } else if (wPts > wWins * 2) { errorMsg = '白の本数が多すぎます'; }

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('他コートの簡易入力', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('他チームの試合結果（勝者数と本数）だけを素早く記録します。', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                    child: Column(
                      children: [
                        Text(rTeam, style: TextStyle(color: isDark ? Colors.red.shade400 : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        buildCounter('勝者数', rWins, () => rWins--, () { if(rWins+wWins<totalMatches) { rWins++; } }, Colors.red),
                        buildCounter('取得本数', rPts, () => rPts--, () { if(rPts<rWins*2) { rPts++; } }, Colors.red),
                      ]
                    )
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? Colors.blue.shade900.withValues(alpha: 0.15) : Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                    child: Column(
                      children: [
                        Text(wTeam, style: TextStyle(color: isDark ? Colors.blue.shade400 : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        buildCounter('勝者数', wWins, () => wWins--, () { if(rWins+wWins<totalMatches) { wWins++; } }, Colors.blue),
                        buildCounter('取得本数', wPts, () => wPts--, () { if(wPts<wWins*2) { wPts++; } }, Colors.blue),
                      ]
                    )
                  ),
                  if (errorMsg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(errorMsg, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))),
                ]
              )
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () async {
                  if (!isValid) {
                    showDialog(context: context, builder: (dialogCtx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Text('入力エラー')]), content: Text(errorMsg, style: const TextStyle(fontWeight: FontWeight.bold)), actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('確認'))]));
                    return;
                  }
                  Navigator.pop(ctx);
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  try {
                    int rw = rWins, rp = rPts, ww = wWins, wp = wPts;
                    for (var m in normalMatches) {
                      List<ScoreEvent> events = [];
                      int matchRedScore = 0; int matchWhiteScore = 0;
                      if (rw > 0) {
                        rw--; int p = (rp > rw) ? 2 : 1; if (p > rp) p = rp; rp -= p; matchRedScore = p;
                        for(int i=0; i<p; i++) { events.add(ScoreEventLegacyAdapter.fromLegacy(id: const Uuid().v4(), type: PointType.fusen, side: Side.red, timestamp: DateTime.now())); }
                      } else if (ww > 0) {
                        ww--; int p = (wp > ww) ? 2 : 1; if (p > wp) p = wp; wp -= p; matchWhiteScore = p;
                        for(int i=0; i<p; i++) { events.add(ScoreEventLegacyAdapter.fromLegacy(id: const Uuid().v4(), type: PointType.fusen, side: Side.white, timestamp: DateTime.now())); }
                      }
                      final String newNote = m.note.contains('[SUMMARY]') ? m.note : '${m.note} [SUMMARY]'.trim();
                      final updated = m.copyWith(status: 'approved', note: newNote, events: events, redScore: matchRedScore, whiteScore: matchWhiteScore);
                      await ref.read(matchApplicationServiceProvider).saveMatch(updated);
                    }
                  } catch(e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
                  } finally {
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 0),
                child: const Text('記録を確定する', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ]
          );
        }
      )
    );
  }

  void _onReorderMatches(List<MatchModel> list, int oldIndex, int newIndex, WidgetRef ref) async {
    final permissions = ref.read(permissionProvider);
    if (permissions.isReadOnly) return;
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    
    final item = list[oldIndex];
    double newOrder;
    if (newIndex == 0) { newOrder = list.first.order - 100.0; } else if (newIndex == list.length - 1) { newOrder = list.last.order + 100.0; } else {
      final prevOrder = list[newIndex > oldIndex ? newIndex : newIndex - 1].order;
      final nextOrder = list[newIndex > oldIndex ? newIndex + 1 : newIndex].order;
      newOrder = (prevOrder + nextOrder) / 2.0;
    }
    if (newOrder == list[newIndex].order) newOrder += 0.001;
    
    try { await ref.read(matchApplicationServiceProvider).saveMatchesBulk([item.copyWith(order: newOrder)]); } catch (e) { debugPrint('並び替え保存エラー: $e'); }
  }

  void _onReorderTimeline(List<ReorderableTimelineItem> list, int oldIndex, int newIndex, WidgetRef ref) async {
    final permissions = ref.read(permissionProvider);
    if (permissions.isReadOnly) return;
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    
    final item = list[oldIndex];
    double newOrder;
    if (newIndex == 0) { newOrder = list.first.order - 100.0; } else if (newIndex == list.length - 1) { newOrder = list.last.order + 100.0; } else {
      final prevOrder = list[newIndex > oldIndex ? newIndex : newIndex - 1].order;
      final nextOrder = list[newIndex > oldIndex ? newIndex + 1 : newIndex].order;
      newOrder = (prevOrder + nextOrder) / 2.0;
    }
    if (newOrder == list[newIndex].order) newOrder += 0.001;
    
    if (item is CommentTimelineItem) {
      try { await ref.read(commentCommandProvider).updateCommentOrder(item.comment, newOrder); } catch (e) { debugPrint('コメント並び替え保存エラー: $e'); }
    } else if (item is MatchGroupTimelineItem) {
      final offsetOrder = newOrder - item.order;
      final updatedMatches = item.matches.map((m) => m.copyWith(order: m.order + offsetOrder)).toList();
      try { await ref.read(matchApplicationServiceProvider).saveMatchesBulk(updatedMatches); } catch (e) { debugPrint('グループ並び替え保存エラー: $e'); }
    }
  }

  void _showAddCommentDialog(BuildContext context, WidgetRef ref, String tournamentId, String category, String groupName, double order) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text('見出し（コメント）の追加', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        content: TextField(controller: controller, autofocus: true, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(hintText: '見出しやコメントを入力', hintStyle: const TextStyle(color: Colors.grey, fontSize: 13), filled: true, fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () async { final text = controller.text.trim(); if (text.isNotEmpty) { await ref.read(commentCommandProvider).addComment(tournamentId: tournamentId, category: category, groupName: groupName, text: text, order: order); } if (ctx.mounted) Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 0), child: const Text('追加', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showEditGroupNoteDialog(BuildContext context, WidgetRef ref, List<MatchModel> groupList) {
    final firstMatch = groupList.first;
    final controller = TextEditingController(text: firstMatch.note);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text('グループ詳細の編集', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        content: TextField(controller: controller, autofocus: true, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(hintText: 'グループのメモを入力', filled: true, fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () async { final newNote = controller.text.trim(); if (newNote != firstMatch.note) { await ref.read(matchApplicationServiceProvider).saveMatchesBulk(groupList.map((m) => m.copyWith(note: newNote)).toList()); } if (ctx.mounted) Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 0), child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, WidgetRef ref, MatchModel match) {
    final controller = TextEditingController(text: match.note);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text('試合詳細の編集', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        content: TextField(controller: controller, autofocus: true, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(hintText: '試合のメモを入力', filled: true, fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () async { final newNote = controller.text.trim(); if (newNote != match.note) { await ref.read(matchApplicationServiceProvider).saveMatchesBulk([match.copyWith(note: newNote)]); } if (ctx.mounted) Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, elevation: 0), child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}