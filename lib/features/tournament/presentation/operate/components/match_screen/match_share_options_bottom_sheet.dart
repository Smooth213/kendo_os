import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/p2p/presentation/components/p2p_broadcast_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/share_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 観戦の共有方法選択ボトムシート
class MatchShareOptionsBottomSheet extends ConsumerWidget {
  final MatchModel match;

  const MatchShareOptionsBottomSheet({super.key, required this.match});

  static Future<void> show(BuildContext context, {required MatchModel match}) {
    return showAppBottomSheet(
      context: context,
      backgroundColor: AppKendoColors.transparent,
      builder: (_) => MatchShareOptionsBottomSheet(match: match),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = context.appColors.cardBackground;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: subTextColor.withValues(alpha: 0.3),
                borderRadius: AppRadius.compact,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '観戦の共有方法を選択',
            style: TextStyle(
              fontSize: AppFontSize.header,
              fontWeight: AppFontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '用途に合わせて最適な共有方法を選択してください。',
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 1. LINE / クラウド共有
          InkWell(
            onTap: () {
              Navigator.pop(context);
              ref.read(shareProvider).shareMatch(match);
            },
            borderRadius: AppRadius.medium,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : context.appColors.separatorColor,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06C755).withValues(alpha: 0.15),
                      borderRadius: AppRadius.small,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF06C755),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📱 LINE / クラウドで共有',
                          style: TextStyle(
                            fontSize: AppFontSize.bodyMedium,
                            fontWeight: AppFontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '自宅の保護者や遠隔地へURLを送信（ネット必須）',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: subTextColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. 体育館ローカルP2P配信
          InkWell(
            onTap: () {
              Navigator.pop(context);
              P2pBroadcastDialog.show(context, match: match);
            },
            borderRadius: AppRadius.medium,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? context.appColors.primaryAccent.withValues(alpha: 0.15)
                    : context.appColors.primaryAccent.withValues(alpha: 0.08),
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: context.appColors.primaryAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.appColors.primaryAccent.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: AppRadius.small,
                    ),
                    child: Icon(
                      Icons.wifi_tethering,
                      color: context.appColors.primaryAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '📶 体育館ローカルP2P配信',
                              style: TextStyle(
                                fontSize: AppFontSize.bodyMedium,
                                fontWeight: AppFontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.subValue,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: AppKendoColors.ipponGold,
                                borderRadius: AppRadius.compact,
                              ),
                              child: const Text(
                                '圏外OK',
                                style: TextStyle(
                                  fontSize: AppFontSize.badge,
                                  fontWeight: AppFontWeight.bold,
                                  color: AppKendoColors.pureWhite,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '2階席の保護者へQRコードで即時配信（アプリ不要・0遅延）',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.appColors.primaryAccent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
