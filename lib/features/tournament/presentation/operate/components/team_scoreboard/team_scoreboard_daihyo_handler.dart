import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/time/time_source.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

/// 団体戦スコアボード 代表戦追加ハンドラー
class TeamScoreboardDaihyoHandler {
  static Future<void> handleAddDaihyo({
    required BuildContext context,
    required WidgetRef ref,
    required List<MatchModel> teamMatches,
    required String redTeam,
    required String whiteTeam,
    required bool isDark,
  }) async {
    final first = teamMatches.first;
    final now = ref.read(timeSourceProvider).now();
    final nextMatchId = 'match_${now.millisecondsSinceEpoch}';
    final rule = first.rule;
    final isDaihyoIppon = rule?.isDaihyoIpponShobu ?? true;
    final double daihyoTime = rule != null
        ? rule.daihyoMatchTimeMinutes
        : (isDaihyoIppon ? 0.0 : first.matchTimeMinutes.toDouble());
    final bool hasExt = rule != null ? rule.daihyoHasExtension : true;
    final double extTime = rule != null ? rule.daihyoEnchoTimeMinutes : 3.0;
    final int extCount = rule != null ? rule.daihyoEnchoCount : -2;
    final bool hasHantei = rule != null ? rule.daihyoHasHantei : false;

    final newMatch = first.copyWith(
      id: nextMatchId,
      order: teamMatches.last.order + 1,
      matchType: '代表戦',
      redName: '$redTeam : 代表選手',
      whiteName: '$whiteTeam : 代表選手',
      status: 'scheduled',
      redScore: 0,
      whiteScore: 0,
      events: [],
      matchTimeMinutes: daihyoTime,
      hasExtension: hasExt,
      extensionTimeMinutes: extTime,
      extensionCount: extCount,
      hasHantei: hasHantei,
    );
    await ref.read(matchCommandProvider).addMatch(newMatch);

    if (!context.mounted) return;

    showAppDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppKendoColors.pureBlack.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: isDark
            ? const Color(0xFF2C2C2E)
            : context.appColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.round),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppKendoColors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppKendoColors.green,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '代表戦を追加しました',
                style: TextStyle(
                  fontSize: AppFontSize.title,
                  fontWeight: AppFontWeight.bold,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '代表戦のスコア入力に進みますか？',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      onPressed: () => ctx.pop(),
                      child: Text(
                        '一覧に戻る',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: AppKendoColors.pureWhite,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      onPressed: () {
                        ctx.pop();
                        context.push('/match/$nextMatchId');
                      },
                      child: const Text(
                        '試合へ進む',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
