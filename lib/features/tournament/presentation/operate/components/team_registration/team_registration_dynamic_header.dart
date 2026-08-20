import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 チーム登録画面 動的グラデーションヘッダー（ステッププログレスバー付き）
class TeamRegistrationDynamicHeader extends StatelessWidget {
  final int currentPage;
  final AppThemeColors themeColors;

  const TeamRegistrationDynamicHeader({
    super.key,
    required this.currentPage,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final t = (currentPage / 2).clamp(0.0, 1.0);
        final gradientColor = Color.lerp(
          themeColors.primaryAccent,
          themeColors.primaryAccent.withValues(alpha: 0.8),
          t,
        )!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientColor, themeColors.softAccent],
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
                'チームとオーダー登録',
                style: TextStyle(
                  fontSize: AppFontSize.heroLarge,
                  fontWeight: AppFontWeight.bold,
                  color: AppKendoColors.pureWhite,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '魔法のウィザードに従って、\n3つのステップで編成を完了しましょう',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  color: AppKendoColors.pureWhite.withValues(alpha: 0.9),
                  fontWeight: AppFontWeight.medium,
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: (currentPage + 1) / 3,
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
