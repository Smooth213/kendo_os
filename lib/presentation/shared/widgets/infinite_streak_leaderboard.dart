import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../operate/providers/bunaiksen_provider.dart';

class InfiniteStreakLeaderboard extends ConsumerWidget {
  const InfiniteStreakLeaderboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaks = ref.watch(bunaiksenInfiniteStreakProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (streaks.isEmpty || !streaks.values.any((v) => v > 0)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('まだ連勝記録はありません', style: TextStyle(color: Colors.grey)),
      );
    }

    // 連勝数で降順にソートし、Top3を抽出
    final sorted = streaks.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.where((e) => e.value > 0).take(3).toList();

    return Column(
      children: top.map((e) {
        final isTop = e.key == top.first.key && e.value > 0;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.military_tech, 
            color: isTop ? Colors.amber : (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
          ),
          title: Text(e.key, style: TextStyle(fontWeight: isTop ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white : Colors.black87)),
          trailing: Text('${e.value} 連勝', style: TextStyle(fontWeight: FontWeight.bold, color: isTop ? Colors.red.shade600 : (isDark ? Colors.grey.shade300 : Colors.black87), fontSize: 15)),
        );
      }).toList(),
    );
  }
}