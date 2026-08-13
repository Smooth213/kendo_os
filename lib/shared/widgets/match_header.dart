import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_timer_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class MatchHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String matchId; // ★ IDのみに変更
  final bool isInputLocked;

  const MatchHeader({
    super.key,
    required this.matchId,
    required this.isInputLocked,
  });

  @override
  Size get preferredSize => const Size.fromHeight(150);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ 試合の特定ステータスだけをピンポイント監視
    final matchStatus = ref.watch(
      matchListProvider.select(
        (list) =>
            list.where((m) => m.id == matchId).firstOrNull?.status ?? 'waiting',
      ),
    );
    final isApproved = matchStatus == 'approved';

    // 大会全体の状況判断も、ヘッダー自身が行う
    final isAllDone = ref.watch(
      matchListProvider.select((list) {
        final match = list.where((m) => m.id == matchId).firstOrNull;
        if (match == null || match.groupName == null) return false;
        return list
            .where((m) => m.groupName == match.groupName)
            .every((m) => m.status == 'finished' || m.status == 'approved');
      }),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final headerColor = isDark
        ? themeColors.cardBackground
        : themeColors.primaryAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: headerColor,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppKendoColors.pureWhite,
                      size: 20,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        // 名前だけを監視
                        final names = ref.watch(
                          matchListProvider.select((list) {
                            final m = list
                                .where((m) => m.id == matchId)
                                .firstOrNull;
                            return '${m?.redName ?? ""} vs ${m?.whiteName ?? ""}';
                          }),
                        );
                        return Text(
                          names,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppKendoColors.pureWhite,
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.subhead,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              // ステータスバッジ
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isApproved
                      ? AppKendoColors.successGreen
                      : (isAllDone
                            ? const Color(0xFFFF9800)
                            : AppKendoColors.pureWhite.withValues(alpha: 0.24)),
                  borderRadius: AppRadius.medium,
                ),
                child: Text(
                  isApproved ? '記録確定済み' : (isAllDone ? '全試合終了' : '試合進行中'),
                  style: const TextStyle(
                    color: AppKendoColors.pureWhite,
                    fontSize: AppFontSize.small,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // マスタータイマー表示
        _MasterTimerBanner(matchId: matchId),
      ],
    );
  }
}

class _MasterTimerBanner extends ConsumerWidget {
  final String matchId;
  const _MasterTimerBanner({required this.matchId});

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 試合データから groupName を取得
    final groupName = ref.watch(
      matchListProvider.select(
        (list) => list.where((m) => m.id == matchId).firstOrNull?.groupName,
      ),
    );

    if (groupName == null || groupName.isEmpty) return const SizedBox.shrink();

    // ★ 修正: 正しいプロバイダから秒数を取得する
    final masterTime = ref.watch(renseikaiMasterTimerProvider(groupName));
    final isTimeUp = masterTime == 0;
    final displayTime = _formatTime(masterTime > 0 ? masterTime : 0);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isTimeUp
        ? (isDark
              ? context.appColors.errorColor.withValues(alpha: 0.3)
              : context.appColors.errorColor)
        : (isDark
              ? context.appColors.primaryAccent.withValues(alpha: 0.3)
              : context.appColors.primaryAccent);

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Center(
        child: Text(
          isTimeUp ? '錬成会 終了時間！' : '全体の残り時間: $displayTime',
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            color: isTimeUp
                ? AppKendoColors.red
                : (isDark ? const Color(0xFF3F51B5) : const Color(0xFF3F51B5)),
          ),
        ),
      ),
    );
  }
}
