import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/screens/home_screen.dart';

// 大会ごとの試合リスト（オーダー順ソート済み）
final tournamentMatchesProvider = Provider.family.autoDispose<List<MatchModel>, String>((ref, tournamentId) {
  final matches = ref.watch(matchListProvider);
  final filtered = matches.where((m) => m.tournamentId == tournamentId).toList();
  return filtered..sort((a, b) => a.order.compareTo(b.order));
});

// アクティブな試合（バナー表示用）
class ActiveMatches {
  final List<MatchModel> inProgress;
  final List<MatchModel> waiting;
  ActiveMatches({required this.inProgress, required this.waiting});
}

final activeMatchesProvider = Provider.family.autoDispose<ActiveMatches, String>((ref, tournamentId) {
  final matches = ref.watch(tournamentMatchesProvider(tournamentId));
  final uniqueInProgress = <MatchModel>[];
  final uniqueWaiting = <MatchModel>[];
  final seenGroups = <String>{};

  for (var m in matches) {
    if (m.groupName != null && m.groupName!.isNotEmpty) {
      if (seenGroups.contains(m.groupName)) continue; 
      seenGroups.add(m.groupName!);
      final groupMatches = matches.where((gm) => gm.groupName == m.groupName).toList();
      if (groupMatches.any((gm) => gm.status == 'in_progress')) { uniqueInProgress.add(m); } 
      else if (groupMatches.every((gm) => gm.status == 'waiting')) { uniqueWaiting.add(m); }
    } else {
      if (m.status == 'in_progress') { uniqueInProgress.add(m); } 
      else if (m.status == 'waiting') { uniqueWaiting.add(m); }
    }
  }

  return ActiveMatches(inProgress: uniqueInProgress, waiting: uniqueWaiting);
});

class TimelineMatchesResult {
  final List<MapEntry<String, List<MatchModel>>> entries;
  final Set<String> matchedGroupNames;
  final Set<String> matchedMatchIds;

  TimelineMatchesResult({
    required this.entries,
    required this.matchedGroupNames,
    required this.matchedMatchIds,
  });
}

// タイムライン表示用（検索・カテゴリソート適用済み）
final timelineMatchesByCategoryProvider = Provider.family.autoDispose<TimelineMatchesResult, String>((ref, tournamentId) {
  final matches = ref.watch(tournamentMatchesProvider(tournamentId));
  final searchQuery = ref.watch(searchQueryProvider).replaceAll(RegExp(r'\s+'), '').toLowerCase();
  final isAscending = ref.watch(categorySortProvider);

  final matchedGroupNames = <String>{};
  final matchedMatchIds = <String>{};

  if (searchQuery.isNotEmpty) {
    for (var m in matches) {
      String rTeam = m.redName.contains(':') ? m.redName.split(':').first : m.redName;
      String wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first : m.whiteName;
      String rPlayer = m.redName.contains(':') ? m.redName.split(':').last : m.redName;
      String wPlayer = m.whiteName.contains(':') ? m.whiteName.split(':').last : m.whiteName;

      bool teamHit = rTeam.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(searchQuery) ||
                     wTeam.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(searchQuery);
      bool playerHit = rPlayer.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(searchQuery) ||
                       wPlayer.replaceAll(RegExp(r'\s+'), '').toLowerCase().contains(searchQuery);

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
    if (searchQuery.isNotEmpty) {
      final isMatchedGroup = m.groupName != null && matchedGroupNames.contains(m.groupName!);
      final isMatchedMatch = matchedMatchIds.contains(m.id);
      if (!isMatchedMatch && !isMatchedGroup) continue;
    }
    final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : 'カテゴリ未設定（全体）';
    matchesByCategory.putIfAbsent(cat, () => []).add(m);
  }

  final sortedEntries = matchesByCategory.entries.toList();
  
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
    if (weightA != weightB) return isAscending ? weightA.compareTo(weightB) : weightB.compareTo(weightA);
    return isAscending ? a.key.compareTo(b.key) : b.key.compareTo(a.key);
  });

  return TimelineMatchesResult(
    entries: sortedEntries,
    matchedGroupNames: matchedGroupNames,
    matchedMatchIds: matchedMatchIds,
  );
});

// 部内戦（Bunaiksen）用：進行中を上部、終了を下部に並び替えた試合リスト
final bunaiksenMatchesProvider = Provider.family.autoDispose<List<MatchModel>, String>((ref, tournamentId) {
  final matches = ref.watch(matchListProvider);
  final filtered = matches.where((m) => m.tournamentId == tournamentId).toList();
  return filtered..sort((a, b) {
    final aFinished = a.status == 'finished' || a.status == 'approved';
    final bFinished = b.status == 'finished' || b.status == 'approved';
    final aInProgress = a.status == 'in_progress';
    final bInProgress = b.status == 'in_progress';
    if (aFinished && !bFinished) return 1;
    if (!aFinished && bFinished) return -1;
    if (aInProgress && !bInProgress) return -1;
    if (!aInProgress && bInProgress) return 1;
    return b.order.compareTo(a.order);
  });
});

// 部内戦成績出力用：カテゴリごとのグループ化済みデータ
final bunaiksenRecordCategoryGroupsProvider = Provider.family.autoDispose<Map<String, Map<String, List<MatchModel>>>, String>((ref, tournamentId) {
  final matches = ref.watch(tournamentMatchesProvider(tournamentId));
  final categoryGroups = <String, Map<String, List<MatchModel>>>{};
  for (var m in matches) {
    final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : '部内戦';
    categoryGroups.putIfAbsent(cat, () => {});
    final groupKey = (m.groupName != null && m.groupName!.isNotEmpty) ? m.groupName! : '__default__';
    categoryGroups[cat]!.putIfAbsent(groupKey, () => []).add(m);
  }
  return categoryGroups;
});