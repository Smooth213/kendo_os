import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/match_screen/smart_undo_floating_bar.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_ui_assist_provider.dart';
import 'package:kendo_os/shared/application/services/kendo_haptics.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/action_buttons.dart';

/// 試合画面の赤・白打突入力アクションパネル（左右反転・スマートUndo統合）
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
    final isFlipped = ref.watch(isMatchViewFlippedProvider(matchId));

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

    // 通常時: [redPanel, whitePanel] (左が赤、右が白)
    // 反転時または左利き設定時: [whitePanel, redPanel] (左が白、右が赤)
    final shouldFlip = isFlipped ^ settings.leftHanded;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: shouldFlip
                  ? [whitePanel, redPanel]
                  : [redPanel, whitePanel],
            ),
          ),
        ),

        // 中央上部の視点反転トグルボタン
        Positioned(
          top: 2,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: isDark
                  ? const Color(0xFF2C2C2E).withValues(alpha: 0.85)
                  : const Color(0xFFFFFFFF).withValues(alpha: 0.90),
              borderRadius: AppRadius.full,
              elevation: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  KendoHaptics.viewFlip();
                  ref.read(isMatchViewFlippedProvider(matchId).notifier).state =
                      !isFlipped;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 14,
                        color: isFlipped
                            ? const Color(0xFFD97706)
                            : (isDark
                                  ? AppKendoColors.pureWhite
                                  : AppKendoColors.pureBlack),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isFlipped ? '逆サイド視点' : '正面視点',
                        style: TextStyle(
                          fontSize: AppFontSize.badge,
                          fontWeight: AppFontWeight.bold,
                          color: isFlipped
                              ? const Color(0xFFD97706)
                              : (isDark
                                    ? AppKendoColors.pureWhite
                                    : AppKendoColors.pureBlack),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 浮遊スマートUndoバー（直近イベント発生時の5秒間表示）
        Positioned(
          bottom: 4,
          left: 0,
          right: 0,
          child: SmartUndoFloatingBar(matchId: matchId, isDark: isDark),
        ),
      ],
    );
  }
}
