import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/infinite_streak_leaderboard.dart';

/// 🥋 部内戦 無限勝ち抜き連勝ランキングカード
class BunaiksenLeaderboardCard extends StatelessWidget {
  const BunaiksenLeaderboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Card(
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppKendoColors.deepOrange,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '無限勝ち抜き 連勝ランキング',
                    style: TextStyle(
                      fontSize: AppFontSize.subhead,
                      fontWeight: AppFontWeight.bold,
                      color: context.appColors.textColor,
                    ),
                  ),
                ],
              ),
              const Divider(),
              const InfiniteStreakLeaderboard(),
            ],
          ),
        ),
      ),
    );
  }
}
