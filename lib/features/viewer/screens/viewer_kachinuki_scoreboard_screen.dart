import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/shared/widgets/liquid_background.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';

class ViewerKachinukiScoreboardScreen extends ConsumerWidget {
  final String groupName;
  const ViewerKachinukiScoreboardScreen({super.key, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : context.appColors.primaryAccent;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: AppKendoColors.transparent,
        appBar: AppHeader(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          title: '勝ち抜き戦 記録 (観戦)',
          elevation: 0,
        ),
        // 既存の勝ち抜き戦スコアボードをそのまま再利用
        body: KachinukiScoreboardScreen(groupName: groupName),
      ),
    );
  }
}
