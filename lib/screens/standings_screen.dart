import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/match_list_provider.dart';
import '../repositories/player_repository.dart';
import '../models/player_model.dart';

final playerListProvider = StreamProvider.autoDispose<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).getPlayers();
});

class PlayerStats {
  final String name;
  int matches = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;
  int pointsScored = 0;
  double matchPoints = 0.0; // ★ 追加：勝ち点

  PlayerStats(this.name);
}

class StandingsScreen extends ConsumerWidget {
  final String tournamentId;
  const StandingsScreen({super.key, required this.tournamentId});

  String _formatWinRate(double rate) {
    if (rate >= 1.0) return '10割';
    if (rate <= 0.0) return '0割';
    
    int wari = (rate * 10).floor() % 10;
    int bu = (rate * 100).floor() % 10;
    int rin = (rate * 1000).floor() % 10;
    
    if (bu == 0 && rin == 0) return '$wari割';
    if (rin == 0) return '$wari割$bu分';
    return '$wari割$bu分$rin厘';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ Step 3-2: selectを使い、計算に必要なこの大会の試合データのみを監視
    final matches = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.tournamentId == tournamentId).toList()
    ));
    
    // iOS Native: True Black & Elevation
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade700;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade200;
    final headerTextColor = isDark ? Colors.white : Colors.indigo.shade900;

    final playerListAsync = ref.watch(playerListProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: headerTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('成績・順位表', style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor)),
        backgroundColor: Colors.transparent, // 透かし
        elevation: 0,
      ),
      body: playerListAsync.when(
        data: (players) {
          final statsMap = <String, PlayerStats>{};
          for (var match in matches) {
            if (match.status != 'approved' && match.status != 'finished') continue;

            statsMap.putIfAbsent(match.redName, () => PlayerStats(match.redName));
            statsMap.putIfAbsent(match.whiteName, () => PlayerStats(match.whiteName));

            final redStats = statsMap[match.redName]!;
            final whiteStats = statsMap[match.whiteName]!;

            redStats.matches++;
            whiteStats.matches++;

            final rScore = (match.redScore as num).toInt();
            final wScore = (match.whiteScore as num).toInt();

            redStats.pointsScored += rScore;
            whiteStats.pointsScored += wScore;

            // ★ 勝ち点ロジックの適用
            final r = match.rule;
            if (rScore > wScore) {
              redStats.wins++;
              whiteStats.losses++;
              if (r != null && r.isLeague) {
                redStats.matchPoints += r.winPoint;
                whiteStats.matchPoints += r.lossPoint;
              }
            } else if (wScore > rScore) {
              whiteStats.wins++;
              redStats.losses++;
              if (r != null && r.isLeague) {
                whiteStats.matchPoints += r.winPoint;
                redStats.matchPoints += r.lossPoint;
              }
            } else {
              redStats.draws++;
              whiteStats.draws++;
              if (r != null && r.isLeague) {
                redStats.matchPoints += r.drawPoint;
                whiteStats.matchPoints += r.drawPoint;
              }
            }
          }

          final sortedStats = statsMap.values.where((s) => s.matches > 0).toList();
          sortedStats.sort((a, b) {
            // ★ 修正：最優先を「勝ち点」にする
            if (b.matchPoints != a.matchPoints) return b.matchPoints.compareTo(a.matchPoints);
            if (b.wins != a.wins) return b.wins.compareTo(a.wins);
            if (a.losses != b.losses) return a.losses.compareTo(b.losses);
            return b.pointsScored.compareTo(a.pointsScored);
          });

          if (sortedStats.isEmpty) {
            return Center(child: Text('まだ承認済みの試合結果がありません', style: TextStyle(color: subTextColor)));
          }

          // ★ 修正：3チーム以上の完全同点に対応（勝ち点誤差対策込）
          final tieGroups = <List<PlayerStats>>[];
          if (sortedStats.length > 1) {
            List<PlayerStats> currentTie = [sortedStats.first];
            const double epsilon = 0.001; 

            for (int i = 1; i < sortedStats.length; i++) {
              final prev = sortedStats[i - 1];
              final curr = sortedStats[i];
              
              bool isTie = (prev.matchPoints - curr.matchPoints).abs() < epsilon && 
                           prev.wins == curr.wins && 
                           prev.pointsScored == curr.pointsScored;

              if (isTie) {
                currentTie.add(curr);
              } else {
                if (currentTie.length > 1) tieGroups.add(List.from(currentTie));
                currentTie = [curr];
              }
            }
            if (currentTie.length > 1) tieGroups.add(currentTie);
          }

          return Column(
            children: [
              // 元々の順位表リスト
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedStats.length,
                  itemBuilder: (context, index) {
                    final stat = sortedStats[index];
              final winRate = stat.matches > 0 ? (stat.wins / stat.matches) : 0.0;
              final rateStr = _formatWinRate(winRate);

              Color avatarColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200;
              Color iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

              if (index == 0) { avatarColor = isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade100; iconColor = isDark ? Colors.amber.shade400 : Colors.amber.shade600; }
              else if (index == 1) { avatarColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300; iconColor = isDark ? Colors.grey.shade300 : Colors.grey.shade600; }
              else if (index == 2) { avatarColor = isDark ? Colors.brown.shade900.withValues(alpha: 0.5) : Colors.orange.shade100; iconColor = isDark ? Colors.orange.shade300 : Colors.brown.shade400; }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // iOS角丸
                  side: isDark ? BorderSide.none : BorderSide(color: borderColor),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: avatarColor,
                    radius: 24,
                    child: index < 3 
                      ? Icon(Icons.military_tech, color: iconColor, size: 28)
                      : Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 18)),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(stat.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor))),
                      Text('勝率: $rateStr', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600, fontSize: 15)),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${stat.matches}試合: ${stat.wins}勝 ${stat.losses}敗 ${stat.draws}分 / 取得: ${stat.pointsScored}本',
                      style: TextStyle(color: subTextColor, fontSize: 13),
                    ),
                  ),
                ),
              );
            },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('エラーが発生しました: $e', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
      ),
    );
  }
}