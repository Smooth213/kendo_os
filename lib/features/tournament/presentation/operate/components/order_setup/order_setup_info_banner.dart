import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 オーダー設定画面 選手選択案内バナー
class OrderSetupInfoBanner extends StatelessWidget {
  final AppThemeColors themeColors;

  const OrderSetupInfoBanner({super.key, required this.themeColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: themeColors.softAccent,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: themeColors.primaryAccent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '自チームの選手を選択し、必要に応じて相手のチーム・選手名を入力してください。',
              style: TextStyle(color: context.appColors.subTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
