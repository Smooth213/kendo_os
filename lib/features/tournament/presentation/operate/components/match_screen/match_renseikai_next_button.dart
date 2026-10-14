import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/utils/app_snack_bar.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 時間制錬成会用「追加して継続 / 確定して終了」ボトムアクションボタン群
class MatchRenseikaiNextButton extends ConsumerWidget {
  final MatchModel match;
  final bool isViewOnly;
  final String currentUserId;
  final VoidCallback onAddNext;
  final Future<void> Function() onConfirmAndFinish;

  const MatchRenseikaiNextButton({
    super.key,
    required this.match,
    required this.isViewOnly,
    required this.currentUserId,
    required this.onAddNext,
    required this.onConfirmAndFinish,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterTime = ref.watch(
      renseikaiMasterTimerProvider(match.groupName ?? ''),
    );
    final isTimeUp = masterTime == 0;
    final isInputLocked =
        match.scorerId != null && match.scorerId != currentUserId;
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmAction = isViewOnly
        ? null
        : () async {
            if (settings.haptic) {
              HapticFeedback.heavyImpact();
            }
            await onConfirmAndFinish();
          };

    return Row(
      children: [
        Expanded(
          child: GlassButton.custom(
            onPressed: (isInputLocked || isTimeUp) ? null : onAddNext,
            color: AppKendoColors.teal,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.autorenew,
                      size: 18,
                      color: AppKendoColors.pureWhite,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      '追加して継続',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.bodyMedium,
                        color: AppKendoColors.pureWhite,
                      ),
                    ),
                  ],
                ),
                Text(
                  '※現在の枠内に追加',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: AppKendoColors.pureWhite,
                    fontWeight: AppFontWeight.regular,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GestureDetector(
            onDoubleTap: settings.confirmBehavior == 'double'
                ? confirmAction
                : null,
            child: ElevatedButton.icon(
              onPressed: settings.confirmBehavior == 'single'
                  ? confirmAction
                  : (isViewOnly
                        ? null
                        : () => AppSnackBar.show(
                            context,
                            settings.confirmBehavior == 'double'
                                ? 'ダブルタップで確定してください'
                                : '長押しで確定してください',
                          )),
              onLongPress: settings.confirmBehavior == 'long'
                  ? confirmAction
                  : null,
              icon: const Icon(Icons.verified, size: 24),
              label: const Text(
                '確定して終了',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppFontSize.bodyMedium,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF3F51B5)
                    : const Color(0xFF3F51B5),
                foregroundColor: const Color(0xFFFFFFFF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                elevation: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
