import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 試合形式設定画面 ダイナミックグラデーションヘッダー（レスポンシブ・プログレスバー付き）
class MatchFormatDynamicHeader extends StatelessWidget {
  final int currentPage;
  final AppThemeColors themeColors;

  const MatchFormatDynamicHeader({
    super.key,
    required this.currentPage,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ★ 画面が横向き（かつ高さ500以下）のスマホ・タブレットではヘッダーを隠して作業領域を確保
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        if (isLandscape && MediaQuery.of(context).size.height < 500) {
          return const SizedBox.shrink();
        }

        final t = (currentPage / 1).clamp(0.0, 1.0);

        final color1 = themeColors.primaryAccent;
        final color2 = themeColors.primaryAccent.withValues(alpha: 0.8);
        final endColor = themeColors.softAccent;

        final gradientColor = Color.lerp(color1, color2, t)!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientColor, endColor],
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
                '試合ルールの設定',
                style: TextStyle(
                  fontSize: AppFontSize.heroLarge,
                  fontWeight: AppFontWeight.bold,
                  color: AppKendoColors.pureWhite,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '魔法のウィザードに従って、\n2つのステップで条件を設定しましょう',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  color: AppKendoColors.pureWhite.withValues(alpha: 0.9),
                  fontWeight: AppFontWeight.medium,
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: (currentPage + 1) / 2,
                backgroundColor: AppKendoColors.pureWhite.withValues(
                  alpha: 0.3,
                ),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppKendoColors.pureWhite,
                ),
                minHeight: 6,
                borderRadius: AppRadius.tiny,
              ),
            ],
          ),
        );
      },
    );
  }
}
