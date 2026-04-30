import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'kachinuki_scoreboard_screen.dart';

class ViewerKachinukiScoreboardScreen extends ConsumerWidget {
  final String groupName;
  const ViewerKachinukiScoreboardScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDark ? Colors.white : Colors.indigo.shade900;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: headerTextColor, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('勝ち抜き戦 記録 (観戦)', style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor, fontSize: 16)),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
      ),
      // 既存の勝ち抜き戦スコアボードをそのまま再利用
      body: KachinukiScoreboardScreen(groupName: groupName),
    );
  }
}