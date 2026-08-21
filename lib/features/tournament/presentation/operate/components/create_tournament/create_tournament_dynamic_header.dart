import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 大会新規作成画面のダイナミックグラデーションヘッダー
class CreateTournamentDynamicHeader extends StatelessWidget {
  final double currentProgress;

  const CreateTournamentDynamicHeader({
    super.key,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    final t = (currentProgress / 1).clamp(0.0, 1.0);

    final color1 = context.appColors.primaryAccent;
    final color2 = context.appColors.primaryAccent;
    final endColor = context.appColors.primaryAccent;
    final gradientColor = Color.lerp(color1, color2, t) ?? color1;

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
            '大会を新規作成',
            style: TextStyle(
              fontSize: AppFontSize.hero,
              fontWeight: AppFontWeight.bold,
              color: AppKendoColors.pureWhite,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '魔法のウィザードに従って、\n2つのステップで設定を完了しましょう',
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              color: AppKendoColors.pureWhite.withValues(alpha: 0.9),
              fontWeight: AppFontWeight.medium,
            ),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: (currentProgress + 1) / 2,
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
