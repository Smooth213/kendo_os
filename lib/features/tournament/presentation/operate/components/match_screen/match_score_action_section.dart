import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/action_buttons.dart';

/// 試合画面の赤・白打突入力アクションパネル
class MatchScoreActionSection extends ConsumerWidget {
  final String matchId;
  final bool isInputLocked;
  final bool isDark;

  const MatchScoreActionSection({
    super.key,
    required this.matchId,
    required this.isInputLocked,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final redPanel = ScoreActionPanel(
      matchId: matchId,
      side: Side.red,
      color: AppKendoColors.hansokuRed,
      isLocked: isInputLocked,
    );

    final whitePanel = ScoreActionPanel(
      matchId: matchId,
      side: Side.white,
      color: isDark
          ? const Color(0xFF1C1C1E)
          : context.appColors.cardBackground,
      textColor: context.appColors.textColor,
      isLocked: isInputLocked,
    );

    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: settings.leftHanded
            ? [whitePanel, redPanel]
            : [redPanel, whitePanel],
      ),
    );
  }
}
