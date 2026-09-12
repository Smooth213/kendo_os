import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';

/// 観戦者用 勝ち抜き戦スコアボード画面
class ViewerKachinukiScoreboardScreen extends StatelessWidget {
  final String groupName;
  const ViewerKachinukiScoreboardScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return KachinukiScoreboardScreen(groupName: groupName, isViewer: true);
  }
}
