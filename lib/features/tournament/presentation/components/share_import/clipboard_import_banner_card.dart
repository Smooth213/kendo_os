import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/application/clipboard_import_service.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// クリップボードからの大会情報取り込みを案内・実行する解説付きバナーカード。
///
/// 手入力の手間を省くアシスト機能としての発見性を高め、
/// 共有テキスト（LINE・メール等）からのワンタップ反映を促します。
class ClipboardImportBannerCard extends ConsumerWidget {
  final VoidCallback? onImportCompleted;
  final EdgeInsetsGeometry? margin;

  const ClipboardImportBannerCard({
    super.key,
    this.onImportCompleted,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appColors = context.appColors;

    // ライト/ダークモード双方で高い視認性と上質感を両立するカラーパレット
    final accentColor = isDark
        ? const Color(0xFFFBBF24) // 鮮やかなアンバーゴールド
        : const Color(0xFFB45309); // 高コントラスト・ディープアンバー

    final cardBgColor = isDark
        ? const Color(0xFF231F17) // ダークサーフェスに暖かみのあるトーン
        : const Color(0xFFFFFBEB); // 明るく柔らかなアンバー50

    final borderColor = isDark
        ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
        : const Color(0xFFD97706).withValues(alpha: 0.28);

    final iconBadgeBg = isDark
        ? const Color(0xFFF59E0B).withValues(alpha: 0.20)
        : const Color(0xFFFEF3C7);

    final descTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF4B5563);

    final shadowColor = isDark
        ? appColors.cardShadowColor
        : const Color(0xFFD97706).withValues(alpha: 0.06);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: AppRadius.large,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: AppKendoColors.transparent,
        child: InkWell(
          borderRadius: AppRadius.large,
          onTap: () {
            AppHaptics.light();
            ref.read(clipboardImportServiceProvider).importManually(context);
            onImportCompleted?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // アイコンバッジ
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBadgeBg,
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.content_paste_go_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // タイトルと解説
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'クリップボードから自動入力',
                              style: TextStyle(
                                fontSize: AppFontSize.body,
                                fontWeight: AppFontWeight.bold,
                                color: appColors.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: AppRadius.micro,
                            ),
                            child: Text(
                              '便利',
                              style: TextStyle(
                                fontSize: AppFontSize.micro,
                                fontWeight: AppFontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '共有された大会テキストをコピーしていれば、大会名・日程・チーム情報をワンタップで反映できます',
                        style: TextStyle(
                          fontSize: AppFontSize.small,
                          color: descTextColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // 矢印インジケーター
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: accentColor.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
