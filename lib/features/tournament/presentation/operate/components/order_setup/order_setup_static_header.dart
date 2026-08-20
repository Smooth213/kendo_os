import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 オーダー設定画面 静的グラデーションヘッダー（レスポンシブ・進行プログレスバー付き）
class OrderSetupStaticHeader extends StatelessWidget {
  final AppThemeColors themeColors;

  const OrderSetupStaticHeader({super.key, required this.themeColors});

  @override
  Widget build(BuildContext context) {
    // ★ 横画面（かつ高さ500以下）のスマホ・タブレットではヘッダーを隠して作業領域を確保
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape && MediaQuery.of(context).size.height < 500) {
      return const SizedBox.shrink();
    }

    final color1 = themeColors.primaryAccent;
    final endColor = themeColors.softAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.giantValue),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最終ステップ: オーダー編成',
            style: TextStyle(
              fontSize: AppFontSize.display,
              fontWeight: AppFontWeight.bold,
              color: AppKendoColors.pureWhite,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '対戦相手と出場選手を決定し、\n試合枠を生成します',
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              color: AppKendoColors.pureWhite.withValues(alpha: 0.9),
              fontWeight: AppFontWeight.medium,
            ),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: AppKendoColors.pureWhite.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppKendoColors.pureWhite,
            ),
            minHeight: 6,
            borderRadius: AppRadius.tiny,
          ),
        ],
      ),
    );
  }
}
