import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/application/services/kendo_haptics.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 形・基本判定試合専用の判定入力アクションセクション
class KataScoreActionSection extends ConsumerWidget {
  final String matchId;
  final bool isInputLocked;
  final bool isDark;
  final bool hasEvents;

  const KataScoreActionSection({
    super.key,
    required this.matchId,
    required this.isInputLocked,
    required this.isDark,
    required this.hasEvents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(isMatchCommandProcessingProvider);
    final bool effectiveLocked = isInputLocked || isProcessing;
    final themeColors = context.appColors;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
          borderRadius: AppRadius.medium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 審判旗判定ボタン群 (赤勝ち 2種 / 白勝ち 2種)
            Row(
              children: [
                // 赤 判定勝ちグループ
                Expanded(
                  child: Column(
                    children: [
                      _buildJudgeButton(
                        label: '赤 3 - 0 白',
                        subLabel: '赤旗 3本',
                        isRed: true,
                        disabled: effectiveLocked,
                        onTap: () async {
                          await KendoHaptics.scorePoint();
                          ref
                              .read(matchCommandProvider)
                              .addKataJudge(matchId, 3, 0);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildJudgeButton(
                        label: '赤 2 - 1 白',
                        subLabel: '赤旗 2本',
                        isRed: true,
                        disabled: effectiveLocked,
                        onTap: () async {
                          await KendoHaptics.scorePoint();
                          ref
                              .read(matchCommandProvider)
                              .addKataJudge(matchId, 2, 1);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 白 判定勝ちグループ
                Expanded(
                  child: Column(
                    children: [
                      _buildJudgeButton(
                        label: '赤 0 - 3 白',
                        subLabel: '白旗 3本',
                        isRed: false,
                        disabled: effectiveLocked,
                        onTap: () async {
                          await KendoHaptics.scorePoint();
                          ref
                              .read(matchCommandProvider)
                              .addKataJudge(matchId, 0, 3);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildJudgeButton(
                        label: '赤 1 - 2 白',
                        subLabel: '白旗 2本',
                        isRed: false,
                        disabled: effectiveLocked,
                        onTap: () async {
                          await KendoHaptics.scorePoint();
                          ref
                              .read(matchCommandProvider)
                              .addKataJudge(matchId, 1, 2);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // 不戦勝ボタン (赤 / 白)
            Row(
              children: [
                Expanded(
                  child: _buildFusenButton(
                    label: '赤 不戦勝',
                    isRed: true,
                    disabled: effectiveLocked,
                    onTap: () async {
                      await KendoHaptics.scorePoint();
                      ref
                          .read(matchCommandProvider)
                          .addScoreEvent(matchId, Side.red, PointType.fusen);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildFusenButton(
                    label: '白 不戦勝',
                    isRed: false,
                    disabled: effectiveLocked,
                    onTap: () async {
                      await KendoHaptics.scorePoint();
                      ref
                          .read(matchCommandProvider)
                          .addScoreEvent(matchId, Side.white, PointType.fusen);
                    },
                  ),
                ),
              ],
            ),

            // 取消 (Undo) ボタン (イベントが存在するときのみ有効)
            if (hasEvents) ...[
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: effectiveLocked
                      ? null
                      : () async {
                          await KendoHaptics.undoEvent();
                          ref.read(matchCommandProvider).undoLastEvent(matchId);
                        },
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text(
                    '直前の判定を取り消す (Undo)',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.semiBold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: themeColors.subTextColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJudgeButton({
    required String label,
    required String subLabel,
    required bool isRed,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    final bgColor = isRed
        ? AppKendoColors.hansokuRed
        : AppKendoColors.pureWhite;
    final textColor = isRed
        ? AppKendoColors.pureWhite
        : AppKendoColors.pureBlack;
    final borderColor = isRed
        ? AppKendoColors.hansokuRed
        : const Color(0xFFD1D1D6);

    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Material(
        color: bgColor,
        borderRadius: AppRadius.small,
        elevation: isRed ? 1.0 : 0.5,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: AppRadius.small,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              borderRadius: AppRadius.small,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                Text(
                  subLabel,
                  style: TextStyle(
                    color: isRed
                        ? AppKendoColors.pureWhite.withValues(alpha: 0.7)
                        : const Color(0xFF8E8E93),
                    fontSize: AppFontSize.micro,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFusenButton({
    required String label,
    required bool isRed,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    final accentColor = isRed
        ? AppKendoColors.hansokuRed
        : const Color(0xFF636366);

    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: OutlinedButton(
        onPressed: disabled ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accentColor, width: 1.0),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: accentColor,
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
      ),
    );
  }
}
